---
name: migrate
description: Migrate an entire module to SDK extension pattern in a single request. Analyzes source, creates all files (schema, repository, router, types, schemas), registers everything, and provides deployment commands.
---

# Full Module Migration to SDK Extension

Migrate an entire module from old NextJS pattern to SDK extension in one workflow.

## Required Arguments

Provide in your request:
- **Source module path**: Where the existing module lives (e.g., `/apps/old-app/src/features/products`)
- **Target app**: Where to create the extension (e.g., `cadra-web`, `core-saas`, `yobo-merchant`)
- **Module name**: The extension name (e.g., `products`, `campaigns`, `outlets`)

---

## Migration Workflow

Execute these steps in order:

### Phase 1: Analysis

1. **Explore source module structure**
   ```bash
   ls -la {source-path}/
   ls -la {source-path}/components/ 2>/dev/null
   ```

2. **Identify database tables** - Look for schema files, `pgTable` definitions
3. **Find router patterns** - Check for `createTRPCRouter`, handler signatures
4. **List permissions** - Search for permission strings like `module:read`
5. **Catalog components** - List React components to migrate

### Phase 2: Create Extension Structure

```bash
mkdir -p /{target-app}/src/extensions/{module}/components
```

### Phase 3: Create All Files

Create files in this order:

---

## File 1: schema.ts (Database Schema)

```typescript
// /{target-app}/src/extensions/{module}/schema.ts
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

export const {tableName} = pgTable(
  '{table_name}',
  {
    id: serial('id').primaryKey(),
    uuid: uuid('uuid').defaultRandom().notNull().unique(),

    // Multi-tenant isolation (REQUIRED)
    orgId: integer('org_id')
      .notNull()
      .references(() => orgs.id, { onDelete: 'cascade' }),

    // Business fields - ADD FROM SOURCE
    name: text('name').notNull(),
    description: text('description'),

    // Ownership
    ownerId: integer('owner_id').references(() => users.id, { onDelete: 'set null' }),

    // Timestamps
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
    isActive: boolean('is_active').default(true).notNull(),
  },
  (table) => ({
    orgIdIdx: index('idx_{table_name}_org_id').on(table.orgId),
    uuidIdx: index('idx_{table_name}_uuid').on(table.uuid),
  })
);

export const {tableName}Relations = relations({tableName}, ({ one }) => ({
  org: one(orgs, {
    fields: [{tableName}.orgId],
    references: [orgs.id],
  }),
  owner: one(users, {
    fields: [{tableName}.ownerId],
    references: [users.id],
  }),
}));
```

---

## File 2: types.ts (Types & Permissions)

```typescript
// /{target-app}/src/extensions/{module}/types.ts
import type { {tableName} } from './schema';

export type {TypeName} = typeof {tableName}.$inferSelect;
export type New{TypeName} = typeof {tableName}.$inferInsert;

export const {Module}Permissions = {
  READ: '{module}:read',
  CREATE: '{module}:create',
  UPDATE: '{module}:update',
  DELETE: '{module}:delete',
} as const;
```

---

## File 3: schemas.ts (Zod Validation - SEPARATE FILE)

```typescript
// /{target-app}/src/extensions/{module}/schemas.ts
import { z } from 'zod';

export const listSchema = z.object({
  page: z.number().int().positive().default(1),
  pageSize: z.number().int().min(1).max(100).default(20),
  search: z.string().optional().nullable(),
  isActive: z.boolean().optional().nullable(),
  sortBy: z.enum(['name', 'createdAt', 'updatedAt']).default('createdAt'),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
});

export const getByIdSchema = z.object({
  uuid: z.string().uuid(),
});

export const createSchema = z.object({
  name: z.string().min(1).max(255),
  description: z.string().optional(),
  // ADD FIELDS FROM SOURCE
});

export const updateSchema = z.object({
  uuid: z.string().uuid(),
  name: z.string().min(1).max(255).optional(),
  description: z.string().optional().nullable(),
  // ADD FIELDS FROM SOURCE
});

export const deleteSchema = z.object({
  uuid: z.string().uuid(),
});

// Type exports
export type ListInput = z.infer<typeof listSchema>;
export type GetByIdInput = z.infer<typeof getByIdSchema>;
export type CreateInput = z.infer<typeof createSchema>;
export type UpdateInput = z.infer<typeof updateSchema>;
```

---

## File 4: repository.ts (Database Operations)

```typescript
// /{target-app}/src/extensions/{module}/repository.ts
import { and, desc, count as drizzleCount, eq, like, or } from 'drizzle-orm';
import type { PostgresJsDatabase } from 'drizzle-orm/postgres-js';
import type * as schema from '@/db/schema';
import { {tableName} } from './schema';
import {
  auditLog,
  calculateChanges,
  invalidateKey,
  invalidatePattern,
  publishEvent,
  trackMetric,
  withTelemetry,
} from '@jetdevs/framework';
import type { CreateInput, ListInput, UpdateInput } from './schemas';

export interface ListOptions extends ListInput {
  orgId: number;
}

export class {Module}Repository {
  constructor(private db: PostgresJsDatabase<typeof schema>) {}

  async findByUuid(uuid: string) {
    const item = await this.db.query.{tableName}.findFirst({
      where: eq({tableName}.uuid, uuid),
    });
    return item || null;
  }

  async list(options: ListOptions) {
    return withTelemetry('{module}.list', async () => {
      const { page, pageSize, search, isActive, sortBy, sortOrder, orgId } = options;
      const offset = (page - 1) * pageSize;

      const conditions = [];
      if (search) {
        conditions.push(
          or(
            like({tableName}.name, `%${search}%`),
            like({tableName}.description, `%${search}%`)
          )
        );
      }
      if (isActive !== null && isActive !== undefined) {
        conditions.push(eq({tableName}.isActive, isActive));
      }

      const where = conditions.length > 0 ? and(...conditions) : undefined;
      const orderBy = sortOrder === 'desc' ? desc({tableName}[sortBy]) : {tableName}[sortBy];

      const items = await this.db.select().from({tableName}).where(where).orderBy(orderBy).limit(pageSize).offset(offset);
      const [countResult] = await this.db.select({ total: drizzleCount() }).from({tableName}).where(where);

      return {
        items,
        total: countResult?.total ?? 0,
        page,
        pageSize,
        totalPages: Math.ceil((countResult?.total ?? 0) / pageSize),
      };
    });
  }

  async create(data: CreateInput, orgId: number, userId?: string) {
    return withTelemetry('{module}.create', async () => {
      const [newItem] = await this.db.insert({tableName}).values({ ...data, orgId }).returning();
      if (!newItem) throw new Error('Failed to create item');

      await auditLog({ action: 'create', entityType: '{module}', entityId: newItem.uuid, userId, orgId, metadata: { name: newItem.name } });
      await publishEvent('{module}.created', { itemId: newItem.uuid, orgId, createdBy: userId, data: newItem });
      await invalidatePattern('{module}:list:*');
      await trackMetric('{module}.created', 'counter');

      return newItem;
    });
  }

  async update(uuid: string, data: Partial<UpdateInput>, userId?: string) {
    return withTelemetry('{module}.update', async () => {
      const current = await this.findByUuid(uuid);
      if (!current) return null;

      const [updatedItem] = await this.db.update({tableName}).set({ ...data, updatedAt: new Date() }).where(eq({tableName}.uuid, uuid)).returning();
      if (!updatedItem) return null;

      await auditLog({ action: 'update', entityType: '{module}', entityId: uuid, userId, orgId: updatedItem.orgId, changes: calculateChanges(current, updatedItem) });
      await publishEvent('{module}.updated', { itemId: uuid, orgId: updatedItem.orgId, updatedBy: userId, changes: calculateChanges(current, updatedItem) });
      await invalidateKey(['{module}', uuid]);
      await invalidatePattern('{module}:list:*');

      return updatedItem;
    });
  }

  async delete(uuid: string, userId?: string) {
    return withTelemetry('{module}.delete', async () => {
      const item = await this.findByUuid(uuid);
      if (!item) return null;

      const [deletedItem] = await this.db.delete({tableName}).where(eq({tableName}.uuid, uuid)).returning({ id: {tableName}.id });
      if (!deletedItem) return null;

      await auditLog({ action: 'delete', entityType: '{module}', entityId: uuid, userId, orgId: item.orgId, metadata: { deletedData: item } });
      await publishEvent('{module}.deleted', { itemId: uuid, orgId: item.orgId, deletedBy: userId, deletedData: item });
      await invalidateKey(['{module}', uuid]);
      await invalidatePattern('{module}:list:*');

      return deletedItem;
    });
  }
}
```

---

## File 5: router.ts (tRPC Router)

```typescript
// /{target-app}/src/extensions/{module}/router.ts
import { TRPCError } from '@trpc/server';
import { trackMetric } from '@jetdevs/framework';
import { createRouterWithActor } from '@jetdevs/framework/router';
import { createSchema, deleteSchema, getByIdSchema, listSchema, updateSchema } from './schemas';
import { {Module}Repository } from './repository';

export const {module}Router = createRouterWithActor({
  list: {
    type: 'query',
    input: listSchema,
    cache: { ttl: 60, tags: ['{module}'] },
    repository: {Module}Repository,
    handler: async ({ input, service, repo }) => {
      return repo.list({ ...input, orgId: service.orgId });
    },
  },

  getById: {
    type: 'query',
    input: getByIdSchema,
    repository: {Module}Repository,
    handler: async ({ input, repo }) => {
      const item = await repo.findByUuid(input.uuid);
      if (!item) throw new TRPCError({ code: 'NOT_FOUND', message: 'Item not found.' });
      return item;
    },
  },

  create: {
    permission: '{module}:create',
    input: createSchema,
    invalidates: ['{module}'],
    entityType: '{module}',
    repository: {Module}Repository,
    handler: async ({ input, service, repo }) => {
      const newItem = await repo.create(input, service.orgId, service.userId);
      if (!newItem) throw new TRPCError({ code: 'INTERNAL_SERVER_ERROR', message: 'Failed to create item' });
      await trackMetric('api.{module}.created', 'counter');
      return newItem;
    },
  },

  update: {
    permission: '{module}:update',
    input: updateSchema,
    invalidates: ['{module}'],
    entityType: '{module}',
    repository: {Module}Repository,
    handler: async ({ input, service, repo }) => {
      const { uuid, ...updateData } = input;
      const updatedItem = await repo.update(uuid, updateData, service.userId);
      if (!updatedItem) throw new TRPCError({ code: 'NOT_FOUND', message: 'Item not found.' });
      return updatedItem;
    },
  },

  delete: {
    permission: '{module}:delete',
    input: deleteSchema,
    invalidates: ['{module}'],
    entityType: '{module}',
    repository: {Module}Repository,
    handler: async ({ input, service, repo }) => {
      const deletedItem = await repo.delete(input.uuid, service.userId);
      if (!deletedItem) throw new TRPCError({ code: 'NOT_FOUND', message: 'Item not found.' });
      await trackMetric('api.{module}.deleted', 'counter');
      return { success: true, deletedId: deletedItem.id };
    },
  },
});
```

---

## File 6: index.ts (Extension Definition)

```typescript
// /{target-app}/src/extensions/{module}/index.ts
import 'server-only';
import { defineExtension } from '@jetdevs/core';
import * as schema from './schema';
import { {module}Router } from './router';

const rlsConfig = [
  {
    tableName: '{table_name}',
    orgIdColumn: 'org_id',
    workspaceId: false,
    isolation: 'org' as const,
    policies: ['select', 'insert', 'update', 'delete'] as const,
    description: '{Module} management for organizations',
  },
];

export const {module}Extension = defineExtension({
  name: '{module}',
  version: '1.0.0',
  schema,
  router: {module}Router,
  rls: rlsConfig,
});

export * from './schema';
export { {module}Router } from './router';
export type { {TypeName} } from './types';
```

---

## File 7: client.ts (Client-Safe Exports)

```typescript
// /{target-app}/src/extensions/{module}/client.ts
export type { {TypeName} } from './types';
export { {Module}Permissions } from './types';

// Export components after copying
// export { {Module}DataTable } from './components/{Module}DataTable';
// export { {Module}FormDialog } from './components/{Module}FormDialog';
```

---

## Phase 4: Copy UI Components

```bash
# Copy ALL components from source
cp -r {source-path}/components/* /{target-app}/src/extensions/{module}/components/

# Then update imports in each file:
# - Change api.{old}.* to api.{module}.*
# - Change @/constants/* to @/config/constants
# - Change route constants to string literals
```

---

## Phase 5: Registration

### 1. Register Router in root.ts

```typescript
// /{target-app}/src/server/api/root.ts
import { {module}Router } from '@/extensions/{module}/router';

export const appRouter = createTRPCRouter({
  // ... existing routers
  {module}: {module}Router,
});
```

### 2. Export Schema in DB Index

```typescript
// /{target-app}/src/db/schema/index.ts
export * from '@/extensions/{module}/schema';
```

### 3. Add Permissions to Registry

```typescript
// /{target-app}/src/permissions/registry.ts
const {module}Module: PermissionModule = {
  name: "{Module} Management",
  description: "Manage {module}",
  category: '{module}' as any,
  dependencies: ['organization'],
  rlsTable: '{table_name}',
  permissions: {
    "{module}:read": { slug: "{module}:read", name: "View {Module}", description: "View {module} details", category: '{module}' as any, requiresOrg: true, dependencies: ["org:member"] },
    "{module}:create": { slug: "{module}:create", name: "Create {Module}", description: "Create new {module}", category: '{module}' as any, requiresOrg: true, dependencies: ["org:member"] },
    "{module}:update": { slug: "{module}:update", name: "Update {Module}", description: "Edit {module}", category: '{module}' as any, requiresOrg: true, dependencies: ["{module}:read"] },
    "{module}:delete": { slug: "{module}:delete", name: "Delete {Module}", description: "Remove {module}", category: '{module}' as any, requiresOrg: true, dependencies: ["{module}:read"], critical: true },
  }
};
```

### 4. Add to RLS Registry

```typescript
// /{target-app}/scripts/core/rls-registry.ts
{table_name}: {
  isolation: 'org',
  orgId: true,
  workspaceId: false,
  description: '{Module} management',
  rlsEnabled: true,
},
```

### 5. Add Navigation Item

```typescript
// /{target-app}/src/components/Sidebar/Sidebar.tsx
import { IconName } from 'lucide-react';

{
  title: '{Module}',
  href: '/{module}',
  icon: IconName,
  permission: '{module}:read',
},
```

### 6. Create Page Route

```typescript
// /{target-app}/src/app/(org)/{module}/page.tsx
import { {Module}Table } from '@/extensions/{module}/client';

export default function {Module}Page() {
  return (
    <div className="container mx-auto py-6">
      <h1 className="text-2xl font-bold mb-6">{Module}</h1>
      <{Module}Table />
    </div>
  );
}
```

---

## Phase 6: Deploy

```bash
cd /{target-app}

# Generate and apply migration
pnpm db:migrate:generate
pnpm db:migrate:run

# Deploy RLS policies
pnpm db:rls:deploy

# Seed permissions
pnpm generate:seed-permissions && pnpm db:seed:rbac

# Build and verify
pnpm build && pnpm typecheck

# CRITICAL: Log out and log back in to refresh JWT
```

---

## Verification Checklist

**Extension Files:**
- [ ] `schema.ts` - DB schema with org_id, uuid, indexes
- [ ] `types.ts` - Types and permissions enum
- [ ] `schemas.ts` - Zod schemas (SEPARATE FILE)
- [ ] `repository.ts` - Repository with SDK utilities
- [ ] `router.ts` - Using createRouterWithActor
- [ ] `index.ts` - Extension definition with RLS
- [ ] `client.ts` - Client-safe exports
- [ ] `components/` - UI components copied and updated

**Registration:**
- [ ] Router in `src/server/api/root.ts`
- [ ] Schema in `src/db/schema/index.ts`
- [ ] Permissions in `src/permissions/registry.ts`
- [ ] RLS in `scripts/core/rls-registry.ts`
- [ ] Navigation in `Sidebar.tsx`
- [ ] Page route in `app/(org)/{module}/page.tsx`

**Database:**
- [ ] Migration generated
- [ ] Migration applied
- [ ] RLS policies deployed
- [ ] Permissions seeded
- [ ] Logged out and back in

---

## Reference Documentation

- Extension Migration Guide: `/_context/core-sdk/guide-extension-migration.md`
- SDK Feature Guide: `/_context/core-sdk/feature-sdk.md`
- Backend Patterns: `/_context/_arch/patterns-backend.md`
- Products Router Example: `/yobo-merchant/src/server/api/routers/products.router.ts`
