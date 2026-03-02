# SDK Migration Plugin

A Claude Code plugin for migrating NextJS application modules to the `@jetdevs/core` SDK extension pattern in a single request.

## Installation

### Local Development

```bash
claude --plugin-dir ./_context/_claude/plugins/sdk
```

### Team Installation

```bash
/plugin marketplace add ./path/to/monorepo
/plugin install sdk@my-marketplace
```

## Quick Start - Single Command Migration

Use the unified migrate skill to handle everything in one request:

```
/sdk:migrate

Migrate the products module from /apps/old-app/src/features/products to cadra-web
```

This will:
1. Analyze the source module
2. Create extension directory structure
3. Generate all files (schema, types, schemas, repository, router, index, client)
4. Copy and update UI components
5. Provide all registration steps
6. Output deployment commands

## Available Skills

| Skill | Command | Description |
|-------|---------|-------------|
| **Migrate (Full)** | `/sdk:migrate` | **Primary** - Complete module migration in one request |
| Analyze Module | `/sdk:analyze-module` | Just analyze a module (no changes) |
| Migrate Extension | `/sdk:migrate-extension` | Step-by-step extension guide |
| Migrate Router | `/sdk:migrate-router` | Router conversion reference |
| Migrate Schema | `/sdk:migrate-schema` | Schema pattern reference |
| Migrate Repository | `/sdk:migrate-repository` | Repository pattern reference |

## Example Usage

### Full Migration (Recommended)

```
/sdk:migrate

Migrate the campaigns module:
- Source: /apps/ai-saas/src/features/campaigns
- Target: cadra-web
- Module name: campaigns
```

### Analysis Only

```
/sdk:analyze-module

Analyze /apps/old-app/src/features/products before migrating
```

## What Gets Created

```
/{target-app}/src/extensions/{module}/
├── schema.ts       # DB schema with org_id, uuid, indexes
├── types.ts        # TypeScript types & permissions enum
├── schemas.ts      # Zod validation schemas (SEPARATE FILE)
├── repository.ts   # Repository with SDK utilities
├── router.ts       # tRPC router (createRouterWithActor)
├── index.ts        # Extension definition with RLS config
├── client.ts       # Client-safe exports
└── components/     # Copied & updated UI components
```

## Key SDK Patterns

### Handler Context (NEW vs OLD)

```typescript
// OLD - Wrong
handler: async ({ ctx, input }) => {
  const orgId = ctx.actor.orgId;  // FAILS
}

// NEW - Correct
handler: async ({ input, service, repo }) => {
  return repo.list({ ...input, orgId: service.orgId });
}
```

### Router Factory

```typescript
import { createRouterWithActor } from '@jetdevs/framework/router';
import { listSchema } from './schemas';  // ALWAYS import, never inline
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

### Repository with SDK Utilities

```typescript
import { withTelemetry, auditLog, publishEvent } from '@jetdevs/framework';

export class ItemsRepository {
  async create(data, orgId, userId) {
    return withTelemetry('items.create', async () => {
      const item = await this.db.insert(items).values(data).returning();
      await auditLog({ action: 'create', entityType: 'item', ... });
      await publishEvent('item.created', { ... });
      return item;
    });
  }
}
```

## Common Pitfalls (Auto-Avoided)

1. **Inline schemas** - Plugin always creates separate `schemas.ts`
2. **Direct DB in router** - Plugin creates repository pattern
3. **Wrong context** - Plugin uses `service.orgId` correctly
4. **Missing org_id** - Plugin includes RLS-required columns
5. **Missing registration** - Plugin lists all registration steps

## Reference Documentation

- `/_context/core-sdk/guide-extension-migration.md`
- `/_context/core-sdk/feature-sdk.md`
- `/_context/_arch/patterns-backend.md`

## Version

1.0.0
