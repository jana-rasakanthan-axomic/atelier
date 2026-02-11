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

A thin wrapper around `fetch` that handles base URL, headers, and error responses.

```tsx
// src/shared/services/apiClient.ts
const API_BASE = import.meta.env.VITE_API_BASE_URL ?? '/api/v1';

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public detail?: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new ApiError(
      body.detail ?? response.statusText,
      response.status,
      body.detail,
    );
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
  const response = await fetch(`${API_BASE}${path}`, {
    method: 'DELETE',
  });
  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new ApiError(
      body.detail ?? response.statusText,
      response.status,
      body.detail,
    );
  }
}
```

Rules:
- Generic type parameter on response helpers for type safety
- `ApiError` class carries status code and server detail
- Parse error body once, throw structured error
- Base URL from environment variable with fallback

## Feature Service (CRUD)

```tsx
// src/features/recipes/services/recipeService.ts
import { apiGet, apiPost, apiPatch, apiDelete } from '@/shared/services/apiClient';
import type {
  Recipe,
  CreateRecipeRequest,
  UpdateRecipeRequest,
} from '../types/recipe.types';

export async function getRecipes(): Promise<Recipe[]> {
  return apiGet<Recipe[]>('/recipes');
}

export async function getRecipeById(id: string): Promise<Recipe> {
  return apiGet<Recipe>(`/recipes/${id}`);
}

export async function createRecipe(data: CreateRecipeRequest): Promise<Recipe> {
  return apiPost<Recipe>('/recipes', data);
}

export async function updateRecipe(
  id: string,
  data: UpdateRecipeRequest,
): Promise<Recipe> {
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
- Keep functions stateless and side-effect-free (beyond the HTTP call)

## Service with Query Parameters

```tsx
// src/features/recipes/services/recipeService.ts
import { apiGet } from '@/shared/services/apiClient';
import type { Recipe, RecipeListParams } from '../types/recipe.types';

export async function searchRecipes(params: RecipeListParams): Promise<Recipe[]> {
  const searchParams = new URLSearchParams();

  if (params.query) searchParams.set('q', params.query);
  if (params.category) searchParams.set('category', params.category);
  if (params.limit) searchParams.set('limit', String(params.limit));
  if (params.offset) searchParams.set('offset', String(params.offset));

  const queryString = searchParams.toString();
  const path = queryString ? `/recipes?${queryString}` : '/recipes';

  return apiGet<Recipe[]>(path);
}
```

Rules:
- Use `URLSearchParams` for query string construction (handles encoding)
- Only include parameters that have values (avoid `?key=undefined`)
- Accept a typed params object, not individual arguments

## Service with Authentication

```tsx
// src/shared/services/apiClient.ts (extended)
export async function apiGetAuth<T>(
  path: string,
  token: string,
): Promise<T> {
  const response = await fetch(`${API_BASE}${path}`, {
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });
  return handleResponse<T>(response);
}
```

Rules:
- Pass the token explicitly (do not read from localStorage inside the service)
- Hooks or middleware provide the token, services consume it
- Keep services unaware of where the token comes from

## Testing a Service

```tsx
// src/features/recipes/__tests__/recipeService.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { getRecipes, createRecipe } from '../services/recipeService';
import type { Recipe, CreateRecipeRequest } from '../types/recipe.types';

const mockRecipe: Recipe = {
  id: '1',
  title: 'Pasta Carbonara',
  description: 'Classic Italian',
  createdAt: '2024-01-15T10:00:00Z',
  updatedAt: '2024-01-15T10:00:00Z',
};

describe('recipeService', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('should return recipes when getRecipes succeeds', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve([mockRecipe]),
    });

    const result = await getRecipes();

    expect(result).toEqual([mockRecipe]);
    expect(fetch).toHaveBeenCalledWith(
      expect.stringContaining('/recipes'),
    );
  });

  it('should throw ApiError when getRecipes fails', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 500,
      statusText: 'Internal Server Error',
      json: () => Promise.resolve({ detail: 'Server error' }),
    });

    await expect(getRecipes()).rejects.toThrow('Server error');
  });

  it('should send POST request when createRecipe is called', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve(mockRecipe),
    });

    const input: CreateRecipeRequest = {
      title: 'Pasta Carbonara',
      description: 'Classic Italian',
    };
    const result = await createRecipe(input);

    expect(result).toEqual(mockRecipe);
    expect(fetch).toHaveBeenCalledWith(
      expect.stringContaining('/recipes'),
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify(input),
      }),
    );
  });
});
```

Rules:
- Mock `global.fetch` (or use MSW for integration-level tests)
- Verify request URL, method, and body
- Test both success and error paths
- Restore mocks in `beforeEach` to prevent test leakage
- For MSW-based tests, set up request handlers in `beforeAll` and tear down in `afterAll`

## Anti-Patterns

```tsx
// BAD: Inline fetch in hooks or components
const { data } = useQuery({
  queryKey: ['recipes'],
  queryFn: () => fetch('/api/recipes').then(r => r.json()),
});

// GOOD: Delegate to a service function
const { data } = useQuery({
  queryKey: ['recipes'],
  queryFn: getRecipes,
});

// BAD: Hardcoded base URL
const response = await fetch('https://api.example.com/recipes');

// GOOD: Environment-driven base URL
const response = await fetch(`${API_BASE}/recipes`);

// BAD: Swallowing errors
export async function getRecipes(): Promise<Recipe[]> {
  try {
    const response = await fetch('/api/recipes');
    return response.json();
  } catch {
    return []; // Caller has no idea something failed
  }
}

// GOOD: Throw typed errors (let caller decide how to handle)
export async function getRecipes(): Promise<Recipe[]> {
  return apiGet<Recipe[]>('/recipes');
}

// BAD: Reading auth token from localStorage inside the service
const token = localStorage.getItem('token');

// GOOD: Accept token as a parameter
export async function getProtectedData(token: string): Promise<Data> {
  return apiGetAuth<Data>('/protected', token);
}

// BAD: Returning raw Response objects
export async function getRecipes(): Promise<Response> {
  return fetch('/api/recipes');
}

// GOOD: Return parsed, typed data
export async function getRecipes(): Promise<Recipe[]> {
  return apiGet<Recipe[]>('/recipes');
}
```

## Cross-References

- See `hook.md` for how hooks consume service functions via TanStack Query
- See `types.md` for request/response type definitions
- See `component.md` for how components handle errors from hooks/services
