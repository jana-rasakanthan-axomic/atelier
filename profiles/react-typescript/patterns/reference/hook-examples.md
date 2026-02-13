# Hook Pattern — Extended Examples

Reference examples for the hook pattern. See `../hook.md` for core rules.

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

Testing rules:
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
