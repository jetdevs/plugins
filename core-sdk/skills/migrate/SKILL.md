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

2. **Identify database tables** — Look for schema files, `pgTable` definitions
3. **Check column types** — `orgId` should be `varchar(36)`, `id` should be `varchar(36)`. Note if they're `integer`/`serial` (needs type migration)
4. **Find router patterns** — Check for `createTRPCRouter` (legacy), `createRouterWithActor` (SDK), or hybrid
5. **List permissions** — Search for permission strings like `module:read`
6. **Catalog components** — List React components to migrate

### Phase 2: Create Extension Structure

```bash
mkdir -p {target-app}/src/extensions/{module}/components
```

### Phase 3: Create All Files

Create files in this order:

---

## File 1: schema.ts (Database Schema)

```typescript
// {target-app}/src/extensions/{module}/schema.ts
import { pgTable, varchar, text, timestamp, boolean, jsonb, index } from 'drizzle-orm/pg-core'
import { relations } from 'drizzle-orm'
import { orgs } from '@jetdevs/core/db/schema'
import { generateId } from '@jetdevs/core/lib'

export const {tableName} = pgTable('{table_name}', {
  // VARCHAR UUID primary key (NOT serial integer)
  id: varchar('id', { length: 36 }).primaryKey().$defaultFn(() => generateId()),

  // Multi-tenant isolation (REQUIRED)
  orgId: varchar('org_id', { length: 36 }).notNull().references(() => orgs.id),

  // Business fields — ADD FROM SOURCE
  name: text('name').notNull(),
  description: text('description'),
  status: varchar('status', { length: 20 }).notNull().default('active'),
  metadata: jsonb('metadata'),

  // Ownership
  createdBy: varchar('created_by', { length: 36 }),

  // Timestamps
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
  isActive: boolean('is_active').default(true).notNull(),
}, (table) => [
  // ARRAY syntax for indexes
  index('{table_name}_org_id_idx').on(table.orgId),
])

export const {tableName}Relations = relations({tableName}, ({ one }) => ({
  org: one(orgs, { fields: [{tableName}.orgId], references: [orgs.id] }),
}))
```

---

## File 2: types.ts (Types & Permissions)

```typescript
// {target-app}/src/extensions/{module}/types.ts
import type { InferSelectModel, InferInsertModel } from 'drizzle-orm'
import type { {tableName} } from './schema'

export type {TypeName} = InferSelectModel<typeof {tableName}>
export type New{TypeName} = InferInsertModel<typeof {tableName}>

export const {Module}Permissions = {
  READ: '{module}:read',
  CREATE: '{module}:create',
  UPDATE: '{module}:update',
  DELETE: '{module}:delete',
} as const
```

---

## File 3: router.ts (tRPC Router)

Choose Pattern A (simple CRUD, direct db) or Pattern B (complex, with repository):

### Pattern A: Direct DB (preferred for simple modules)

```typescript
// {target-app}/src/extensions/{module}/router.ts
import { createRouterWithActor } from '@jetdevs/framework/router'
import { TRPCError } from '@trpc/server'
import { z } from 'zod'
import { {tableName} } from './schema'
import { eq, and, desc } from 'drizzle-orm'

export const {module}Router = createRouterWithActor({
  list: {
    type: 'query',
    permission: '{module}:read',
    input: z.object({
      limit: z.number().min(1).max(100).default(20),
      offset: z.number().min(0).default(0),
    }).optional(),
    handler: async ({ input, db, service }) => {
      return db.query.{tableName}.findMany({
        where: eq({tableName}.orgId, service.orgId),
        limit: input?.limit ?? 20,
        offset: input?.offset ?? 0,
        orderBy: [desc({tableName}.createdAt)],
      })
    },
  },

  getById: {
    type: 'query',
    permission: '{module}:read',
    input: z.object({ id: z.string() }),
    handler: async ({ input, db, service }) => {
      const item = await db.query.{tableName}.findFirst({
        where: and(eq({tableName}.id, input.id), eq({tableName}.orgId, service.orgId)),
      })
      if (!item) throw new TRPCError({ code: 'NOT_FOUND', message: 'Not found' })
      return item
    },
  },

  create: {
    type: 'mutation',
    permission: '{module}:create',
    input: z.object({
      name: z.string().min(1).max(255),
      description: z.string().optional(),
      // ADD FIELDS FROM SOURCE
    }),
    handler: async ({ input, db, service }) => {
      const [item] = await db.insert({tableName}).values({
        orgId: service.orgId,
        createdBy: service.userId,
        ...input,
      }).returning()
      return item
    },
  },

  update: {
    type: 'mutation',
    permission: '{module}:update',
    input: z.object({
      id: z.string(),
      name: z.string().min(1).max(255).optional(),
      description: z.string().optional().nullable(),
      // ADD FIELDS FROM SOURCE
    }),
    handler: async ({ input, db, service }) => {
      const { id, ...data } = input
      const [item] = await db.update({tableName})
        .set({ ...data, updatedAt: new Date() })
        .where(and(eq({tableName}.id, id), eq({tableName}.orgId, service.orgId)))
        .returning()
      if (!item) throw new TRPCError({ code: 'NOT_FOUND', message: 'Not found' })
      return item
    },
  },

  delete: {
    type: 'mutation',
    permission: '{module}:delete',
    input: z.object({ id: z.string() }),
    handler: async ({ input, db, service }) => {
      const [item] = await db.delete({tableName})
        .where(and(eq({tableName}.id, input.id), eq({tableName}.orgId, service.orgId)))
        .returning({ id: {tableName}.id })
      if (!item) throw new TRPCError({ code: 'NOT_FOUND', message: 'Not found' })
      return { success: true }
    },
  },
})
```

### Pattern B: With Repository (for complex modules needing audit/telemetry)

```typescript
import { createRouterWithActor } from '@jetdevs/framework/router'
import { {Module}Repository } from './repository'
import { listSchema, createSchema, updateSchema, deleteSchema } from './schemas'

export const {module}Router = createRouterWithActor({
  list: {
    type: 'query',
    input: listSchema,
    repository: {Module}Repository,
    handler: async ({ input, service, repo }) => {
      return repo.list({ ...input, orgId: service.orgId })
    },
  },
  create: {
    type: 'mutation',
    permission: '{module}:create',
    input: createSchema,
    repository: {Module}Repository,
    handler: async ({ input, service, repo }) => {
      return repo.create(input, service.orgId, service.userId)
    },
  },
})
```

---

## File 4: index.ts (Extension Definition)

```typescript
// {target-app}/src/extensions/{module}/index.ts
import "server-only"
import { defineExtension } from '@jetdevs/core/config'
import * as schema from './schema'
import { {module}Router } from './router'

export const {module}Extension = defineExtension({
  name: '{module}',
  version: '1.0.0',
  schema,
  router: {module}Router,
  rls: {
    tables: ['{table_name}'],
    orgIdColumn: 'org_id',
  },
  permissions: {
    '{module}:create': { description: 'Create {module}', requiresOrg: true },
    '{module}:read':   { description: 'View {module}', requiresOrg: true },
    '{module}:update': { description: 'Edit {module}', requiresOrg: true },
    '{module}:delete': { description: 'Delete {module}', requiresOrg: true },
  },
})
```

---

## File 5: client.ts (Client-Safe Exports)

```typescript
// {target-app}/src/extensions/{module}/client.ts
export type { {TypeName} } from './types'
export { {Module}Permissions } from './types'

// Export components after copying
// export { {Module}DataTable } from './components/{Module}DataTable'
// export { {Module}FormDialog } from './components/{Module}FormDialog'
```

---

## Phase 4: Copy UI Components

```bash
# Copy ALL components from source
cp -r {source-path}/components/* {target-app}/src/extensions/{module}/components/

# Then update imports in each file:
# - Change api.{old}.* to api.{module}.*
# - Import from @/extensions/{module}/client not @/extensions/{module}
# - Change @/constants/* to @/config/constants
```

---

## Phase 5: Registration

### 1. Register in saas.config.ts

```typescript
import { {module}Extension } from './src/extensions/{module}'

export default defineSaasConfig({
  extensions: [{module}Extension],
})
```

### 2. Register Router in root.ts

```typescript
import { {module}Router } from '@/extensions/{module}/router'

export const appRouter = createTRPCRouter({
  {module}: {module}Router,
})
```

### 3. Export Schema in DB Index

```typescript
// src/db/schema/index.ts
export * from '@/extensions/{module}/schema'
```

### 4. Add Permissions to Registry

```typescript
// src/permissions/registry.ts
import { corePermissions, mergePermissions } from '@jetdevs/core/permissions'

const appPermissions = {
  {module}: {
    category: '{module}',
    permissions: {
      '{module}:read':   { requiresOrg: true },
      '{module}:create': { requiresOrg: true },
      '{module}:update': { requiresOrg: true },
      '{module}:delete': { requiresOrg: true },
    },
  },
}

export const allPermissions = mergePermissions(corePermissions, appPermissions)
```

### 5. Add to RLS Registry

```typescript
// scripts/core/rls-registry.ts
{table_name}: {
  isolation: 'org',
  orgId: true,
  workspaceId: false,
  description: '{Module} management',
  rlsEnabled: true,
},
```

### 6. Add Navigation Item

```typescript
// Sidebar.tsx
{
  title: '{Module}',
  href: '/{module}',
  icon: IconName,
  permission: '{module}:read',
},
```

### 7. Create Page Route

```typescript
// src/app/(org)/{module}/page.tsx
import { {Module}Table } from '@/extensions/{module}/client'

export default function {Module}Page() {
  return (
    <div className="container mx-auto py-6">
      <h1 className="text-2xl font-bold mb-6">{Module}</h1>
      <{Module}Table />
    </div>
  )
}
```

---

## Phase 6: Deploy

```bash
cd {target-app}

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
- [ ] `schema.ts` — varchar IDs, varchar orgId, array-syntax indexes
- [ ] `types.ts` — Types using InferSelectModel/InferInsertModel
- [ ] `router.ts` — `createRouterWithActor` with `type` field on every procedure
- [ ] `index.ts` — `defineExtension` from `@jetdevs/core/config` with permissions + RLS
- [ ] `client.ts` — Client-safe exports only (types + components)
- [ ] `components/` — UI components with updated imports

**Registration:**
- [ ] Extension in `saas.config.ts`
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

- Extension Pattern: `/_context/_arch/core-architecture/extension-pattern.md`
- Migration Guide: `/_context/_arch/core-architecture/migration-guide.md`
- Target Architecture: `/_context/_arch/core-architecture/target-architecture.md`
- SDK Inventory: `/_context/_arch/core-architecture/sdk-inventory.md`
- Lessons Learned: `/_context/_arch/core-architecture/lessons-learned.md`
