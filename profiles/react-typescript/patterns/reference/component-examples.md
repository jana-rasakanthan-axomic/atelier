# Component Pattern — Extended Examples

Reference examples for the component pattern. See `../component.md` for core rules.

## Form Component

```tsx
// src/features/recipes/components/RecipeForm.tsx
import { useState } from 'react';
import type { CreateRecipeRequest } from '../types/recipe.types';

interface RecipeFormProps {
  onSubmit: (data: CreateRecipeRequest) => void;
  isSubmitting: boolean;
}

export function RecipeForm({ onSubmit, isSubmitting }: RecipeFormProps) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    onSubmit({ title, description });
  }

  return (
    <form onSubmit={handleSubmit}>
      <label htmlFor="title">Title</label>
      <input
        id="title"
        type="text"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        required
      />

      <label htmlFor="description">Description</label>
      <textarea
        id="description"
        value={description}
        onChange={(e) => setDescription(e.target.value)}
      />

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Saving...' : 'Save Recipe'}
      </button>
    </form>
  );
}
```

Form rules:
- Form state is local (`useState`), not global
- `onSubmit` callback is passed as a prop (parent owns the mutation)
- Disable submit button while submitting
- Use `htmlFor` (not `for`) to associate labels with inputs
- Use controlled inputs (`value` + `onChange`)

## Testing a Component

```tsx
// src/features/recipes/__tests__/RecipeCard.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { RecipeCard } from '../components/RecipeCard';
import type { Recipe } from '../types/recipe.types';

const mockRecipe: Recipe = {
  id: '1',
  title: 'Pasta Carbonara',
  description: 'Classic Italian pasta dish',
  createdAt: '2024-01-15T10:00:00Z',
  updatedAt: '2024-01-15T10:00:00Z',
};

describe('RecipeCard', () => {
  it('should render recipe title and description', () => {
    render(<RecipeCard recipe={mockRecipe} onDelete={vi.fn()} />);

    expect(screen.getByText('Pasta Carbonara')).toBeInTheDocument();
    expect(screen.getByText('Classic Italian pasta dish')).toBeInTheDocument();
  });

  it('should call onDelete with recipe id when delete is clicked', async () => {
    const onDelete = vi.fn();
    const user = userEvent.setup();

    render(<RecipeCard recipe={mockRecipe} onDelete={onDelete} />);
    await user.click(screen.getByRole('button', { name: /delete/i }));

    expect(onDelete).toHaveBeenCalledWith('1');
  });
});
```

Testing rules:
- Use `screen` queries (not destructured `getBy` from `render`)
- Prefer `getByRole` and `getByText` over `getByTestId`
- Use `userEvent` (not `fireEvent`) for user interactions
- Mock callbacks with `vi.fn()`
- AAA pattern: Arrange (setup), Act (interact), Assert (verify)

## Anti-Patterns

```tsx
// BAD: Default export
export default function RecipeCard() { ... }

// GOOD: Named export
export function RecipeCard() { ... }

// BAD: Inline props type
export function RecipeCard(props: { recipe: Recipe; onDelete: (id: string) => void }) { ... }

// GOOD: Props interface
interface RecipeCardProps { recipe: Recipe; onDelete: (id: string) => void; }
export function RecipeCard({ recipe, onDelete }: RecipeCardProps) { ... }

// BAD: Fetching data inside a presentational component
export function RecipeCard({ id }: { id: string }) {
  const { data } = useQuery({ queryKey: ['recipe', id], queryFn: () => getRecipe(id) });
  return <div>{data?.title}</div>;
}

// GOOD: Receive data via props
export function RecipeCard({ recipe }: RecipeCardProps) {
  return <div>{recipe.title}</div>;
}

// BAD: Component doing too much (fetching + rendering + form handling)
export function RecipesPage() {
  const [recipes, setRecipes] = useState([]);
  useEffect(() => { fetch('/api/recipes').then(...) }, []);
  // ... 200 lines of mixed concerns
}

// GOOD: Delegate to hooks and child components
export function RecipesPage() {
  const { data: recipes, isLoading } = useRecipes();
  if (isLoading) return <LoadingSpinner />;
  return <RecipeList recipes={recipes ?? []} />;
}
```
