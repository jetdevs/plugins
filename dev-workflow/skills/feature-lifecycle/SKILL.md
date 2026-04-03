---
name: feature-lifecycle
description: End-to-end feature development from idea to merged PR. Use when starting a new feature, epic, or initiative that needs brainstorming, specs, Jira stories, implementation planning, parallel execution, and testing. Also use when the user says "new feature", "build this", "let's plan", "create epic", "start a project", "end to end", or wants the full development workflow from idea through implementation and review.
---

# Feature Lifecycle

Complete workflow for taking a feature from idea to merged code. Orchestrates brainstorming, spec writing, Jira tracking, Codex review, implementation planning, parallel agent execution, browser testing, and PR creation.

## When to Use

Use this skill when the user wants to build a feature from scratch — not a quick bug fix or minor change. Indicators:
- "I want to build..."
- "Let's create a new feature for..."
- "Here's an idea, let's plan it out"
- References to epics, phases, or multi-story work
- Asks for brainstorming before coding

## Workflow Overview

```
1. Session Start     → /session-start
2. Brainstorm        → superpowers:brainstorming (interactive dialogue, NOT template)
3. Spec Writing      → Write design doc as source of truth
4. Create-Specs      → /create-specs (prd.md, implementation.md, story_list.json)
5. Codex Review      → [auto-launches via hook] or /codex-review
6. Address Feedback  → /address-feedback (Claude responds to Codex's feedback.md)
7. Codex Re-review   → /codex-review (Codex verifies Claude's responses)
8. Jira Stories      → Create epic + stories via REST API
9. Worktree Setup    → Isolated branch for implementation
10. Implementation   → Parallel agents via plan groups
11. Migration + Test → Run DB migrations, RLS deploy, browser test
12. Debug & Fix      → Fix issues found during testing
13. Session Update   → /session-update with full progress
14. PR Creation      → superpowers:finishing-a-development-branch
```

## Phase 1: Brainstorm & Design

### Start a Session

```
/session-start [feature description]
```

### Brainstorm (NOT template-generated)

Invoke `superpowers:brainstorming`. The key insight: **iterative dialogue produces better specs than templates**. Ask questions one at a time:

1. Explore the codebase first (dispatch Explore agent)
2. Ask clarifying questions — one per message, prefer multiple choice
3. Propose 2-3 approaches with trade-offs and your recommendation
4. Present design in sections, get approval after each
5. Write the design doc

The brainstorm design doc becomes the **source of truth** — it has the rationale, edge cases, and decision context that template specs lose.

### Write the Design Doc

Save to: `docs/superpowers/specs/YYYY-MM-DD-<feature>-design.md` (in the project repo)

Include:
- Overview and motivation
- Prior art references
- Schema changes with exact TypeScript
- RLS policies with exact SQL
- Permission changes
- Lifecycle state machine
- Router/API changes
- UI changes with ASCII wireframes
- Testing strategy
- Phase 2 / future direction

### Internal Spec Review

Before Codex review, dispatch a spec-document-reviewer subagent to catch issues:
- Wrong RLS functions
- Missing superuser bypass
- Schema migration ordering
- Edge cases (orphaned records, nullable FKs)
- Team/delegation guard gaps

Fix all issues, then proceed to create-specs.

## Phase 2: Specs & Codex Review

### Create Supporting Docs

```
/create-specs @_context/{project}/_specs/{feature}/
```

This creates prd.md, implementation.md, story_list.json alongside your design doc. **Replace the template specs.md with your brainstorm design doc** — it's always better.

### Codex Review Cycle

The PostToolUse hook auto-launches Codex after `/create-specs`. The cycle:

1. [Hook auto-launches Codex] → Codex writes `feedback.md`
2. Wait for Codex to finish (check `ps aux | grep codex`)
3. Invoke `/address-feedback` — read feedback.md, address each item, update specs
4. Invoke `/codex-review` — Codex re-reviews Claude's responses
5. Repeat 3-4 until all items ALIGNED/RESOLVED

**Critical rule:** Never ask the user if they want to review feedback first. Always address it immediately.

### Create Jira Stories

Use curl with Jira REST API v2 (not jira-cli which uses v3):

```bash
export JIRA_API_TOKEN="..."
# Create epic first
curl -s -X POST -H "Authorization: Bearer $JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://jira.jetdevs.com/rest/api/2/issue" \
  -d '{"fields":{"project":{"key":"CAD"},"summary":"Epic Name","issuetype":{"name":"Epic"},"customfield_10103":"Epic Name"}}'

# Then stories linked to epic
curl -s -X POST ... \
  -d '{"fields":{"project":{"key":"CAD"},"summary":"Story","issuetype":{"name":"Story"},"customfield_10101":"CAD-1","description":"..."}}'
```

**Jira structure:** Epic → Stories only. No sub-tasks. Each story has checklist to-dos in the description using Jira wiki markup (` - [ ] item`).

**Update story_list.json** with Jira keys (e.g., CAD-2 through CAD-9) and fix dependency references.

**Update Jira status** as implementation progresses:
```bash
# Move to In Progress (transition ID 51)
curl -s -X POST ... "issue/CAD-2/transitions" -d '{"transition":{"id":"51"}}'
# Move to Done (transition ID 171)
curl -s -X POST ... "issue/CAD-2/transitions" -d '{"transition":{"id":"171"}}'
```

## Phase 3: Implementation

### Worktree Setup

Create isolated worktree inside the project repo (NOT at monorepo root):

```bash
cd /Volumes/HD/code/monorepo/cadra-web
git worktree add .claude/worktrees/<feature> -b feature/<feature> develop
cp .env .claude/worktrees/<feature>/.env
cd .claude/worktrees/<feature> && pnpm install
```

### Write Implementation Plan

Invoke `superpowers:writing-plans`. Key additions beyond the standard plan:

1. **Identify parallel groups** from the dependency graph:
   ```
   Group 1: [Foundation] — sequential
   Group 2: [Independent tasks] — parallel
   Group 3: [Dependent on group 2] — parallel
   ...
   ```

2. **Map each group to Jira stories** so status updates are automatic

3. Save plan to `docs/superpowers/plans/` in the worktree

### Parallel Agent Execution

For each group, dispatch cadra-dev (or appropriate) agents in parallel:

```
Group 1: Sequential — dispatch single agent
Group 2: Dispatch 2+ agents simultaneously via Agent tool
Group 3: Wait for group 2, then dispatch next set
```

Each agent prompt must include:
- Working directory (worktree path)
- What was already done (prior group commits)
- Exact files to modify with code patterns
- What NOT to modify
- Commit message format: `feat(module): description (JIRA-KEY)`

**Between groups:** Update Jira status (In Progress → Done for completed stories, In Progress for next).

### Post-Implementation: Verification Protocol

**HARD GATE: No story can have `passes: true` until ALL 4 proof types are collected. No PR can be created until ALL stories pass.**

#### Step 1: Infrastructure Setup

1. **Run migration:** `pnpm db:migrate:run`
2. **Deploy RLS:** `pnpm db:rls:deploy`
3. **Sync permissions:** `pnpm generate:permissions && pnpm db:seed:rbac`
4. **Seed data:** Run any seed scripts (e.g., `pnpm db:seed:agent-roles`)
5. **Build check:** `pnpm build`
6. **Start dev server with log capture:**
```bash
pnpm dev > /tmp/server-test.log 2>&1 &
```

#### Step 2: Verification per Story (invoke `/test-specs`)

For EACH story, collect the **4 mandatory proof types**:

| Proof | What | How | Required For |
|-------|------|-----|--------------|
| **Screenshot** | Visual proof the feature works | Playwright `page.screenshot()` saved to `evidence/` | All frontend stories |
| **DB Records** | Data layer proof | Direct SQL query, paste output | All schema/data stories |
| **Browser Console** | No client-side errors | Playwright console listener, assert 0 errors | All frontend stories |
| **Server Console** | No server-side errors | `grep -i error /tmp/server-test.log` during test window | All stories |

**Invoke `/test-specs` with the feature path** — it handles test classification, execution, and evidence collection against the verification rubric.

#### Step 3: Fix and Re-verify

- Fix bugs found during testing — commit as separate bugfix commits
- Re-run verification for affected stories
- Repeat until ALL stories have `passes: true`

#### Step 4: Final Gate Check

Before proceeding to Phase 4:
```
□ pnpm build passes
□ ALL stories in story_list.json have passes: true
□ ALL stories have 4 proof types in AC notes
□ Server log clean during full test run
□ No unacknowledged browser console errors
```

If ANY box is unchecked, go back to Step 2. **Do NOT proceed to PR creation.**

## Phase 4: Wrap Up

### Session Update

```
/session-update
```

Include: git log, test results, bugs found and fixed, context documents, lessons learned.

### Lessons Learned

Always capture:
- **Architecture lessons** — RLS gotchas, framework gaps, schema mapping issues
- **Tools lessons** — CLI quirks, command corrections, workflow fixes
- **Process lessons** — what worked, what to do differently
- **UI lessons** — correct file paths, component patterns

### PR Creation

```
superpowers:finishing-a-development-branch
```

Or create PR directly:
```bash
git push -u origin feature/<feature>
gh pr create --title "feat: ..." --body "..."
```

## Common Pitfalls

### RLS
- Framework `getDbContext` only sets `rls.current_org_id`, NOT `rls.current_user_id` — must wire in app's `actor.ts` wrapper
- INSERT with RETURNING checks both INSERT policy AND SELECT policy — if SELECT needs a session var that's not set, INSERT fails
- `withPrivilegedDb` routes bypass RLS entirely — visibility checks must be explicit in application code

### Schema
- Drizzle `findFirst` returns all columns, but manual return object mappings in repository methods drop new columns — always add new columns to the mapping
- Migration default values: use three-step approach (add with temp default → existing rows get value → change default for new rows)

### Jira
- jira-cli v1.7+ uses API v3 which doesn't work on Jira DC — use curl with REST API v2
- Epic Link field: `customfield_10101`. Epic Name field: `customfield_10103`
- Permission sync: `pnpm generate:permissions` (not `generate:seed-permissions`) + `pnpm db:seed:rbac`

### Codex
- Hook uses `--sandbox workspace-write` so Codex CAN write feedback.md directly
- Output also logged to `/tmp/codex-spec-review-latest.log` as fallback
- Hook triggers on `create-specs` skill only (auto-launch)
- Use `/codex-review` for manual launches and re-reviews
- If Codex still fails to write (permissions issue), capture from log and write manually

## Reference

| Resource | Path |
|----------|------|
| Backend patterns | `_context/_arch/patterns-backend.md` |
| Extension pattern | `_context/_arch/core-architecture/extension-pattern.md` |
| Jira skill | `plugins/dev-workflow/skills/jira-expert/SKILL.md` |
| Session files | `_ai/sessions/` |
| Spec templates | `plugins/dev-workflow/skills/create-specs/` |
