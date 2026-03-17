---
name: develop-specs
description: Implements features by writing code guided by story_list.json tracking. Use when developing features from specs, implementing user stories, or resuming implementation work. NOT for reviewing or creating specs — use create-specs or spec-feedback-reviewer for that. Provides atomic task execution with git commits and verification.
---

# Develop Specs

Implement features systematically using the Anthropic Agent Harness Protocol. This skill treats the codebase + git + story_list.json as long-term memory, enabling reliable feature development across context resets.

## Core Philosophy

The agent completes ONE story at a time, verifies it with tests, updates the story_list.json, commits, and only then moves to the next story. This ensures:

1. **Atomic Progress**: Each commit represents a verified, working increment
2. **Resumability**: Any new agent instance can read story_list.json and continue
3. **Accountability**: All changes are tracked with verification status

## Phase Gate: Implementation vs Review

**Before modifying ANY `done`, `verified`, `passes`, or `status` field, you MUST confirm you are in IMPLEMENTATION mode.**

You are in **IMPLEMENTATION mode** ONLY if ALL three are true:
1. You **wrote source code** in this session (not just JSON, markdown, or documentation)
2. You **ran tests or verification** in this session and observed real output
3. You **will create a git commit** with source code changes

If ANY of the above is false, you are in **REVIEW mode**. In review mode:
- You MAY update `status` to `"in_progress"` or `"blocked"`
- You MAY add items to `blockers`
- You MAY read and analyze stories for planning purposes
- You MUST NOT set `done: true`, `verified: true`, or `passes: true`
- You MUST NOT set `status` to `"testing"` or `"passes"`

**This gate exists because**: Stories were previously marked `passes: true` during spec review sessions where zero code was written, creating false progress signals.

## Instructions

### Step 1: Locate Feature Context

First, find the feature's story_list.json:

```bash
# Check for story_list.json in the feature folder
ls .context/{project}/{feature}/story_list.json

# Or find all story lists
find .context -name "story_list.json" -type f
```

Read the story_list.json to understand current state:
- Which stories have `passes: true`?
- Which story should be worked on next (first with `passes: false`)?
- Are there any blockers?

### Step 2: Read Supporting Documentation

Before implementing, read the feature's documentation:

```
.context/{project}/{feature}/
  - specs.md          # Technical specifications
  - prd.md           # Product requirements
  - implementation.md # Progress tracking
  - story_list.json  # Task tracking (THIS IS THE SOURCE OF TRUTH)
```

Also read relevant architecture docs:
```
.context/{project}/_arch/
  - patterns-*.md    # Coding patterns to follow
  - learning-*.md    # Project-specific knowledge

_context/_arch/
  - patterns-testing.md  # REQUIRED — testing rules (no DB mocks, error monitoring, smoke/regression patterns)
```

### Step 3: Implement ONE Story

**CRITICAL**: Only work on ONE story at a time. Never implement multiple stories before committing.

#### Status Progression (MUST follow this order)

```
pending -> in_progress -> testing -> passes
                 \-> blocked (at any point)
```

- **pending**: No work started. All `done`/`verified` fields are `false`. `passes` is `false`.
- **in_progress**: Code is being written. Some `done` fields may be `true`. `passes` MUST be `false`.
- **testing**: All code is written, running verification. Some `verified` fields may be `true`. `passes` MUST be `false`.
- **passes**: ALL `done: true`, ALL `verified: true`, `commits` array non-empty with real hashes, tests executed with observed output.
- **blocked**: Cannot proceed. Document in `blockers` array.

**NEVER skip statuses.** You cannot go from `pending` to `passes` or from `in_progress` to `passes` without going through `testing`.

#### 3a. Mark Story as In Progress

Update story_list.json:
```json
{
  "id": "STORY-001",
  "status": "in_progress",
  ...
}
```

#### 3b. Work Through Definition of Done

For each item in `definition_of_done`:

1. Implement the requirement
2. Mark `"done": true` in story_list.json
3. Continue to next item

Example definition_of_done items:
- Database schema created -> Run migration
- API endpoint implemented -> Create tRPC router
- Unit tests passing -> Write and run tests
- UI components built -> Create React components

#### 3c. Testing Protocol (Required Before `passes`)

When all DoD items are done, set `status: "testing"` and follow this protocol. Testing follows the project's testing patterns (see `_context/_arch/patterns-testing.md`).

**Foundational rules:**
1. **NEVER mock the database.** All tests must run against real PostgreSQL/database. Mocked DB tests verify mock behavior, not application behavior.
2. **NEVER count mock-based tests as functional verification.** A test that mocks HTTP calls, database queries, or external services proves nothing about whether the actual system works. Mock-based unit tests are useful for development but they DO NOT satisfy acceptance criteria or definition of done items.
3. **The system under test MUST be running.** For API/backend stories, the server must be started and tests must hit real endpoints. For frontend stories, the app must be running and tests must interact with real pages.

##### What counts as a valid test?

| Valid (counts toward `passes`) | Invalid (does NOT count) |
|-------------------------------|--------------------------|
| Integration test hitting real database | Unit test with `vi.mock("@/db/clients")` |
| E2E test against running server | Test with mocked HTTP (`vi.mock("node-fetch")`) |
| Playwright test loading real pages | Test with in-memory Map pretending to be DB |
| API test calling real endpoints | Test with mocked Fastify request/reply |
| Test against real PostgreSQL test DB | Test using `jest.fn()` for all dependencies |

**If a test file contains `vi.mock`, `jest.mock`, `sinon.stub`, or manual mock objects for core infrastructure (database, HTTP, message queues), it is a mock-based test. Mock-based tests CANNOT be cited as evidence for `verified: true` or `done: true`.**

##### Step 1: Discover and Classify Existing Tests

Before writing new tests, understand what already exists AND whether they are real or mocked:

```bash
# Find existing test files for this module/feature
find src/test -name "*.spec.ts" | grep -i {feature}
find src/test -name "*.test.ts" | grep -i {feature}

# CRITICAL: Check if tests use mocks (these don't count as functional verification)
grep -l "vi\.mock\|jest\.mock\|sinon\.stub\|new Map()" src/test/**/*.{spec,test}.ts 2>/dev/null
grep -l "mockResolvedValue\|mockImplementation\|createMock" src/test/**/*.{spec,test}.ts 2>/dev/null

# Check smoke test page array — is the new page already listed?
grep -n "{route-path}" src/test/e2e/smoke*.spec.ts

# Check regression tests — do they cover this module?
ls src/test/e2e/regression/
```

Classify each test file:
- **REAL**: Connects to actual database, calls real endpoints, starts real server
- **MOCK**: Uses vi.mock/jest.mock, in-memory stubs, mocked HTTP clients

Only REAL tests count toward verification. Report mock tests separately — they exist but don't prove the system works.

Determine:
- Which REAL test files already exist and what they cover
- Which new REAL tests are needed for the changes in this story
- Which existing tests need updating due to the changes (new routes, renamed fields, changed behavior)
- Whether the service/app needs to be running for tests (and if so, start it)

##### Step 2: Run Smoke Tests (Page Load Verification)

Smoke tests verify: **"Does every page load without crashing?"**

If this story adds or modifies a page route:

1. **Add the new page to the smoke test PAGES array** (if not already present):
```typescript
// In smoke-pages.spec.ts or equivalent
{ name: 'My Feature', path: '/my-feature' },
{ name: 'My Feature Detail', path: '/my-feature/[uuid]' }, // if applicable
```

2. **Run smoke tests** and verify the new page loads without errors:
```bash
pnpm test:e2e --grep "smoke"
# OR
pnpm playwright test smoke-pages.spec.ts
```

3. **What smoke tests check** (all five must pass):
   - HTTP status < 500
   - No Next.js error overlay visible
   - No `console.error` messages (using denylist filtering, NOT allowlist)
   - No per-procedure failures in tRPC batch response bodies
   - No uncaught JS errors (`pageerror` events)

##### Step 3: Run or Write Regression Tests (Interaction Verification)

Regression tests verify: **"Do all user interactions work without errors?"** They cover three levels:

| Level | What it catches | Example |
|-------|----------------|---------|
| **Page load** | API errors on initial render | `loyalty.get` 500 on customers page |
| **Detail navigation** | API errors when clicking into detail | `customers.getById` 500 on detail |
| **Dialog interaction** | Errors inside modals/forms | `"Failed to load whitelist"` in edit dialog |

For each level affected by this story:

1. **Write or update the regression test** following these rules:
   - Use `setupErrorMonitoring(page)` before first navigation
   - Call `monitor.assertNoErrors()` after EVERY page load and interaction
   - Use `waitForLoadState('networkidle')` before `assertNoErrors()`
   - Assert actual data content, NOT page shell (`<main>`, `[role="main"]`)
   - NEVER use `monitor.clear()` before `assertNoErrors()` (unless after a known 404 redirect)
   - NEVER use `.catch(() => {})` on required element assertions

2. **Run the regression tests**:
```bash
pnpm test:e2e --grep "{feature}"
# OR
pnpm playwright test regression/{feature}.spec.ts
```

3. **Record test output** — paste or summarize the actual test runner results.

##### Step 4: Run Integration Tests (API Verification)

If this story modifies tRPC procedures, database queries, API endpoints, or backend services:

1. **Ensure infrastructure is running**:
   - Database: PostgreSQL must be up and migrated (`pnpm db:migrate` or equivalent)
   - Cache: Redis must be up if the service uses it
   - Server: The API/service must be started (`pnpm dev` or `pnpm start`)
   - Verify with a health check: `curl http://localhost:{port}/health` or equivalent

2. **Write or update integration tests** that hit a real database and real endpoints:
   - Tests MUST connect to real PostgreSQL (not SQLite, not in-memory, not mocked)
   - Tests MUST call real HTTP endpoints or tRPC procedures (not mocked handlers)
   - If the test file contains `vi.mock` or `jest.mock` for DB/HTTP — it is NOT an integration test

3. **Run them**:
```bash
pnpm test --testPathPattern={feature}
# OR
pnpm vitest run src/test/integration/{feature}
```

4. **Record test output** — paste the actual test runner results showing which tests ran and passed

**If the service cannot be started** (missing env vars, database not provisioned, etc.), document this as a **blocker** and set status to `"blocked"`. Do NOT mark the story as `passes` — infrastructure issues must be resolved first.

##### Step 5: Type Check

```bash
pnpm tsc --noEmit
# OR
pnpm typecheck
```

Record whether it passes clean or has errors.

##### Step 6: Verify Acceptance Criteria

NOW — with all tests passing — verify each `acceptance_criteria` item:

For each item:
1. Check the `verification_method` field
2. Execute verification based on method:
   - **`unit_test` / `integration_test` / `e2e_test`**: Reference the specific test that covers this criterion. If the test ran and passed in Steps 2-4, cite it. If no test covers it, WRITE one.
   - **`manual`**: Describe what you checked and what you observed. "Looks correct" is NOT sufficient — describe the specific file, line, and behavior you verified.
3. Set `"verified": true` ONLY after completing the above
4. Add a `notes` field describing the evidence

```json
{
  "item": "Uses createRouterWithActor pattern for tRPC router",
  "verified": true,
  "verification_method": "manual",
  "notes": "Verified at src/extensions/my-feature/router.ts:15 — exports ActorRouterConfig, createRouterWithActor used in root.ts:42"
}
```

**You MUST paste or summarize actual test runner output as evidence. "Tests should pass" is not verification.**

##### Testing Checklist (All Must Be True Before `passes`)

- [ ] Existing tests classified as REAL or MOCK — only REAL tests count
- [ ] No mock-based test results cited as verification evidence
- [ ] Service/app is running (for API/backend stories: server started, database connected)
- [ ] Smoke tests pass for all affected pages (frontend stories)
- [ ] New pages added to smoke test PAGES array (frontend stories)
- [ ] Regression tests cover page load, detail navigation, and dialog interaction for affected modules
- [ ] Integration tests pass against real PostgreSQL (NO mocked database)
- [ ] Integration tests call real endpoints (NO mocked HTTP handlers)
- [ ] Type check passes (`tsc --noEmit`)
- [ ] All `acceptance_criteria` items have `verified: true` with evidence in `notes`
- [ ] Evidence references REAL test output (not mock test output)
- [ ] No `monitor.clear()` before `assertNoErrors()` in any test
- [ ] No database mocks (`vi.mock("@/db/clients")`) in any test used for verification

### Step 4: Evaluate Completion

A story can ONLY have `passes: true` when ALL SEVEN conditions are met:

1. **ALL** `definition_of_done` items have `"done": true`
2. **ALL** `acceptance_criteria` items have `"verified": true` with evidence in `notes`
3. **Smoke tests** pass for all affected pages (new pages added to PAGES array)
4. **Regression tests** exist and pass for affected modules (covering page load, detail nav, dialog interaction as applicable)
5. **Integration tests** pass against real PostgreSQL (no mocked database)
6. **Type check** passes (`tsc --noEmit` or `pnpm typecheck`)
7. **At least one git commit** exists in the story's `commits` array with a real hash

```javascript
// Pseudo-code for passes evaluation
const allDoDDone = definition_of_done.every(item => item.done === true);
const allACVerified = acceptance_criteria.every(item => item.verified === true && item.notes);
const hasCommits = commits.length > 0 && commits.every(c => c.hash && c.hash !== "");
const sourceFilesExist = files_to_modify.every(f => fs.existsSync(f));
const smokeTestsPassed = /* ran smoke tests, observed passing output */;
const regressionTestsPassed = /* ran regression tests, observed passing output */;
const typeCheckPassed = /* ran tsc --noEmit, observed clean output */;
const passes = allDoDDone && allACVerified && hasCommits && sourceFilesExist
  && smokeTestsPassed && regressionTestsPassed && typeCheckPassed;
```

**HARD RULES**:
- If ANY `done` or `verified` item is false → `passes` MUST be false
- If `commits` array is empty → `passes` CANNOT be true (no commits = no code = no passes)
- If `status` is not `"testing"` or `"passes"` → `passes` CANNOT be true (must go through status progression)
- If you did not run the Testing Protocol (Step 3c) in this session → `passes` CANNOT be true
- If any `verified` item lacks a `notes` field with evidence → `passes` CANNOT be true

### Step 5: Update story_list.json

Once all criteria are met:

```json
{
  "id": "STORY-001",
  "status": "passes",
  "definition_of_done": [
    { "item": "Database schema created", "done": true },
    { "item": "API endpoint implemented", "done": true },
    { "item": "Unit tests passing", "done": true }
  ],
  "acceptance_criteria": [
    { "item": "User can create X", "verified": true, "verification_method": "e2e_test" },
    { "item": "System validates input", "verified": true, "verification_method": "unit_test" }
  ],
  "passes": true,
  "commits": [
    { "hash": "abc123", "message": "feat: implement STORY-001", "date": "2024-01-15T10:30:00Z" }
  ]
}
```

Also update feature status if all stories pass:
```json
{
  "status": "completed"  // Only if ALL stories have passes: true
}
```

### Step 6: Git Commit (The Save Point)

**CRITICAL**: Commit after EVERY completed story.

```bash
git add .
git commit -m "feat({feature}): {STORY-ID} - {brief description}

Definition of Done: ALL COMPLETE
- [x] Database schema created
- [x] API endpoint implemented
- [x] Unit tests passing

Acceptance Criteria: ALL VERIFIED
- [x] User can create X (e2e_test)
- [x] System validates input (unit_test)

Story Status: PASSES"
```

### Step 7: Update Progress Log (Optional)

If the project uses claude-progress.md or implementation.md:

```markdown
## {YYYY-MM-DD} - {STORY-ID} Complete

**Feature**: {feature-name}
**Story**: {story-title}
**Commits**: {commit-hash}

### What Was Done
- Implemented {X}
- Added tests for {Y}
- Verified acceptance criteria via {method}

### Next Steps
- Continue with {next-story-id}
```

### Step 8: Repeat or Report

If more stories remain:
- Return to Step 3 with the next story

If all stories complete:
- Report feature completion
- Update feature status to "completed"
- Create summary for handoff

## Workflow Loop Summary

```
READ story_list.json
  -> Find next story with passes: false
  -> Read specs/docs + _arch/patterns-testing.md
  -> Set status: "in_progress"
  -> Implement (working through DoD items)
  -> Set status: "testing"
  -> TESTING PROTOCOL:
     1. Discover existing tests (find affected smoke/regression/integration tests)
     2. Run smoke tests (add new pages to PAGES array if needed)
     3. Write/update regression tests (page load, detail nav, dialog interaction)
     4. Run integration tests against real PostgreSQL
     5. Run type check (tsc --noEmit)
     6. Verify each AC item with evidence
  -> ALL DoD done? ALL AC verified? ALL tests passing?
     -> YES: Set passes: true, COMMIT, update log
     -> NO: Fix issues, do NOT set passes: true
  -> REPEAT until all stories pass
```

## Resume Protocol

When resuming work (new context/session):

```bash
# 1. Orient yourself
pwd
git log --oneline -10
git status

# 2. Find and read the story list
cat .context/{project}/{feature}/story_list.json

# 3. Identify current state
# - Which stories have passes: true?
# - Which is the next story to work on?
# - Are there any blockers?

# 4. Continue from Step 3 above
```

## Examples

### Example 1: Starting a New Feature

User: "Implement the agents feature from specs"

```bash
# Read the story list
cat .context/ai-saas/agents/story_list.json

# Output shows:
# STORY-001: passes: false
# STORY-002: passes: false

# Start with STORY-001
# 1. Mark as in_progress
# 2. Read specs.md for details
# 3. Implement each DoD item
# 4. Verify each AC item
# 5. Update story_list.json with passes: true
# 6. Commit
# 7. Move to STORY-002
```

### Example 2: Resuming After Context Reset

User: "Resume work on agents feature"

```bash
# Check git state
git log --oneline -5
# Shows: "feat(agents): STORY-001 - Verified Passing"

# Read story list
cat .context/ai-saas/agents/story_list.json
# Shows: STORY-001 passes: true, STORY-002 passes: false

# Continue with STORY-002
```

### Example 3: Handling Test Failures

When a test fails:

1. Keep `passes: false` in story_list.json
2. Document the failure in blockers array
3. Fix the issue
4. Re-run tests
5. Only set `passes: true` when ALL tests pass

```json
{
  "id": "STORY-001",
  "status": "in_progress",
  "passes": false,
  "blockers": ["Test failing: expected 200, got 401 - auth issue"]
}
```

## story_list.json Rules

### NEVER Do These:
- Set `passes: true` if ANY DoD item has `"done": false`
- Set `passes: true` if ANY AC item has `"verified": false`
- Set `passes: true` when the `commits` array is empty
- Set `passes: true` without running the Testing Protocol (smoke + regression + integration + typecheck)
- Set `passes: true` based on mock-based test results (tests using vi.mock/jest.mock for DB, HTTP, or core infra)
- Set `done: true` on DoD items without having written actual source code
- Set `verified: true` on AC items without running the verification_method and observing output
- Set `verified: true` without adding a `notes` field with evidence
- Cite mock-based unit tests as evidence for `verified: true` — they prove nothing about real system behavior
- Count "N tests passing" as verification without confirming the tests hit real infrastructure (database, API, running server)
- Change any completion fields (`done`/`verified`/`passes`) during spec review, planning, or documentation-only sessions
- Skip statuses (e.g., `pending` directly to `passes`)
- Mock the database in tests (`vi.mock("@/db/clients")` or similar)
- Use `monitor.clear()` before `assertNoErrors()` to suppress real errors
- Use allowlist error monitoring (catch only known patterns) — always use denylist (catch all, filter safe noise)
- Implement multiple stories before committing
- Skip the commit step after completing a story
- Modify completed stories (passes: true) unless fixing bugs

### ALWAYS Do These:
- Read story_list.json before starting work
- Read `_context/_arch/patterns-testing.md` before writing any tests
- Confirm you are in IMPLEMENTATION mode (wrote code, ran tests, will commit) before touching completion fields
- Follow status progression: `pending -> in_progress -> testing -> passes`
- Update status to "in_progress" when starting
- Update status to "testing" before running the Testing Protocol
- Discover existing tests before writing new ones (check smoke array, regression files, integration tests)
- Add new pages to smoke test PAGES array in the same story that creates the page
- Write regression tests that cover all three levels (page load, detail nav, dialog) for affected modules
- Run tests against real PostgreSQL — never mock the database
- Use `setupErrorMonitoring(page)` + denylist approach in all E2E tests
- Wait for `networkidle` before `assertNoErrors()` in E2E tests
- Assert actual data content, not page shell visibility
- Check ALL DoD and AC items before setting passes
- Record evidence (test output, manual check details) in `notes` field when setting `verified: true`
- Include commit hash in the story after committing
- Update the "updated" date in story_list.json
- Update implementation.md progress after completing a story

## Integration with Existing Workflow

This skill integrates with:

- **create-specs**: Creates the initial story_list.json from specs/prd
- **browser-testing**: Provides Playwright tests for AC verification
- **commit-message**: Generates appropriate commit messages
- **update-wiki-docs**: Updates implementation.md after progress

## Notes

- story_list.json is per-feature, not global (enables parallel feature work)
- The schema is at `.claude/skills/create-specs/story_list.schema.json`
- Template is at `.claude/skills/create-specs/story_list.template.json`
- This protocol is based on the Anthropic Agent Harness Protocol
- JSON is used instead of markdown for better LLM parsing reliability
