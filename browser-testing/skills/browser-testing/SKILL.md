---
name: browser-testing
description: Use when writing tests, creating test files, adding smoke tests, regression tests, E2E tests, integration tests, or running Playwright tests. Also use when the user says "test this page", "add tests", "write tests for", "run tests", "verify this works", "add test coverage", or asks about testing patterns, error monitoring, or test architecture. ALWAYS use Playwright for browser tests, NEVER use chrome-browser MCP.
---

# Playwright E2E Testing Guide

Write E2E tests that verify real functionality against real servers and real databases. Never mock the database.

## Foundational Rule: NEVER Mock the Database

Tests that mock the database are banned. They verify mock behavior, not application behavior.

```typescript
// BANNED
vi.mock("@/db/clients", () => ({
  db: { select: vi.fn().mockResolvedValue([{ id: 1 }]) }
}));

// REQUIRED: Test against real PostgreSQL via real dev server
```

Mocks are only acceptable for external services (email, payment gateways) and pure computation.

---

## Error Monitoring Architecture

Every test file must use `setupErrorMonitoring`. It catches ALL errors and filters known-safe noise (denylist pattern).

### setupErrorMonitoring Implementation

```typescript
export function setupErrorMonitoring(page: Page) {
  const errors: string[] = [];

  // 1. Uncaught JS errors
  page.on('pageerror', (err) => {
    errors.push(`[JS Error] ${err.message}`);
  });

  // 2. ALL console.error (denylist, NOT allowlist)
  page.on('console', (msg) => {
    if (msg.type() === 'error') {
      errors.push(`[Console Error] ${msg.text()}`);
    }
  });

  // 3. tRPC batch response inspection
  page.on('response', async (response) => {
    const url = response.url();
    if (!url.includes('/api/trpc/')) return;

    if (response.status() >= 400) {
      errors.push(`[HTTP ${response.status()}] ${url}`);
      return;
    }

    if (response.status() === 200) {
      try {
        const body = await response.json();
        const items = Array.isArray(body) ? body : [body];
        for (const item of items) {
          if (item?.error) {
            const code = item.error?.data?.code || 'UNKNOWN';
            const message = item.error?.message || 'Unknown error';
            errors.push(`[tRPC Error] ${code}: ${message}`);
          }
        }
      } catch { /* Not JSON (SSE stream) — skip */ }
    }
  });

  return {
    errors,
    assertNoErrors(context?: string) {
      const realErrors = errors.filter(msg =>
        !msg.includes('ResizeObserver loop') &&
        !msg.includes('Non-Error promise rejection') &&
        !msg.includes('NEXT_REDIRECT') &&
        !msg.includes('hydration') &&
        !msg.includes('Download the React DevTools') &&
        !msg.includes('Warning:') &&
        !msg.includes('Each child in a list') &&
        !msg.includes('Cannot update a component') &&
        !msg.includes('findDOMNode is deprecated') &&
        !msg.includes('net::ERR_') &&
        !msg.includes('favicon.ico')
      );
      if (realErrors.length > 0) {
        throw new Error(
          `${context ? context + ': ' : ''}Found ${realErrors.length} error(s):\n${realErrors.join('\n')}`
        );
      }
    },
    clear() { errors.length = 0; },
  };
}
```

### Critical Rules

- **Denylist, not allowlist**: Catch ALL errors, filter known-safe noise. Never filter for known-bad patterns.
- **tRPC batch inspection**: HTTP 200 can hide per-procedure 500s inside the batch response body. Always parse and check each item.
- **Three error sources**: console.error, HTTP/tRPC responses, uncaught JS errors (pageerror). Monitor all three.

---

## Smoke Tests

Smoke tests answer: "Does every page load without crashing?"

### Template

```typescript
const PAGES: { name: string; path: string; timeout?: number }[] = [
  { name: 'Dashboard', path: '/dashboard', timeout: 60_000 },
  { name: 'Leads', path: '/leads' },
  { name: 'Deals', path: '/deals' },
  // ALL tenant pages must be listed
];

for (const { name, path, timeout: pageTimeout } of PAGES) {
  test(`${name} (${path}) – no errors`, async () => {
    const monitor = setupErrorMonitoring(page);

    const response = await page.goto(path, {
      waitUntil: 'domcontentloaded',
      timeout: pageTimeout ?? 30_000,
    });

    expect(response?.status()).toBeLessThan(500);
    await page.waitForLoadState('networkidle', { timeout: 15_000 }).catch(() => {});
    monitor.assertNoErrors(`${name} page`);
  });
}
```

### Coverage Rule

ALL pages in `src/app/(org)/` MUST be in the smoke test PAGES array. Add new pages in the same PR.

---

## Regression Tests — Three Levels

Regression tests answer: "Do all user interactions work without errors?"

### Level 1: Page Load

```typescript
test('1. List page loads without errors', async () => {
  const monitor = setupErrorMonitoring(page);
  await page.goto('/my-module');
  await page.waitForLoadState('networkidle', { timeout: 15_000 }).catch(() => {});

  // Assert ACTUAL DATA, not page shell
  const rows = page.locator('table tbody tr');
  expect(await rows.count()).toBeGreaterThan(0);

  monitor.assertNoErrors('List page');
});
```

### Level 2: Detail Navigation

```typescript
test('2. Detail page loads with real data', async () => {
  const monitor = setupErrorMonitoring(page);

  const firstRow = page.locator('table tbody tr').first();
  await firstRow.click();
  await page.waitForLoadState('networkidle', { timeout: 15_000 }).catch(() => {});

  // Assert content that only appears when API succeeds
  const heading = page.locator('h1, h2, [data-testid="detail-title"]').first();
  await expect(heading).toBeVisible({ timeout: 10_000 });
  const text = await heading.textContent();
  expect(text?.length).toBeGreaterThan(0);

  monitor.assertNoErrors('Detail page');
});
```

### Level 3: Dialog Interaction

```typescript
test('3. Edit dialog opens without errors', async () => {
  const monitor = setupErrorMonitoring(page);

  await page.click('button:has-text("Edit")');
  const dialog = page.locator('[role="dialog"]');
  await expect(dialog).toBeVisible({ timeout: 10_000 });
  await page.waitForLoadState('networkidle', { timeout: 10_000 }).catch(() => {});

  // Assert form fields populated
  const nameInput = dialog.locator('input[name="name"]');
  const value = await nameInput.inputValue();
  expect(value.length).toBeGreaterThan(0);

  monitor.assertNoErrors('Edit dialog');
});
```

---

## Anti-Patterns — NEVER Do These

### 1. Assert page shell instead of data

```typescript
// BAD: Page shell is always visible even when API fails
await expect(page.locator('main')).toBeVisible();

// GOOD: Content that only exists when API succeeds
await expect(page.locator('td:has-text("$")')).toBeVisible();
```

### 2. monitor.clear() before assertNoErrors()

```typescript
// BAD: Hides real bugs
monitor.clear();
monitor.assertNoErrors('My page');

// GOOD: Let errors fail the test
monitor.assertNoErrors('My page');
```

`monitor.clear()` is ONLY valid after a known redirect/404 when trying alternative routes.

### 3. Allowlist error monitoring

```typescript
// BAD: Only catches errors you already know about
if (text.includes('tRPC failed') || text.includes('500')) {
  errors.push(text);
}

// GOOD: Catch everything, filter safe noise
errors.push(text); // Catch ALL console.error
```

### 4. Assert without waiting for network

```typescript
// BAD: tRPC call may still be in-flight
await page.goto('/customers/uuid');
monitor.assertNoErrors('Detail'); // Race condition!

// GOOD: Wait for all API calls
await page.goto('/customers/uuid');
await page.waitForLoadState('networkidle', { timeout: 15_000 }).catch(() => {});
monitor.assertNoErrors('Detail');
```

### 5. Suppress required assertions

```typescript
// BAD: Catch and ignore
await assertDataLoaded(page, selectors).catch(() => {});

// GOOD: Let it fail — fix in application code
await assertDataLoaded(page, selectors);
```

---

## Regression Test Boilerplate

```typescript
import { test, expect, type Page } from '@playwright/test';
import { login, setupErrorMonitoring, waitForStable, assertNoErrorUI } from './helpers';

test.describe.configure({ mode: 'serial' });
test.setTimeout(90_000);

let page: Page;

test.beforeAll(async ({ browser }) => {
  page = await browser.newPage();
  await login(page);
});

test.afterAll(async () => { await page?.close(); });
```

---

## Checklist: New Test File

Before submitting, verify:

- [ ] Tests run against real PostgreSQL (NOT mocked)
- [ ] `setupErrorMonitoring(page)` called before first navigation
- [ ] `monitor.assertNoErrors()` called after EVERY page load and interaction
- [ ] `waitForLoadState('networkidle')` before `assertNoErrors()`
- [ ] Assertions check actual data content, not page shell
- [ ] No `monitor.clear()` before `assertNoErrors()`
- [ ] No `.catch(() => {})` on required element assertions
- [ ] Detail page tests exist (click row → verify data)
- [ ] Dialog tests exist (open create/edit → verify form loads)
- [ ] Page added to smoke test PAGES array
- [ ] No `vi.mock("@/db/clients")` or similar database mocks

## Checklist: New Extension Page

When adding a page under `src/app/(org)/`:

- [ ] Add to smoke test PAGES array
- [ ] Add `timeout: 60_000` if page is heavy
- [ ] Create regression test covering all three levels
- [ ] All tests run against real dev server with real database
