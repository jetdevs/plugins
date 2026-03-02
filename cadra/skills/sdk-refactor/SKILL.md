---
name: sdk-refactor
description: Use when working on CadraOS SDK (@cadraos/sdk), refactoring SDK internals, updating the default adapter, SSE streaming, chat components, or SDK-to-API contract alignment. Also use when the user mentions "cadra sdk", "sdk refactor", or "adapter".
---

# CadraOS SDK Refactor Guide

Reference for the CadraOS SDK package (`cadra-sdk/`) and its integration with `cadra-web`.

## SDK Structure

```
cadra-sdk/src/
  chat/
    index.ts              # All exports
    types.ts              # Stream events, subagent types
    adapters/
      default-adapter.ts  # Direct API adapter (no tRPC proxy)
    components/
      AgentChat.tsx        # Main chat component
      ChatMessage.tsx      # Message rendering
      MessageList.tsx      # Message list
      MarkdownContent.tsx  # Markdown with custom components
    hooks/
      useAgentChat.ts      # Chat state management
      useExecutionStream.ts # SSE event handling
```

## Default Adapter Contract

The adapter wraps `AISaaSClient` for direct API communication:

```typescript
// Auth: tokenProvider fetches API key from /api/v1/copilot/auth
// Team mode: pathId = input.agentId || input.teamId
// Execute format: { task, context, teamUuid } (NOT legacy { input: { task } })
```

### API Contract Alignment

| SDK Sends | API Expects | Status |
|-----------|-------------|--------|
| `task` (string) | `task` (string) | Aligned |
| `attachmentIds` | `attachmentIds` | Aligned |
| `message` | `message` | Aligned (sendMessage) |

### SSE Streaming

- `StreamConfig` must include `tokenProvider` for dynamic auth
- Use EventSource polyfill that supports custom headers (NOT query param auth)
- Stream URL: `/api/v1/agents/runs/{runId}/stream`
- Auth: `Authorization: Bearer {apiKey}` via headers

### Complete Handler

Must extract `execution.output` when `streamingContentRef` is empty.

## API Key Format

New format: `cdr_{env}_{random}_{checksum}`
- SDK accepts both `cdr_*` (new) and `jetai_*` (legacy)
- Config always requires explicit `orgId`

## useExecutionStream Events

Full event set supported:
- `log`, `tool_call`, `tool_result`, `text_delta`
- `execution_paused`, `started`, `progress`, `status_update`
- `delegation_started`, `delegation_completed`
- `handoff_started`, `handoff_completed`
- Subagent detection via `_subagentExecutionId` metadata

## MarkdownContent

- `components` prop: `{ ...defaultComponents, ...customComponents }` (user overrides win)
- `contentTransform` applied via `useMemo` before ReactMarkdown
- `urlTransform` for link rewriting

## Build

```bash
cd cadra-sdk && pnpm build  # ESM + CJS + DTS via tsup
```

## Reference Documentation

- SDK specs: `_context/cadra/sdk/p3-refactor-for-launch/specs.md`
- SDK PRD: `_context/cadra/sdk/p3-refactor-for-launch/prd.md`
