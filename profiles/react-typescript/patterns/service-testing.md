# Service Testing Pattern

Extracted from service.md. Full examples for testing service functions with Vitest.

## Setup

Mock `global.fetch` (or use MSW for integration-level tests). Restore mocks in `beforeEach` to prevent test leakage.

## Full Example

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

## Rules

- Mock `global.fetch` (or use MSW for integration-level tests)
- Verify request URL, method, and body
- Test both success and error paths
- Restore mocks in `beforeEach` to prevent test leakage
- For MSW-based tests, set up request handlers in `beforeAll` and tear down in `afterAll`
