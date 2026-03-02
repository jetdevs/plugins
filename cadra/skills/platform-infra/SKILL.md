---
name: platform-infra
description: Use when working on CadraOS platform infrastructure — custom domains, white-label, permissions, RBAC, users, roles, org isolation, subscriptions, token metering, audits, or multi-tenant security. Also use when the user mentions "custom domain", "permissions", "roles", "multi-tenant", "subscription", "metering", or "audit".
---

# CadraOS Platform Infrastructure

Multi-tenant platform features: custom domains, permissions, users/roles, subscriptions, and auditing.

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

## Subscriptions & Token Metering

### Token Metering
- Track LLM token usage per org/agent/execution
- Cost calculation and billing integration
- Usage limits and alerts

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

## Reference Documentation

### Custom Domains
- Feature: `_context/cadra/custom-domains/feature.md`
- PRD: `_context/cadra/custom-domains/prd.md`
- Implementation: `_context/cadra/custom-domains/implementation.md`
- Change log: `_context/cadra/custom-domains/log.md`

### Permissions
- Registry: `_context/cadra/permissions/permissions-registry.md`
- Overview: `_context/cadra/permissions/permissions.md`
- Org isolation: `_context/cadra/permissions/p2-custom-domain-org-isolation/`

### Users & Roles
- Feature: `_context/cadra/user+roles/feature.md`
- Specs: `_context/cadra/user+roles/specs.md`
- Implementation: `_context/cadra/user+roles/implementation.md`
- Real-time permissions: `_context/cadra/user+roles/p1-real-time-permissions/`
- Service roles: `_context/cadra/user+roles/p2-service-roles/`

### Subscriptions
- Initial design: `_context/cadra/subscriptions/p0-initial/`
- Token metering: `_context/cadra/subscriptions/p1-token-metering/`

### Audits
- Fallback audits: `_context/cadra/audits/p1-audit-for-fallbacks/`

### Cadra-Specific Learnings
- Backend lessons: `_context/cadra/_arch/learning-backend.md`
- Frontend lessons: `_context/cadra/_arch/learning-frontend.md`
