---
name: migrate-repository
description: Create or migrate a repository using SDK utilities (withTelemetry, auditLog, publishEvent, trackMetric). Repositories handle all database operations.
---

# Migrate/Create Repository with SDK Utilities

Repositories encapsulate all database operations and use SDK utilities for telemetry, caching, audit logging, and events.

## Repository Pattern

**CRITICAL**: Routers should NEVER query the database directly. All DB operations go through repositories.

---

## Repository Template

```typescript
// repository.ts
import { and, desc, count as drizzleCount, eq, like, or } from 'drizzle-orm';
import type { PostgresJsDatabase } from 'drizzle-orm/postgres-js';

import type * as schema from '@/db/schema';
import { items } from './schema';
import {
  auditLog,
  calculateChanges,
  invalidateKey,
  invalidatePattern,
  publishEvent,
  trackMetric,
  withCache,
  withTelemetry,
} from '@jetdevs/framework';
import type { CreateInput, ListInput, UpdateInput } from './schemas';

// Types
export interface ListOptions extends ListInput {
  orgId: number;
}

/**
 * Items Repository
 * Handles all database operations for items
 */
export class ItemsRepository {
  constructor(private db: PostgresJsDatabase<typeof schema>) {}

  /**
   * Find item by UUID
   */
  async findByUuid(uuid: string) {
    const item = await this.db.query.items.findFirst({
      where: eq(items.uuid, uuid),
    });
    return item || null;
  }

  /**
   * Find item by ID
   */
  async findById(id: number) {
    const item = await this.db.query.items.findFirst({
      where: eq(items.id, id),
    });
    return item || null;
  }

  /**
   * List items with filtering and pagination
   * NOTE: withCache is currently a stub - consider skipping for frequently-mutated lists
   */
  async list(options: ListOptions) {
    return withTelemetry('items.list', async () => {
      const { page, pageSize, search, isActive, sortBy, sortOrder, orgId } = options;
      const offset = (page - 1) * pageSize;

      // Build where conditions
      const conditions = [];

      if (search) {
        conditions.push(
          or(
            like(items.name, `%${search}%`),
            like(items.description, `%${search}%`)
          )
        );
      }

      if (isActive !== null && isActive !== undefined) {
        conditions.push(eq(items.isActive, isActive));
      }

      const where = conditions.length > 0 ? and(...conditions) : undefined;

      // Fetch items
      const results = await this.db
        .select()
        .from(items)
        .where(where)
        .orderBy(sortOrder === 'desc' ? desc(items[sortBy]) : items[sortBy])
        .limit(pageSize)
        .offset(offset);

      // Get total count
      const [countResult] = await this.db
        .select({ total: drizzleCount() })
        .from(items)
        .where(where);

      const total = countResult?.total ?? 0;

      return {
        items: results,
        total,
        page,
        pageSize,
        totalPages: Math.ceil(total / pageSize),
      };
    });
  }

  /**
   * Create new item with audit logging and event publishing
   */
  async create(data: CreateInput, orgId: number, userId?: string) {
    return withTelemetry('items.create', async () => {
      const [newItem] = await this.db
        .insert(items)
        .values({
          ...data,
          orgId,
        })
        .returning();

      if (!newItem) {
        throw new Error('Failed to create item');
      }

      // Audit log the creation
      await auditLog({
        action: 'create',
        entityType: 'item',
        entityId: newItem.uuid,
        userId,
        orgId,
        metadata: {
          name: newItem.name,
        },
      });

      // Publish domain event
      await publishEvent('item.created', {
        itemId: newItem.uuid,
        orgId,
        createdBy: userId,
        timestamp: new Date(),
        data: newItem,
      });

      // Invalidate related caches
      await invalidatePattern('items:list:*');

      // Track business metric
      await trackMetric('items.created', 'counter');

      return newItem;
    });
  }

  /**
   * Update item with change tracking and audit logging
   */
  async update(uuid: string, data: Partial<UpdateInput>, userId?: string) {
    return withTelemetry('items.update', async () => {
      // Get current state for audit
      const current = await this.findByUuid(uuid);
      if (!current) return null;

      const [updatedItem] = await this.db
        .update(items)
        .set({
          ...data,
          updatedAt: new Date(),
        })
        .where(eq(items.uuid, uuid))
        .returning();

      if (!updatedItem) return null;

      // Log changes
      await auditLog({
        action: 'update',
        entityType: 'item',
        entityId: uuid,
        userId,
        orgId: updatedItem.orgId,
        changes: calculateChanges(current, updatedItem),
        metadata: {
          name: updatedItem.name,
        },
      });

      // Publish domain event
      await publishEvent('item.updated', {
        itemId: uuid,
        orgId: updatedItem.orgId,
        updatedBy: userId,
        timestamp: new Date(),
        changes: calculateChanges(current, updatedItem),
      });

      // Invalidate caches
      await invalidateKey(['item', uuid]);
      await invalidatePattern('items:list:*');

      return updatedItem;
    });
  }

  /**
   * Delete item with audit logging
   */
  async delete(uuid: string, userId?: string) {
    return withTelemetry('items.delete', async () => {
      // Get item before deletion for audit
      const item = await this.findByUuid(uuid);
      if (!item) return null;

      const [deletedItem] = await this.db
        .delete(items)
        .where(eq(items.uuid, uuid))
        .returning({ id: items.id });

      if (!deletedItem) return null;

      // Audit log the deletion
      await auditLog({
        action: 'delete',
        entityType: 'item',
        entityId: uuid,
        userId,
        orgId: item.orgId,
        metadata: {
          name: item.name,
          deletedData: item,
        },
      });

      // Publish domain event
      await publishEvent('item.deleted', {
        itemId: uuid,
        orgId: item.orgId,
        deletedBy: userId,
        timestamp: new Date(),
        deletedData: item,
      });

      // Invalidate caches
      await invalidateKey(['item', uuid]);
      await invalidatePattern('items:list:*');

      return deletedItem;
    });
  }
}
```

---

## SDK Utilities Reference

| Utility | Purpose | When to Use |
|---------|---------|-------------|
| `withTelemetry` | Performance tracking | Wrap ALL public methods |
| `withCache` | Cache query results | Read operations (currently stub) |
| `auditLog` | Audit trail | All create/update/delete |
| `publishEvent` | Domain events | Lifecycle events |
| `invalidateKey` | Clear specific cache | After updates |
| `invalidatePattern` | Clear cache pattern | After mutations affecting lists |
| `calculateChanges` | Compute diff | For audit logs on updates |
| `trackMetric` | Business metrics | Important operations |

---

## Using Repository in Router

```typescript
// router.ts
import { createRouterWithActor } from '@jetdevs/framework/router';
import { ItemsRepository } from './repository';
import { listSchema, createSchema } from './schemas';

export const itemsRouter = createRouterWithActor({
  list: {
    type: 'query',
    input: listSchema,
    repository: ItemsRepository,  // SDK auto-instantiates
    handler: async ({ input, service, repo }) => {
      // repo is already instantiated with DB connection
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
      // Pass userId for audit logging
      return repo.create(input, service.orgId, service.userId);
    },
  },
});
```

---

## Caching Guidelines

**When to DISABLE caching (skip withCache):**
- Frequently-mutated lists (outlets, products with inventory)
- Real-time data requirements
- Small datasets (<1000 rows) with fast queries (<50ms)

**When to KEEP caching:**
- Large datasets with expensive aggregations
- Reference data that rarely changes
- Read-heavy endpoints with infrequent mutations

```typescript
// Example: Skip cache for frequently-mutated list
async list(options: ListOptions) {
  return withTelemetry('items.list', async () => {
    // No withCache wrapper - direct DB query
    const results = await this.db.select()...;
    return { data: results, totalCount };
  });
}
```

---

## Multi-Tenant Context

Repository methods receive `orgId` from the router:

```typescript
// Router passes orgId from service context
handler: async ({ input, service, repo }) => {
  return repo.list({ ...input, orgId: service.orgId });
}

// Repository uses orgId for all queries
async list(options: ListOptions) {
  const { orgId } = options;
  // Filter by orgId for RLS defense-in-depth
  return this.db.select().from(items).where(eq(items.orgId, orgId));
}
```

---

## Common Repository Mistakes

### 1. Missing withTelemetry
```typescript
// WRONG - No performance tracking
async list(options) {
  return this.db.select()...;
}

// CORRECT
async list(options) {
  return withTelemetry('items.list', async () => {
    return this.db.select()...;
  });
}
```

### 2. Missing Audit on Mutations
```typescript
// WRONG - No audit trail
async create(data, orgId) {
  return this.db.insert(items).values(data).returning();
}

// CORRECT
async create(data, orgId, userId) {
  const [item] = await this.db.insert(items).values(data).returning();

  await auditLog({
    action: 'create',
    entityType: 'item',
    entityId: item.uuid,
    userId,
    orgId,
  });

  return item;
}
```

### 3. Not Invalidating Cache
```typescript
// WRONG - Stale data after create
async create(data) {
  const item = await this.db.insert(items)...;
  return item;  // List cache still has old data!
}

// CORRECT
async create(data) {
  const item = await this.db.insert(items)...;
  await invalidatePattern('items:list:*');
  return item;
}
```
