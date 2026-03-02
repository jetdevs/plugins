---
name: open-api
description: Use when creating or modifying REST API endpoints at /api/v1/*, adding API routes, working with API key authentication, withApiAuth, withPrivilegedDb, or OpenAPI patterns in cadra-web.
---

# CadraOS OpenAPI REST API Development

Patterns for building REST API endpoints in the CadraOS platform.

## API Structure

All endpoints live at `src/app/api/v1/` with standard CRUD patterns:

```
src/app/api/v1/
  agents/          # Agents CRUD + skills, tools, provider-config
  tools/           # Tools CRUD
  teams/           # Teams CRUD + members
  workflows/       # Workflows CRUD + execute + executions
  webhooks/        # Webhooks CRUD + test + deliveries
  prompts/         # Prompts CRUD
  knowledge-bases/ # KBs CRUD + documents
  providers/       # Providers CRUD + models
  internal/        # Internal-only endpoints
```

## Authentication

Bearer token: `Authorization: Bearer jetai_test_xxx` (or `cdr_test_xxx`)

```typescript
import { withApiAuth, type ApiContext } from "@/lib/api/auth";

export async function GET(request: NextRequest) {
  return withApiAuth(request, async (req, apiContext: ApiContext) => {
    // apiContext: { orgId, apiKeyId, permissions, environment }
  });
}
```

## CRITICAL: Always Use withPrivilegedDb

REST API routes MUST use `withPrivilegedDb`, NOT `db`. RLS context isn't set for API key auth.

```typescript
import { withPrivilegedDb } from "@/db/clients";

const result = await withPrivilegedDb(async (db) => {
  const repo = new Repository(db);
  return repo.list({ orgId: apiContext.orgId });
});
```

## Permission Checking

```typescript
import { hasPermission } from "@/lib/api/trpc-bridge";

if (!hasPermission(apiContext, "resource:read")) {
  return errorResponse(insufficientPermissions(["resource:read"]));
}
```

## Response Helpers

```typescript
import { successResponse, errorResponse, notFound, insufficientPermissions, fromZodError, internalError, badRequest } from "@/lib/api/errors";

return successResponse(data);       // 200
return successResponse(data, 201);  // 201
return errorResponse(notFound("Resource", uuid)); // 404
```

## CORS

Every route file must handle OPTIONS:

```typescript
import { handleCorsPreflightRequest } from "@/lib/api/cors";
export async function OPTIONS(request: NextRequest) {
  return handleCorsPreflightRequest(request);
}
```

## Next.js 15 Params

```typescript
// params is a Promise in Next.js 15
const { id } = await context.params;
```

## New Endpoint Checklist

1. Create route at `src/app/api/v1/{resource}/route.ts`
2. Add CORS OPTIONS handler
3. Import `withApiAuth` and `withPrivilegedDb`
4. Check permissions with `hasPermission()`
5. Validate input with Zod
6. Use repository pattern for DB operations
7. Return with `successResponse()` / `errorResponse()`

## Reference Documentation

- API guide: `_context/cadra/open-api/feature.md`
- Architecture: `_context/cadra/open-api/architecture.md`
