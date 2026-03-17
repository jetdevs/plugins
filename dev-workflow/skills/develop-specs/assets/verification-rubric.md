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

## Section 5: Acceptance Criteria Evidence

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 5.1 | Every AC item has `verified: true` | All items true | Any item false |
| 5.2 | Every AC item has a `notes` field | All items have non-empty notes | Any item missing notes |
| 5.3 | Notes reference REAL evidence only | Notes cite: REAL test files (from classification), manual inspection with file:line, or live API response | Notes cite MOCK test files, or say "looks correct" / "should work" |
| 5.4 | `verification_method` matches actual method used | If notes describe a test → method is `unit_test`/`integration_test`/`e2e_test`. If notes describe code inspection → method is `manual` | Mismatch between method and evidence |

**Evidence quality guide**:

```
GOOD evidence (specific, verifiable):
  "Verified at src/server/tools/tool-registry.ts:142 — get_planning_context handler
   uses Promise.all() for 5 parallel queries. Functional test hit localhost:4100/v1/tools
   with tool=get_planning_context, returned business+brand+segments in 380ms."

BAD evidence (vague, unverifiable):
  "Tool handler implemented and tests pass"
  "Checked the file, looks correct"
  "12 tests in adapter.test.ts — all pass" (if adapter.test.ts is a MOCK test)
```

---

## Section 6: Definition of Done

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 6.1 | Every DoD item has `done: true` | All items true | Any item false |
| 6.2 | DoD items reflect actual work done | `pnpm build` was run (not assumed). Tests were run (not assumed). Type check was run (not assumed). | DoD items marked done without running the verification command |

---

## Section 7: Status Progression

| # | Criterion | PASS | FAIL |
|---|-----------|------|------|
| 7.1 | Story went through `pending → in_progress → testing → passes` | Status history shows all transitions | Jumped from `pending` to `passes` |
| 7.2 | Status was `testing` when tests were run | `testing` set before test execution | Tests run while status was `in_progress` or `pending` |

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
