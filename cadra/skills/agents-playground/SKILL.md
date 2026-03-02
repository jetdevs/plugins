---
name: agents-playground
description: Use when working on AI agents, agent configuration, teams, agent execution runtime, playground chat, SSE streaming, artifacts, tools, prompts, skills, guardrails, or knowledge bases in cadra-web. Also use when the user mentions "agent", "playground", "execution", "tools", "prompts", "skills", "guardrails", "artifacts", or "knowledge base".
---

# Agents & Playground Development Guide

Core product area of CadraOS — AI agent orchestration, execution, and interactive playground.

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

### Extension Structure

```
cadra-web/src/extensions/
  agents/           # Agents, teams, executions, runs, logs (6 tables)
  artifacts/        # Agent-generated files and documents
  skills/           # Reusable skill templates
  tools/            # External integrations & credentials (2 tables)
  guardrails/       # Safety profiles
  prompts/          # Prompt management with embedded versioning (2 tables)
  knowledge-bases/  # RAG knowledge bases (5 tables)
  models/           # ML model registry (3 tables)
  providers/        # LLM provider configurations
```

## Playground

Interactive testing environment for AI agents:
- Real-time SSE streaming for thinking blocks, tool calls, results
- Session management (continue conversations)
- Artifact preview (side panel with markdown/code rendering)
- Performance tracking (tokens, cost, execution stats)

### Key Files
- Playground page: `src/app/(org)/workforce/playground/`
- SDK chat components: `cadra-sdk/src/chat/`
- Agent runtime: `cadra-web/src/` (agent execution backend)

### SSE Streaming
- Events flow through Redis pub/sub (`execution:{runId}*` pattern)
- Stream URL: `/api/v1/agents/runs/{runId}/stream`
- Auth: Bearer token via EventSource polyfill headers (NOT query params)

## Tools System

### Tool Types
- **REST API**: External HTTP endpoints with credential management
- **MCP Servers**: Model Context Protocol (STDIO, HTTP, WebSocket)
- **Internal Tools**: Pre-built platform tools (12 tools, 41 endpoints)
- **Webhooks**: Incoming/outgoing webhook integrations

### Tool Features
- Multiple endpoints per tool
- Credential management for secure API access
- Auto-detection of auth headers (Google, Anthropic, Azure, etc.)

### Internal Tools Seeding
```bash
pnpm db:seed:internal-tools  # Seeds 12 tools, 41 endpoints
pnpm db:seed:agents          # Seeds default platform agents
pnpm db:seed:skills          # Seeds default skills
```

## Prompts System

- Version-controlled prompt library
- Embedded versioning (versions stored in same table)
- Golden version publishing
- Playground testing integration
- Execution tracking

## Artifacts

Agent-generated files and documents:
- Stored with metadata linking to execution
- Preview in playground side panel
- Markdown and code rendering support

## Reference Documentation

### Agents & Execution
- Overview: `_context/cadra/agents+api/_overview.md`
- Architecture: `_context/cadra/agents+api/architecture.md`
- Execution feature: `_context/cadra/agents+api/feature-agent-execution.md`
- Execution phases: `_context/cadra/_specs/p1-agents/` through `p6-team-execution/`

### Playground
- Feature: `_context/cadra/playground/feature.md`
- Architecture: `_context/cadra/playground/architecture.md`
- Feed improvements: `_context/cadra/playground/p2-improve-feed/`
- File uploads: `_context/cadra/playground/p3-file-uploads/`
- SDK migration: `_context/cadra/playground/sdk-migration/`
- Change log: `_context/cadra/playground/log.md`

### Tools
- Feature: `_context/cadra/tools/feature.md`
- Internal tools: `_context/cadra/tools/implementation-internal-tools.md`
- Internal tools PRD: `_context/cadra/tools/prd-internal-tools.md`
- QA report: `_context/cadra/tools/qa-report-internal-tools.md`

### Prompts
- Feature: `_context/cadra/prompts/feature.md`
- Implementation: `_context/cadra/prompts/implementation.md`
- Change log: `_context/cadra/prompts/log.md`

### Artifacts
- Feature: `_context/cadra/artifacts/feature.md`
- Preview: `_context/cadra/artifact-preview/`

### Sandbox
- Specs: `_context/cadra/sandbox/specs-sandbox.md`
- PRD: `_context/cadra/sandbox/prd-sandbox.md`
- Implementation: `_context/cadra/sandbox/implementation-sandbox.md`
