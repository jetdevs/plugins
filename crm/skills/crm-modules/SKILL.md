---
name: crm-modules
description: Use when creating or modifying CRM modules (leads, deals, companies, people, tasks, notes, tags, teams, starred, reports, custom fields, lifecycles), adding new CRM features, working on detail panels, grid cards, or following the CRM module blueprint. Also use when the user mentions "CRM", "leads page", "deals page", "companies", "people", or any CRM entity.
---

# CRM Module Blueprint

Every CRM module follows a consistent blueprint pattern. Use this when creating new modules or modifying existing ones.

## Module Structure

Each module in `src/extensions/{module}/`:

```
src/extensions/{module}/
  schema.ts              # Drizzle table definition
  router.ts              # tRPC router (createRouterWithActor)
  constants.ts           # Column definitions, status enums
  components/
    {Module}Page.tsx      # Main list page (table + grid + kanban)
    {Module}DetailPanel.tsx  # 1000px slide-over detail panel
    {Module}GridCard.tsx  # Grid view card
    {Module}FormDialog.tsx # Create/edit dialog
```

## Extension Modules (15 total)

| Module | Key Features |
|--------|-------------|
| companies | Company CRUD, detail panel, grid cards |
| people | Contact management, phone/email fields |
| leads | Lead management, conversion, dedup |
| deals | Pipeline, kanban board, stages |
| tasks | Task board by status/priority |
| notes | Rich text editor, linked entities |
| tags | Tagging system across entities |
| teams | Team management, member assignment |
| starred | Bookmarking across entities |
| reports | Business metrics dashboard |
| lifecycles | State machine editor (lead/pipeline/customer) |
| custom-fields | Dynamic field definitions per entity |
| messaging | Omnichannel inbox (WhatsApp, email, etc.) |
| projects | Project organization |
| dashboard | Analytics widgets |

## Key Patterns

### Page Component Pattern

```typescript
// {Module}Page.tsx
'use client'
import { Secure } from '@/components/auth/Secure'
import { createTableStore } from '@/stores/createTableStore'

// Zustand store for column state persistence
const useTableStore = createTableStore("{module}-table")

export function ModulePage() {
  // useMemo for tRPC query inputs (prevents infinite re-render)
  const queryInput = useMemo(() => ({
    page, pageSize, search, sortBy, sortOrder,
  }), [page, pageSize, search, sortBy, sortOrder])

  const { data, isLoading } = (api.module as any).list.useQuery(queryInput)

  return (
    <Secure.Container permission="{module}:read">
      <BaseListTable columns={columns} data={data?.items ?? []} />
    </Secure.Container>
  )
}
```

### Detail Panel (1000px slide-over)

```typescript
// {Module}DetailPanel.tsx
<div className="fixed inset-0 z-50">
  <div className="absolute inset-0 bg-black/20" onClick={onClose} />
  <div className="absolute right-0 top-0 h-full w-[1000px] bg-background shadow-xl">
    {/* Panel content */}
  </div>
</div>
```

### tRPC Type Cast

Due to Zod `~standard`/`~validate` type issues with createRouterWithActor:
```typescript
const { data } = (api.module as any).list.useQuery(input)
```

### Zod Error Extraction

```typescript
const fieldErrors = err?.data?.zodError?.fieldErrors
if (fieldErrors) {
  const messages = Object.entries(fieldErrors)
    .map(([field, errors]) => `${field}: ${(errors as string[]).join(', ')}`)
    .join('\n')
  toast.error(messages)
}
```

### Permission Wrapping

```typescript
<Secure.Container permission="module:read">
  {/* Page content */}
</Secure.Container>

<Secure.Button permission="module:create" onClick={handleCreate}>
  Add New
</Secure.Button>
```

## Lifecycle Categories

Lifecycles map to specific modules:
- `LEAD` → leads module
- `PIPELINE` → deals module
- `CUSTOMER` → companies module

## iOS Mobile Layout (CRITICAL)

- Outer container: `h-dvh flex flex-col` (NOT `min-h-screen`)
- Content area: `flex-1 min-h-0 overflow-hidden`
- Scroll div: `data-scroll-container flex-1 overflow-y-auto min-h-0` — ONLY element that scrolls
- html/body: `position: fixed; inset: 0; height: 100dvh; overflow: hidden`

## New Module Checklist

1. Create extension files (schema, router, constants, components)
2. Register router in `src/server/api/root.ts`
3. Export schema in `src/db/schema/index.ts`
4. Add permissions to `src/permissions/registry.ts`
5. Add RLS to `scripts/core/rls-registry.ts`
6. Add sidebar nav item
7. Create page route in `src/app/(org)/{module}/page.tsx`
8. Add to smoke test PAGES array
9. `pnpm db:migrate:generate && pnpm db:full:update && pnpm db:rls:deploy`
10. `pnpm generate:seed-permissions && pnpm db:seed:rbac`
11. Log out and back in

## Reference Documentation

### Core
- CRM specs & PRD: `_context/yobo-crm/specs/p1-core-build/{specs,prd,implementation}.md`
- Design system: `crm/DESIGN.md`
- Design thinking: `_context/yobo-crm/specs/p1-core-build/design-thinking.md`
- Screenshots: `_context/yobo-crm/specs/p1-core-build/screenshots/`

### Feature Specs (read these when working on specific features)
- Auth & SSO: `_context/yobo-crm/auth/{feature,implementation}.md`
- Lead conversion: `_context/yobo-crm/convert-lead-data/{specs,implementation}.md`
- Custom fields: `_context/yobo-crm/custom-fields/{specs,prd,implementation}.md`
- Merge records: `_context/yobo-crm/merge-records/{specs,prd,implementation}.md`
- Select-all: `_context/yobo-crm/select-all-records/{specs,prd,implementation}.md`
- Team permissions: `_context/yobo-crm/team-permissions/{specs,prd,implementation}.md`
- Test scripts: `_context/yobo-crm/test-scripts/{specs,prd,implementation}.md`
- Open API: `_context/yobo-crm/open-api/{feature,architecture,requirements}.md`

### Release Notes
- v0.1.0: `_context/yobo-crm/_release-notes/v0.1.0-initial-release.md`
