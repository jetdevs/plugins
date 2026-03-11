---
name: billing-subscriptions
description: Use when working on billing UI, credits system, Stripe integration, subscription plans, site license, Google OAuth login, auto-registration, or payment flows in cadra-web. Also use when the user mentions "billing", "credits", "stripe", "subscription", "site license", "google login", or "plan upgrade".
---

# Billing, Credits & Subscriptions

Billing UI, credit system, Stripe integration, subscription plan management, and authentication flows for CadraOS.

## Extension Structure

```
cadra-web/src/extensions/
  billing/
    schema.ts              # billingSubscriptions, billingSubscriptionEvents
    router.ts              # createSubscription, getSubscription, getPlans, getInvoices, getPlanSlug
    repository.ts          # BillingRepository
    hooks/
      use-site-license.ts  # useSiteLicense hook (plan-gated UI hiding)
    components/
      BillingSettings.tsx   # Main billing settings UI (in Settings > Billing tab)
      PlanBadge.tsx         # Plan name + credits badge (header/profile)
      HeaderCreditBalance.tsx # Compact credit display in DesktopHeader
  credits/
    schema.ts              # 5 tables: balances, transactions, packages, purchases, rules
    router.ts              # getBalance, getTransactions, purchaseCredits
    repository.ts          # CreditsRepository
    hooks/use-credits.ts   # useCredits, useCreditConsumer, useAdminCredits
    components/            # 10 credit UI components + CreditsModal
```

## Billing Tab in Settings

Settings page at `/settings` accepts `?tab=billing` query param via `useSearchParams` + `useEffect` in `SettingsClient.tsx`. All credit CTAs should use `<Link href="/settings?tab=billing">` — prefer navigation over inline modals for management/overview actions.

## Subscription Plans

- Plans defined in `src/db/seeds/seed-subscription-plans.ts`
- Upsert by slug (idempotent)
- Stripe price IDs: ALWAYS create real ones via `scripts/setup-stripe-prices.ts` — NEVER use fake `price_dev_*` IDs
- Setup script is idempotent: searches by metadata slug, reuses existing products/prices

### Site License Plan

Special plan that hides all billing/credit UI for designated orgs:
- `site_license` plan (tier 100, status `inactive` to hide from public API)
- `useSiteLicense()` hook calls `billing.getPlanSlug` (no permission required)
- When `isSiteLicense === true`: HeaderCreditBalance returns null, PlanBadge returns null, Billing tab hidden
- Backoffice `ChangePlanDialog` shows all plans with `includeInactive: true`

### Permission Pattern

- `billing.getSubscription` requires `org:billing` permission
- For UI-gating hooks that ALL users need, create separate lightweight queries with no permission requirement (e.g., `getPlanSlug`)
- `createRouterWithActor` routes inherit `protectedProcedure` — omit `permission` field for universally accessible queries

## Google OAuth Login

- GoogleProvider in NextAuth config (conditional on env vars: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`)
- Auto-registration flow: creates user → org → Owner role assignment → free subscription
- 200 credits granted via fire-and-forget `grantSignupCredits()` into `token_usage_events`
- Idempotency key prevents double-granting
- Owner role query: `roles.name = 'Owner' AND isSystemRole = false` (global, not per-org)

### Key Files
- Auth config: `src/server/auth-simple.ts` (Google OAuth + auto-register)
- Signup credits: `src/server/google-signup-credits.ts`

## Stripe Integration

- Stripe test keys in env vars (cadra-web's own Stripe account)
- Webhook handler at `src/app/api/webhooks/`
- `src/lib/stripe.ts` — Stripe client initialization

### Credits Schema (5 tables)
| Table | Purpose |
|-------|---------|
| credit_balances | Current balance per org |
| credit_transactions | All credit movements (debit/credit) |
| credit_packages | Purchasable credit bundles |
| credit_purchases | Purchase records |
| credit_rules | Auto-grant rules |

## Critical Patterns

### Database Migrations
- `drizzle-kit generate` and `drizzle-kit push` are BROKEN in this monorepo due to `hoist=false`
- Create migration SQL manually following CLAUDE.md recovery pattern
- Always register in `drizzle/meta/_journal.json` with correct idx
- Credits schema MUST be exported from `src/db/schema/index.ts` (both named + default object)

### Type Safety
- `(api as any).credits.*` and `(api as any).billing.*` pattern for tRPC calls (createRouterWithActor type mismatch)
- Cross-package Drizzle refs require `as any` casts on `.references()` calls

### Standalone Seed Runner
- `npx tsx seed-file.ts` can fail with circular dependency errors
- Use `pnpm db:seed:complete` instead (app bootstraps imports correctly)
- Always verify actual DB state when debugging "feature not working"

## UI/UX Patterns

- Plan-gated UI: dedicated hook (`useSiteLicense`) > inline plan checking
- Site License orgs: return null from entire component, not partial hiding
- Credit CTAs: `<Link href="/settings?tab=billing">` (navigation > modal for infrequent actions)
- Importing modals into dashboard adds entire dependency tree — prefer navigation links

## Reference Documentation

- Subscription design: `_context/cadra/subscriptions/p0-initial/`
- Token metering: `_context/cadra/subscriptions/p1-token-metering/`
- Billing seed: `cadra-web/src/db/seeds/seed-subscription-plans.ts`
- Billing extension: `cadra-web/src/extensions/billing/`
- Credits extension: `cadra-web/src/extensions/credits/`
