---
name: crm-uiux
description: Use when working on CRM UI/UX, styling components, design system, layout, mobile responsiveness, theming, sidebar, modals, forms, cards, or visual consistency. Also use when the user mentions "design system", "UI", "UX", "styling", "mobile layout", "responsive", "theme", or "sidebar".
---

# CRM UI/UX Design System & Patterns

Comprehensive guide for visual consistency across the Yobo CRM.

## Design System (crm/DESIGN.md)

### Typography
- **Font**: System Sans-serif (Inter, SF Pro Text, Segoe UI)
- **Base**: 14px (0.875rem), line-height 1.5
- **H1**: 30px bold `#111827` (page titles)
- **H2**: 20px bold `#111827` (section headers)
- **H3**: 12px bold uppercase tracking-wide `#6B7280` (sidebar/table headers)
- **Body**: 14px regular `#374151` (primary) or `#6B7280` (muted)
- **Micro**: 10-12px bold uppercase (badges, metadata)

### Colors
- **Background**: `#FFFFFF` (app), `#F9FAFB` (panels)
- **Border**: `#E5E7EB`
- **Primary action**: `#030712` (black buttons)
- **Brand blue**: `#2563EB` (links, active states)
- **Status**: Green `#DCFCE7`/`#166534`, Yellow `#FEF9C3`/`#854D0E`, Blue `#DBEAFE`/`#1E40AF`, Red `#FEE2E2`/`#991B1B`

### Spacing (4pt grid)
- Small gap: 8-12px, Medium: 16px, Large: 24-32px
- Sidebar: 240px fixed, Right panel: 300-320px, Page padding: 24px h / 16px v

## Component Standards

### Buttons
- Height: 36-40px, radius: 4-6px, padding: 12px h / 8px v
- Primary: black bg, white text
- Brand: blue `#2563EB` bg, white text
- Secondary: white bg, gray border
- Ghost: transparent, gray text

### Data Tables
- Header: 48px, `#F9FAFB` bg, uppercase bold xs gray text
- Rows: 56-64px, white bg, gray border-bottom, hover `#F9FAFB`
- No vertical borders

### Cards
- White bg, 1px gray border, `shadow-sm`, radius 6-8px
- Hover: slight lift or border darken

### Modals
- Overlay: black 50% opacity with backdrop blur
- Container: white, radius 8-12px, `shadow-xl`
- Header with border-bottom, footer actions right-aligned

### Chat Bubbles
- Incoming: white bg, gray border, radius 12px
- Outgoing: brand blue bg, white text, radius 12px
- Internal note: light yellow bg

### Icons
- Heroicons (Outline) / Feather style
- 20x20px, stroke 1.5-2px, round corner joins

## Layout Patterns

### iOS Mobile Layout (CRITICAL)

```
html/body: position: fixed; inset: 0; height: 100dvh; overflow: hidden
  └─ Outer: h-dvh flex flex-col (NOT min-h-screen)
       ├─ Nav: shrink-0
       └─ Content: flex-1 min-h-0 overflow-hidden
            └─ SidebarContentWrapper: flex-1 min-h-0 overflow-hidden
                 └─ Page: flex-1 min-h-0 flex flex-col
                      └─ Scroll: data-scroll-container flex-1 overflow-y-auto min-h-0
```

**Rules:**
- `h-dvh` not `min-h-screen` (100vh on iOS is taller than visible area)
- Only `data-scroll-container` element scrolls
- Body padding: ONLY `padding-top: env(safe-area-inset-top)` — bottom creates gap
- AnimatedDrawer uses `[data-scroll-container]` selector

### Sidebar Navigation
- Item: 8px 12px padding, flex align-center, 12px gap
- Default: transparent bg, gray text
- Hover: `#F3F4F6` bg, dark gray text
- Active: `#E5E7EB` bg, black text, medium weight

### Detail Panel (Slide-Over)
- 1000px fixed width, right-aligned
- Backdrop: `bg-black/20`
- Content: full height, white bg, `shadow-xl`

## SDK UI Patterns

### Factory Pattern (Shadcn injection)
SDK components are factories — apps inject their own Shadcn primitives:

```typescript
const DataTable = createDataTableWithToolbar({
  Table, TableHeader, TableBody, TableRow, TableCell,
  Button, Input, Select,
})
```

### SDK Theme System
- SDK provides theme tRPC router (CRUD for DB records)
- Apps own: CSS files (`public/themes/*.css`), React theme components
- Per-org theming via SDK theme config

## Create vs Edit UI Patterns

### Create Operations → Wizards
Multi-step wizard with Next/Back buttons for creation flows.

### Edit Operations → Direct Forms
Inline editing or modal forms for editing existing records.

### Form Fields
- Height: 40px, white bg, 1px gray border, radius 6px
- Focus: blue border + subtle blue ring/shadow
- Placeholder: gray `#9CA3AF`

## Visual Effects
- Shadows: very subtle — `shadow-sm` for cards, `shadow-xl` for modals
- Disabled: 50% opacity
- Transitions: 150ms ease-in-out on hover states

## React Patterns

### Prevent Infinite Re-renders
```typescript
// ALWAYS use useMemo for tRPC query inputs
const queryInput = useMemo(() => ({ page, search }), [page, search])

// ALWAYS use specific properties in useEffect deps, not objects
useEffect(() => { /* ... */ }, [item.id, item.name])  // NOT [item]
```

### SDK Hook Factories
```typescript
import { createUseAuthSession } from '@jetdevs/core/hooks'
const useAuthSession = createUseAuthSession(useSession)
```

## Reference Documentation

- Design system: `crm/DESIGN.md`
- UI patterns: `_context/_arch/pattern-ui.md`
- React patterns: `_context/_arch/pattern-react.md`
- Frontend patterns: `_context/_arch/patterns-frontend.md`
- CRM screenshots: `_context/yobo-crm/specs/p1-core-build/screenshots/`
