# Types Pattern

TypeScript interfaces, type aliases, enums, and constants for API contracts and shared data structures.

## Location

`src/features/{feature}/types/{feature}.types.ts` - Feature-specific types
`src/shared/types/api.types.ts` - Shared API types (pagination, errors)
`src/shared/types/common.types.ts` - Common utility types

## Key Rules

1. **Contract-first**: Types are defined before implementation (they are the spec)
2. **`interface` for object shapes** - extendable and mergeable
3. **`type` for unions, intersections, and computed types** - use when `interface` is insufficient
4. **Suffix convention**: `Request` for inputs, `Response` for outputs (API boundary types)
5. **`string` for API dates** - parse at the boundary, not in the type definition
6. **Co-locate with feature** - types belong to the feature that owns them

## Entity Type (API Response)

The primary data type representing a resource returned by the API.

```tsx
// src/features/recipes/types/recipe.types.ts
export interface Recipe {
  id: string;
  title: string;
  description: string;
  servings: number;
  prepTimeMinutes: number;
  cookTimeMinutes: number;
  createdAt: string;
  updatedAt: string;
}
```

Rules:
- Use `string` for UUIDs (no runtime parsing needed on the frontend)
- Use `string` for ISO date strings from APIs
- Use camelCase for property names (match JSON convention from API)
- All fields are required unless the API explicitly returns `null`

## Request Types

Types for data sent to the API.

```tsx
// src/features/recipes/types/recipe.types.ts
export interface CreateRecipeRequest {
  title: string;
  description: string;
  servings: number;
  prepTimeMinutes: number;
  cookTimeMinutes: number;
}

export interface UpdateRecipeRequest {
  title?: string;
  description?: string;
  servings?: number;
  prepTimeMinutes?: number;
  cookTimeMinutes?: number;
}
```

Rules:
- `Create` types have all required fields (no `?`)
- `Update` types have all optional fields (`?`) for partial updates
- Never include `id`, `createdAt`, or `updatedAt` in request types (server-managed)
- Request types mirror the API contract body shape

## Query Parameter Types

```tsx
// src/features/recipes/types/recipe.types.ts
export interface RecipeListParams {
  query?: string;
  category?: string;
  limit?: number;
  offset?: number;
}
```

Rules:
- All fields are optional (query params are always optional)
- Use specific types (`number` for pagination, `string` for search)

## Shared API Types

Types used across multiple features.

```tsx
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

Rules:
- Use generics for wrapper types (`PaginatedResponse<T>`)
- Keep shared types minimal; feature-specific types belong in the feature
- Match the API error response format exactly

## Enum-Like Types

Prefer string literal unions over TypeScript `enum` for API values.

```tsx
// src/features/recipes/types/recipe.types.ts
export type RecipeStatus = 'draft' | 'published' | 'archived';

export type DifficultyLevel = 'easy' | 'medium' | 'hard';
```

Rules:
- String literal unions over `enum` (better tree-shaking, simpler to serialize)
- Use `type` (not `interface`) for unions
- Match the exact string values the API sends/receives

## Constants Derived from Types

```tsx
// src/features/recipes/types/recipe.types.ts
export type RecipeStatus = 'draft' | 'published' | 'archived';

export const RECIPE_STATUS_LABELS: Record<RecipeStatus, string> = {
  draft: 'Draft',
  published: 'Published',
  archived: 'Archived',
};
```

Rules:
- Use `Record<UnionType, string>` for label maps (TypeScript enforces all keys are present)
- Constants are `UPPER_SNAKE_CASE`
- Co-locate constants with the types they reference

## Utility Types

Common type patterns for reuse.

```tsx
// src/shared/types/common.types.ts

/** Make specific keys optional */
export type PartialBy<T, K extends keyof T> = Omit<T, K> & Partial<Pick<T, K>>;

/** Make specific keys required */
export type RequiredBy<T, K extends keyof T> = Omit<T, K> & Required<Pick<T, K>>;

/** Extract the element type from an array type */
export type ArrayElement<T extends readonly unknown[]> = T[number];
```

Rules:
- Only create utility types when the built-in TypeScript utilities (`Partial`, `Required`, `Pick`, `Omit`) are insufficient
- Document each utility type with a JSDoc comment
- Keep utility types in `shared/types/common.types.ts`

## Type Organization within a Feature

A feature's type file groups related types together:

```tsx
// src/features/recipes/types/recipe.types.ts

// --- Entity ---
export interface Recipe {
  id: string;
  title: string;
  description: string;
  status: RecipeStatus;
  createdAt: string;
  updatedAt: string;
}

// --- Request/Response ---
export interface CreateRecipeRequest {
  title: string;
  description: string;
}

export interface UpdateRecipeRequest {
  title?: string;
  description?: string;
}

// --- Query Params ---
export interface RecipeListParams {
  query?: string;
  status?: RecipeStatus;
  limit?: number;
  offset?: number;
}

// --- Enums / Unions ---
export type RecipeStatus = 'draft' | 'published' | 'archived';

// --- Constants ---
export const RECIPE_STATUS_LABELS: Record<RecipeStatus, string> = {
  draft: 'Draft',
  published: 'Published',
  archived: 'Archived',
};
```

Rules:
- One type file per feature (avoid splitting types across many files)
- Group by category with comment separators
- Entity types first, then requests, then params, then unions, then constants

## Importing Types

```tsx
// GOOD: Use `import type` for type-only imports
import type { Recipe, CreateRecipeRequest } from '../types/recipe.types';

// GOOD: Mixed import when you need both types and values
import type { RecipeStatus } from '../types/recipe.types';
import { RECIPE_STATUS_LABELS } from '../types/recipe.types';

// BAD: Regular import for types (bloats bundle if not tree-shaken)
import { Recipe, CreateRecipeRequest } from '../types/recipe.types';
```

Rules:
- Use `import type` for interfaces and type aliases (removed at compile time)
- Use regular imports for runtime values (constants, enums)
- TypeScript's `verbatimModuleSyntax` or `isolatedModules` enforces this

## Anti-Patterns

```tsx
// BAD: Using `enum` for API values
enum RecipeStatus {
  Draft = 'draft',
  Published = 'published',
}

// GOOD: String literal union
type RecipeStatus = 'draft' | 'published' | 'archived';

// BAD: `any` type
export interface Recipe {
  id: any;
  metadata: any;
}

// GOOD: Specific types
export interface Recipe {
  id: string;
  metadata: Record<string, unknown>;
}

// BAD: Putting all types in one global file
// src/types/index.ts (700 lines of every type in the app)

// GOOD: Co-locate with feature
// src/features/recipes/types/recipe.types.ts
// src/features/users/types/user.types.ts

// BAD: Date objects in API types
export interface Recipe {
  createdAt: Date; // API sends a string, not a Date object
}

// GOOD: String for API dates
export interface Recipe {
  createdAt: string; // ISO 8601 string from API
}

// BAD: Duplicating types across features
// recipes/types.ts: interface User { id: string; name: string; }
// comments/types.ts: interface User { id: string; name: string; }

// GOOD: Import from the owning feature or shared types
import type { User } from '@/features/users/types/user.types';

// BAD: Using `interface` for a union type
interface Status {
  value: 'active' | 'inactive'; // Unnecessary wrapper
}

// GOOD: Direct union type
type Status = 'active' | 'inactive';
```

## Cross-References

- See `component.md` for how types are used in props interfaces
- See `hook.md` for how types are used in TanStack Query generics
- See `service.md` for how types define API function signatures
