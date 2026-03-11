---
name: agents-playground
description: Use when working on AI agents, agent configuration, teams, agent execution runtime, playground chat, SSE streaming, artifacts, tools, prompts, skills, guardrails, knowledge bases, agent detail page, or dashboard in cadra-web. Also use when the user mentions "agent", "playground", "execution", "tools", "prompts", "skills", "guardrails", "artifacts", "knowledge base", "agent detail", "config pills", "dashboard", or "PlaygroundChat".
---

# Agents & Playground Development Guide

Core product area of CadraOS — AI agent orchestration, execution, interactive playground, and agent detail UX.

## Agent System Architecture

### Agent Types
- **Orchestrator**: Plans and delegates to specialist agents
- **Specialist**: Executes specific tasks with tools

### Agent Configuration
- **Brain**: LLM provider, model, temperature, thinking budget
- **Skills**: Reusable prompt templates with RAG integration
- **Tools**: External integrations (REST, MCP, internal)
- **Guardrails**: Safety profiles (PII redaction, profanity, cost limits, approval triggers)
- **Team Assembly**: Group agents with lead orchestrator
- **Default model**: `google/gemini-3-flash-preview` (across 6 files: schema, schemas, repository + 3 UI files)
- **Default system prompt**: Set in `repository.ts` for new agents

### Extension Structure

```
cadra-web/src/extensions/
  agents/           # Agents, teams, executions, runs, logs (6 tables)
    components/
      detail/       # Agent detail page UX (chat-first)
        AgentDetailHeader.tsx
        ConfigPillsRow.tsx
        AgentConfigDialog.tsx   # Full-screen config with tab+sidebar nav
        ArtifactsDrawer.tsx
        TeamOrgChart.tsx        # Team hierarchy visualization
        tabs/                   # PersonaTab, KnowledgeTab, SkillsTab, MemoryTab
      playground/
        PlaygroundChat.tsx      # ~6000+ lines — ALWAYS dynamic import
      executions/
        ExecutionsDataTable.tsx  # tRPC-based (NOT SDK hook — requires no AISaaSSDKProvider)
    executions-router.ts        # getDashboardSummary endpoint
    executions-repository.ts    # getOrgStats, getRecentExecutions
  artifacts/        # Agent-generated files and documents
  skills/           # Reusable skill templates
  tools/            # External integrations & credentials (2 tables)
  guardrails/       # Safety profiles
  prompts/          # Prompt management with embedded versioning (2 tables)
  knowledge-bases/  # RAG knowledge bases (5 tables)
  models/           # ML model registry (3 tables)
  providers/        # LLM provider configurations
```

## Agent Detail Page (Chat-First UX)

HeyLua-inspired pattern — users configure and test agents in one place.

### UX Flow
1. "Create Agent" creates a draft and navigates to `/workforce/agents/[uuid]`
2. Full-width PlaygroundChat with built-in header hidden (`hideHeader` prop)
3. Custom `AgentDetailHeader`: inline-editable name, status badge, deploy, artifacts toggle, new chat
4. `ConfigPillsRow` renders via `renderAboveInput` slot, positioned above message input
5. Config pills ("Skills", "Knowledge", "Persona", "Memory") open `AgentConfigDialog`
6. `AgentConfigDialog`: full-screen dialog with top tabs + left sidebar sub-nav

### Config Dialog Tabs
- **Persona**: Name, description, type (Planner/Executor), system instruction, model/temperature
- **Knowledge**: Knowledge resources + guardrail profile multi-select
- **Skills**: Two-column tools & skills toggle list with search
- **Memory**: Memory strategy (type, history window, compress) + team assignments

### Team Detail Page
- Same pattern as agent detail but with team-specific tabs
- `TeamOrgChart`: visual hierarchy (lead agent top, members below, CSS connectors, add agent card)
- Org chart toggle button in header

### Key Patterns
- `renderAboveInput` slot prop on PlaygroundChat — least invasive way to inject UI into the 6000+ line component
- `forwardRef` on PlaygroundChat — new props must be destructured inside the forwardRef callback
- `agents.create` mutation only requires `name` — enables "create draft + navigate" pattern
- `AgentDetail.temperature` comes as `string | number` from DB — coerce with `Number()`
- Rebuild form fields directly in config tabs rather than reusing wizard step components (different data flow)

## Playground

Interactive testing environment for AI agents:
- Real-time SSE streaming for thinking blocks, tool calls, results
- Session management (continue conversations)
- Artifact preview (side panel with markdown/code rendering)
- Performance tracking (tokens, cost, execution stats)

### Key Files
- Agent detail page: `src/app/(org)/workforce/agents/[uuid]/`
- Team detail page: `src/app/(org)/workforce/teams/[uuid]/`
- Playground page: `src/app/(org)/workforce/playground/`
- SDK chat components: `cadra-sdk/src/chat/`

### SSE Streaming
- Events flow through Redis pub/sub (`execution:{runId}*` pattern)
- Stream URL: `/api/v1/agents/runs/{runId}/stream`
- Auth: Bearer token via EventSource polyfill headers (NOT query params)
- Always call `stream.connect()` after registering SSE listeners (SDK no longer auto-connects)

## PlaygroundChat Critical Patterns (MUST READ)

PlaygroundChat is ~6000+ lines. These patterns prevent critical bugs:

### 1. Atomic State Updates
NEVER split `setStreamEntries` calls that depend on each other. Two sequential calls race — first clears `isStreaming`, second can't find the streaming entry. Combine into single atomic update.

### 2. SSE + Polling Dedup
Both paths can deliver the same execution result. Always guard with content equality check before adding entries: `prev.some(e => e.content === output)`.

### 3. Session ID Prop Loop
`onSessionStart` → parent sets `sessionId` → child's `useEffect(initialSessionId)` must NOT `loadSession` for internally-created sessions. Use `sessionInitiatedInternallyRef` guard to prevent empty state flash.

### 4. Image Carousel Loading
`isLoadingArtifacts` must be `false` by default. Setting `true` whenever session exists causes skeleton flash for ALL agents (most don't generate images).

### 5. Content-Based Dedup for Rendering
Entry ID dedup is insufficient — SSE and polling create entries with different IDs. Add `assistant_text` content equality check in render pipeline.

### 6. Error Surfacing
Surface streaming errors as visible chat entries — never silently swallow with just `setIsLoading(false)`.

### 7. DRAFT Agent Support
Both REST API (`/api/v1/agents/[id]/execute`) and tRPC routes must allow DRAFT status agents for playground testing.

### 8. SSE Event Type Matching
Publisher (cadra-api) and consumer (SSE route) event types must match exactly. `completed` ≠ `execution_complete` — silent event drops.

## Dashboard

Operational dashboard at `/dashboard` with real-time stats.

### Architecture
- Single aggregated `executions.getDashboardSummary` tRPC endpoint (prefer over multiple parallel queries)
- `getOrgStats(orgId, days)` for org-wide execution stats
- `getRecentExecutions(orgId, limit)` with task extraction from JSONB `input.task`/`input.prompt`
- SQL `FILTER (WHERE ...)` for conditional aggregates in single query

### Dashboard Sections
1. Attention alerts (low credits, failed executions)
2. Stat cards (agents, executions, success rate, credits)
3. Recent executions + agent health (2-column)
4. Usage + credits (2-column)

### Key Patterns
- Postgres `decimal` columns return strings via Drizzle — coerce with `Number()`
- Use `enabled: !!session?.user` to prevent queries before auth loads
- Use `retry: false` for dashboard queries
- CTA links: verify against `Sidebar.tsx` routes (source of truth for nav paths)

## Executions List

Standalone `/workforce/executions` page with sidebar nav item.

- Uses tRPC queries directly (NOT SDK hooks — those require `AISaaSSDKProvider` context)
- Search support via `executionsSchemas` search param
- `agentId` optional for org-wide listing

## Data Table UI Standards

### Agent/Team List Pages
- Grid + list view toggle using `hideTable` prop on BaseListTable
- Agent type icons: Network (ORCHESTRATOR), Wrench (SPECIALIST) with tooltips
- `AgentAvatar`: deterministic color from name hash
- `MemberAvatarStack`: agent name initials (up to 5 per team)
- Name columns: `text-[15px] font-semibold leading-tight` clickable button
- Reference: `AgentsDataTable.tsx` is gold standard for list page styling

### Sidebar Navigation
- `siblingHrefs` prop prevents false-positive active states when routes share prefix
- Example: `/workforce/executions` vs `/workforce` — without siblingHrefs, both highlight

## Tools System

### Tool Types
- **REST API**: External HTTP endpoints with credential management
- **MCP Servers**: Model Context Protocol (STDIO, HTTP, WebSocket)
- **Internal Tools**: Pre-built platform tools (12 tools, 41 endpoints)
- **Webhooks**: Incoming/outgoing webhook integrations

### Internal Tools Seeding
```bash
pnpm db:seed:internal-tools  # Seeds 12 tools, 41 endpoints
pnpm db:seed:agents          # Seeds default platform agents
pnpm db:seed:skills          # Seeds default skills
```

## Prompts, Artifacts, Sandbox

- **Prompts**: Version-controlled library, golden version publishing, playground testing
- **Artifacts**: Agent-generated files, preview in side panel, markdown/code rendering
- **Sandbox**: Isolated execution environment

## Reference Documentation

### Agents & Execution
- Overview: `_context/cadra/agents+api/_overview.md`
- Architecture: `_context/cadra/agents+api/architecture.md`
- Execution feature: `_context/cadra/agents+api/feature-agent-execution.md`
- Execution phases: `_context/cadra/_specs/p1-agents/` through `p6-team-execution/`
- Agent config simplification: `_context/cadra/agent-config-simplification/`

### Playground
- Feature: `_context/cadra/playground/feature.md`
- Architecture: `_context/cadra/playground/architecture.md`
- SDK migration: `_context/cadra/playground/sdk-migration/`

### Tools, Prompts, Artifacts
- Tools: `_context/cadra/tools/feature.md`
- Internal tools: `_context/cadra/tools/implementation-internal-tools.md`
- Prompts: `_context/cadra/prompts/feature.md`
- Artifacts: `_context/cadra/artifacts/feature.md`
- Sandbox: `_context/cadra/sandbox/specs-sandbox.md`
