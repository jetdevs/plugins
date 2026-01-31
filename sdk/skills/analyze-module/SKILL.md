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
- Check if `org_id` column exists (required for RLS)

### 3. Router Patterns
Identify:
- tRPC router files
- Procedure types (query/mutation)
- Permission requirements
- Input schemas (Zod)
- Handler patterns (old `{ ctx, input }` vs new `{ actor, db, input }`)

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

## Output Format

Provide a migration report:

```markdown
## Module Analysis: {module-name}

### Database Tables
| Table | Has org_id | Foreign Keys | RLS Needed |
|-------|------------|--------------|------------|
| ...   | ...        | ...          | ...        |

### Router Endpoints
| Router | Procedure | Type | Permission | Handler Pattern |
|--------|-----------|------|------------|-----------------|
| ...    | ...       | ...  | ...        | old/new         |

### Permissions Required
- `{module}:create` - Create items
- `{module}:read` - View items
- `{module}:update` - Edit items
- `{module}:delete` - Remove items

### Component Files
- [ ] List of components to migrate
- [ ] Stores to migrate
- [ ] Utilities to migrate

### Migration Complexity
- **Estimated effort**: Low/Medium/High
- **Key challenges**: (list any blockers)
```

## Reference Documentation
- Extension Migration Guide: `/_context/core-sdk/guide-extension-migration.md`
- SDK Feature Guide: `/_context/core-sdk/feature-sdk.md`
- Backend Patterns: `/_context/_arch/patterns-backend.md`
