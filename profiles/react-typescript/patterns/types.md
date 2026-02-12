# Types Pattern

TypeScript interfaces, type aliases, enums, and constants for API contracts and shared data structures.

## Location

- `src/features/{feature}/types/{feature}.types.ts` - Feature-specific types
- `src/shared/types/api.types.ts` - Shared API types (pagination, errors)
- `src/shared/types/common.types.ts` - Common utility types

## Key Rules

1. **Contract-first**: Types are defined before implementation (they are the spec)
2. **`interface` for object shapes** - extendable and mergeable
3. **`type` for unions, intersections, and computed types**
4. **Suffix convention**: `Request` for inputs, `Response` for outputs
5. **`string` for API dates** - parse at the boundary, not in the type definition
6. **Co-locate with feature** - types belong to the feature that owns them

## Entity Type (API Response)

```tsx
export interface Recipe {
  id: string;
  title: string;
  description: string;
  servings: number;
  prepTimeMinutes: number;
  cookTimeMinutes: number;
  createdAt: string;   // ISO 8601 from API
  updatedAt: string;
}
```

Rules: Use `string` for UUIDs and ISO dates. Use camelCase. All fields required unless API returns `null`.

## Request Types

```tsx
export interface CreateRecipeRequest {
  title: string;
  description: string;
  servings: number;
}

export interface UpdateRecipeRequest {
  title?: string;         // All optional for partial updates
  description?: string;
  servings?: number;
}
```

`Create` = all required. `Update` = all optional. Never include `id`, `createdAt`, `updatedAt` (server-managed).

## Query Parameter & Shared API Types

```tsx
export interface RecipeListParams {
  query?: string;
  category?: string;
  limit?: number;
  offset?: number;
}

// src/shared/types/api.types.ts
export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  limit: number;
  offset: number;
}

export interface ApiErrorResponse {
  detail: string;
  status: number;
  errors?: ValidationError[];
}

export interface ValidationError {
  field: string;
  message: string;
}
```

## Enum-Like Types & Constants

```tsx
// String literal unions over TypeScript `enum` (better tree-shaking)
export type RecipeStatus = 'draft' | 'published' | 'archived';

export const RECIPE_STATUS_LABELS: Record<RecipeStatus, string> = {
  draft: 'Draft',
  published: 'Published',
  archived: 'Archived',
};
```

## Utility Types

```tsx
// src/shared/types/common.types.ts
/** Make specific keys optional */
export type PartialBy<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

/** Make specific keys required */
export type RequiredBy<T, K extends keyof T> = Omit<T, K> & Required<Pick<T, K>>;

/** Extract the element type from an array type */
export type ArrayElement<T extends readonly unknown[]> = T[number];
```

Only create utility types when built-in `Partial`, `Required`, `Pick`, `Omit` are insufficient.

## Type Organization within a Feature

```tsx
// src/features/recipes/types/recipe.types.ts

// --- Entity ---
export interface Recipe { id: string; title: string; status: RecipeStatus; createdAt: string; }

// --- Request/Response ---
export interface CreateRecipeRequest { title: string; }
export interface UpdateRecipeRequest { title?: string; }

// --- Query Params ---
export interface RecipeListParams { query?: string; status?: RecipeStatus; limit?: number; }

// --- Enums / Unions ---
export type RecipeStatus = 'draft' | 'published' | 'archived';

// --- Constants ---
export const RECIPE_STATUS_LABELS: Record<RecipeStatus, string> = { ... };
```

One type file per feature. Group by category. Entity first, then requests, params, unions, constants.

## Importing Types

```tsx
// Use `import type` for type-only imports (removed at compile time)
import type { Recipe, CreateRecipeRequest } from '../types/recipe.types';

// Regular imports for runtime values (constants)
import { RECIPE_STATUS_LABELS } from '../types/recipe.types';
```

## Anti-Patterns

| Bad | Good | Why |
|-----|------|-----|
| `enum RecipeStatus { Draft = 'draft' }` | `type RecipeStatus = 'draft' \| 'published'` | Better tree-shaking, simpler serialization |
| `id: any; metadata: any` | `id: string; metadata: Record<string, unknown>` | Type safety |
| Global `src/types/index.ts` (700 lines) | `src/features/X/types/X.types.ts` | Co-location |
| `createdAt: Date` | `createdAt: string` | API sends ISO string, not Date object |
| Duplicate types across features | Import from the owning feature | DRY |
| `interface Status { value: 'active' \| 'inactive' }` | `type Status = 'active' \| 'inactive'` | No unnecessary wrapper |

## Cross-References

- See `component.md` for how types are used in props interfaces
- See `hook.md` for how types are used in TanStack Query generics
- See `service.md` for how types define API function signatures
