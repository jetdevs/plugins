---
name: slides-editor
description: Use when working on the slides presentation editor, canvas rendering, object manipulation, variable system, auto-save, themes, groups, text editing, PDF/PPTX export, or template system. Also use when the user mentions "slides", "presentation editor", "canvas", "variables", or "templates".
---

# Slides Presentation Editor Guide

A Google Slides-like presentation editor built with React, Next.js, and tRPC.

## Core Architecture

### Canvas System (`SlideCanvas.tsx`)
- **Display**: 800x450, **Page**: 1920x1080 (widescreen)
- **Coordinates**: Objects stored in display coords, rendered at page pixels
- **Zoom**: CSS transform scale on entire canvas
- **Scale**: `displayScale = Math.min(800 / pageWidth, 600 / pageHeight)`

### State (`editorStore.ts` — Zustand + Immer)
- Key state: slides, currentSlide, selectedIds, zoom, isDirty, isInteracting
- Deferred dirty state: changes during interaction set `pendingChanges`, dirty flag set AFTER interaction ends
- Auto-save: debounced 1s, only triggers after interactions complete

### Object Types
Text, Shape (rect/circle/triangle/star/hex/arrow), Image, Line, Group

## Variable System

- Event-based: singleton emitter, cross-component communication
- Trigger `[` in any text input for autocomplete dropdown
- Format: `[type.name]` e.g., `[client.company_name]`
- Preview mode: toggle to see rendered values
- Variables replaced during PDF export

## Group System

- Multi-object grouping with unified drag/resize/delete
- Group-aware selection: clicking grouped object selects entire group
- Proportional resize: scales all children
- Hierarchical deletion: group + all children removed together

## Critical Patterns

### Avoid Closure Issues — Use Refs
```typescript
const editTextRef = useRef(editText);
const handleVariableSelected = () => {
  const newText = replaceVariable(editTextRef.current, variable);
  setEditText(newText);
  editTextRef.current = newText;
};
```

### Component Discovery
Multiple similarly-named components exist (e.g., `PropertiesPanel` vs `PropertiesPanelCompact`). Always verify which component is actually rendered via imports.

### Canvas Overflow
- Canvas mode: `overflow: 'visible'` (allow shadows/effects to extend)
- Export/thumbnail mode: `overflow: 'hidden'` (clean output)

## Template System

- Templates created from presentations via "Save as Template"
- Auto-extracts variables from slides
- API generation: `POST /api/v1/generate` with templateId + variables
- Auth: API keys with SHA-256 hashing, Bearer token

## Known Issues

| Issue | Fix |
|-------|-----|
| Text can't be clicked with markdown | `pointerEvents: 'none'` on all text content renderers |
| Theme not updating slide background | Update slide in array AND sync `currentSlide` reference |
| PDF export shows raw variables | Fetch variables from DB, substitute if `showVariablePreview` |
| tRPC list shows empty | Add `transformer: superjson` to `httpBatchLink` |
| Heavy library build errors (pptxgenjs) | Use dynamic imports |
| Next.js 15 params | `const { id } = await params` |

## Database Schema

```
presentations: { id, title, slides (json), theme, org_id, user_id, ... }
variables: { id, presentation_id, type, name, value, default_value, ... }
templates: { id, name, category_id, variables_schema (jsonb), slides (jsonb), ... }
```

## Reference Documentation

- Slides feature: `_context/slides/feature-slides.md`
- Design Studio: `_context/slides/design-studio/feature.md`
