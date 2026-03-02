---
name: crm-data-table
description: Use when working on CRM data tables, inline editing, column resize, column drag-reorder, calc footer, pagination, view modes (table/grid/kanban), bulk operations, select-all, or BaseListTable. Also use when the user mentions "table", "columns", "inline edit", "resize", "kanban", or "grid view".
---

# CRM Data Table Components

Shared data-table components in `src/components/data-table/` used across all CRM modules.

## Component Inventory

| Component | Purpose |
|-----------|---------|
| `BaseListTable` | Main table wrapper with toolbar, pagination, view modes |
| `InlineInput` | Inline text/number editing with overlay pattern |
| `InlineSelect` | Inline select dropdown, accepts `{value,label}[]` or `string[]` |
| `InlineBooleanToggle` | Inline checkbox toggle |
| `InlineDatePicker` | Inline date picker |
| `InlineMultiSelect` | Inline multi-select |
| `CellWrap` | Cell wrapper for overlay-based inline editing |
| `CalcCell` + `computeCalc` | Calculation footer (count, sum, avg, min, max) |
| `TablePagination` | Pagination with page size selector |
| `ViewModeToggle` | Table/grid/kanban toggle |
| `KanbanBoard` | Kanban view with drag-and-drop columns |
| `CardGrid` | Grid view with cards |
| `SelectAllBanner` | Select-all-across-pages banner |
| `ToolbarMoreMenu` | Toolbar overflow menu |
| `DataTableColumnHeader` | Sortable column header |

## Column Resize (CRITICAL FIX)

TanStack's `getResizeHandler()` does NOT work when `<th>` has `draggable=true`. Browser native drag steals mousemove events.

**Fix:**
1. Move `draggable` to inner `<div>` content, NOT on `<th>`
2. Use custom resize with document-level mouse listeners

```typescript
// Custom resize handler on the resize handle element
const handleResizeStart = (e: React.MouseEvent) => {
  e.preventDefault()
  e.stopPropagation()
  const startX = e.clientX
  const startWidth = currentWidth

  const onMouseMove = (e: MouseEvent) => {
    const newWidth = Math.max(50, startWidth + (e.clientX - startX))
    // Update column width
  }

  const onMouseUp = () => {
    document.removeEventListener('mousemove', onMouseMove)
    document.removeEventListener('mouseup', onMouseUp)
  }

  document.addEventListener('mousemove', onMouseMove)
  document.addEventListener('mouseup', onMouseUp)
}
```

Min width: 50px enforced in handler. `data-[resizing]` attribute for Tailwind styling.

## Column Drag Reorder

`draggable` goes on the inner content `<div>`, NOT on `<th>` (conflicts with resize).

## Zustand Table Store

```typescript
// stores/createTableStore.ts
export function createTableStore(name: string) {
  return create(persist(
    (set) => ({
      columnOrder: [],
      columnVisibility: {},
      columnSizing: {},
      // ... with queueMicrotask sync pattern
    }),
    { name }
  ))
}
```

Each module creates its own store: `useCompaniesTableStore`, `useLeadsTableStore`, etc.

## Inline Editing Pattern

```typescript
// InlineInput with overlay pattern + savedRef + tab navigation
<CellWrap>
  <InlineInput
    value={row.original.name}
    onSave={(newValue) => updateMutation.mutate({ id, name: newValue })}
    type="text"
  />
</CellWrap>
```

## Calc Footer

```typescript
// CalcCell with computeCalc for column aggregations
<CalcCell
  column={column}
  rows={table.getFilteredRowModel().rows}
  calc="sum" // count | sum | avg | min | max
/>
```

## Bulk Operations

- Select-all across pages: `SelectAllBanner` component
- `bulkDeleteByFilter` backend for server-side filtered deletion
- Confirmation dialog for large bulk operations (>100 items)

## useMemo for Query Inputs

CRITICAL: Always memoize tRPC query inputs to prevent infinite re-render loops:

```typescript
const queryInput = useMemo(() => ({
  page, pageSize, search, sortBy, sortOrder,
}), [page, pageSize, search, sortBy, sortOrder])

const { data } = (api.module as any).list.useQuery(queryInput)
```
