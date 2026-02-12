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

For delete and update mutation hooks, see `reference/hook-examples.md`.

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

## Testing

See `reference/hook-examples.md` for a full hook test example with QueryClient setup.

## Anti-Patterns

Key mistakes to avoid:
- Using `useState` + `useEffect` + `fetch` instead of TanStack Query for server data
- Hardcoding query keys across files instead of using centralized constants
- Missing generics on `useMutation` calls
- Storing server state in Zustand instead of TanStack Query

See `reference/hook-examples.md` for detailed anti-pattern examples.

## Cross-References

- See `component.md` for how components consume hooks
- See `service.md` for API functions that hooks delegate to
- See `types.md` for shared type definitions used in generics
