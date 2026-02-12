# Component Pattern

React functional components with typed props, named exports, and single-responsibility design.

## Location

`src/features/{feature}/components/{Feature}Page.tsx` - Page-level components
`src/features/{feature}/components/{Feature}Card.tsx` - Presentational components
`src/shared/components/{Component}.tsx` - Shared/reusable components

## Key Rules

1. **Contract-first**: Define props interface before writing the component
2. **Named exports only** - no `export default` (enables consistent imports and refactoring)
3. **Functional components** - no class components
4. **Destructure props** - in the function signature, not inside the body
5. **Single responsibility** - one visual concern per component
6. **Co-locate styles** - CSS modules or Tailwind classes alongside the component

## Props Interface

Props interfaces are always defined directly above the component in the same file. For shared or reusable components, the interface may be exported.

```tsx
// src/features/recipes/components/RecipeCard.tsx
interface RecipeCardProps {
  recipe: Recipe;
  onDelete: (id: string) => void;
  isLoading?: boolean;
}
```

Rules:
- Name as `{Component}Props`
- Required props have no `?` suffix
- Optional props use `?` with sensible defaults in destructuring
- Callback props use `on{Action}` naming (e.g., `onClick`, `onSubmit`, `onDelete`)
- Avoid passing more than 5 props; if needed, group into an object

## Page Component (with Hooks)

Page components orchestrate data fetching and render child components.

```tsx
// src/features/recipes/components/RecipesPage.tsx
import { useRecipes } from '../hooks/useRecipes';
import { useDeleteRecipe } from '../hooks/useDeleteRecipe';
import { RecipeCard } from './RecipeCard';
import { LoadingSpinner } from '@/shared/components/LoadingSpinner';
import { ErrorMessage } from '@/shared/components/ErrorMessage';

export function RecipesPage() {
  const { data: recipes, isLoading, error } = useRecipes();
  const deleteRecipe = useDeleteRecipe();

  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorMessage message={error.message} />;

  return (
    <div className="recipes-page">
      <h1>Recipes</h1>
      <div className="recipe-grid">
        {recipes?.map((recipe) => (
          <RecipeCard
            key={recipe.id}
            recipe={recipe}
            onDelete={(id) => deleteRecipe.mutate(id)}
          />
        ))}
      </div>
    </div>
  );
}
```

Rules:
- Hooks at the top of the component body
- Handle loading, error, and empty states explicitly
- Delegate data fetching to custom hooks (never call `fetch` directly)
- Pass callbacks down to presentational components

## Presentational Component (Pure)

Presentational components receive data via props and render UI. They contain no hooks or side effects.

```tsx
// src/features/recipes/components/RecipeCard.tsx
import type { Recipe } from '../types/recipe.types';

interface RecipeCardProps {
  recipe: Recipe;
  onDelete: (id: string) => void;
}

export function RecipeCard({ recipe, onDelete }: RecipeCardProps) {
  return (
    <article className="recipe-card">
      <h3>{recipe.title}</h3>
      <p>{recipe.description}</p>
      <footer>
        <time dateTime={recipe.createdAt}>
          {new Date(recipe.createdAt).toLocaleDateString()}
        </time>
        <button
          type="button"
          onClick={() => onDelete(recipe.id)}
          aria-label={`Delete ${recipe.title}`}
        >
          Delete
        </button>
      </footer>
    </article>
  );
}
```

Rules:
- No `useState`, `useEffect`, or data-fetching hooks
- Receives all data through props
- Semantic HTML elements (`article`, `header`, `footer`, `time`)
- Accessible: `aria-label` on interactive elements, `type="button"` on non-submit buttons

## Form Components

For form component patterns, see `reference/component-examples.md`.

Form rules:
- Form state is local (`useState`), not global
- `onSubmit` callback is passed as a prop (parent owns the mutation)
- Disable submit button while submitting
- Use `htmlFor` (not `for`) to associate labels with inputs
- Use controlled inputs (`value` + `onChange`)

## Testing

See `reference/component-examples.md` for a full component test example.

Testing rules:
- Use `screen` queries (not destructured `getBy` from `render`)
- Prefer `getByRole` and `getByText` over `getByTestId`
- Use `userEvent` (not `fireEvent`) for user interactions
- Mock callbacks with `vi.fn()`
- AAA pattern: Arrange (setup), Act (interact), Assert (verify)

## Anti-Patterns

Key mistakes to avoid:
- Using `export default` instead of named exports
- Inline props types instead of a named `Props` interface
- Fetching data inside presentational components
- Components doing too much (fetching + rendering + form handling in one)

See `reference/component-examples.md` for detailed anti-pattern examples.

## Cross-References

- See `hook.md` for custom hook patterns (data fetching, state)
- See `types.md` for props interface and shared type definitions
- See `service.md` for API client functions called by hooks
