---
name: migrate-extension
description: Migrate an application module to the SDK extension pattern. Creates the full extension structure with router, repository, schema, and types.
---

# Migrate Module to SDK Extension

Guide for migrating application modules to the SaaS Core SDK framework.

## Extension Directory Structure (Flat)

Every domain feature lives in `src/extensions/{module-name}/`:

```
src/extensions/projects/
  index.ts          # Extension definition (server-only)
  client.ts         # Client-safe re-exports (types + components)
  server.ts         # Server-only re-exports (optional)
  schema.ts         # Drizzle table definitions
  router.ts         # tRPC router (createRouterWithActor or hybrid)
  types.ts          # Shared TypeScript types
  components/       # React UI components
    ProjectList.tsx
    ProjectForm.tsx
```

**DO NOT create deeply nested folders** like `server/routers/`, `server/repos/`, `db/schema/`.

---

## Step-by-Step Migration

### Step 1: Create Extension Structure

```bash
mkdir -p {target-app}/src/extensions/{module}/components
```

### Step 2: Create Files in Order

#### 2a. schema.ts — Table Definitions

```typescript
import { pgTable, varchar, text, timestamp, jsonb, index } from 'drizzle-orm/pg-core'
import { orgs } from '@jetdevs/core/db/schema'
import { relations } from 'drizzle-orm'
import { generateId } from '@jetdevs/core/lib'

export const projects = pgTable('projects', {
  id:          varchar('id', { length: 36 }).primaryKey().$defaultFn(() => generateId()),
  orgId:       varchar('org_id', { length: 36 }).notNull().references(() => orgs.id),
  name:        text('name').notNull(),
  description: text('description'),
  status:      varchar('status', { length: 20 }).notNull().default('active'),
  metadata:    jsonb('metadata'),
  createdBy:   varchar('created_by', { length: 36 }),
  createdAt:   timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt:   timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('projects_org_id_idx').on(table.orgId),
])

export const projectsRelations = relations(projects, ({ one }) => ({
  org: one(orgs, { fields: [projects.orgId], references: [orgs.id] }),
}))
```

#### 2b. types.ts — Shared Types

```typescript
import type { InferSelectModel, InferInsertModel } from 'drizzle-orm'
import type { projects } from './schema'

export type Project = InferSelectModel<typeof projects>
export type NewProject = InferInsertModel<typeof projects>

export interface CreateProjectInput {
  name: string
  description?: string
}
```

#### 2c. router.ts — tRPC Router

Use Pattern A (pure) or Pattern B (hybrid):

**Pattern A: Pure createRouterWithActor (most common)**

```typescript
import { createRouterWithActor } from '@jetdevs/framework/router'
import { z } from 'zod'
import { projects } from './schema'
import { eq, desc } from 'drizzle-orm'

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
        orderBy: [desc(projects.createdAt)],
      })
    },
  },

  getById: {
    type: 'query',
    permission: 'projects:read',
    input: z.object({ id: z.string() }),
    handler: async ({ input, db, service }) => {
      return db.query.projects.findFirst({
        where: and(eq(projects.id, input.id), eq(projects.orgId, service.orgId)),
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

**Pattern B: Hybrid (when you need public/admin endpoints too)**

```typescript
import { createRouterWithActor } from '@jetdevs/framework/router'
import { createTRPCRouter, publicProcedure } from '@/server/api/trpc'

const orgRouter = createRouterWithActor({ /* org-protected */ })
const publicRouter = createTRPCRouter({ /* public endpoints */ })

export const projectsRouter = createTRPCRouter({
  ...orgRouter._def.procedures,
  ...publicRouter._def.procedures,
})
```

#### 2d. index.ts — Extension Definition

```typescript
import "server-only"
import { defineExtension } from '@jetdevs/core/config'
import * as schema from './schema'
import { projectsRouter } from './router'

export const projectsExtension = defineExtension({
  name: 'projects',
  version: '1.0.0',
  schema,
  router: projectsRouter,
  rls: {
    tables: ['projects'],
    orgIdColumn: 'org_id',
  },
  permissions: {
    'projects:create': { description: 'Create projects', requiresOrg: true },
    'projects:read':   { description: 'View projects', requiresOrg: true },
    'projects:update': { description: 'Edit projects', requiresOrg: true },
    'projects:delete': { description: 'Delete projects', requiresOrg: true },
  },
})
```

#### 2e. client.ts — Client-Safe Exports

Only types and React components (never schema or server code):

```typescript
export type { Project, CreateProjectInput } from './types'
export { ProjectList } from './components/ProjectList'
export { ProjectForm } from './components/ProjectForm'
```

#### 2f. server.ts — Server-Only Exports (optional)

```typescript
import "server-only"
export { projects, projectsRelations } from './schema'
export { projectsRouter } from './router'
export { projectsExtension } from './index'
```

### Step 3: Register in Application

#### 3a. saas.config.ts

```typescript
import { projectsExtension } from './src/extensions/projects'

export default defineSaasConfig({
  extensions: [projectsExtension],
})
```

#### 3b. Root Router (src/server/api/root.ts)

```typescript
import { projectsRouter } from '@/extensions/projects/router'

export const appRouter = createTRPCRouter({
  projects: projectsRouter,
})
```

#### 3c. Schema Index (src/db/schema/index.ts)

```typescript
export * from '@jetdevs/core/db/schema'
export * from '@/extensions/projects/schema'
```

#### 3d. Permissions Registry

```typescript
// src/permissions/registry.ts
import { corePermissions, mergePermissions } from '@jetdevs/core/permissions'

const appPermissions = {
  projects: {
    category: 'projects',
    permissions: {
      'projects:create': { requiresOrg: true },
      'projects:read':   { requiresOrg: true },
      'projects:update': { requiresOrg: true },
      'projects:delete': { requiresOrg: true },
    },
  },
}

export const allPermissions = mergePermissions(corePermissions, appPermissions)
```

#### 3e. RLS Registry

```typescript
// scripts/core/rls-registry.ts
{table_name}: {
  isolation: 'org',
  orgId: true,
  workspaceId: false,
  description: 'Projects management',
  rlsEnabled: true,
},
```

#### 3f. Sidebar Navigation

```typescript
{
  title: 'Projects',
  href: '/projects',
  icon: FolderIcon,
  permission: 'projects:read',
},
```

### Step 4: Database & Permissions

```bash
pnpm db:migrate:generate
pnpm db:migrate:run
pnpm db:rls:deploy
pnpm generate:seed-permissions && pnpm db:seed:rbac
```

**CRITICAL**: Log out and log back in to refresh JWT with new permissions.

---

## Key Conventions

| Rule | Rationale |
|------|-----------|
| `index.ts` starts with `import "server-only"` | Prevents accidental client bundling |
| Client imports use `@/extensions/xxx/client` | Never import the bare index from client |
| Every table has `orgId` varchar(36) FK to `orgs.id` | Required for RLS |
| Schema imports core tables from `@jetdevs/core/db/schema` | Avoids circular deps |
| Permission slugs follow `{module}:{action}` | e.g., `projects:create` |
| Use `service.orgId` and `service.userId` in handlers | Provided by `createRouterWithActor` |
| ID columns are `varchar(36)` with `generateId()` | NOT serial integers |
| Index syntax uses arrays `(table) => [...]` | NOT objects `(table) => ({...})` |

---

## Verification Checklist

**Files:**
- [ ] `schema.ts` — varchar IDs, varchar orgId, array-syntax indexes
- [ ] `types.ts` — TypeScript types
- [ ] `router.ts` — `createRouterWithActor` (Pattern A or B)
- [ ] `index.ts` — `defineExtension` with `rls` and `permissions`
- [ ] `client.ts` — client-safe exports only

**Registration:**
- [ ] `saas.config.ts` — extension registered
- [ ] `root.ts` — router imported
- [ ] `schema/index.ts` — schema re-exported
- [ ] `permissions/registry.ts` — permissions added
- [ ] `rls-registry.ts` — RLS configured
- [ ] `Sidebar.tsx` — navigation item added

**Database:**
- [ ] Migration generated and applied
- [ ] RLS policies deployed
- [ ] Permissions seeded
- [ ] Logged out and back in

---

## Reference Documentation

- Extension Pattern: `/_context/_arch/core-architecture/extension-pattern.md`
- Migration Guide: `/_context/_arch/core-architecture/migration-guide.md`
- Target Architecture: `/_context/_arch/core-architecture/target-architecture.md`
- Lessons Learned: `/_context/_arch/core-architecture/lessons-learned.md`
