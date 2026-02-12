# Service Pattern

API client functions with typed request/response contracts, error handling, and environment-driven configuration.

## Location

`src/features/{feature}/services/{feature}Service.ts` - Feature-specific API functions
`src/shared/services/apiClient.ts` - Shared HTTP client configuration
`src/shared/services/errorHandler.ts` - Centralized error handling

## Key Rules

1. **Contract-first**: Define function signatures (params + return types) before implementing
2. **Pure async functions** - no React hooks, no state, no side effects beyond HTTP
3. **Typed inputs and outputs** - accept and return TypeScript interfaces
4. **Centralized base URL** - use environment variable or shared constant
5. **Consistent error handling** - throw typed errors, not raw Response objects
6. **No direct DOM or React dependencies** - services are framework-agnostic

## Shared API Client

```tsx
// src/shared/services/apiClient.ts
const API_BASE = import.meta.env.VITE_API_BASE_URL ?? '/api/v1';

export class ApiError extends Error {
  constructor(message: string, public status: number, public detail?: string) {
    super(message);
    this.name = 'ApiError';
  }
}

async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new ApiError(body.detail ?? response.statusText, response.status, body.detail);
  }
  return response.json();
}

export async function apiGet<T>(path: string): Promise<T> {
  const response = await fetch(`${API_BASE}${path}`);
  return handleResponse<T>(response);
}

export async function apiPost<T>(path: string, data: unknown): Promise<T> {
  const response = await fetch(`${API_BASE}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return handleResponse<T>(response);
}

export async function apiPatch<T>(path: string, data: unknown): Promise<T> {
  const response = await fetch(`${API_BASE}${path}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  return handleResponse<T>(response);
}

export async function apiDelete(path: string): Promise<void> {
  const response = await fetch(`${API_BASE}${path}`, { method: 'DELETE' });
  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new ApiError(body.detail ?? response.statusText, response.status, body.detail);
  }
}
```

Rules:
- Generic type parameter on response helpers for type safety
- `ApiError` class carries status code and server detail
- Base URL from environment variable with fallback

## Feature Service (CRUD)

```tsx
// src/features/recipes/services/recipeService.ts
import { apiGet, apiPost, apiPatch, apiDelete } from '@/shared/services/apiClient';
import type { Recipe, CreateRecipeRequest, UpdateRecipeRequest } from '../types/recipe.types';

export async function getRecipes(): Promise<Recipe[]> {
  return apiGet<Recipe[]>('/recipes');
}

export async function getRecipeById(id: string): Promise<Recipe> {
  return apiGet<Recipe>(`/recipes/${id}`);
}

export async function createRecipe(data: CreateRecipeRequest): Promise<Recipe> {
  return apiPost<Recipe>('/recipes', data);
}

export async function updateRecipe(id: string, data: UpdateRecipeRequest): Promise<Recipe> {
  return apiPatch<Recipe>(`/recipes/${id}`, data);
}

export async function deleteRecipe(id: string): Promise<void> {
  return apiDelete(`/recipes/${id}`);
}
```

Rules:
- One exported function per API endpoint
- Function name matches the HTTP action: `get`, `create`, `update`, `delete`
- Accept typed request objects, return typed response objects
- Use the shared `apiClient` helpers (not raw `fetch`)

## Service with Authentication

```tsx
// src/shared/services/apiClient.ts (extended)
export async function apiGetAuth<T>(path: string, token: string): Promise<T> {
  const response = await fetch(`${API_BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
  });
  return handleResponse<T>(response);
}
```

Rules:
- Pass the token explicitly (do not read from localStorage inside the service)
- Hooks or middleware provide the token, services consume it

## Testing

> See [service-testing.md](service-testing.md) for full testing examples with Vitest and fetch mocking.

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|-------------|-----------------|
| Inline `fetch` in hooks/components | Delegate to a service function |
| Hardcoded base URL | Environment-driven: `import.meta.env.VITE_API_BASE_URL` |
| Swallowing errors (returning `[]` on failure) | Throw typed `ApiError`, let caller decide |
| Reading auth token from localStorage in service | Accept token as parameter |
| Returning raw `Response` objects | Return parsed, typed data |

## Cross-References

- See `hook.md` for how hooks consume service functions via TanStack Query
- See `types.md` for request/response type definitions
- See `component.md` for how components handle errors from hooks/services
