---
name: migrate-extension
description: Migrate an application module to the SDK extension pattern. Creates the full extension structure with router, repository, schema, and types.
---

# Migrate Module to SDK Extension

Guide for migrating application modules to the SaaS Core SDK framework.

## Prerequisites

Before starting, read:
1. Extension Migration Guide: `/_context/core-sdk/guide-extension-migration.md`
2. SDK Feature Guide: `/_context/core-sdk/feature-sdk.md`
3. Backend Patterns: `/_context/_arch/patterns-backend.md`

**Reference Implementations:**
- Products Router: `/yobo-merchant/src/server/api/routers/products.router.ts`
- Products Repository: `/yobo-merchant/src/server/repos/products.repository.ts`

---

## Extension Directory Structure (Flat)

Extensions use a **flat structure** - no deep nesting:

```
/{target-app}/src/extensions/{module}/
├── client.ts       # Client-safe exports (no server imports)
├── components/     # React components (copied from source app)
├── index.ts        # Extension definition + server exports
├── router.ts       # tRPC router using createRouterWithActor
├── repository.ts   # Repository for all DB operations
├── schemas.ts      # Zod validation schemas (separate file, NOT inline)
├── schema.ts       # Drizzle DB schema
├── server.ts       # Server-only exports (optional)
└── types.ts        # TypeScript types & permissions enum
```

**DO NOT create deeply nested folders** like `server/routers/`, `server/repos/`, `db/schema/`, etc.

---

## Step-by-Step Migration

### Step 1: Create Extension Structure
```bash
mkdir -p /{target-app}/src/extensions/{module}/components
```

### Step 2: Create Files in Order
1. `schema.ts` - Database schema with `org_id` column
2. `types.ts` - TypeScript types and permissions
3. `schemas.ts` - Zod validation schemas (SEPARATE FILE)
4. `repository.ts` - Repository with SDK utilities
5. `router.ts` - tRPC router using `createRouterWithActor`
6. `index.ts` - Extension definition
7. `client.ts` - Client-safe exports

### Step 3: Register in Application
1. Add router to `src/server/api/root.ts`
2. Export schema in `src/db/schema/index.ts`
3. Add permissions to `src/permissions/registry.ts`
4. Add RLS config to `scripts/core/rls-registry.ts`
5. Add navigation item to `Sidebar.tsx`

### Step 4: Database & Permissions
```bash
pnpm db:migrate:generate
pnpm db:migrate:run
pnpm db:rls:deploy
pnpm generate:seed-permissions && pnpm db:seed:rbac
```

**CRITICAL**: Log out and log back in to refresh JWT with new permissions.

---

## Key Patterns

### Router Pattern (Use createRouterWithActor)
```typescript
import { createRouterWithActor } from '@jetdevs/framework/router';
import { listSchema, createSchema } from './schemas';
import { ModuleRepository } from './repository';

export const moduleRouter = createRouterWithActor({
  list: {
    type: 'query',
    input: listSchema,
    repository: ModuleRepository,
    handler: async ({ input, service, repo }) => {
      return repo.list({ ...input, orgId: service.orgId });
    },
  },
});
```

### Handler Context Properties
| Property | Description |
|----------|-------------|
| `input` | Validated input from schema |
| `service` | Service context with `orgId`, `userId` |
| `repo` | Instantiated repository |
| `actor` | Actor with permissions, `isSystemUser` |
| `ctx` | Full tRPC context (rarely needed) |

### Common Pitfalls
1. **Inline schemas** - WRONG. Always import from `schemas.ts`
2. **Direct DB queries in router** - WRONG. Use repository
3. **Using createTRPCRouter** - WRONG. Use `createRouterWithActor`
4. **Wrong context access** - Use `service.orgId` not `ctx.session.user.currentOrgId`

---

## Verification Checklist

**Files:**
- [ ] `schema.ts` - DB schema with `org_id`, `uuid`, indexes
- [ ] `types.ts` - Types and permissions enum
- [ ] `schemas.ts` - Zod schemas in SEPARATE file
- [ ] `repository.ts` - Repository with SDK utilities
- [ ] `router.ts` - Using `createRouterWithActor`
- [ ] `index.ts` - Extension definition with RLS config
- [ ] `client.ts` - Client-safe exports

**Registration:**
- [ ] Router in `src/server/api/root.ts`
- [ ] Schema in `src/db/schema/index.ts`
- [ ] Permissions in `src/permissions/registry.ts`
- [ ] RLS in `scripts/core/rls-registry.ts`
- [ ] Navigation in `Sidebar.tsx`

**Database:**
- [ ] Migration generated and applied
- [ ] RLS policies deployed
- [ ] Permissions seeded
