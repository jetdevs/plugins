---
name: merchant-modules
description: Use when working on merchant-specific modules like onboarding, offers, outlets, products, transactions, integrations, analytics, business profile, ad studio, billing/subscriptions, microsites/CMS, API keys, or navigation/loading states in yobo-merchant. Also use when creating new modules, working on the product catalog, POS integrations, Stripe billing, Puck editor, landing pages, S3 uploads, or general merchant platform features.
---

# Merchant Module Development Guide

Business domain modules of Yobo Merchant — onboarding, offers, outlets, products, transactions, and integrations.

## Module Overview

### Merchant Lifecycle Modules

```
yobo-merchant/src/extensions/
  onboarding/            # Multi-step merchant onboarding
  onboarding-gtm/        # GTM-specific onboarding variant
  business/              # Business profile & settings
  brand-profile/         # Brand/merchant profile management
```

### Commerce Modules

```
  offers/                # Offer/promotion management
  promotions/            # Promotion campaigns
  products/              # Product catalog
  categories/            # Product category tree
  outlets/               # Merchant outlet/branch management
  outlet-contracts/      # Outlet contract management
```

### Transaction Modules

```
  transactions/          # Financial transaction processing
  transaction-products/  # Product transaction records
  transaction-discounts/ # Discount transaction tracking
```

### Integration Modules

```
  integrations/          # Third-party integration framework
  moka/ & moka-pos/      # Moka POS integration
  whatsapp-auth/         # WhatsApp OAuth flow
```

### Billing & API Keys

```
  billing/               # Stripe billing & subscriptions (Plans, Elements, webhooks)
```

### CMS & Content

```
  microsites/            # Visual page builder (Puck editor, SSR, form submissions)
```

### Analytics & Admin

```
  analytics/             # Campaign & business analytics
  ad-studio/             # Ad design & creation
  mission-control/       # Admin control panel
  audit/                 # Audit logging system
```

## Onboarding Flow (CRITICAL — MOST COMPLEX SUBSYSTEM)

### Multi-Step Process
1. **Instagram Handle** → Business analysis (AI-powered)
2. **Goals & Preferences** → Selection UI
3. **WhatsApp Verification** → Auth step (returns verified phone only)
4. **Registration Form** → Name, Business Name, Optional Email (phone NOT shown — already verified)
5. **Create User & Organization** → Server-side with privileged DB
6. **Generate Proposal** → AI-powered campaign/creative generation
7. **Finalize Campaign** → Org-scoped data writes

### Auth Boundary (PUBLIC → PROTECTED)

```
Steps 1-3: publicProcedure (no org context)
  - NO org-coupled writes
  - Store data in memory/session, NOT in DB
  - WhatsApp auth: creates session with phoneNumber + status: 'verified'

Step 4-5: Transition point
  - Create user + org with withPrivilegedDb
  - copyOrgRoleTemplates(orgId) for role setup
  - Owner role: lookup by name/flags (global, non-system)
  - NEVER assign Super User in onboarding

Steps 6-7: orgProtectedProcedure
  - ONLY after session includes user.currentOrgId
  - Use ctx.dbWithRLS for org reads/writes
```

### Session Hydration (CRITICAL TIMING)

```typescript
// WRONG: Assume session is immediately available
await finalizeOnboarding({ ... }); // May get UNAUTHORIZED

// CORRECT: Poll until session hydrated
let attempts = 0;
while (attempts < 10) {
  const session = await getSession();
  if (session?.user?.currentOrgId) break;
  await new Promise(r => setTimeout(r, 500));
  attempts++;
}
```

### Idempotency Guards
- Use `hasTriggeredFinalize` ref to prevent duplicate org creation
- Double-click on finalize button = two orgs created without guard
- Derive "registered" from real session (`getSession()`), NOT local state flags

### WhatsApp Phone Auth
```typescript
// Phone verification returns ONLY verified number
// Registration form must NOT show phone field (already verified)
// Auth provider detects phone vs email:
const isPhoneNumber = /^\+?[1-9]\d{1,14}$/.test(identifier.replace(/\s/g, ''));
```

### Image Generation During Onboarding
- Model: `gemini-2.5-flash-image-preview` (NOT `gemini-1.5-flash-002`)
- Cast to `any` for Gemini-specific methods: `(llmProvider as any).generatePromotionalImage(...)`
- S3 bucket priority: `S3_BUCKET` → `NEXT_PUBLIC_S3_BUCKET` → `AWS_BUCKET_NAME`
- Handle both data URLs and remote URLs during S3 upload

### LLM Output Defensive Rendering (Triple-Layer)
```typescript
// Layer 1: Server normalization
const normalizeCadraAnalysis = (data) => ({
  brandPersonality: strArr(data.brandPersonality), // coerce array items to strings
});

// Layer 2: Zustand cache can hold stale data — server fix alone insufficient

// Layer 3: Client-side defensive rendering
{brandPersonality.map(trait => <span key={trait}>{toStr(trait)}</span>)}
// ALL optional properties need sensible defaults + optional chaining
```

### Common Onboarding Pitfalls
- **RLS violations**: Use `withPrivilegedDb` for system operations
- **Hydration errors**: Move divs outside DialogDescription components
- **Double modals**: Use `hasTriggeredFinalize` flag
- **Missing auth records**: Ensure `verifiedPhoneNumber` passed through component chain
- **Cookie/origin alignment**: Set `NEXTAUTH_URL` to actual origin/port, omit `COOKIE_DOMAIN` locally
- **React object-as-child crashes**: `brandPersonality` etc. may be objects instead of strings. Apply `strArr()` server-side + `toStr()` client-side. Search ALL files rendering same data (page.tsx, OnboardingGTMPage.tsx, AnalysisResults.tsx).
- **Zustand persist caches stale shapes**: Server normalization only fixes new data — localStorage still has old shape. Client-side `toStr()` is the safety net.

### GTM Variant
- Separate onboarding flow for Go-To-Market scenarios
- Simplified steps for quick merchant acquisition
- Custom theme (GTM dark theme — zinc/indigo palette)
- `// @ts-nocheck` must be FIRST line (before `'use client'`)

## Offers & Promotions

### Offer Types
- **Discount** — Percentage or fixed amount off
- **Cashback** — Credit back after purchase
- **BOGO** — Buy one get one
- **Bundle** — Product package deals
- **Points multiplier** — Bonus loyalty points

### Promotion Structure
```
Promotion (campaign-level)
  └── Offers (individual deal configurations)
       ├── Conditions (min spend, eligible products, time windows)
       ├── Limits (per customer, total redemptions, budget cap)
       └── Creative (images, copy, QR codes)
```

### Redemption Flow
1. Customer receives offer via campaign
2. Customer presents offer at outlet (QR/code)
3. POS validates offer conditions
4. Transaction recorded with discount applied
5. Analytics updated

## Product Catalog

### Structure
- **Categories** — Hierarchical tree (unlimited depth)
- **Products** — Items within categories
- **Variants** — Size, color, flavor options
- **Pricing** — Base price, promotional pricing

### Category Tree
```typescript
// Recursive tree structure with parent-child relationships
// Drag-drop reordering supported
// Bulk import via CSV
```

### Specs
- Product catalog: `_context/yobo-merchant/_specs/p15-segment-explorer+product-catalog/`
- Feature doc: `_context/yobo-merchant/_wiki/feature-product-catalog+category-tree.md`

## Outlet Management

### Outlet Data
- Location (address, coordinates)
- Operating hours
- Contact information
- Contract details (outlet-contracts extension)
- Associated staff/users

### Multi-Outlet Patterns
- Org-scoped outlet list
- Per-outlet transaction tracking
- Outlet-level analytics
- Franchise support (multiple outlets under one merchant)

## Transaction Processing

### Transaction Types
- **Purchase** — Customer buy event
- **Redemption** — Offer/loyalty redemption
- **Top-up** — Credit balance addition
- **Refund** — Transaction reversal

### Transaction Data Flow
1. POS or API sends transaction
2. Validate against offers/loyalty rules
3. Apply discounts/points
4. Record transaction + line items
5. Update customer lifetime metrics
6. Trigger segment recalculation

## POS Integrations

### Moka POS
- Two extensions: `moka` (auth) and `moka-pos` (data sync)
- OAuth-based authentication
- Transaction sync (pull from Moka API)
- Product catalog sync

### Integration Framework
- `integrations` extension provides base pattern
- OAuth token management
- Webhook receivers for real-time events
- Data transformation layer

## Analytics

### Dashboard Metrics
- Revenue and transaction volume
- Customer acquisition and retention
- Campaign performance (ROI, engagement)
- Outlet comparison
- Product performance

### Data Sources
- Transaction records
- Campaign events
- Customer lifecycle events
- Redemption data

### Chart Libraries
- Recharts (primary)
- ECharts (complex visualizations)

## Stripe Billing & Subscriptions

### Extension Structure
```
src/extensions/billing/
  schema.ts              # subscription_plans, subscriptions, subscription_events
  repository.ts          # CRUD, upsert, webhook idempotency
  router.ts              # 6 org-protected + 1 public procedure
  types.ts, schemas.ts, client.ts, index.ts
  components/
    UpgradeDialog.tsx    # Two-step: plan grid → Stripe Elements PaymentForm
    BillingSettings.tsx  # Main billing page, portal sync
    PaymentForm.tsx      # useStripe() + useElements() + confirmPayment()
    PlanCard.tsx, BillingAlert.tsx, PlanBadge.tsx, PlanSkeleton.tsx
    stripe-provider.ts   # Lazy loadStripe() singleton
```

### Plans
- Free (200 credits), Pro ($29/mo, 500 credits), Max ($99/mo, 2000 credits)
- Seed: `src/db/seeds/seed-billing.ts`
- Migration: `drizzle/0124_add_billing_tables.sql`

### Stripe SDK v20+ (API 2026-02-25.clover) Gotchas
- `payment_intent` on Invoice is **null** — use `invoice.confirmation_secret.client_secret`
- Period data on `SubscriptionItem`, not `Subscription` — use `sub.items.data[0].current_period_start`
- Invoice's `subscription` field at `invoice.parent.subscription_details.subscription`
- Portal cancellation: check BOTH `cancel_at` (timestamp) AND `cancel_at_period_end` (boolean)

### Payment Flow
1. `createSubscription` → Stripe `subscriptions.create({ payment_behavior: 'default_incomplete' })`
2. Returns `clientSecret` from `invoice.confirmation_secret.client_secret`
3. Frontend: `stripe.confirmPayment({ elements, redirect: 'if_required' })`
4. `confirmSubscription` syncs result to DB
5. Webhook handler (7 events) provides belt-and-suspenders idempotency

### Portal Pattern
- `window.open(portalUrl)` → poll `closed` → `syncSubscription` → refetch UI
- `syncSubscription` essential for dev without webhooks — fetches live from Stripe API

### Webhook Handler
- Route: `src/app/api/webhooks/stripe/route.ts`
- 7 event handlers with atomic idempotency via `INSERT ON CONFLICT DO NOTHING`

## CMS Microsites (Puck Visual Editor)

### Extension Structure
```
src/extensions/microsites/
  schema.ts              # microsites + microsite_submissions tables
  repository.ts          # CRUD with orgId, transactions for publish/unpublish/duplicate
  router.ts              # 9 tRPC endpoints
  puck/
    config.tsx           # Puck component registry
    theme.ts             # Editor theme config
    components/          # 7 Puck components: Hero, ProductsGrid, OfferBanner, ContactForm, TextBlock, Footer, Spacer
  renderer/
    MicrositeRenderer.tsx  # SSR renderer
    sections/            # 7 server-side section components
```

### Pages
- List: `src/app/(org)/microsites/` (list, new, [id], [id]/edit, [id]/submissions)
- Public SSR: `src/app/m/[orgSlug]/[siteSlug]/page.tsx` (uses `withPrivilegedDb`, no auth)
- Sitemap: `src/app/m/sitemap.ts`
- Form API: `src/app/api/microsites/submit/route.ts` (rate-limited)

### Dependencies
- `@puckeditor/core` v0.21.1
- Peer deps: `@dnd-kit/abstract`, `@dnd-kit/dom`, `@dnd-kit/geometry`, `@dnd-kit/react`, `@dnd-kit/state`
- Webpack fix: `config.resolve.modules` appended with local `node_modules` path in `next.config.mjs`

### Key Patterns
- Public pages bypass auth with `withPrivilegedDb` from `@/db/clients`
- `db.transaction()` for multi-operation mutations (publish, unpublish, duplicate)
- Permissions: 6 microsites permissions, enum `MicrositesPermissions` (plural, from `generate:permissions`)
- Spec: `_context/yobo-merchant/max-cms/specs.md`

## API Keys Management

### Implementation
- UI: `src/components/settings/ApiKeySettings.tsx` — full CRUD (create, list, revoke, view details)
- Tab in `src/app/(org)/settings/SettingsClient.tsx` (Profile, Security, Organization, Billing, API Keys)
- Backend: SDK's `createApiKeysRouterConfig()` with `SDKApiKeysRepository`
- Migration: `drizzle/0126_add_api_keys_role_id.sql` (adds `role_id` to api_keys)

### Org Isolation Override (CRITICAL)
- SDK's default `list` handler calls `listAll()` for superusers (`crossOrg: true`)
- Override in `root.ts`: always use `listByOrgId(service.orgId)` for strict org isolation
- RLS: `api_keys` and `api_usage_logs` with org-strict policies (NO superuser bypass)

### Settings → Profile Rename
- Profile dropdown: "Settings" renamed to "Profile", opens as modal dialog
- Preferences: standalone modal from profile dropdown
- `SettingsClient` accepts `isModal` prop for scrollable tabs inside modal
- Never use `window.location.reload()` in save handlers inside dialogs — use query invalidation

## S3 Upload Patterns

### Two Cloud Module Paths
| Module | Import | Auth | When to Use |
|--------|--------|------|-------------|
| `@jetdevs/cloud` | `uploadFileToS3`, `getS3Client` | Static AWS env vars | Always (until Credentials Service deployed) |
| `@jetdevs/cloud/storage` | `storage.upload`, `storage.getSignedUrl` | STS tokens via Credentials Service | Only when Credentials Service available |

- Central wrapper: `src/lib/storage-compat.ts`
- Presigned URLs: `src/app/api/upload/presigned/route.ts`
- CSP: `img-src` and `media-src` must include `http://localhost:*` in dev mode for MinIO

### Instagram CDN Downloads
- Always add `AbortController` with 10s timeout to external `fetch()` calls
- Try `uploadImageFromUrl()` (SDK server-side) before manual download+upload

## Navigation & Loading States

### Loading State Hierarchy (CRITICAL)
- Only ONE loading state should be visible per page transition
- AuthGuard: default to `null` fallback (not spinner) — brief auth check is invisible
- Secure.Container: provides page-level skeleton — sufficient for permission + data loading
- Never wrap AuthGuard + Suspense + Secure.Container — creates spinner → spinner → skeleton

### Route Navigation
- Logo links to `/dashboard` (never `/`)
- `Secure.tsx` default `redirectTo`: `/dashboard`
- Root `app/page.tsx` does `getServerSession()` + DB queries — hangs on Vercel cold starts
- Cross-route-group navigation (`(no-sidebar)` → `(org)`) requires RSC payload fetches

### Layout Patterns
- `force-dynamic` on root layout: NEVER — blocks every navigation with server round-trip
- Theme query in root layout: use `unstable_cache` with 60s revalidation
- Only ONE `next.config` file (`.ts` overrides `.mjs` in Next.js 15)
- `optimizePackageImports` for echarts, lucide-react, codemirror, radix packages

## Sidebar Patterns

### Styling Tokens
- Register sidebar color tokens in `tailwind.config.ts`: `sidebar: { DEFAULT, foreground, primary, accent, border, ring }`
- Missing tokens silently produce no styles
- Active state: `bg-sidebar-accent text-sidebar-accent-foreground font-medium`
- Inactive: `text-sidebar-foreground hover:text-white/70 hover:bg-white/[0.06] font-normal`
- Active route matching: `pathname === item.href || pathname.startsWith(item.href + "/")`

### Layout
- Sidebar width: `14rem`, dynamic via `--sidebar-width` CSS variable
- `MainContent.tsx`: `md:ml-[var(--sidebar-width)]` (not hardcoded `md:ml-64`)
- `dividerBefore` property on NavItem for visual grouping between sections

### PWA Sheet Animation
- Open: 280ms with spring easing `cubic-bezier(0.2, 0.9, 0.3, 1)`
- Close: 200ms snap-back `cubic-bezier(0.4, 0, 0.6, 1)`
- Overlay: ~80ms faster than content for layered feel
- `will-change-transform` for GPU compositing

## Creating New Modules

Follow the module implementation checklist:

1. **Permission registry** (`src/permissions/registry.ts`) — Add CRUD permissions
2. **Database schema** (`src/db/schema/`) — Create with `org_id` column
3. **RLS registry** (`scripts/rls-registry.ts`) — Add table entry
4. **Migration** — `pnpm db:migrate:generate` → `pnpm db:full:update`
5. **RLS deploy** — `pnpm db:rls:deploy`
6. **Extension files** — router, repository, schema, types, schemas, index, client
7. **Root router** — Register in `src/server/api/root.ts`
8. **Frontend** — Pages, components, permission guards
9. **Tests** — Unit + integration

### Detailed Guide
- `yobo-merchant/ai/wiki/guide-new-module.md` — Step-by-step instructions
- Blueprint template: `_context/yobo-merchant/_wiki/blueprint-template.md`
- New module blueprint: `_context/yobo-merchant/_wiki/blueprint-new-module.md`

## Reference Documentation

- Onboarding: `_context/yobo-merchant/_wiki/feature-onboarding.md`
- Product catalog: `_context/yobo-merchant/_wiki/feature-product-catalog+category-tree.md`
- Tagging: `_context/yobo-merchant/_wiki/feature-tagging.md`
- Scripts: `_context/yobo-merchant/_wiki/feature-scripts.md`
- Business phase: `_context/yobo-merchant/_specs/p9-business/`
- Promotions phase: `_context/yobo-merchant/_specs/p3-promos/`
- Backoffice phase: `_context/yobo-merchant/_specs/p5-backoffice/`
- Refactoring phase: `_context/yobo-merchant/_specs/p6-refactor/`
- Open API: `_context/yobo-merchant/_specs/p16-open-api/`
- Microsites/CMS: `_context/yobo-merchant/max-cms/specs.md`
- PWA native UX: `_context/_arch/pwa-native-app-ux.md`
- Billing extension: `yobo-merchant/src/extensions/billing/`
- API keys settings: `yobo-merchant/src/components/settings/ApiKeySettings.tsx`
- Storage compat: `yobo-merchant/src/lib/storage-compat.ts`
