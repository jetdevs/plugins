---
name: migrate-repository
description: Create or migrate a repository using SDK utilities (withTelemetry, auditLog, publishEvent, trackMetric). Repositories handle all database operations.
---

# Migrate/Create Repository with SDK Utilities

Repositories encapsulate database operations and use SDK utilities for telemetry, caching, audit logging, and events. Use repositories for complex modules that need these cross-cutting concerns. For simple CRUD, use `db` directly in handlers (Pattern A).

## When to Use a Repository vs Direct DB

| Approach | When to Use |
|----------|-------------|
| **Direct `db` in handler** | Simple CRUD, <5 procedures, no audit/telemetry needs |
| **Repository class** | Complex business logic, audit logging, telemetry, event publishing |

---

## Repository Template

```typescript
// repository.ts
import { and, desc, count as drizzleCount, eq, like, or } from 'drizzle-orm'
import type { PostgresJsDatabase } from 'drizzle-orm/postgres-js'
import type * as schema from '@/db/schema'
import { items } from './schema'
import {
  auditLog,
  calculateChanges,
  invalidateKey,
  invalidatePattern,
  publishEvent,
  trackMetric,
  withTelemetry,
} from '@jetdevs/framework'
import type { CreateInput, ListInput, UpdateInput } from './schemas'

export interface ListOptions extends ListInput {
  orgId: string  // varchar(36), NOT number
}

export class ItemsRepository {
  constructor(private db: PostgresJsDatabase<typeof schema>) {}

  async findById(id: string) {
    const item = await this.db.query.items.findFirst({
      where: eq(items.id, id),
    })
    return item || null
  }

  async list(options: ListOptions) {
    return withTelemetry('items.list', async () => {
      const { page, pageSize, search, isActive, sortBy, sortOrder, orgId } = options
      const offset = (page - 1) * pageSize

      const conditions = []
      if (search) {
        conditions.push(
          or(
            like(items.name, `%${search}%`),
            like(items.description, `%${search}%`)
          )
        )
      }
      if (isActive !== null && isActive !== undefined) {
        conditions.push(eq(items.isActive, isActive))
      }

      const where = conditions.length > 0 ? and(...conditions) : undefined
      const orderBy = sortOrder === 'desc' ? desc(items[sortBy]) : items[sortBy]

      const results = await this.db.select().from(items).where(where).orderBy(orderBy).limit(pageSize).offset(offset)
      const [countResult] = await this.db.select({ total: drizzleCount() }).from(items).where(where)

      return {
        items: results,
        total: countResult?.total ?? 0,
        page,
        pageSize,
        totalPages: Math.ceil((countResult?.total ?? 0) / pageSize),
      }
    })
  }

  async create(data: CreateInput, orgId: string, userId?: string) {
    return withTelemetry('items.create', async () => {
      const [newItem] = await this.db.insert(items).values({ ...data, orgId }).returning()
      if (!newItem) throw new Error('Failed to create item')

      await auditLog({ action: 'create', entityType: 'item', entityId: newItem.id, userId, orgId, metadata: { name: newItem.name } })
      await publishEvent('item.created', { itemId: newItem.id, orgId, createdBy: userId, data: newItem })
      await invalidatePattern('items:list:*')
      await trackMetric('items.created', 'counter')

      return newItem
    })
  }

  async update(id: string, data: Partial<UpdateInput>, userId?: string) {
    return withTelemetry('items.update', async () => {
      const current = await this.findById(id)
      if (!current) return null

      const [updatedItem] = await this.db.update(items).set({ ...data, updatedAt: new Date() }).where(eq(items.id, id)).returning()
      if (!updatedItem) return null

      await auditLog({ action: 'update', entityType: 'item', entityId: id, userId, orgId: updatedItem.orgId, changes: calculateChanges(current, updatedItem) })
      await publishEvent('item.updated', { itemId: id, orgId: updatedItem.orgId, updatedBy: userId, changes: calculateChanges(current, updatedItem) })
      await invalidateKey(['item', id])
      await invalidatePattern('items:list:*')

      return updatedItem
    })
  }

  async delete(id: string, userId?: string) {
    return withTelemetry('items.delete', async () => {
      const item = await this.findById(id)
      if (!item) return null

      const [deletedItem] = await this.db.delete(items).where(eq(items.id, id)).returning({ id: items.id })
      if (!deletedItem) return null

      await auditLog({ action: 'delete', entityType: 'item', entityId: id, userId, orgId: item.orgId, metadata: { deletedData: item } })
      await publishEvent('item.deleted', { itemId: id, orgId: item.orgId, deletedBy: userId, deletedData: item })
      await invalidateKey(['item', id])
      await invalidatePattern('items:list:*')

      return deletedItem
    })
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
import { createRouterWithActor } from '@jetdevs/framework/router'
import { ItemsRepository } from './repository'
import { listSchema, createSchema } from './schemas'

export const itemsRouter = createRouterWithActor({
  list: {
    type: 'query',
    input: listSchema,
    repository: ItemsRepository,  // SDK auto-instantiates
    handler: async ({ input, service, repo }) => {
      return repo.list({ ...input, orgId: service.orgId })
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
      return repo.create(input, service.orgId, service.userId)
    },
  },
})
```

---

## Key Changes from Old Pattern

| Old | New |
|-----|-----|
| `orgId: number` | `orgId: string` (varchar(36)) |
| `findByUuid(uuid)` | `findById(id)` (id IS the UUID now) |
| `uuid` param everywhere | `id` param (no separate uuid column) |
| Repository required for all routers | Optional — use `db` directly for simple CRUD |

---

## Caching Guidelines

**When to SKIP caching (no withCache):**
- Frequently-mutated lists
- Real-time data requirements
- Small datasets (<1000 rows) with fast queries (<50ms)

**When to USE caching:**
- Large datasets with expensive aggregations
- Reference data that rarely changes
- Read-heavy endpoints with infrequent mutations

---

## Common Repository Mistakes

### 1. Using integer orgId
```typescript
// WRONG — orgId is varchar now
async create(data: CreateInput, orgId: number, userId?: string) {

// CORRECT
async create(data: CreateInput, orgId: string, userId?: string) {
```

### 2. Separate uuid column
```typescript
// WRONG — no separate uuid needed
async findByUuid(uuid: string) {
  return this.db.query.items.findFirst({ where: eq(items.uuid, uuid) })
}

// CORRECT — id IS the public identifier
async findById(id: string) {
  return this.db.query.items.findFirst({ where: eq(items.id, id) })
}
```

### 3. Missing withTelemetry
```typescript
// WRONG
async list(options) {
  return this.db.select()...
}

// CORRECT
async list(options) {
  return withTelemetry('items.list', async () => {
    return this.db.select()...
  })
}
```

---

## Reference Documentation

- Extension Pattern: `/_context/_arch/core-architecture/extension-pattern.md`
- SDK Inventory: `/_context/_arch/core-architecture/sdk-inventory.md`
- Lessons Learned: `/_context/_arch/core-architecture/lessons-learned.md`
