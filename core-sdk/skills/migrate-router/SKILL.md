---
name: migrate-router
description: Migrate a tRPC router from old pattern to SDK createRouterWithActor pattern. Handles the handler signature change and repository integration.
---

# Migrate Router to SDK Pattern

Convert routers from old `createTRPCRouter` pattern to `createRouterWithActor`.

## Three Router Patterns

### Pattern A: Pure createRouterWithActor (most common)

All procedures are org-protected with declarative config:

```typescript
import { createRouterWithActor } from '@jetdevs/framework/router'
import { z } from 'zod'
import { projects } from './schema'
import { eq, and, desc } from 'drizzle-orm'

export const projectsRouter = createRouterWithActor({
  list: {
    type: 'query',
    permission: 'projects:read',
    input: z.object({
      limit: z.number().min(1).max(100).default(20),
      offset: z.number().min(0).default(0),
    }).optional(),
    handler: async ({ input, db, service }) => {
      return db.query.projects.findMany({
        where: eq(projects.orgId, service.orgId),
        limit: input?.limit ?? 20,
        offset: input?.offset ?? 0,
        orderBy: [desc(projects.createdAt)],
      })
    },
  },

  create: {
    type: 'mutation',
    permission: 'projects:create',
    input: z.object({
      name: z.string().min(1).max(255),
      description: z.string().optional(),
    }),
    handler: async ({ input, db, service }) => {
      const [project] = await db.insert(projects).values({
        orgId: service.orgId,
        createdBy: service.userId,
        ...input,
      }).returning()
      return project
    },
  },
})
```

### Pattern B: Hybrid (SDK + public/admin procedures)

For routers that need both org-protected AND public/admin endpoints:

```typescript
import { createRouterWithActor } from '@jetdevs/framework/router'
import { createTRPCRouter, publicProcedure, adminOnlyProcedure } from '@/server/api/trpc'

// SDK-managed org-protected procedures
const orgRouter = createRouterWithActor({
  list: {
    type: 'query',
    permission: 'projects:read',
    handler: async ({ db, service }) => { /* ... */ },
  },
})

// Public/admin procedures that don't fit the actor pattern
const publicRouter = createTRPCRouter({
  getPublicTemplates: publicProcedure
    .query(async ({ ctx }) => { /* ... */ }),

  adminStats: adminOnlyProcedure
    .query(async ({ ctx }) => { /* ... */ }),
})

// Merge both into one router
export const projectsRouter = createTRPCRouter({
  ...orgRouter._def.procedures,
  ...publicRouter._def.procedures,
})
```

### Pattern C: Legacy (BEFORE — what you're migrating FROM)

```typescript
// OLD — verbose, repetitive boilerplate
export const projectsRouter = createTRPCRouter({
  list: orgProtectedProcedureWithPermission('projects:read')
    .input(z.object({ /* ... */ }))
    .query(async ({ ctx, input }) => {
      const actor = createActor(ctx)
      const { dbFunction, effectiveOrgId } = getDbContext(ctx, actor)
      return dbFunction(async (db) => {
        const serviceContext = createServiceContext(db, actor, effectiveOrgId)
        // actual logic
      })
    }),
})
```

---

## Handler Context Properties

| Property | Type | Description |
|----------|------|-------------|
| `input` | TInput | Validated input from Zod schema |
| `db` | DrizzleDB | Direct DB access (use for simple queries) |
| `service` | ServiceContext | Contains `orgId`, `userId` |
| `repo` | Repository | Auto-instantiated repository (if `repository` specified) |
| `actor` | Actor | Permissions, `isSystemUser`, `roles` |
| `ctx` | TRPCContext | Full context (rarely needed) |

**When to use `db` vs `repo`:**
- Use `db` directly for simple CRUD (Pattern A) — most common
- Use `repo` when you need telemetry, audit logging, caching (complex modules)

---

## Route Configuration Options

```typescript
{
  list: {
    type: 'query',                    // 'query' or 'mutation'
    input: listSchema,                // Zod schema (import, don't inline)
    permission: 'items:read',         // Permission slug (optional for queries)
    cache: { ttl: 60, tags: ['items'] }, // Caching config
    invalidates: ['items'],           // Cache tags to invalidate (mutations)
    entityType: 'item',               // For audit logging
    repository: ItemsRepository,      // Repository class (optional)
    crossOrg: true,                   // Bypass RLS for system data
    handler: async ({ ... }) => {},   // Handler function
  },
}
```

---

## Migration Steps

### 1. Determine Router Pattern

Choose Pattern A (pure) or Pattern B (hybrid) based on your needs:
- All procedures are org-protected? → Pattern A
- Mix of public/admin + org-protected? → Pattern B

### 2. Convert Handler Signatures

```typescript
// OLD
.query(async ({ ctx, input }) => {
  const orgId = ctx.session.user.currentOrgId
  return ctx.db.query.items.findMany()
})

// NEW (Pattern A — direct db)
handler: async ({ input, db, service }) => {
  return db.query.items.findMany({
    where: eq(items.orgId, service.orgId),
  })
}

// NEW (with repository)
handler: async ({ input, service, repo }) => {
  return repo.list({ ...input, orgId: service.orgId })
}
```

### 3. System Data Access (org_id = NULL)

For accessing system-level data:

```typescript
getAllSystemItems: {
  type: 'query',
  permission: 'admin:manage',
  crossOrg: true,  // Bypass RLS for org_id = NULL data
  handler: async ({ db }) => {
    return db.query.items.findMany()
  },
},
```

---

## Common Mistakes

### 1. Inline Schemas
```typescript
// WRONG
list: {
  input: z.object({ page: z.number() }),  // Inline!
}

// CORRECT
import { listSchema } from './schemas'
list: {
  input: listSchema,
}
```

### 2. Wrong Context Property
```typescript
// WRONG
ctx.session.user.currentOrgId

// CORRECT
service.orgId
```

### 3. Missing `type` field
```typescript
// WRONG — missing type
list: {
  input: listSchema,
  handler: async ({ db }) => { /* ... */ },
}

// CORRECT
list: {
  type: 'query',  // Required!
  input: listSchema,
  handler: async ({ db }) => { /* ... */ },
}
```

---

## SDK-Provided Router Configs

Before writing a custom router, check if an SDK config exists:

| Module | SDK Config Import |
|--------|------------------|
| Auth | `createAuthRouterConfig` from `@jetdevs/core/auth` |
| Users | `createUserRouterConfig` from `@jetdevs/core/users` |
| User-Org | `userOrgRouterConfig` from `@jetdevs/core/user-org` |
| Orgs | `createOrgRouterConfig` from `@jetdevs/core/organizations` |
| Roles | `createRoleRouterConfig` from `@jetdevs/core/features/rbac` |
| Permissions | `permissionRouterConfig` from `@jetdevs/core/trpc/routers` |
| Themes | `themeRouterConfig` from `@jetdevs/core/trpc/routers` |
| API Keys | `createApiKeysRouterConfig` from `@jetdevs/core/api-keys` |
| System Config | `systemConfigRouterConfig` from `@jetdevs/core/system-config` |
| Org Membership | `orgMembershipRouterConfig` from `@jetdevs/core/org-membership` |

Usage in root.ts:
```typescript
import { createRouterWithActor } from '@jetdevs/framework/router'
import { themeRouterConfig } from '@jetdevs/core/trpc/routers'

export const appRouter = createTRPCRouter({
  theme: createRouterWithActor(themeRouterConfig),
})
```

---

## Reference Documentation

- Extension Pattern: `/_context/_arch/core-architecture/extension-pattern.md`
- Migration Guide: `/_context/_arch/core-architecture/migration-guide.md`
- SDK Inventory: `/_context/_arch/core-architecture/sdk-inventory.md`
