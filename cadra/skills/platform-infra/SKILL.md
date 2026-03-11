---
name: platform-infra
description: Use when working on CadraOS platform infrastructure — custom domains, white-label, permissions, RBAC, users, roles, org isolation, subscriptions, token metering, audits, multi-tenant security, Google OAuth, site license, global dark mode, sidebar, or theming. Also use when the user mentions "custom domain", "permissions", "roles", "multi-tenant", "subscription", "metering", "audit", "google login", "site license", "dark mode", "sidebar", or "theme".
---

# CadraOS Platform Infrastructure

Multi-tenant platform features: custom domains, permissions, users/roles, subscriptions, authentication, theming, and auditing.

## Custom Domains (White-Label)

Organizations access the platform via their own domains (e.g., `ai.customer.com`).

### Architecture
- Users automatically locked to mapped organization
- Backoffice routes blocked on custom domains
- Header spoofing prevention
- Global role users can access any custom domain

### Key Files
- Extension: `cadra-web/src/extensions/custom-domains/`
- Middleware: `cadra-web/src/middleware.ts` (domain detection)

## Permission System

97 permissions across 18 modules with CRUD-first pattern.

### Role Types
- **System**: Platform-wide (superuser)
- **Global**: All organizations
- **Org-specific**: Per-organization

### Key Files
- Registry: `cadra-web/src/permissions/registry.ts`
- RLS registry: `cadra-web/scripts/core/rls-registry.ts`

### Permission Workflow
```bash
# After adding/modifying permissions:
pnpm generate:seed-permissions
pnpm db:seed:rbac
# Then log out and back in to refresh JWT
```

### Real-Time Permission Updates
WebSocket-based permission monitoring — when roles change, connected clients get updated permissions without re-login.

### Custom Domain Org Isolation
Users on custom domains are automatically scoped to that org's data via RLS.

## Users & Roles

### User Management
- CRUD operations via tRPC or REST API
- Org membership (invite → active → suspended → removed)
- Bulk operations (role assignment, status changes)

### Role Management
- Permission matrix UI for role configuration
- Role-based API key permissions
- Service roles for internal operations

## Authentication

### Google OAuth Login
- GoogleProvider in NextAuth config (conditional on `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET` env vars)
- Auto-registration: creates user → org → Owner role → free subscription
- 200 credits granted via `grantSignupCredits()` (fire-and-forget, idempotency key)
- Owner role query: `roles.name = 'Owner' AND isSystemRole = false` (global, not per-org)
- Key files: `src/server/auth-simple.ts`, `src/server/google-signup-credits.ts`

### Auth Patterns
- `signIn` callback modifies `user.id` in-place (same object reference persists to JWT callback)
- Auto-registration must create ALL entities: user + org + role + subscription (missing any → auth failure)
- Sign-in orchestration (auto-registration, credit grants) is app-specific — keep in app layer, not SDK

## Subscriptions & Token Metering

### Subscription Plans
- Database-driven via `subscription_plans` table
- Site License plan: `status: 'inactive'` (hidden from self-service, visible in backoffice with `includeInactive: true`)
- `useSiteLicense()` hook for plan-gated UI hiding (calls `billing.getPlanSlug` — no permission required)

### Token Metering
- Track LLM token usage per org/agent/execution
- Cost calculation and billing integration
- Usage limits and alerts

## Theming & Dark Mode

### Theme System
- Backoffice theme is entirely **database-driven** via `themes` table (NOT `config/theme.ts`)
- Themes loaded via `api.theme.getAllSystem.useQuery()`
- To add a new theme: add to `EXTENDED_THEMES` in `core-sdk/core/src/db/seeds/seed-themes.ts` → `pnpm db:seed:complete`

### Global Dark Mode
- `next-themes` reads localStorage on hydration, can override server-injected global dark mode
- Fix: pass `forcedTheme` prop to next-themes when global dark mode is "dark" or "light"
- `getGlobalDarkMode()` extracted in `theme-script.tsx` — layout queries once, passes to both ThemeScript and ThemeProvider
- `enableSystem` should be disabled when `forcedTheme` is set

### Sidebar Styling
- yobo-merchant sidebar is gold standard for sidebar styling across all apps
- Collapse state: `useSyncExternalStore` with localStorage persistence + cross-tab sync
- Active state: `bg-sidebar-accent text-sidebar-accent-foreground font-medium`
- `siblingHrefs` prop prevents false-positive active states for routes sharing prefix

## Auditing

### Audit Logging
- Track all system activities
- Per-entity audit trail
- Filterable audit log UI

### Fallback Audits
- Automated checks for missing fallbacks
- Error tracking and alerting

## Database Security

### Row Level Security (RLS)
- Every org-scoped table has automatic RLS
- Isolation levels: `public`, `org`, `workspace`, `user`
- RLS registry: centralized at `scripts/core/rls-registry.ts`
- Context variable: `rls.current_org_id` (NOT `app.current_org_id`)

### Three-Tier DB Clients
| Client | Connection | RLS | Use Case |
|--------|-----------|-----|----------|
| `db` | `DATABASE_URL` | Enabled | Web app with session auth |
| `privilegedDb` | `INTERNAL_API_DATABASE_URL` | Bypassed | API routes, internal services |
| `adminDb` | `ADMIN_DATABASE_URL` | Bypassed | Migrations, system ops |

## Branding

- All surfaces must use "CadraOS" (NOT "A.I. Core", "SaaS Core", "Merchant Portal", "AI Agent Platform")
- Check: `saas.config.ts`, `PublicHeader`, `AuthHeader`, `mobile-nav`, `layout.tsx` metadata, `apple-mobile-web-app-title`
- CadraOS SVG logo in public header and auth header

## Reference Documentation

### Custom Domains
- Feature: `_context/cadra/custom-domains/feature.md`
- PRD: `_context/cadra/custom-domains/prd.md`
- Implementation: `_context/cadra/custom-domains/implementation.md`

### Permissions
- Registry: `_context/cadra/permissions/permissions-registry.md`
- Overview: `_context/cadra/permissions/permissions.md`

### Users & Roles
- Feature: `_context/cadra/user+roles/feature.md`
- Real-time permissions: `_context/cadra/user+roles/p1-real-time-permissions/`
- Service roles: `_context/cadra/user+roles/p2-service-roles/`

### Subscriptions
- Initial design: `_context/cadra/subscriptions/p0-initial/`
- Token metering: `_context/cadra/subscriptions/p1-token-metering/`

### Cadra-Specific Learnings
- Backend lessons: `_context/cadra/_arch/learning-backend.md`
- Frontend lessons: `_context/cadra/_arch/learning-frontend.md`
