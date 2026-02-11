# Hook Pattern

Custom React hooks for data fetching (TanStack Query), mutations, and local state management (Zustand).

## Location

`src/features/{feature}/hooks/use{Feature}.ts` - Feature-specific hooks
`src/features/{feature}/hooks/use{Feature}List.ts` - List/collection hooks
`src/shared/hooks/use{Hook}.ts` - Shared/reusable hooks

## Key Rules

1. **Contract-first**: Define the hook's return type and parameters before implementing
2. **`use` prefix** - all hooks must start with `use` (React convention)
3. **One hook per file** - for feature-specific hooks
4. **Encapsulate query keys** - consumers should never construct query keys manually
5. **Type all returns** - TanStack Query generics must be specified
6. **No direct fetch calls** - delegate to service functions

## Query Hook (Read Data)

```tsx
// src/features/recipes/hooks/useRecipes.ts
import { useQuery } from '@tanstack/react-query';
import { getRecipes } from '../services/recipeService';
import type { Recipe } from '../types/recipe.types';

const RECIPES_KEY = ['recipes'] as const;

export function useRecipes() {
  return useQuery<Recipe[]>({
    queryKey: RECIPES_KEY,
    queryFn: getRecipes,
  });
}
```

Rules:
- Define query key as a constant (enables cache invalidation from mutations)
- Specify the generic type parameter on `useQuery<T>`
- Point `queryFn` to a service function (not an inline fetch)
- Export the query key constant if other hooks need it for invalidation

## Query Hook with Parameters

```tsx
// src/features/recipes/hooks/useRecipe.ts
import { useQuery } from '@tanstack/react-query';
import { getRecipeById } from '../services/recipeService';
import type { Recipe } from '../types/recipe.types';

export function useRecipe(id: string) {
  return useQuery<Recipe>({
    queryKey: ['recipes', id],
    queryFn: () => getRecipeById(id),
    enabled: !!id,
  });
}
```

Rules:
- Include parameters in the query key array for proper caching
- Use `enabled` to prevent queries when parameters are missing
- Return the full `useQuery` result (let consumers decide what to destructure)

## Mutation Hook (Write Data)

```tsx
// src/features/recipes/hooks/useCreateRecipe.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { createRecipe } from '../services/recipeService';
import type { Recipe, CreateRecipeRequest } from '../types/recipe.types';

export function useCreateRecipe() {
  const queryClient = useQueryClient();

  return useMutation<Recipe, Error, CreateRecipeRequest>({
    mutationFn: createRecipe,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recipes'] });
    },
  });
}
```

Rules:
- Specify all three generics: `useMutation<TData, TError, TVariables>`
- Invalidate related queries on success
- Use `onSuccess` for cache invalidation, not for UI effects (components handle that)
- Point `mutationFn` to a service function

## Delete Mutation Hook

```tsx
// src/features/recipes/hooks/useDeleteRecipe.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { deleteRecipe } from '../services/recipeService';

export function useDeleteRecipe() {
  const queryClient = useQueryClient();

  return useMutation<void, Error, string>({
    mutationFn: deleteRecipe,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['recipes'] });
    },
  });
}
```

## Update Mutation Hook

```tsx
// src/features/recipes/hooks/useUpdateRecipe.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { updateRecipe } from '../services/recipeService';
import type { Recipe, UpdateRecipeRequest } from '../types/recipe.types';

interface UpdateRecipeVariables {
  id: string;
  data: UpdateRecipeRequest;
}

export function useUpdateRecipe() {
  const queryClient = useQueryClient();

  return useMutation<Recipe, Error, UpdateRecipeVariables>({
    mutationFn: ({ id, data }) => updateRecipe(id, data),
    onSuccess: (updatedRecipe) => {
      queryClient.invalidateQueries({ queryKey: ['recipes'] });
      queryClient.setQueryData(['recipes', updatedRecipe.id], updatedRecipe);
    },
  });
}
```

Rules:
- Use an interface for multi-field mutation variables
- Optimistically update the single-item cache with `setQueryData` when the server returns the updated entity

## Zustand Store Hook (Local State)

For UI state that does not come from the server (modals, filters, selections):

```tsx
// src/features/recipes/hooks/useRecipeFilters.ts
import { create } from 'zustand';

interface RecipeFiltersState {
  searchTerm: string;
  category: string | null;
  setSearchTerm: (term: string) => void;
  setCategory: (category: string | null) => void;
  reset: () => void;
}

export const useRecipeFilters = create<RecipeFiltersState>((set) => ({
  searchTerm: '',
  category: null,
  setSearchTerm: (term) => set({ searchTerm: term }),
  setCategory: (category) => set({ category }),
  reset: () => set({ searchTerm: '', category: null }),
}));
```

Rules:
- Use Zustand for client-only UI state (filters, selections, modals)
- Use TanStack Query for server state (API data)
- Never mix server state and client state in the same store
- Keep stores small and focused on a single concern

## Testing a Hook

```tsx
// src/features/recipes/__tests__/useRecipes.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { describe, it, expect, vi } from 'vitest';
import { useRecipes } from '../hooks/useRecipes';
import * as recipeService from '../services/recipeService';
import type { Recipe } from '../types/recipe.types';

vi.mock('../services/recipeService');

const mockRecipes: Recipe[] = [
  {
    id: '1',
    title: 'Pasta Carbonara',
    description: 'Classic Italian',
    createdAt: '2024-01-15T10:00:00Z',
    updatedAt: '2024-01-15T10:00:00Z',
  },
];

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    );
  };
}

describe('useRecipes', () => {
  it('should return recipes when fetch succeeds', async () => {
    vi.mocked(recipeService.getRecipes).mockResolvedValue(mockRecipes);

    const { result } = renderHook(() => useRecipes(), {
      wrapper: createWrapper(),
    });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    expect(result.current.data).toEqual(mockRecipes);
  });

  it('should return error when fetch fails', async () => {
    vi.mocked(recipeService.getRecipes).mockRejectedValue(
      new Error('Network error'),
    );

    const { result } = renderHook(() => useRecipes(), {
      wrapper: createWrapper(),
    });

    await waitFor(() => expect(result.current.isError).toBe(true));

    expect(result.current.error?.message).toBe('Network error');
  });
});
```

Rules:
- Mock the service layer, not `fetch` or `axios`
- Create a fresh `QueryClient` per test (prevents cache leakage)
- Wrap hooks in `QueryClientProvider` via a test wrapper
- Use `waitFor` for async assertions
- Disable retries in tests (`retry: false`)

## Anti-Patterns

```tsx
// BAD: Fetching inside a hook without TanStack Query
export function useRecipes() {
  const [recipes, setRecipes] = useState<Recipe[]>([]);
  useEffect(() => {
    fetch('/api/recipes').then(r => r.json()).then(setRecipes);
  }, []);
  return recipes;
}

// GOOD: Use TanStack Query
export function useRecipes() {
  return useQuery<Recipe[]>({ queryKey: ['recipes'], queryFn: getRecipes });
}

// BAD: Hardcoded query key scattered across files
useQuery({ queryKey: ['recipes'], ... });
// In another file:
queryClient.invalidateQueries({ queryKey: ['recipes'] });

// GOOD: Centralized query key constant
const RECIPES_KEY = ['recipes'] as const;
export function useRecipes() {
  return useQuery<Recipe[]>({ queryKey: RECIPES_KEY, queryFn: getRecipes });
}

// BAD: Missing generics on useMutation
useMutation({ mutationFn: createRecipe });

// GOOD: Explicit generics
useMutation<Recipe, Error, CreateRecipeRequest>({ mutationFn: createRecipe });

// BAD: Server state in Zustand
const useStore = create((set) => ({
  recipes: [],
  fetchRecipes: async () => { ... },
}));

// GOOD: Server state in TanStack Query, client state in Zustand
// TanStack Query for server data, Zustand for UI filters/selections
```

## Cross-References

- See `component.md` for how components consume hooks
- See `service.md` for API functions that hooks delegate to
- See `types.md` for shared type definitions used in generics
