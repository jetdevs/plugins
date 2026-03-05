---
name: frontend-development
description: Use when working on React/Next.js frontend code, tRPC mutations, cache invalidation, data tables, modals/wizards, or form state persistence bugs. Also use when the user mentions "stale data", "cache not updating", "checkboxes not persisting", or "detail query".
---

# Frontend Development Patterns

Apply established frontend patterns from `_context/_arch/patterns-frontend.md` when building or debugging React/Next.js UI code.

## Instructions

### Step 1: Load Project Patterns

Before making changes, read the frontend patterns doc:

```
Read _context/_arch/patterns-frontend.md
```

Key sections to reference:
- **Cache Invalidation (CRITICAL)** — `invalidate()` vs `removeQueries()` rules
- **Detail Query Stale Cache on Edit-Save-Reopen** — when editing the same record shows stale data
- **Dialog/Modal Callback Ordering** — race conditions on close
- **Standard List/Table Pattern** — BaseListTable, columns, toolbar

### Step 2: Diagnose the Category

Identify which pattern applies:

| Symptom | Pattern |
|---------|---------|
| Edit form shows old values after save+reopen | Detail query stale cache — use `queryClient.removeQueries()` |
| List doesn't update after create/update/delete | Missing `utils.xxx.list.invalidate()` in mutation `onSuccess` |
| Checkboxes/toggles not reflecting saved state | Detail cache stale OR wrong property name in prefill |
| Modal closes but data doesn't refresh | Dialog callback ordering — `onSuccess` before `onOpenChange(false)` |
| Infinite re-renders on list page | Missing `useMemo` on tRPC query input objects |
| Column resize broken with drag-reorder | Custom resize handler needed — TanStack `getResizeHandler()` conflicts with `draggable` |

### Step 3: Cache Invalidation Rules

#### List queries — use `invalidate()`
```typescript
const utils = api.useUtils();

const mutation = api.entity.update.useMutation({
  onSuccess: () => {
    utils.entity.list.invalidate(); // Background refetch, stale list OK briefly
  },
});
```

#### Detail/edit queries — use `removeQueries()`
When a mutation changes data that a detail query caches (e.g., `getByUuid`), `invalidate()` serves stale data immediately. Use the raw React Query client instead:

```typescript
import { useQueryClient } from "@tanstack/react-query";

const utils = api.useUtils();
const queryClient = useQueryClient();

const handleSuccess = () => {
  // Remove cached detail — forces loading state on next fetch
  // tRPC keys are nested arrays: [["entity", "getByUuid"], ...]
  queryClient.removeQueries({ queryKey: [["entity", "getByUuid"]] });
  // Invalidate list (safe for lists)
  utils.entity.list.invalidate();
  // Clear local editing state
  setEditingItem(null);
};
```

**NEVER use tRPC utils for `cancel()` or `removeQueries()`** — they don't exist on the utils proxy and throw `contextMap[utilName] is not a function`.

#### Full app cache clear (org switch) — three-layer pattern
```typescript
queryClient.cancelQueries();
queryClient.removeQueries();
queryClient.resetQueries();
window.location.href = '/dashboard';
```

### Step 4: Form Prefill Debugging

When edit forms show wrong values, check the data flow:

1. **Repository** — What shape does `findByUuid` return? (e.g., `teams: [{ uuid, name }]`)
2. **Types** — Does the TypeScript interface match? (e.g., `AgentDetail.teams` vs `teamMemberships`)
3. **Prefill** — Does the `useEffect` read the correct property? (e.g., `agent.teams?.map(t => t.uuid)`)
4. **Submit** — Does the payload include the field? (e.g., `teamUuids: formData.teamUuids`)

Common bug: Repository maps a relation to a simplified shape (e.g., `teamMemberships` → `teams`), but the form reads the raw relation name.

### Step 5: Mutation Callback Order

Always follow this order in `onSuccess`:
```typescript
onSuccess: () => {
  toast.success("Saved");      // 1. User feedback
  onSuccess?.();               // 2. Parent callback (while mounted)
  utils.entity.list.invalidate(); // 3. Cache invalidation
  resetForm();                 // 4. Reset local state
  onOpenChange(false);         // 5. Close dialog LAST
};
```

### Step 6: Verify Fix

After applying a fix:
1. Save the record
2. Immediately reopen the same record
3. Confirm all fields reflect the saved values (not stale cache)
4. Open a different record, then reopen the original — confirm no cross-contamination
