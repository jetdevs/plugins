# Story Verification Rubric

This rubric is the authority for evaluating whether a story can transition to `passes: true`. Every criterion has exactly one correct answer — there is no room for interpretation.

## How to Use This Rubric

For each story, evaluate every section below. A story MUST score **PASS** on ALL sections to set `passes: true`. A single **FAIL** in any section means the story remains `pending`, `in_progress`, or `blocked`.

---

## Section 1: Code Exists

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 1.1 | Source files listed in `files_to_modify` exist on disk | `ls {file}` returns the file | File not found |
| 1.2 | Code compiles without errors | `pnpm build` or `tsc --noEmit` exits 0 | Any compilation error |
| 1.3 | At least one git commit with real hash in `commits` array | `git log --oneline {hash}` shows the commit | Empty `commits` array or placeholder hash |

**Evaluation method**: Run `ls`, `tsc --noEmit`, and `git log` — paste output.

---

## Section 2: Infrastructure Running

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 2.1 | Database is up and migrated | `pnpm db:migrate` or equivalent succeeds, or DB is already current | DB connection refused, migration errors |
| 2.2 | Required services are running (Redis, message queues, etc.) | Service responds to ping/health check | Connection refused or timeout |
| 2.3 | Application/API server is running | `curl http://localhost:{port}` returns a response (any status) | Connection refused |
| 2.4 | If frontend story: app is accessible in browser | `curl http://localhost:{port}` returns HTML | Connection refused |

**Evaluation method**: Run health checks — paste output. If infrastructure cannot be started, the story is `"blocked"`, not `"passes"`.

**Exception**: Stories that are purely build/compile-time (e.g., SDK packages, libraries with no runtime server) may skip 2.1-2.4 if they have no server component. Document why in notes.

---

## Section 3: Test Classification

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 3.1 | Every test file has been inspected for mock patterns | Grep output shown for `vi.mock`, `jest.mock`, `sinon.stub`, `mockResolvedValue`, `mockImplementation` | No grep performed |
| 3.2 | Each test file classified as REAL or MOCK in a table | Classification table produced with columns: File, Type, Mocks Found, Valid? | No table, or table missing files |
| 3.3 | At least one REAL test exists for the story | At least one test file marked REAL/YES | All tests are mock-based |

**How to classify a test**:

```
REAL test (valid for verification):
  - Connects to actual database (PostgreSQL, not SQLite/in-memory)
  - Calls real HTTP endpoints on a running server
  - Uses Playwright/browser against a running app
  - No vi.mock/jest.mock for database, HTTP, or core infrastructure

MOCK test (NOT valid for verification):
  - Contains vi.mock("@/db/clients") or similar DB mock
  - Contains vi.mock("node-fetch") or mocked HTTP clients
  - Uses in-memory Map/object pretending to be database
  - Mocks Fastify request/reply objects
  - Uses jest.fn() for all external dependencies
  - Contains mockResolvedValue/mockImplementation for core infra
```

**Evaluation method**: Grep test files, produce classification table — paste both.

---

## Section 4: Test Execution

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 4.1 | REAL tests were executed in this session | Test runner output shown with pass/fail counts | No test output, or only mock test output |
| 4.2 | All REAL tests pass | 0 failures in test runner output | Any test failure |
| 4.3 | Type check passes | `tsc --noEmit` exits 0 with no errors | Any type error |
| 4.4 | For frontend: smoke tests pass for affected pages | Playwright output showing page load success | Smoke test failures or new pages not in PAGES array |
| 4.5 | For frontend: regression tests cover affected modules | Test output showing interaction-level tests pass | No regression tests or failures |

**Evaluation method**: Run tests, paste actual runner output. "Tests should pass" or "N tests passed" without classification is automatic FAIL.

---

## Section 5: Verification Evidence (4 Proof Types)

**Every frontend story MUST provide ALL 4 proof types. Backend-only stories require proofs 2, 4.**

### Proof 1: Screenshot Evidence

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 5.1 | Playwright screenshot captured for each affected page/modal/dialog | Screenshot file saved and path referenced in story notes | No screenshot taken |
| 5.2 | Screenshot shows the feature working (not just the page loading) | Screenshot clearly shows the new UI element, data, or interaction result | Screenshot shows generic page shell or unrelated content |
| 5.3 | For modals/dialogs: screenshot captured in open state | Modal/dialog visible with content populated | Only closed state or page behind shown |

**How to capture**: Use Playwright `page.screenshot({ path: 'evidence/{story-id}-{description}.png' })` during test execution. Reference the file path in AC notes.

### Proof 2: Database Record Verification

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 5.4 | New records created by the feature exist in the database | SQL query output showing the expected rows with correct column values | No DB query run, or expected records missing |
| 5.5 | Record values match expected data from the story | Column values match what the feature should have inserted/updated | Values wrong, nulls where data expected, wrong foreign keys |
| 5.6 | RLS policies work correctly | Query run both with and without org context returns expected results | RLS not verified, or policy allows unauthorized access |

**How to verify**: Run direct SQL queries against the database and paste the output:
```sql
-- Example: verify agent_roles were seeded
SELECT id, name, org_id, agent_type FROM agent_roles WHERE org_id IS NULL;

-- Example: verify RLS works
SET LOCAL rls.current_org_id = '1';
SELECT count(*) FROM agent_roles; -- should see platform + org 1 roles
```

### Proof 3: Browser Console Clean

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 5.7 | No `console.error` messages on affected pages | Playwright console message capture shows zero errors (or only known/allowlisted errors) | Any unexpected console.error present |
| 5.8 | No uncaught exceptions (`pageerror` events) | Playwright pageerror listener captured zero events | Any uncaught exception |
| 5.9 | No failed network requests (4xx/5xx) related to the feature | Network request log shows all feature-related requests succeeded | Any 4xx/5xx on feature endpoints |

**How to capture**: Use Playwright's console and network monitoring:
```typescript
const errors: string[] = [];
page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
page.on('pageerror', err => errors.push(err.message));
// ... navigate and interact ...
expect(errors).toEqual([]); // paste this assertion result
```

### Proof 4: Server Console Clean

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 5.10 | No server-side errors logged during test execution | Server log output (stdout/stderr) shows no ERROR/FATAL entries during the test window | Unhandled errors, stack traces, or tRPC internal errors in server logs |
| 5.11 | No unhandled promise rejections | Server log clean of `UnhandledPromiseRejection` or equivalent | Any unhandled rejection |
| 5.12 | tRPC procedures complete without internal errors | No `TRPCError` with code INTERNAL_SERVER_ERROR in logs | Any INTERNAL_SERVER_ERROR |

**How to capture**: Start the dev server with output piped to a log file, run tests, then check the log:
```bash
# Start server with log capture
pnpm dev > /tmp/server-test.log 2>&1 &
# ... run Playwright tests ...
# Check for errors
grep -i "error\|fatal\|unhandled" /tmp/server-test.log
# Paste the grep output (or "no matches" if clean)
```

---

## Section 6: Acceptance Criteria Evidence

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 6.1 | Every AC item has `verified: true` | All items true | Any item false |
| 6.2 | Every AC item has a `notes` field | All items have non-empty notes | Any item missing notes |
| 6.3 | Notes reference REAL evidence only | Notes cite: REAL test files (from classification), manual inspection with file:line, screenshot paths, DB query output, or console proof | Notes cite MOCK test files, or say "looks correct" / "should work" |
| 6.4 | `verification_method` matches actual method used | If notes describe a test → method is `unit_test`/`integration_test`/`e2e_test`. If notes describe code inspection → method is `manual` | Mismatch between method and evidence |
| 6.5 | At least one AC item references screenshot evidence | Screenshot path cited in notes for a UI-related criterion | No screenshots referenced for any frontend AC |
| 6.6 | At least one AC item references DB verification | SQL query output cited for a data/schema criterion | No DB evidence for data-layer AC |

**Evidence quality guide**:

```
GOOD evidence (specific, verifiable):
  "Verified at src/server/tools/tool-registry.ts:142 — get_planning_context handler
   uses Promise.all() for 5 parallel queries. Functional test hit localhost:4100/v1/tools
   with tool=get_planning_context, returned business+brand+segments in 380ms.
   Screenshot: evidence/CAD-25-role-grid.png
   DB: SELECT count(*) FROM agent_roles WHERE org_id IS NULL → 8 rows
   Console: 0 errors captured during page load"

BAD evidence (vague, unverifiable):
  "Tool handler implemented and tests pass"
  "Checked the file, looks correct"
  "12 tests in adapter.test.ts — all pass" (if adapter.test.ts is a MOCK test)
```

---

## Section 7: Definition of Done

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 7.1 | Every DoD item has `done: true` | All items true | Any item false |
| 7.2 | DoD items reflect actual work done | `pnpm build` was run (not assumed). Tests were run (not assumed). Type check was run (not assumed). | DoD items marked done without running the verification command |

---

## Section 8: Status Progression

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 8.1 | Story went through `pending → in_progress → testing → passes` | Status history shows all transitions | Jumped from `pending` to `passes` |
| 8.2 | Status was `testing` when tests were run | `testing` set before test execution | Tests run while status was `in_progress` or `pending` |

---

## Scoring

```
ALL sections PASS  →  Story status: "passes", passes: true
ANY section FAIL   →  Story status: remains current, passes: false
                      Document which section failed in blockers array
```

## Quick Reference: Automatic FAIL Conditions

Any ONE of these means the story CANNOT be `passes: true`:

1. `commits` array is empty
2. No Test Classification Report produced
3. All tests are mock-based (no REAL tests exist)
4. Service/infrastructure not running (for backend/API stories)
5. Any AC item missing `notes` field
6. Any AC item's `notes` references a MOCK test
7. Test runner output not shown (just "N passed" without details)
8. Type check not run or has errors
9. `files_to_modify` files don't exist on disk
10. Status jumped directly to `passes` without going through `testing`
11. **No screenshot evidence for any frontend story**
12. **No database record verification for any data-layer story**
13. **Browser console errors present (unacknowledged)**
14. **Server console errors present during test window**

## Proof Evidence Summary

| Proof Type | Required For | How to Capture | What to Paste in Notes |
|------------|-------------|----------------|----------------------|
| Screenshot | All frontend stories | Playwright `page.screenshot()` | File path: `evidence/{story}-{desc}.png` |
| DB Records | All stories with schema/data changes | Direct SQL query | Query + output rows |
| Browser Console | All frontend stories | Playwright console/pageerror listeners | Error count (must be 0) + any captured messages |
| Server Console | All stories | `grep -i error /tmp/server-test.log` | Grep output (must be empty or allowlisted only) |
