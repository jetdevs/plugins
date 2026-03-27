---
name: smoke-test
description: Run browser smoke tests to verify pages load without errors after code changes. Use BEFORE claiming any implementation work is done. Also use when the user says "smoke test", "verify pages", "check if it works", "test the pages", "does it load", or "run a quick test".
---

# Smoke Test

Verify that pages affected by code changes load in the browser without JavaScript errors, console errors, or tRPC failures. This is the minimum verification before claiming work is complete.

**MANDATORY**: Every implementation agent MUST run this before saying "done."

## When to Run

- After implementing a feature
- After fixing a bug
- After any change that touches UI components, routes, tRPC routers, or database schema
- Before creating a PR
- Before telling the user "it's done"

## Process

### Step 1: Identify the Project

Determine which project was changed based on the working directory or recent git changes.

| Project | Path | Dev Command | Base URL |
|---------|------|-------------|----------|
| cadra-web | `cadra-web/` | `pnpm dev` | `http://localhost:3000` |
| yobo-merchant | `yobo-merchant/` | `pnpm dev` | `http://localhost:3000` |
| crm | `crm/` | `pnpm dev` | `http://localhost:3000` |
| slides | `slides/` | `pnpm dev` | `http://localhost:3000` |
| core-saas | `core-saas/` | `pnpm dev` | `http://localhost:3000` |

### Step 2: Identify Affected Pages

From git diff, determine which pages could be affected:

1. **Direct page changes** — files in `src/app/(org)/` → those pages
2. **Component changes** — search for imports to find which pages use the component
3. **Router/API changes** — find which pages call the affected tRPC procedures
4. **Schema changes** — any page that displays data from the changed table
5. **Layout changes** — all pages under that layout

**Minimum**: Always test at least the pages directly touched. If the change is broad (schema, shared component, layout), test all org pages.

### Step 3: Check if Dev Server is Running

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null || echo "not running"
```

If not running, start it:
```bash
cd /Volumes/HD/code/monorepo/{project} && pnpm dev &
# Wait for server to be ready
sleep 10
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000
```

If the server fails to start, that IS a test failure — report it.

### Step 4: Run Smoke Tests with Playwright

Use the Playwright MCP tools to verify each affected page:

For each page:

1. **Navigate** to the page
2. **Wait** for network idle (all API calls complete)
3. **Check** for:
   - HTTP status < 500
   - No JavaScript errors in console
   - No tRPC errors in API responses
   - Page content renders (not a blank white page)
   - No error boundary / "Something went wrong" UI

```
For each affected page:
  1. mcp__plugin_playwright_playwright__browser_navigate → page URL
  2. mcp__plugin_playwright_playwright__browser_snapshot → verify content rendered
  3. mcp__plugin_playwright_playwright__browser_console_messages → check for errors
  4. mcp__plugin_playwright_playwright__browser_network_requests → check for failed API calls
```

### Step 5: Report Results

Report results clearly:

**All pages passed:**
```
Smoke test passed — N pages verified:
  ✓ /dashboard — loaded, no errors
  ✓ /agents — loaded, no errors
  ✓ /agents/[id] — loaded, no errors
```

**Failures found:**
```
Smoke test FAILED — M of N pages have errors:
  ✓ /dashboard — loaded, no errors
  ✗ /agents — console error: TypeError: Cannot read property 'name' of undefined
  ✗ /agents/[id] — tRPC error: INTERNAL_SERVER_ERROR in agents.getById
```

**On failure**: FIX the issues, then re-run the smoke test. Do NOT claim work is done with failing smoke tests.

## Error Classification

### Real errors (must fix):
- `TypeError`, `ReferenceError`, `SyntaxError` in console
- tRPC errors (`INTERNAL_SERVER_ERROR`, `NOT_FOUND`, `UNAUTHORIZED` when logged in)
- HTTP 500 responses
- Blank/white page (component crash)
- Error boundary UI visible

### Ignorable noise (filter out):
- `ResizeObserver loop` warnings
- `NEXT_REDIRECT` (expected for auth redirects)
- `hydration` warnings
- React DevTools messages
- `favicon.ico` 404
- `net::ERR_` for external resources

## Quick Reference: Common Page Paths

### cadra-web
- `/dashboard`, `/agents`, `/agents/[id]`, `/agents/[id]/playground`
- `/tools`, `/skills`, `/prompts`, `/guardrails`
- `/knowledge-bases`, `/providers`, `/api-keys`
- `/settings`, `/settings/members`, `/settings/billing`

### yobo-merchant
- `/dashboard`, `/campaigns`, `/customers`, `/segments`
- `/offers`, `/outlets`, `/products`, `/workflows`
- `/settings`, `/settings/members`

### crm
- `/dashboard`, `/leads`, `/deals`, `/companies`, `/people`
- `/tasks`, `/settings`

### slides
- `/dashboard`, `/presentations`, `/editor/[id]`

## Integration with Other Skills

| Skill | Relationship |
|-------|--------------|
| `browser-testing` | Full E2E/regression patterns — use for comprehensive testing |
| `develop-specs` | Should invoke smoke-test after each story implementation |
| `feature-lifecycle` | Smoke test runs in Phase 3 (Post-Implementation) |

## Critical Rules

- **Never skip this** — "it compiles" is not "it works"
- **Test the actual page** — not just the API endpoint
- **Fix before done** — smoke test failures mean the work is NOT complete
- **Test with real data** — pages that load empty but fail with data are still broken
- **Check after deploy steps** — if you ran migrations or RLS deploy, re-test affected pages
