---
name: test-specs
description: Run smoke, regression, and integration tests for a completed spec implementation. This skill should be used when the user asks to test specs, run tests for specs, verify implementation, test my stories, run smoke tests, check spec tests, or when develop-specs completed but testing was skipped or incomplete. Also use when the user mentions test the feature, verify stories pass, or run the testing protocol.
---

# Test Specs

Run the full testing protocol against a completed (or partially completed) spec implementation. Designed for the scenario where `develop-specs` finished writing code but testing was skipped, incomplete, or needs re-running.

## When to Use

- After `develop-specs` completes implementation but tests were not run
- When stories have `status: "in_progress"` with all `done: true` but `passes: false`
- When re-verifying a feature after code changes
- When smoke/regression/integration tests need to be run standalone

## Instructions

### Step 1: Locate Feature Context

Find the feature's `story_list.json`:

```bash
# Check for story_list.json in the feature folder
ls _context/{project}/{feature}/story_list.json

# Or find all story lists
find _context -name "story_list.json" -type f
```

Read `story_list.json` to identify:
- Stories with `done: true` items but `passes: false` (need testing)
- Stories with `status: "in_progress"` or `"testing"` (in flight)
- Stories already `passes: true` (skip unless re-verification requested)

Also read `_context/_arch/patterns-testing.md` if it exists — it defines project-specific testing rules.

### Step 2: For Each Testable Story

Process one story at a time. Set `status: "testing"` before starting.

#### 2a. Discover and Classify Existing Tests

Before writing new tests, understand what exists:

```bash
# Find test files for this feature
find src/test -name "*.spec.ts" -o -name "*.test.ts" | grep -i {feature}

# CRITICAL: Identify mock-based tests (these do NOT count)
grep -l "vi\.mock\|jest\.mock\|sinon\.stub\|new Map()" src/test/**/*.{spec,test}.ts 2>/dev/null
grep -l "mockResolvedValue\|mockImplementation\|createMock" src/test/**/*.{spec,test}.ts 2>/dev/null

# Check smoke test page array
grep -n "{route-path}" src/test/e2e/smoke*.spec.ts

# Check regression tests
ls src/test/e2e/regression/
```

Classify each test file as **REAL** or **MOCK**:
- **REAL**: Connects to actual database, calls real endpoints, starts real server
- **MOCK**: Uses `vi.mock`/`jest.mock`, in-memory stubs, mocked HTTP clients

**Only REAL tests count toward verification.**

#### 2b. Run Smoke Tests (Page Load Verification)

If the story adds or modifies a page route:

1. **Add new pages to the smoke test PAGES array** (if not already present):
```typescript
{ name: 'My Feature', path: '/my-feature' },
```

2. **Run smoke tests**:
```bash
pnpm test:e2e --grep "smoke"
# OR
pnpm playwright test smoke-pages.spec.ts
```

3. **Smoke tests check** (all five must pass):
   - HTTP status < 500
   - No Next.js error overlay visible
   - No `console.error` messages (denylist filtering)
   - No per-procedure failures in tRPC batch response bodies
   - No uncaught JS errors (`pageerror` events)

#### 2c. Run Regression Tests (Interaction Verification)

Regression tests cover three levels:

| Level | What it catches | Example |
|-------|----------------|---------|
| **Page load** | API errors on initial render | `loyalty.get` 500 on customers page |
| **Detail navigation** | API errors when clicking into detail | `customers.getById` 500 |
| **Dialog interaction** | Errors inside modals/forms | `"Failed to load whitelist"` in edit dialog |

For each level affected by this story:

1. **Write or update regression tests** following these rules:
   - Use `setupErrorMonitoring(page)` before first navigation
   - Call `monitor.assertNoErrors()` after EVERY page load and interaction
   - Use `waitForLoadState('networkidle')` before `assertNoErrors()`
   - Assert actual data content, NOT page shell (`<main>`, `[role="main"]`)
   - NEVER use `monitor.clear()` before `assertNoErrors()`

2. **Run regression tests**:
```bash
pnpm test:e2e --grep "{feature}"
# OR
pnpm playwright test regression/{feature}.spec.ts
```

3. **Record actual test output** as evidence.

#### 2d. Run Integration Tests (API Verification)

If the story modifies tRPC procedures, database queries, or backend services:

1. **Ensure infrastructure is running**:
   - PostgreSQL must be up and migrated
   - Redis must be up if the service uses it
   - Server must be started (`pnpm dev` or `pnpm start`)

2. **Run integration tests** (must hit real database and real endpoints):
```bash
pnpm test --testPathPattern={feature}
# OR
pnpm vitest run src/test/integration/{feature}
```

**If the service cannot be started**, document as a **blocker** and set `status: "blocked"`.

#### 2e. Type Check

```bash
pnpm tsc --noEmit
# OR
pnpm typecheck
```

### Step 3: Verify Acceptance Criteria

With all tests passing, verify each `acceptance_criteria` item:

1. Check the `verification_method` field
2. Execute verification:
   - **`unit_test`/`integration_test`/`e2e_test`**: Reference the specific passing test
   - **`manual`**: Describe the specific file, line, and behavior verified
3. Set `"verified": true` ONLY after completing verification
4. Add a `notes` field with evidence

```json
{
  "item": "Uses createRouterWithActor pattern",
  "verified": true,
  "verification_method": "manual",
  "notes": "Verified at src/extensions/my-feature/router.ts:15"
}
```

### Step 4: Evaluate and Update story_list.json

A story can ONLY have `passes: true` when ALL conditions are met:

1. ALL `definition_of_done` items have `"done": true`
2. ALL `acceptance_criteria` items have `"verified": true` with evidence in `notes`
3. Smoke tests pass for all affected pages
4. Regression tests exist and pass for affected modules
5. Integration tests pass against real PostgreSQL
6. Type check passes
7. At least one git commit exists in the story's `commits` array

Update `story_list.json` with results and commit:

```bash
git add .
git commit -m "test({feature}): {STORY-ID} - verification complete

Testing Protocol: ALL COMPLETE
- [x] Smoke tests passing
- [x] Regression tests passing
- [x] Integration tests passing
- [x] Type check clean
- [x] All AC verified with evidence

Story Status: PASSES"
```

### Step 5: Continue or Report

If more untested stories remain, return to Step 2. When all stories are verified, update feature status to `"completed"` if all stories pass.

## Hard Rules

- **NEVER** set `passes: true` based on mock-based test results
- **NEVER** set `verified: true` without a `notes` field containing evidence
- **NEVER** skip the status progression (`in_progress` → `testing` → `passes`)
- **NEVER** cite "tests should pass" — paste actual test runner output
- **NEVER** mock the database in tests
- **NEVER** use `monitor.clear()` before `assertNoErrors()`
- If ANY `done` or `verified` item is `false` → `passes` MUST be `false`
- If `commits` array is empty → `passes` CANNOT be `true`

## Integration

Works alongside:
- **develop-specs** — implements the code this skill tests
- **create-specs** — creates the `story_list.json` this skill reads
- **browser-testing** — Playwright test patterns for E2E verification
- **commit-message** — generates commit messages after verification
