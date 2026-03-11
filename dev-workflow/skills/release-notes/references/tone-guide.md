# Release Notes Tone Guide

## Audience

Release notes are for the full internal team: product managers, designers, QA, leadership — not just developers. Everyone should understand every line without needing to ask an engineer.

## Before/After Examples

### Technical jargon to plain language

| Bad (too technical) | Good (plain language) |
|---|---|
| Removed `force-dynamic` from root layout. Theme query now uses `unstable_cache` with 60s revalidation. | Pages load faster because a database query that ran on every page navigation now caches for 60 seconds. |
| Deleted empty `next.config.ts` overriding `next.config.mjs` — dev compiles dropped from ~48s to normal. | Dev environment page loads dropped from ~48 seconds to under 5 seconds. A config file conflict was silently disabling all optimizations. |
| Removed double loading states (AuthGuard spinner + Suspense + page skeleton). AuthGuard renders `null` by default. | Pages no longer flash through multiple loading spinners before showing content. There's now a single clean loading state. |
| S3 uploads: switched from `@jetdevs/cloud/storage` to legacy `@jetdevs/cloud`. | File uploads now work reliably in local development. |
| CSP: added `http://localhost:*` to `img-src`/`media-src` for MinIO in dev. | Uploaded images no longer appear broken in local development. |
| Rewrote iframe theme integration. Parent sends computed CSS variable values via postMessage. | The editor now correctly picks up the organization's theme colors when embedded in Yobo Merchant. |
| Added `ForceLightMode` component with MutationObserver. | Editor pages always display in light mode regardless of the organization's theme setting. |
| Replaced hardcoded colors with semantic tokens across 40+ files. | Updated 40+ files to use theme-aware colors instead of hardcoded grays, so the UI adapts to different themes. |
| Fixed `type="submit"` not working inside Radix Dialog — switched to `type="button"` with explicit `onClick`. | Save buttons inside popups now work correctly. |
| Added RLS policies on both tables, defense-in-depth orgId on all repository methods. | Access controls ensure each organization can only see their own data. |
| Migration 0125: microsites + microsite_submissions tables, 6 permissions, 20 role-permission mappings. | Added the database tables and permissions needed for Landing Pages. |

### Marketing language to factual

| Bad (too salesy) | Good (factual) |
|---|---|
| Create beautiful landing pages without any coding! | Added a landing page builder with drag-and-drop editing. |
| Giving you a complete picture at a glance. | Campaign detail now has tabs for Home, Ads, Redemptions, Outlets, Reports, and Settings. |
| No more navigating away from your work! | Settings opens as a popup from the profile menu instead of navigating to a separate page. |
| Dramatically faster performance. | Dev page loads dropped from ~48 seconds to under 5 seconds. |

## Rules of Thumb

1. **Describe outcomes, not implementation.** "File uploads work in dev" not "switched S3 modules".
2. **Use the feature name, not the code name.** "Landing Pages" not "microsites extension".
3. **Include numbers when available.** "40+ files updated" and "48 seconds to 5 seconds" tell a clearer story than "improved" or "faster".
4. **Skip internal-only fixes unless they affect team workflow.** Dev server speed matters to the team. A Tailwind class warning doesn't.
5. **If you have to explain what a thing is before explaining what changed, you're too technical.** Nobody needs to know what a MutationObserver is to understand that editor pages stay in light mode.
6. **Be factual, not excited.** No exclamation marks. No "now you can finally...". Just state what changed.
