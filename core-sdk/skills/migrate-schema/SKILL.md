---
name: migrate-schema
description: Migrate database schema to SDK pattern with proper org_id, UUID, indexes, and RLS configuration.
---

# Migrate Database Schema to SDK Pattern

Convert database schemas to follow SDK multi-tenant patterns with RLS support.

## Required Schema Elements

Every SDK extension table MUST have:
1. `id` - VARCHAR(36) primary key using `generateId()` (NOT serial integer)
2. `orgId` - VARCHAR(36) FK to `orgs.id` for multi-tenancy (NOT integer)
3. Indexes on `orgId` for RLS performance (array syntax)
4. Timestamps (`createdAt`, `updatedAt`)

---

## Schema Template

```typescript
// schema.ts
import { pgTable, varchar, text, timestamp, boolean, jsonb, index } from 'drizzle-orm/pg-core'
import { relations } from 'drizzle-orm'
import { orgs, users } from '@jetdevs/core/db/schema'
import { generateId } from '@jetdevs/core/lib'

// =============================================================================
// TABLES
// =============================================================================

export const items = pgTable('items', {
  // Primary key — VARCHAR UUID, NOT serial integer
  id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => generateId()),

  // Multi-tenant isolation (REQUIRED for RLS)
  orgId: varchar('org_id', { length: 36 }).notNull().references(() => orgs.id),

  // Business fields
  name: text('name').notNull(),
  description: text('description'),
  status: varchar('status', { length: 20 }).notNull().default('active'),
  metadata: jsonb('metadata'),

  // Ownership
  createdBy: varchar('created_by', { length: 36 }),

  // Audit fields
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  isActive: boolean('is_active').default(true).notNull(),
}, (table) => [
  // ARRAY syntax for indexes (NOT object syntax)
  index('items_org_id_idx').on(table.orgId),
])

// =============================================================================
// RELATIONS
// =============================================================================

export const itemsRelations = relations(items, ({ one }) => ({
  org: one(orgs, {
    fields: [items.orgId],
    references: [orgs.id],
  }),
}))
```

---

## Key Requirements

### 1. ID Column — VARCHAR, NOT Serial

```typescript
// CORRECT — VARCHAR UUID with generateId()
id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => generateId()),

// WRONG — Serial integer (old pattern)
id: serial('id').primaryKey(),

// WRONG — UUID type (use varchar for consistency)
id: uuid('uuid').defaultRandom().notNull().unique(),
```

### 2. orgId Column — VARCHAR(36)

```typescript
// CORRECT — VARCHAR FK to orgs.id
orgId: varchar('org_id', { length: 36 }).notNull().references(() => orgs.id),

// WRONG — Integer (SDK uses varchar for org IDs)
orgId: integer('org_id').notNull().references(() => orgs.id, { onDelete: 'cascade' }),
```

### 3. Indexes — Array Syntax

```typescript
// CORRECT — Array syntax
}, (table) => [
  index('items_org_id_idx').on(table.orgId),
])

// WRONG — Object syntax (old Drizzle pattern)
}, (table) => ({
  orgIdIdx: index('idx_items_org_id').on(table.orgId),
}))
```

### 4. Import from Core

```typescript
// CORRECT — Import from SDK
import { orgs, users } from '@jetdevs/core/db/schema'
import { generateId } from '@jetdevs/core/lib'

// WRONG — Import from local app
import { orgs, users } from '@/db/schema'
```

---

## RLS Configuration

### In Extension Definition (index.ts)

```typescript
import { defineExtension } from '@jetdevs/core/config'

export const itemsExtension = defineExtension({
  name: 'items',
  version: '1.0.0',
  schema,
  router: itemsRouter,
  rls: {
    tables: ['items'],
    orgIdColumn: 'org_id',
  },
  permissions: {
    'items:create': { description: 'Create items', requiresOrg: true },
    'items:read':   { description: 'View items', requiresOrg: true },
    'items:update': { description: 'Edit items', requiresOrg: true },
    'items:delete': { description: 'Delete items', requiresOrg: true },
  },
})
```

### In RLS Registry

```typescript
// scripts/core/rls-registry.ts
export const rlsRegistry = {
  items: {
    isolation: 'org',
    orgId: true,
    workspaceId: false,
    description: 'Items management for organizations',
    rlsEnabled: true,
  },
}
```

---

## Export Schema in DB Index

```typescript
// src/db/schema/index.ts

// Core schemas
export * from '@jetdevs/core/db/schema'

// Extension schemas
export * from '@/extensions/items/schema'
```

---

## Migration Commands

```bash
# Generate migration from schema changes
pnpm db:migrate:generate

# Apply migration
pnpm db:migrate:run

# Deploy RLS policies
pnpm db:rls:deploy
```

---

## Inherited Tables (No orgId)

Child tables that inherit isolation from parent:

```typescript
export const itemDetails = pgTable('item_details', {
  id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => generateId()),

  // Parent reference (inherits org isolation)
  itemId: varchar('item_id', { length: 36 })
    .notNull()
    .references(() => items.id, { onDelete: 'cascade' }),

  // No orgId — inherits from parent

  detail: text('detail').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
}, (table) => [
  index('item_details_item_id_idx').on(table.itemId),
])
```

---

## Common Schema Mistakes

### 1. Missing orgId Index
```typescript
// WRONG — No index, slow RLS queries
}, (table) => [])

// CORRECT
}, (table) => [
  index('items_org_id_idx').on(table.orgId),
])
```

### 2. Wrong ID Type
```typescript
// WRONG — Serial integer
id: serial('id').primaryKey(),

// CORRECT — VARCHAR UUID
id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => generateId()),
```

### 3. Wrong orgId Type
```typescript
// WRONG — Integer
orgId: integer('org_id').notNull(),

// CORRECT — VARCHAR(36)
orgId: varchar('org_id', { length: 36 }).notNull().references(() => orgs.id),
```

### 4. Exposing Internal ID
```typescript
// Not applicable — id IS the public identifier (VARCHAR UUID)
// No separate uuid column needed
return { id: item.id, name: item.name }
```

---

## Reference Documentation

- Extension Pattern: `/_context/_arch/core-architecture/extension-pattern.md`
- Target Architecture: `/_context/_arch/core-architecture/target-architecture.md`
- Lessons Learned: `/_context/_arch/core-architecture/lessons-learned.md`
