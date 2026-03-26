---
name: session-start
description: Start a new development session with YAML frontmatter and RAG-optimized structure. Creates a session file in `_ai/sessions/` with semantic tags, SDK tracking, commit logging, and structured sections for architecture issues and lessons learned.
---

# Session Start

Start a new development session by creating a session file in `_ai/sessions/`.

**PATH RULES**:
- `_ai/` is at the **MONOREPO ROOT** (`/Volumes/HD/code/monorepo/_ai/`), NOT inside project folders
- NEVER create `_ai/` inside project folders like `core-saas/_ai/` or `cadra-web/_ai/`
- The folder is `_ai/` (with underscore prefix), NOT `ai/`

## Session Naming Convention

Format: `YYYY-MM-DD-[project-name]-description.md`

- The `[project-name]` tag identifies which project the session belongs to (e.g., `[crm]`, `[cadra-web]`, `[cadra]`, `[plugins]`)
- Description should be kebab-case, concise, and descriptive
- Examples:
  - `2026-03-26-[cadra-web]-private-agents.md`
  - `2026-03-26-[plugins]-skill-cleanup-and-cto-agent.md`
  - `2026-03-26-[yobo]-sub-org-users-p1.md`

## Multiple Concurrent Sessions

The `.current-session` file supports **multiple active sessions** (one per line). Different Claude Code instances can work on different projects simultaneously.

## Initial Session File Structure

Create the session file with YAML frontmatter and skeleton sections. The frontmatter **must match the format used by `/session-update`** — they share the same schema. Ask the user for goals if not clear from `$ARGUMENTS`.

```markdown
---
title: "Descriptive title of what this session will accomplish"
date: YYYY-MM-DD
projects: [project-name]
branch: branch-name
status: in-progress
type: feature  # feature | bugfix | refactor | investigation | qa | migration | infrastructure
topics: []  # from TOPIC TAXONOMY below
tags: []  # additional semantic tags for RAG retrieval
last_updated: ISO-8601-timestamp
sdk_touched: []
apps_touched: [project-name]
commits: []
related_sessions: []
specs: []
---

# Session: Title

## Objective

(What this session will accomplish and why. Be specific — this is the primary search target for RAG retrieval.)

---

## SDK Notes

(SDK-specific findings will be logged here during updates)

## Architecture Issues

(Cross-cutting concerns, inconsistencies, or misunderstandings discovered)

## Context Documents

| Document | Path | Why It Matters |
|----------|------|----------------|

## Lessons Learned

(Categorized, specific, actionable lessons — see session-update for full format)

## Next Steps

(What to do next)
```

### Topic Taxonomy

Use these standardized topics in the `topics` frontmatter field. This enables consistent grouping when extracting learnings across sessions. Add new topics only when none of the existing ones fit.

**Architecture & Patterns**: `rls`, `permissions`, `rbac`, `multi-tenancy`, `org-isolation`, `org-switching`, `extension-pattern`, `router-pattern`, `repository-pattern`, `actor-pattern`, `schema-design`, `migration`

**SDK**: `core-sdk`, `framework-sdk`, `cloud-sdk`, `messaging-sdk`, `cadra-sdk`, `sdk-api-design`, `sdk-exports`, `sdk-build`

**Infrastructure**: `caching`, `cdn`, `vercel`, `serverless`, `neon-http`, `docker`, `redis`, `bullmq`, `database`, `s3`, `deployment`

**Frontend**: `data-table`, `inline-editing`, `forms`, `modals`, `mobile-layout`, `canvas-rendering`, `streaming`, `sse`

**Auth & Security**: `auth`, `jwt`, `session-management`, `api-keys`, `oauth`, `cors`

**Integration**: `trpc`, `rest-api`, `open-api`, `webhooks`, `messaging-channels`, `whatsapp`

**Testing**: `e2e-testing`, `integration-testing`, `smoke-testing`, `regression-testing`

**Plugins & Agents**: `plugins`, `skills`, `agents`, `hooks`, `codex`, `obsidian`

## After Creating the File

1. **Append** the new session filename as a new line to `_ai/sessions/.current-session` (do NOT overwrite existing lines — other sessions may be active)
2. Confirm the session has started and remind the user they can:
   - Update it with `/session-update`
   - End it with `/session-end`

## Documentation Strategy

**Always read at session start**:
- `CLAUDE.md` — Core guidelines and polyrepo rules

**Read based on the type of work**:
- Backend / extension work: `_context/_arch/patterns-backend.md`, `_context/_arch/core-architecture/extension-pattern.md`
- Frontend work: `_context/_arch/patterns-frontend.md`, `_context/_arch/pattern-react.md`
- SDK work: `_context/_arch/core-architecture/sdk-inventory.md`, `_context/_arch/core-architecture/target-architecture.md`
- Testing: `_context/_arch/patterns-testing.md`
- Debugging: `_context/_arch/learning-backend.md`, `_context/_arch/learning-frontend.md`
- Security / permissions / RLS: `_context/_arch/core-architecture/lessons-learned.md`

**Read only when specifically needed**:
- Migration work: `_context/_arch/core-architecture/migration-guide.md`
- i18n: `_context/_arch/guide-i18n-implementation.md`
- Performance: `_context/_arch/guide-performance.md`
- WhatsApp/messaging: `_context/_arch/learnings-whatsapp.md`
- Polyrepo setup: `_context/_arch/polyrepo-guide.md`

**Project-specific docs** (read when working on that project):
- `_context/cadra/` — Cadra platform specs
- `_context/cadra-sdk/` — Cadra SDK specs
- `_context/core-sdk/` — Core SDK specs
- `_context/yobo-merchant/` — Yobo merchant specs
- `_context/yobo-crm/` — CRM specs
- `_context/slides/` — Slides app specs
- `_context/messaging/` — Messaging service specs

Check the session's **Context Documents** section for task-specific docs from prior updates.
