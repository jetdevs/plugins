---
name: design-studio
description: Use when working on Design Studio mode, artboards, multi-artboard canvas, design export, Kittl-like features, Yobo merchant integration for creatives, or tool panel sidebar in the slides app.
---

# Design Studio Development Guide

Design Studio is a dual-mode extension to the Slides app, providing a Kittl-like multi-artboard design experience.

## Architecture

Dual-mode editor sharing a single canvas engine:

| Mode | UI Shell | Canvas | Export | Users |
|------|----------|--------|--------|-------|
| **Presentation** | Slide sidebar, fixed 16:9 | SlideCanvas | PPTX, PDF | Internal team |
| **Design Studio** | Tool panels, multi-artboard | InfiniteCanvas | PNG, JPG, SVG | Internal + merchants |

### Key Components

| Component | File | Purpose |
|-----------|------|---------|
| Editor | `src/components/Editor.tsx` | Mode-driven layout orchestrator |
| InfiniteCanvas | `src/components/canvas/InfiniteCanvas.tsx` | Multi-artboard canvas (design mode) |
| SlideCanvas | `src/components/canvas/SlideCanvas.tsx` | Single-slide canvas (presentation mode) |
| ToolPanelSidebar | `src/components/studio/ToolPanelSidebar.tsx` | Left sidebar with tool panels |
| ArtboardPresets | `src/lib/artboard-presets.ts` | Size presets (IG, FB, WhatsApp, etc.) |
| ExportDialog | `src/components/studio/ExportDialog.tsx` | Multi-format export |

### Artboard = Enhanced Slide

Artboards extend Slides with configurable dimensions. Backwards compatible — existing presentations work unchanged.

## Yobo Merchant Integration

```
Yobo Campaign → "Design Creative" button
  → Opens slides.app/design/new?mode=studio&preset=ig-post&campaignId=abc
  → User designs in Studio
  → "Send to Campaign" exports + POSTs to Yobo callback
  → Yobo creates creative from image URL
```

Communication via URL params + POST callback.

## Permissions

| Permission | Who Gets It |
|------------|-------------|
| `design:presentations` | Internal team only |
| `design:studio` | Internal team + merchants |
| `design:templates:manage` | Internal admins |
| `design:templates:use` | All users |
| `design:brand-kit` | Org admins |
| `design:ai-generation` | All users |
| `design:export` | All users |

## Anti-Patterns

- Do NOT duplicate canvas code for design mode — share canvas engine, swap UI shell
- Do NOT build a separate design app — single app, mode-driven
- Do NOT expose presentation features to merchants — permission-gate presentation mode

## Reference Documentation

- Design Studio feature: `_context/slides/design-studio/feature.md`
- Design Studio specs: `_context/slides/design-studio/specs.md`
- Design Studio PRD: `_context/slides/design-studio/prd.md`
