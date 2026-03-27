---
name: session-update
description: Update the current development session with detailed, RAG-optimized content. Use when logging progress, capturing architecture issues, recording SDK patterns, or documenting debugging sessions. Generates session files designed for vector embedding and semantic search.
---

# Session Update

Update the current development session. Session files are designed for RAG ingestion and vector embedding — every section must be self-contained, detailed, and semantically searchable.

## Step 1: Find Active Session

Check `_ai/sessions/.current-session` for active sessions.

**PATH RULES**:
- `_ai/` is at the **POLYREPO ROOT** (`/Volumes/T9/code/monorepo/_ai/`), NOT inside project folders
- NEVER create `_ai/` inside project folders like `core-saas/_ai/` or `cadra-web/_ai/`
- The folder is `_ai/` (with underscore prefix), NOT `ai/`

**MULTIPLE SESSION SUPPORT**:
- `.current-session` may contain multiple active session filenames (one per line)
- Match the `[project-name]` prefix against the current working context
- If `$ARGUMENTS` includes a project name or tag, use that to match
- If ambiguous, list sessions and ask the user which to update

If no active session exists, inform user to start one with `/session-start`.

## Step 2: Ensure YAML Frontmatter Exists

Every session file MUST begin with YAML frontmatter. If the session file is missing frontmatter (legacy format), add it now. Update dynamic fields (`status`, `last_updated`, `commits`, `tags`) on every update.

```yaml
---
title: "Descriptive title of what this session accomplished"
date: 2026-03-23
projects: [cadra-web, cadra-api]
branch: feature/my-feature
status: in-progress  # in-progress | completed | blocked | paused
type: feature  # feature | bugfix | refactor | investigation | qa | migration | infrastructure
topics: [rls, caching, org-isolation, permissions]  # from TOPIC TAXONOMY below
tags: [vercel, neon-http, cdn, serverless]  # additional semantic tags for RAG retrieval
last_updated: 2026-03-23T14:30:00
sdk_touched: [core-sdk, cadra-sdk]  # which SDKs were involved, if any
apps_touched: [cadra-web]  # which apps were modified
commits: ["abc1234", "def5678"]  # all commit hashes from this session
related_sessions: []  # filenames of related sessions
specs: []  # paths to related spec documents
---
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

## Step 3: Append Detailed Update

Append a new update block. **Do NOT summarize — capture granular detail.** Each update should contain enough context that someone reading it months later (or a RAG system retrieving it) can understand exactly what happened and why.

### Update Block Format

```markdown
---

### Update — 2026-03-23 14:30

#### What Changed

Describe the specific changes made in this update cycle. Include:
- What code was written or modified and WHY (not just "modified auth.ts")
- What problem was being solved — the specific symptoms, not just "fixed a bug"
- What approach was taken and what alternatives were considered
- What the before/after behavior is

#### Detailed Problem Analysis

(Include this section when debugging or investigating issues)

- **Symptoms observed**: Exact error messages, unexpected behavior, reproduction steps
- **Investigation path**: What was checked, in what order, and what each check revealed
- **Root cause**: The actual underlying issue with technical explanation
- **Why it wasn't obvious**: What made this hard to find

#### Implementation Details

- Specific code patterns used and why they were chosen
- Edge cases handled or intentionally deferred
- Performance implications of the changes
- Security considerations (especially for RLS, auth, permissions)

#### Commit Log

| Hash | Message | Files |
|------|---------|-------|
| `abc1234` | fix(rls): patch session with fresh DB orgId | `src/server/api/trpc.ts` |
| `def5678` | fix(cache): default scope to user for CDN isolation | `src/app/api/trpc/[trpc]/route.ts` |

#### Files Changed (This Update)

```
M src/server/api/trpc.ts          — Added fresh DB read for orgId in orgProtectedProcedure
M src/app/api/trpc/[trpc]/route.ts — Changed default cacheScope from "public" to "user"
A src/lib/new-helper.ts           — New utility for X because Y
D src/lib/old-helper.ts           — Removed: replaced by new-helper.ts
```

#### Git Status

- Branch: `feature/my-feature`
- Last commit: `def5678 fix(cache): default scope to user`
- Working tree: clean / N uncommitted changes
```

## Step 4: Update Standing Sections

After appending the update block, review and update these standing sections. Each section is designed to be independently retrievable by a RAG system — write each as if it will be read without the rest of the document.

### SDK Notes Section

Maintain a `## SDK Notes` section. Record anything specific to `@jetdevs/core`, `@jetdevs/framework`, `@jetdevs/cloud`, `@jetdevs/messaging`, or `@cadraos/sdk`. Focus on:

- **How SDK APIs were used** — correct patterns discovered, incorrect assumptions corrected
- **SDK gaps or limitations** encountered — missing features, workarounds needed
- **Cross-app inconsistencies** — places where different apps use the same SDK differently
- **SDK bugs found** — unexpected behavior in SDK code

```markdown
## SDK Notes

### @jetdevs/core
- `createRouterWithActor` reads orgId from `ctx.session.user.currentOrgId` via `createActor()`. Patching `ctx.activeOrgId` alone is NOT sufficient — must patch `ctx.session` before the actor is created.
- `withPrivilegedDb` bypasses RLS entirely — on neon-http (Vercel), this is the fallback path because `supportsTransactions()` returns false.

### @jetdevs/framework
- (nothing this session)

### @cadraos/sdk
- (nothing this session)
```

### Architecture Issues Section

Maintain a `## Architecture Issues` section. Document inconsistencies, confusion, misunderstandings, or incorrectly implemented patterns across the codebase. These are high-value entries for the knowledge base.

```markdown
## Architecture Issues

### RLS Bypass on Vercel/Neon-HTTP
- **Status**: `known-limitation` — architectural constraint, not fixable without driver change
- **Topics**: `rls`, `org-isolation`, `neon-http`, `vercel`
- **Issue**: On Vercel with neon-http driver, `supportsTransactions()` returns false, causing fallback to `withPrivilegedDb` which bypasses RLS entirely. Org isolation relies on explicit `WHERE orgId = ?` in every repository query.
- **Impact**: If any repo query misses the orgId filter, data leaks across orgs.
- **Inconsistency**: Artifacts module had no cache config (always correct), while agents/skills/tools had `cache: { ttl: 60 }` causing CDN to serve cross-org data.
- **Correct pattern**: Always set `scope: "user"` when using cache TTL on org-scoped routes.
- **Applies to**: cadra-web, yobo-merchant, core-saas (all Vercel-deployed apps)

### Org Switch JWT Timing Race
- **Status**: `workaround-applied` — server-side DB read bypasses stale JWT, but root cause unfixed
- **Topics**: `org-switching`, `jwt`, `session-management`, `vercel`
- **Issue**: `updateSession()` → JWT callback → cookie write can race with `window.location.href` redirect on Vercel serverless.
- **Applies to**: cadra-web (confirmed), yobo-merchant and core-saas (likely)
- **Workaround**: Read org from DB server-side instead of trusting JWT (commit `e8e705a`).
- **Root fix needed**: SDK `createOrgSwitcherFactory` should handle this centrally.
```

Architecture Issue statuses: `resolved` (fixed in this session), `workaround-applied` (mitigated but not root-fixed), `known-limitation` (architectural constraint), `unresolved` (needs future work), `investigating` (not yet understood)

### Context Documents Section

Update `## Context Documents` with files referenced during this session. Include enough description that a RAG system can match queries to the right documents.

```markdown
## Context Documents

| Document | Path | Why It Matters |
|----------|------|----------------|
| tRPC setup | `cadra-web/src/server/api/trpc.ts` | Contains orgProtectedProcedure, RLS context setup, cache-control logic |
| SDK actor | `core-sdk/framework/src/auth/actor.ts` | createActor reads session.user.currentOrgId — source of stale org bug |
```

### Lessons Learned Section

Maintain `## Lessons Learned`. Each lesson is a **candidate for extraction into learning documents and eventually golden docs**. Write each lesson as a self-contained knowledge unit with enough context to be useful outside this session.

Every lesson MUST include:
- **The lesson itself** — specific and actionable, not generic advice
- **Topics** — which taxonomy topics this maps to (for cross-session grouping)
- **Applies to** — which apps/SDKs this lesson is relevant to
- **Confidence** — `confirmed` (verified by testing/deployment) or `hypothesis` (suspected but not fully proven)
- **Evidence** — which commit, update block, or investigation step proved this

```markdown
## Lessons Learned

### Architecture

- **Lesson**: When one module works but another doesn't with identical code, check infrastructure-level differences (HTTP cache headers, middleware order) before code logic.
  - Topics: `caching`, `cdn`, `debugging`
  - Applies to: all apps using `createRouterWithActor` with `cache` config
  - Confidence: confirmed
  - Evidence: Artifacts (no cache) worked; agents (cache: {ttl: 60}) failed — commit `9295d49`

- **Lesson**: `cache: { ttl: N }` in createRouterWithActor translates to `s-maxage=N` on Vercel CDN. Without `scope: "user"`, responses are shared across all users/orgs — a data isolation security issue.
  - Topics: `caching`, `cdn`, `rls`, `org-isolation`
  - Applies to: cadra-web, yobo-merchant, core-saas (any app on Vercel with cached tRPC routes)
  - Confidence: confirmed
  - Evidence: commit `9295d49`, verified via browser testing across org switch

### SDK Patterns

- **Lesson**: `createRouterWithActor` reads org from `createActor(ctx)` which uses `ctx.session.user.currentOrgId`. Any middleware that fixes org context must patch `ctx.session`, not just add `ctx.activeOrgId`.
  - Topics: `actor-pattern`, `org-isolation`, `core-sdk`
  - Applies to: cadra-web, yobo-merchant, core-saas
  - Confidence: confirmed
  - Evidence: commit `e8e705a`, root cause analysis in Update block

### Debugging

- **Lesson**: Browser automation testing is invaluable for verifying org isolation — switch orgs, inspect API responses, check headers in a controlled session.
  - Topics: `debugging`, `org-isolation`, `e2e-testing`
  - Applies to: all apps
  - Confidence: confirmed
  - Evidence: used Chrome automation to verify CDN cache fix in this session
```

### User Steering & Corrections Section

Maintain a `## User Steering & Corrections` section. This captures every instance where the user had to redirect, correct, clarify, or mentor the AI agent during the session. **This is training data** — it reveals where agents need improvement.

Record every user intervention that changed the agent's direction:

```markdown
## User Steering & Corrections

### Corrections (agent was wrong or heading wrong direction)
- **User said**: "review-specs-gpt5 was claude code's skill for reviewing Codex's feedback. That should have stayed"
  - **What agent did wrong**: Deleted the skill thinking it was a Codex-only skill
  - **Root cause**: Misunderstood the actor — assumed "gpt5" in the name meant it was FOR GPT-5
  - **Lesson**: Ask before deleting. Skill names that reference another AI system are ambiguous about direction.

### Clarifications (agent needed more context)
- **User said**: "Codex's skill is here (correctly) — what I want is a new skill that knows how to call the codex cli command"
  - **What was unclear**: The relationship between Claude's skill and Codex's skill
  - **Resolution**: Created `codex-review` as a thin launcher, kept Codex's own skill untouched

### Steering (user redirected approach or priorities)
- **User said**: "Let's only focus on the plugins repo"
  - **What agent was doing**: Trying to fix local `.claude/skills/` files too
  - **Better approach**: Plugin marketplace is the single source of truth; local skills are stale copies

### Requirements additions (user added scope mid-session)
- **User said**: "It's possible the CTO will learn from discussions in Slack channels"
  - **Impact**: Added `gather-intelligence` skill and Slack MCP integration to CTO agent
```

**Capture rules:**
- Record the user's **exact words** (or close paraphrase) — this is the training signal
- Explain what the agent was doing wrong or would have done without intervention
- Identify the **root cause** of the misunderstanding (ambiguous name, missing context, wrong assumption)
- Note if this reveals a pattern (e.g., agent consistently misidentifies actor/ownership)
- Include requirements the user added mid-session that changed the design

### Next Steps Section

Maintain `## Next Steps` with specific, actionable items. Include enough context that another developer (or AI agent) can pick up where this session left off.

## Step 5: Update Frontmatter

After appending all content, update the frontmatter's dynamic fields:
- `last_updated` → current timestamp
- `commits` → append any new commit hashes
- `tags` → add any new semantic tags relevant to the work done
- `status` → update if changed (e.g., `blocked`, `completed`)
- `sdk_touched` / `apps_touched` → update if new SDKs or apps were involved

## Writing Guidelines for RAG Optimization

1. **Be specific, not generic** — "RLS bypass on neon-http Vercel" not "database issue"
2. **Include technical terms** — These are search keywords. Use exact function names, file paths, error messages
3. **Self-contained sections** — Each `##` section should make sense if retrieved independently
4. **Explain WHY, not just WHAT** — "Changed cacheScope to 'user' because Vercel CDN was sharing responses across orgs" not "Updated cache config"
5. **Include the investigation path** — What was checked and eliminated matters as much as the fix
6. **Name specific files and functions** — `createActor()` in `core-sdk/framework/src/auth/actor.ts` not "the actor creation function"
7. **Capture cross-app patterns** — When something applies to multiple apps (cadra-web, yobo-merchant), say so explicitly
8. **Record what DIDN'T work** — Failed approaches are valuable for future debugging
9. **Use exact error messages** — These are high-value search targets for RAG

## Full Session File Structure Reference

```markdown
---
title: "Descriptive title of what this session accomplished"
date: YYYY-MM-DD
projects: [project-name]
branch: branch-name
status: in-progress
type: feature
topics: [topic1, topic2]
tags: [tag1, tag2]
last_updated: ISO-8601
sdk_touched: []
apps_touched: [project-name]
commits: []
related_sessions: []
specs: []
---

# Session: Title

## Objective
(What this session set out to accomplish and why. Be specific — this is the primary
search target for RAG retrieval and the key context for learning extraction.)

---

### Update — YYYY-MM-DD HH:MM

#### What Changed
(Detailed description of changes with WHY, not just WHAT)

#### Detailed Problem Analysis
(Symptoms, investigation path, root cause, why it wasn't obvious)

#### Implementation Details
(Patterns used, edge cases, performance/security considerations)

#### Commit Log
| Hash | Message | Files |
|------|---------|-------|

#### Files Changed (This Update)
(M/A/D prefix with explanation of each change)

#### Git Status
(Branch, last commit, working tree state)

---

## SDK Notes

### @jetdevs/core
(Patterns, gaps, bugs, cross-app inconsistencies)

### @jetdevs/framework
(Patterns, gaps, bugs, cross-app inconsistencies)

### @cadraos/sdk
(Patterns, gaps, bugs, cross-app inconsistencies)

## Architecture Issues

### Issue Title
- **Status**: resolved | workaround-applied | known-limitation | unresolved | investigating
- **Topics**: topic1, topic2
- **Issue**: (description)
- **Impact**: (what breaks or is at risk)
- **Applies to**: (which apps/SDKs)
- **Correct pattern**: (what should be done instead)

## Context Documents

| Document | Path | Why It Matters |
|----------|------|----------------|

## Lessons Learned

### Category (Architecture / SDK Patterns / Debugging / Deployment / Frontend / Testing)

- **Lesson**: (specific, actionable statement)
  - Topics: topic1, topic2
  - Applies to: app1, app2 (or "all apps")
  - Confidence: confirmed | hypothesis
  - Evidence: commit hash, update block reference, or investigation step

## User Steering & Corrections

### Corrections (agent was wrong or heading wrong direction)
- **User said**: "(exact words)"
  - What agent did wrong, root cause, lesson

### Clarifications (agent needed more context)
- **User said**: "(exact words)"
  - What was unclear, resolution

### Steering (user redirected approach or priorities)
- **User said**: "(exact words)"
  - What agent was doing, better approach

### Requirements additions (user added scope mid-session)
- **User said**: "(exact words)"
  - Impact on design/implementation

## Next Steps
(Specific, actionable items with enough context to resume)
```

## Knowledge Pipeline Context

Session files are the **first stage** of a three-stage knowledge pipeline:

1. **Sessions** (this output) — Raw, detailed, comprehensive records of development work
2. **Learnings** (extracted from sessions) — Distilled, cross-session knowledge grouped by topic. Multiple sessions about RLS produce one RLS learning doc.
3. **Golden Docs** (generated from learnings) — Authoritative guidelines defining architecture, patterns, workflows, and configurations. These live in `_context/` and are the source of truth.

To support this pipeline, every session must:
- Use standardized **topics** (from the taxonomy) so learnings can be grouped across sessions
- Tag each lesson with **applies to** so learnings know which apps/SDKs they affect
- Include **confidence** level so learnings can distinguish proven patterns from hypotheses
- Provide **evidence** (commit hashes, file paths) so golden docs can trace back to source
- Capture **architecture issues** with status so unresolved issues surface in learnings
- Record **SDK notes** per package so SDK-specific learnings aggregate cleanly
- Capture **user steering & corrections** — every instance where the user had to redirect or correct the agent. This is training data for improving agent behavior and reveals systematic gaps in agent knowledge or judgment.

**Always** update each relevant `CLAUDE.md` with learnings and standards discovered during the session.
