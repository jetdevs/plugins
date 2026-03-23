---
name: plugin-authoring
description: Use when creating, scaffolding, or debugging Cadra runtime plugins. Also use when the user mentions "cadra plugin", "plugin manifest", "plugin authoring", "register_hooks", "plugin marketplace", "V8 isolate", "plugin bundle", or asks about "tools vs plugins".
---

# Cadra Runtime Plugin Authoring

Create, scaffold, and debug runtime plugins that extend the Cadra platform.

## Tools vs Plugins — CRITICAL DISTINCTION

**Tools** and **Plugins** are different concepts in Cadra. Getting this wrong wastes effort.

### Tools = API integrations agents call

Tools are **typed functions that agents invoke** — REST endpoints, MCP servers, webhooks. They are configured in the UI, stored in the `tools` database table with credentials, and require NO code deployment.

**Use a Tool when:** you want agents to call an external API (Notion, Slack, GitHub, Stripe, etc.)

How to create: Use the `create-tools` or `ai-saas-tool-creation` skill. Define endpoints, JSON Schema, credentials — all via SQL or UI. No code, no bundle, no V8 isolate.

Example: Notion integration → **Tool** (REST API with 12 endpoints + Bearer credential)

### Plugins = code that extends the platform

Plugins are **JavaScript bundles running in V8 isolates** that extend the platform itself — custom hooks, context engines, channel adapters, and computed/composite tools that need logic beyond simple HTTP calls.

**Use a Plugin when:**
- Custom lifecycle hooks (compliance logging, audit trails, Slack notifications on execution)
- Custom context engines (specialized RAG, domain-specific retrieval)
- Custom channel adapters (new messaging platforms)
- Composite tools that need orchestration logic, caching, or state across calls
- Tools that need storage (counters, caches, session state)

Example: "Log all agent executions to Datadog" → **Plugin** (registers `post_execution` hook)
Example: "Send Slack alert when agent fails" → **Plugin** (registers `on_error` hook)

### Decision Matrix

| Need | Solution | Why |
|------|----------|-----|
| Call a REST API | **Tool** (UI config) | No code needed, just endpoints + credentials |
| Call an MCP server | **Tool** (MCP type) | Built-in MCP support with STDIO/HTTP/WebSocket |
| Hook into agent lifecycle | **Plugin** | Only plugins can register hooks |
| Custom RAG context engine | **Plugin** | Only plugins can register context engines |
| Custom messaging channel | **Plugin** | Only plugins can register channels |
| Tool with complex logic | **Plugin** | When simple HTTP call isn't enough |
| Tool that needs persistent state | **Plugin** | Plugin storage API (key-value, 1000 keys) |

## Plugin Architecture Overview

Cadra plugins are JavaScript bundles that run in V8 isolates within cadra-api. They can register hooks, context engines, channel adapters, and composite tools.

```
my-plugin/
  plugin.json          # Manifest (required)
  src/
    index.ts           # Entry point — exports default async init(api)
    hooks/             # Hook handlers
  dist/
    bundle.js          # Compiled output (esbuild, single file)
  package.json
  tsconfig.json
```

## Plugin Manifest (`plugin.json`)

```json
{
  "id": "com.company.plugin-name",
  "name": "Human-Readable Name",
  "version": "1.0.0",
  "description": "What this plugin does",
  "author": { "name": "Company", "email": "dev@company.com" },
  "entry": "bundle.js",
  "capabilities": ["register_hooks", "http_outbound", "storage", "log"],
  "permissions": [],
  "config": [
    { "key": "webhookUrl", "label": "Webhook URL", "type": "string", "required": true }
  ],
  "category": "Monitoring",
  "tags": ["observability"],
  "license": "MIT"
}
```

### Capabilities (request only what you need)

| Capability | Purpose |
|------------|---------|
| `register_tools` | Register composite/computed tools (prefer Tool UI for simple APIs) |
| `register_hooks` | Register lifecycle event handlers |
| `register_context_engine` | Register RAG context engines |
| `register_channel` | Register messaging channel adapters |
| `storage` | Key-value storage (1000 keys, 64KB/value) |
| `http_outbound` | HTTP requests (60/min rate limit, 30s max timeout) |
| `log` | Structured logging (always available) |

### Config Field Types

`string`, `number`, `boolean`, `select` (with `options` array)

## Entry Point Pattern

```typescript
export default async function init(api: CadraPluginApi) {
  const config = api.meta.config;
  api.log.info('Plugin loaded', { version: api.meta.version });

  // Example: Slack notification on agent error
  await api.registerHook('on_error', async (context) => {
    await api.http.fetch(config.webhookUrl as string, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        text: `Agent execution failed: ${context.error?.message}`,
        blocks: [{
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `*Agent Error*\n• Execution: \`${context.executionId}\`\n• Error: ${context.error?.message}`
          }
        }]
      })
    });
  });

  // Example: Track execution count in storage
  await api.registerHook('post_execution', async (context) => {
    const key = `count:${new Date().toISOString().slice(0, 10)}`;
    const current = await api.storage.get(key);
    await api.storage.set(key, String((parseInt(current || '0') + 1)), 86400 * 30);
    api.log.info('Execution tracked', { executionId: context.executionId });
  });
}
```

## CadraPluginApi Reference

```typescript
interface CadraPluginApi {
  registerTool(def: PluginToolDefinition): Promise<void>;
  registerHook(event: PluginHookEvent, handler: Function): Promise<void>;
  registerContextEngine(engine: PluginContextEngine): Promise<void>;
  registerChannel(adapter: PluginChannelAdapter): Promise<void>;
  storage: { get(k): Promise<string|null>, set(k,v,ttl?): Promise<void>, delete(k): Promise<void>, keys(prefix): Promise<string[]> };
  http: { fetch(url, opts?): Promise<{ status, statusText, body, json, headers }> };
  log: { info(msg, data?), warn(msg, data?), error(msg, data?) };
  meta: { orgId: string, pluginId: string, version: string, config: Record<string,unknown> };
}
```

## Hook Events

| Event | When | Context fields |
|-------|------|---------------|
| `pre_execution` | Before agent starts | executionId, agentId, orgId |
| `post_execution` | After agent completes | executionId, agentId, orgId |
| `pre_tool_call` | Before tool invocation | toolName, toolParams |
| `post_tool_call` | After tool returns | toolName, toolResult |
| `on_error` | On execution error | error.message, error.code |
| `on_delegation` | On sub-agent delegation | executionId |

Hook timeout: 2 seconds. Errors logged but don't fail execution.

## Database Tables (cadra-web)

| Table | Scope | Purpose |
|-------|-------|---------|
| `plugin_manifests` | Global | Plugin metadata, status, ratings |
| `plugin_versions` | Global | Version history, bundle hash |
| `org_plugins` | Per-org (RLS) | Installation, config, approved capabilities |
| `plugin_ratings` | Per-org (RLS) | User ratings and reviews |

## Key Source Files

### cadra-web (Plugin Management)
- `src/extensions/plugins/schema.ts` — Drizzle table definitions
- `src/extensions/plugins/router.ts` — tRPC CRUD procedures
- `src/extensions/plugins/repository.ts` — DB queries
- `src/extensions/plugins/components/PluginManagementPage.tsx` — Marketplace UI

### cadra-api (Plugin Runtime)
- `src/services/plugins/types.ts` — TypeScript interfaces
- `src/services/plugins/schemas.ts` — Manifest validation (Zod)
- `src/services/plugins/sandbox.ts` — V8 isolate execution
- `src/services/plugins/loader.ts` — Plugin loading and lifecycle
- `src/services/plugins/registry.ts` — In-memory registry
- `src/services/plugins/api-impl.ts` — CadraPluginApi implementation

### cadra-web (Tool Management — for API integrations)
- `src/extensions/tools/schema.ts` — Tool + credential tables
- `src/extensions/tools/router.ts` — Tool CRUD
- `src/extensions/tools/repository.ts` — Tool DB queries
- `scripts/seed-tool-notion.sql` — Example: Notion tool with 12 endpoints

## Scaffolding a New Plugin

When asked to create a plugin, first verify it shouldn't be a Tool instead (see decision matrix above). If it's truly a plugin, generate:

1. `plugin.json` — Manifest with appropriate capabilities
2. `src/index.ts` — Entry point with `export default async function init(api)`
3. `package.json` — With esbuild as build dependency
4. `tsconfig.json` — Target ES2020, module ESNext
5. `build.mjs` — esbuild script bundling to `dist/bundle.js`

## Critical Rules

- **Single bundle**: Everything must compile to one `dist/bundle.js` file (no external imports at runtime)
- **No Node.js APIs**: No `fs`, `http`, `process`, `require` — V8 isolate blocks these
- **No MCP**: MCP requires Node.js runtime — use Tool (MCP type) instead for MCP servers
- **ESM format**: Use `export default` for the init function
- **Bundle size**: Hard limit 10MB, aim for <1MB
- **Tool names**: snake_case, max 64 chars, unique within plugin
- **Config keys**: alphanumeric + underscores only
- **Capability gating**: Methods throw `PluginCapabilityError` if capability not approved
- **Auto-disable**: 5 consecutive failures disables the plugin
- **Storage namespaced**: Keys are automatically scoped to `plugin:{orgId}:{pluginId}:{key}`
- **HTTP rate limit**: 60 requests/min per plugin per org
- **Prefer Tools for API integrations**: If the use case is "call an external API", use a Tool, not a Plugin

## Publishing Flow

1. Build: `npm run build` → produces `dist/bundle.js`
2. Upload: cadra-web UI → Settings > Plugins > Publish
3. Review: `draft` → `pending_review` → `approved`
4. Install: Org admin browses marketplace → approves capabilities → configures
5. Runtime: cadra-api loads bundle into V8 isolate → plugin hooks/engines available

## Good Plugin Examples

| Plugin | Purpose | Capabilities |
|--------|---------|-------------|
| Datadog Logger | Ship execution traces to Datadog | `register_hooks`, `http_outbound`, `log` |
| Compliance Auditor | Log all tool calls to audit system | `register_hooks`, `http_outbound`, `storage` |
| Slack Notifier | Alert on errors/completions | `register_hooks`, `http_outbound` |
| Custom RAG Engine | Domain-specific retrieval | `register_context_engine`, `http_outbound` |
| Discord Channel | Messaging via Discord | `register_channel`, `http_outbound`, `storage` |

## Anti-Patterns (use Tools instead)

| Bad Plugin Idea | Use Instead |
|----------------|-------------|
| "Notion plugin" with search/create/update | Tool: REST API with Notion endpoints |
| "GitHub plugin" to create issues | Tool: REST API with GitHub endpoints |
| "Stripe plugin" to charge customers | Tool: REST API with Stripe endpoints |
| "Weather plugin" to fetch forecasts | Tool: REST API with weather endpoint |
| "MCP plugin" wrapping an MCP server | Tool: MCP type with STDIO/HTTP transport |
