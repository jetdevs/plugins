---
name: analyze-module
description: Analyze an existing module to prepare for SDK migration. Use when starting migration to identify dependencies, database tables, permissions, and router endpoints.
---

# Analyze Module for SDK Migration

Before migrating a module, analyze it to understand the scope of work.

## What to Analyze

### 1. Identify Source Files
Find all files in the module:
```bash
# List module structure
find {source-app}/src -type d -name "{module}" 2>/dev/null
find {source-app}/src -type f -name "*{module}*" 2>/dev/null
```

### 2. Database Dependencies
Look for:
- Drizzle schema files (`schema.ts`, `*.schema.ts`)
- Table definitions with `pgTable`
- Foreign key relationships
- Check column types: `orgId` should be `varchar(36)`, `id` should be `varchar(36)` with `generateId()`
- If `orgId` is `integer`, note it needs type migration to `varchar(36)`

### 3. Router Patterns
Identify which pattern the router uses:

| Pattern | Indicator | Migration Needed |
|---------|-----------|-----------------|
| **Pattern C (Legacy)** | `orgProtectedProcedure`, `createTRPCRouter` | Full migration |
| **Pattern A (SDK)** | `createRouterWithActor` (pure) | Already migrated |
| **Pattern B (Hybrid)** | Mix of `createRouterWithActor` + `publicProcedure` | Partial migration |

Look for:
- Handler signature: `{ ctx, input }` (old) vs `{ input, db, service }` (new)
- Permission checking: manual `requirePermission` calls vs declarative `permission` field
- DB access: `ctx.db.query` (old) vs `db.query` or `repo.method()` (new)

### 4. Permission Usage
Find permission strings:
```bash
grep -r "permission:" {source-path}/
grep -r ":read\|:create\|:update\|:delete" {source-path}/
```

### 5. Component Dependencies
- React components used
- Shared UI imports
- Custom hooks
- Zustand stores

### 6. Migration Type Assessment

Determine which migration type applies:

| App Type | Auth | Schema | Migration Scope |
|----------|------|--------|----------------|
| **Full SaaS app** (owns auth + users + orgs) | Migrate to SDK auth | Consolidate schema | All phases |
| **Satellite app** (delegates auth elsewhere) | Keep external auth | Keep own schema | Phases 1, 3, 4 only |

## Output Format

Provide a migration report:

```markdown
## Module Analysis: {module-name}

### Migration Type
- [ ] Full SaaS app (all phases)
- [ ] Satellite app (phases 1, 3, 4)

### Database Tables
| Table | Has orgId | orgId Type | ID Type | Foreign Keys | RLS Needed |
|-------|-----------|------------|---------|--------------|------------|
| ...   | ...       | varchar/int| varchar/serial | ... | ... |

### Router Endpoints
| Router | Procedure | Type | Permission | Current Pattern |
|--------|-----------|------|------------|-----------------|
| ...    | ...       | ...  | ...        | Legacy/SDK/Hybrid |

### Permissions Required
- `{module}:create` - Create items
- `{module}:read` - View items
- `{module}:update` - Edit items
- `{module}:delete` - Remove items

### SDK Router Candidates
Check if any routers can be replaced by SDK-provided configs:
| Current Router | SDK Replacement |
|---------------|----------------|
| auth router | `createAuthRouterConfig` |
| user router | `createUserRouterConfig` |
| org router | `createOrgRouterConfig` |
| role router | `createRoleRouterConfig` |
| theme router | `themeRouterConfig` |
| permission router | `permissionRouterConfig` |
| api keys router | `createApiKeysRouterConfig` |
| user-org router | `userOrgRouterConfig` |
| org membership | `orgMembershipRouterConfig` |

### Component Files
- [ ] List of components to migrate
- [ ] Stores to migrate
- [ ] Utilities to migrate

### Known Risks
- [ ] orgId is integer (needs type migration to varchar(36))
- [ ] Schema uses serial IDs (needs migration to varchar(36) + generateId())
- [ ] Index syntax uses object form (needs array syntax)
- [ ] async_hooks risk (framework imports in client bundles)
- [ ] Cross-package Drizzle relations
- [ ] Duplicate core table definitions (orgs, users, roles)

### Migration Complexity
- **Estimated effort**: Low/Medium/High
- **Key challenges**: (list any blockers)
```

## Reference Documentation

- SDK Inventory: `/_context/_arch/core-architecture/sdk-inventory.md`
- Migration Guide: `/_context/_arch/core-architecture/migration-guide.md`
- Lessons Learned: `/_context/_arch/core-architecture/lessons-learned.md`
