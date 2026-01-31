---
name: migrate-schema
description: Migrate database schema to SDK pattern with proper org_id, UUID, indexes, and RLS configuration.
---

# Migrate Database Schema to SDK Pattern

Convert database schemas to follow SDK multi-tenant patterns with RLS support.

## Required Schema Elements

Every SDK extension table MUST have:
1. `org_id` - Foreign key to `orgs.id` for multi-tenancy
2. `uuid` - Public identifier (never expose internal `id`)
3. Indexes on `org_id` and `uuid` for RLS performance
4. Timestamps (`createdAt`, `updatedAt`)

---

## Schema Template

```typescript
// schema.ts
import {
  pgTable,
  serial,
  integer,
  text,
  timestamp,
  boolean,
  index,
  uuid,
} from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';
import { orgs, users } from '@jetdevs/core/db/schema';

// =============================================================================
// TABLES
// =============================================================================

export const items = pgTable(
  'items',
  {
    // Primary key (internal use only)
    id: serial('id').primaryKey(),

    // Public identifier (expose this to API)
    uuid: uuid('uuid').defaultRandom().notNull().unique(),

    // Multi-tenant isolation (REQUIRED for RLS)
    orgId: integer('org_id')
      .notNull()
      .references(() => orgs.id, { onDelete: 'cascade' }),

    // Business fields
    name: text('name').notNull(),
    description: text('description'),

    // Ownership
    ownerId: integer('owner_id')
      .references(() => users.id, { onDelete: 'set null' }),

    // Audit fields
    createdAt: timestamp('created_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .defaultNow()
      .notNull(),
    isActive: boolean('is_active').default(true).notNull(),
  },
  (table) => ({
    // Index for RLS performance (REQUIRED)
    orgIdIdx: index('idx_items_org_id').on(table.orgId),
    // Index for UUID lookups
    uuidIdx: index('idx_items_uuid').on(table.uuid),
  })
);

// =============================================================================
// RELATIONS
// =============================================================================

export const itemsRelations = relations(items, ({ one }) => ({
  org: one(orgs, {
    fields: [items.orgId],
    references: [orgs.id],
  }),
  owner: one(users, {
    fields: [items.ownerId],
    references: [users.id],
  }),
}));
```

---

## Key Requirements

### 1. org_id Column (CRITICAL)
```typescript
// CORRECT
orgId: integer('org_id')
  .notNull()
  .references(() => orgs.id, { onDelete: 'cascade' }),

// WRONG - Missing foreign key
orgId: integer('org_id').notNull(),

// WRONG - Wrong type
orgId: serial('org_id'),
```

### 2. UUID Column
```typescript
// Use UUID for public identifiers
uuid: uuid('uuid').defaultRandom().notNull().unique(),

// Never expose internal id to API
id: serial('id').primaryKey(),  // Internal only
```

### 3. Indexes
```typescript
// REQUIRED: org_id index for RLS performance
orgIdIdx: index('idx_{table}_org_id').on(table.orgId),

// REQUIRED: uuid index for lookups
uuidIdx: index('idx_{table}_uuid').on(table.uuid),
```

### 4. Import from Core
```typescript
// Import org and user tables from core
import { orgs, users } from '@jetdevs/core/db/schema';

// NOT from local app
// import { orgs, users } from '@/db/schema';  // WRONG
```

---

## RLS Registry Configuration

Add table to RLS registry:

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
};
```

---

## Extension Index with RLS Config

```typescript
// index.ts
import 'server-only';
import { defineExtension } from '@jetdevs/core';
import * as schema from './schema';
import { itemsRouter } from './router';

const rlsConfig = [
  {
    tableName: 'items',
    orgIdColumn: 'org_id',
    workspaceId: false,
    isolation: 'org' as const,
    policies: ['select', 'insert', 'update', 'delete'] as const,
    description: 'Items management for organizations',
  },
];

export const itemsExtension = defineExtension({
  name: 'items',
  version: '1.0.0',
  schema,
  router: itemsRouter,
  rls: rlsConfig,
});

export * from './schema';
export { itemsRouter } from './router';
```

---

## Export Schema in DB Index

```typescript
// src/db/schema/index.ts

// Core schemas
export * from '@jetdevs/core/db/schema';

// Extension schemas
export * from '@/extensions/items/schema';
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

## Inherited Tables (No org_id)

Child tables that inherit isolation from parent:

```typescript
// Child table with parent FK instead of org_id
export const itemDetails = pgTable('item_details', {
  id: serial('id').primaryKey(),
  uuid: uuid('uuid').defaultRandom().notNull().unique(),

  // Parent reference (inherits org isolation)
  itemId: integer('item_id')
    .notNull()
    .references(() => items.id, { onDelete: 'cascade' }),

  // No org_id - inherits from parent

  detail: text('detail').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
}, (table) => ({
  itemIdIdx: index('idx_item_details_item_id').on(table.itemId),
}));
```

RLS policy for inherited tables:
```sql
-- Child table policy references parent
CREATE POLICY "item_details_org_isolation" ON item_details
  USING (
    item_id IN (
      SELECT id FROM items WHERE org_id = get_current_org_id()
    )
  );
```

---

## Common Schema Mistakes

### 1. Missing org_id Index
```typescript
// WRONG - No index, slow RLS queries
}, (table) => ({}));

// CORRECT
}, (table) => ({
  orgIdIdx: index('idx_items_org_id').on(table.orgId),
}));
```

### 2. Wrong Foreign Key Import
```typescript
// WRONG - Importing from app
import { orgs } from '@/db/schema';

// CORRECT - Import from core
import { orgs } from '@jetdevs/core/db/schema';
```

### 3. Exposing Internal ID
```typescript
// WRONG - Returning internal id to client
return { id: item.id, name: item.name };

// CORRECT - Return uuid
return { uuid: item.uuid, name: item.name };
```
