---
name: migrate-router
description: Migrate a tRPC router from old pattern to SDK createRouterWithActor pattern. Handles the handler signature change and repository integration.
---

# Migrate Router to SDK Pattern

Convert routers from old `createTRPCRouter` pattern to new `createRouterWithActor` SDK pattern.

## Key Changes

### Handler Signature
```typescript
// OLD - Wrong pattern
handler: async ({ ctx, input }) => {
  const orgId = ctx.actor.orgId;  // FAILS
  return ctx.db.query.items.findMany();  // Direct DB access
}

// NEW - SDK pattern
handler: async ({ input, service, repo, actor }) => {
  return repo.list({ ...input, orgId: service.orgId });
}
```

### Router Factory
```typescript
// OLD
import { createTRPCRouter, orgProtectedProcedure } from '@/server/api/trpc';

export const itemsRouter = createTRPCRouter({
  list: orgProtectedProcedure
    .input(z.object({ page: z.number() }))
    .query(async ({ ctx, input }) => { ... }),
});

// NEW
import { createRouterWithActor } from '@jetdevs/framework/router';
import { listSchema } from './schemas';
import { ItemsRepository } from './repository';

export const itemsRouter = createRouterWithActor({
  list: {
    type: 'query',
    input: listSchema,
    repository: ItemsRepository,
    handler: async ({ input, service, repo }) => {
      return repo.list({ ...input, orgId: service.orgId });
    },
  },
});
```

---

## Handler Context Properties

| Property | Type | Description |
|----------|------|-------------|
| `input` | TInput | Validated input from Zod schema |
| `service` | ServiceContext | Contains `orgId`, `userId` |
| `repo` | Repository | Auto-instantiated repository with DB access |
| `actor` | Actor | Permissions, `isSystemUser`, `roles` |
| `ctx` | TRPCContext | Full context (rarely needed) |
| `db` | DrizzleDB | Direct DB access (use sparingly, prefer repo) |

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
    repository: ItemsRepository,      // Repository class
    handler: async ({ ... }) => {},   // Handler function
  },
}
```

---

## Migration Steps

### 1. Extract Schemas to Separate File
```typescript
// schemas.ts - ALWAYS separate file
import { z } from 'zod';

export const listSchema = z.object({
  page: z.number().int().positive().default(1),
  pageSize: z.number().int().min(1).max(100).default(20),
});

export const createSchema = z.object({
  name: z.string().min(1).max(255),
});
```

### 2. Create Repository
```typescript
// repository.ts
import { withTelemetry, auditLog, publishEvent } from '@jetdevs/framework';

export class ItemsRepository {
  constructor(private db: PostgresJsDatabase<typeof schema>) {}

  async list(options: ListOptions) {
    return withTelemetry('items.list', async () => {
      // DB query here
    });
  }
}
```

### 3. Convert Router
```typescript
// router.ts
import { createRouterWithActor } from '@jetdevs/framework/router';
import { listSchema, createSchema } from './schemas';
import { ItemsRepository } from './repository';

export const itemsRouter = createRouterWithActor({
  list: {
    type: 'query',
    input: listSchema,
    repository: ItemsRepository,
    handler: async ({ input, service, repo }) => {
      return repo.list({ ...input, orgId: service.orgId });
    },
  },

  create: {
    type: 'mutation',
    permission: 'items:create',
    input: createSchema,
    invalidates: ['items'],
    entityType: 'item',
    repository: ItemsRepository,
    handler: async ({ input, service, repo }) => {
      return repo.create(input, service.orgId, service.userId);
    },
  },
});
```

---

## Cross-Org Access Pattern

For endpoints needing cross-org access:

```typescript
list: {
  type: 'query',
  input: listSchema,
  repository: ItemsRepository,
  handler: async ({ input, service, repo, actor, ctx }) => {
    if (input.crossOrgAccess && input.orgId) {
      const { canAccessOrg } = await import('@/server/domain/auth/actor');

      if (!canAccessOrg(actor, input.orgId)) {
        throw new TRPCError({
          code: 'FORBIDDEN',
          message: 'Cross-org access denied.',
        });
      }

      if (actor.isSystemUser) {
        // Full repo access for system users
        const { getDbContext } = await import('@/server/domain/auth/actor');
        const { dbFunction, effectiveOrgId } = getDbContext(ctx, actor, {
          crossOrgAccess: true,
          targetOrgId: input.orgId,
        });

        return dbFunction(async (db) => {
          const crossOrgRepo = new ItemsRepository(db);
          return crossOrgRepo.list({ ...input, orgId: effectiveOrgId });
        });
      }
      // Regular users with permission get read-only
    }

    // Standard same-org query
    return repo.list({ ...input, orgId: service.orgId });
  },
},
```

---

## System Data Access (org_id = NULL)

For accessing system-level data with `org_id = NULL`:

```typescript
getAllSystemItems: {
  type: 'query',
  permission: 'admin:manage',
  crossOrg: true,  // CRITICAL: Bypass RLS for org_id = NULL data
  handler: async ({ ctx }) => {
    // Query returns system items correctly
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
import { listSchema } from './schemas';
list: {
  input: listSchema,
}
```

### 2. Direct DB Queries
```typescript
// WRONG
handler: async ({ input, ctx }) => {
  return ctx.db.query.items.findMany();
}

// CORRECT
handler: async ({ input, repo, service }) => {
  return repo.list({ ...input, orgId: service.orgId });
}
```

### 3. Wrong Context Property
```typescript
// WRONG
ctx.session.user.currentOrgId

// CORRECT
service.orgId
```
