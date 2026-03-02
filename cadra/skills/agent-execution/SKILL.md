---
name: agent-execution
description: Use when optimizing agent execution performance, working on team execution, parallel delegation, batch tool calls, context prefetch, composite tools, or agent runtime in cadra-web. Also use when the user mentions "execution optimization", "agent performance", or "batch tools".
---

# Agent Execution Performance Optimization

Patterns for optimizing AI agent execution in the CadraOS platform.

## Architecture

CadraOS agents use a multi-agent orchestration pattern:
- **Orchestrator agents** plan and delegate to specialists
- **Specialist agents** execute specific tasks with tools
- **Tool executor** handles external API calls with credentials
- **SSE streaming** delivers real-time events to clients

## Optimization Areas

### 1. Non-Blocking Message Save (4.5s savings)

Both user AND assistant message saves should be async fire-and-forget:
- `saveMessageToSession` returns in <10ms
- Background queue buffers saves (max 1000)
- Flush periodically (every 1s)
- Drain on graceful shutdown (max 5s wait)
- Failed saves logged, don't fail execution

### 2. Parallel Credential + Artifact Fetch (2.5s savings)

Use `Promise.all` for credential and artifact fetch in tool executor:
- Credential prefetch uses `tool.uuid` (NOT `request.toolId`)
- Both complete before execution starts
- If credential fails but artifact succeeds, tool may proceed without auth (warning logged)

### 3. Batch Tool Callback (10-20s savings)

Create `/api/v1/internal/tools/batch` endpoint:
- Accepts multiple tool calls in one HTTP request
- Maintains call ordering and per-tool error isolation
- Tool executor detects batching opportunities

### 4. Context Prefetch Bundle (2-5s savings)

Single `get_planning_context` tool replaces 4-5 individual context-loading calls:
- Returns org context, brand context, segments, offers, products in one call
- Assigned to orchestrator agents

### 5. Composite Write Tool (5-10s savings)

Single `create_campaign_bundle` tool replaces 4 sequential write calls:
- Atomically creates campaign + segment + offer + promotion
- Single DB transaction

### 6. Parallel Image Generation (60-100s savings)

`generate_images_batch` tool generates up to N images concurrently:
- Shared brand context across all generations
- Batch insert creative records after completion
- Per-image progress events via SSE

## Parallel Delegation

Already working via Vercel AI SDK `ai@5.0.108`:
- `Promise.all()` at SDK level for tool calls in same step
- `parallelToolCalls: true` enabled in agent runtime
- Sub-agent events flow through Redis pub/sub

Verify: execution logs should show `max(specialist_time)` not `sum(specialist_times)`.

## Reference Documentation

- Team execution: `_context/cadra/_specs/p7-team-execution-optimization/specs.md`
- Agent optimization: `_context/cadra/_specs/p8-yobo-agent-optimization/specs.md`
