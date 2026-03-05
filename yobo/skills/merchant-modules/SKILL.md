---
name: merchant-modules
description: Use when working on merchant-specific modules like onboarding, offers, outlets, products, transactions, integrations, analytics, business profile, or ad studio in yobo-merchant. Also use when creating new modules, working on the product catalog, POS integrations, or general merchant platform features.
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
