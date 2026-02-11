# Profile: react-typescript

React frontend with TypeScript, Vitest, and TanStack Query.

## Detection

How Atelier identifies a project as react-typescript:

```yaml
markers:
  required:
    - package.json
  content_match:
    - file: package.json
      pattern: "react"
    - file: tsconfig.json
      pattern: "compilerOptions"
  optional:
    - tsconfig.json
    - next.config.js
    - vite.config.ts
    - src/App.tsx
```

If `package.json` exists AND contains the string `react`, and `tsconfig.json` contains `compilerOptions`, this profile activates.

---

## Stack

| Component        | Requirement                      |
|------------------|----------------------------------|
| **Language**     | TypeScript >= 5.0                |
| **Framework**    | React >= 18                      |
| **Build**        | Vite or Next.js                  |
| **State**        | React Query (TanStack Query) + Zustand |
| **HTTP**         | fetch or axios                   |
| **Routing**      | React Router or Next.js App Router |
| **Testing**      | Vitest + React Testing Library   |
| **Quality**      | ESLint, Prettier, tsc            |

---

## Architecture Layers

Ordered outside-in (the order you read contracts, write tests, and build implementation).

| # | Layer           | Responsibility                                                                                     |
|---|-----------------|----------------------------------------------------------------------------------------------------|
| 1 | **Component**   | React components, pages, layouts, UI rendering, props interfaces, event handling                    |
| 2 | **Hook**        | Custom hooks, data fetching (useQuery/useMutation), local state management (Zustand), side effects |
| 3 | **Service**     | API client functions, data transformations, request/response mapping, business logic               |
| 4 | **Types**       | TypeScript interfaces, API response types, shared types, enums, constants                          |

---

## Build Order

```
Component --> Hook --> Service --> Types
```

**Rationale:** Start from the user-facing UI contract (what the user sees and interacts with) and drive implementation inward from requirements, not from the API schema.

**Note:** If the feature requires new API types, define placeholder types first so the Component layer compiles, then refine them in the Types layer.

---

## Quality Tools

```yaml
tools:
  test_runner:
    command: "npx vitest run"
    single_file: "npx vitest run {file}"
    verbose: "npx vitest run --reporter=verbose"
    coverage: "npx vitest run --coverage"
    confirm_red: "npx vitest run {test_file}"
    confirm_green: "npx vitest run {test_file}"

  linter:
    command: "npx eslint src/"
    fix: "npx eslint --fix src/"

  type_checker:
    command: "npx tsc --noEmit"

  formatter:
    command: "npx prettier --write src/"
    check: "npx prettier --check src/"
```

### Verify Step (run after every layer)

```bash
npx vitest run {test_file} && npx eslint src/ && npx tsc --noEmit
```

All three must pass before a layer is considered complete.

---

## Allowed Bash Tools

For use in command and agent frontmatter `allowed-tools` fields:

```
Bash(npx:*), Bash(npm:*), Bash(node:*), Bash(git:*), Bash(uuidgen)
```

---

## Test Patterns

### What Gets Tested First (TDD Applicability)

| Layer     | Test First? | Mock Target        | Rationale                                               |
|-----------|-------------|--------------------|---------------------------------------------------------|
| Component | YES         | Hooks              | Contract-driven; validates UI rendering and interactions |
| Hook      | YES         | Services           | Data flow and state transitions verified in isolation    |
| Service   | YES         | fetch/axios (MSW)  | API integration verified without network                 |
| Types     | NO          | --                 | TypeScript compiler validates types at build time        |

### Mocking Strategy

Each layer mocks the layer directly below it. Never mock two layers down.

```
Component Tests --> Mock Hooks (vi.mock)
Hook Tests      --> Mock Services
Service Tests   --> Mock fetch/axios (MSW or vi.mock)
```

### Test Organization

```yaml
test_patterns:
  unit:
    location: "src/__tests__/" or co-located "*.test.ts"
    naming: "*.test.ts, *.test.tsx"
    pattern: "describe-it with AAA (Arrange, Act, Assert)"
    markers: []
  component:
    location: "src/__tests__/components/" or co-located
    naming: "*.test.tsx"
    markers: []
  integration:
    location: "src/__tests__/integration/"
    naming: "*.integration.test.ts"
    markers: []
  e2e:
    location: "e2e/" or "cypress/"
    naming: "*.spec.ts"
    markers: []
```

### Test Function Naming

```
describe('{ComponentOrModule}', () => {
  it('should {expected behavior} when {scenario}', () => { ... });
});
```

Examples:
- `it('should render recipe title when recipe is loaded')`
- `it('should show error message when API call fails')`
- `it('should call createRecipe when form is submitted')`

---

## Naming Conventions

```yaml
naming:
  files: "PascalCase.tsx (components), camelCase.ts (utils/hooks/services)"
  classes: "PascalCase (rarely used, prefer functions)"
  functions: "camelCase"
  constants: "UPPER_SNAKE_CASE"
  test_files: "*.test.ts or *.test.tsx"
  private: "no convention (module-scoped by default)"
  components: "PascalCase (function components)"
  hooks: "use{Name} prefix"
  types: "PascalCase (interfaces and types)"
```

---

## Code Patterns

### Component Pattern

```tsx
// src/features/recipes/components/RecipeCard.tsx
interface RecipeCardProps {
  recipe: Recipe;
  onDelete: (id: string) => void;
}

export function RecipeCard({ recipe, onDelete }: RecipeCardProps) {
  return (
    <div className="recipe-card">
      <h3>{recipe.title}</h3>
      <p>{recipe.description}</p>
      <button onClick={() => onDelete(recipe.id)}>Delete</button>
    </div>
  );
}
```

Rules:
- Props interface defined above component in same file
- Named exports (not default exports)
- Functional components only (no class components)
- Destructure props in function signature
- Keep components focused: one responsibility per component

### Hook Pattern

```tsx
// src/features/recipes/hooks/useRecipes.ts
import { useQuery } from '@tanstack/react-query';
import { getRecipes } from '../services/recipeService';
import type { Recipe } from '../types/recipe.types';

export function useRecipes() {
  return useQuery<Recipe[]>({
    queryKey: ['recipes'],
    queryFn: getRecipes,
  });
}
```

Rules:
- Prefix with `use` (React convention)
- One hook per file for feature-specific hooks
- Return typed values from TanStack Query
- Encapsulate query keys (consumers should not construct keys manually)

### Service Pattern

```tsx
// src/features/recipes/services/recipeService.ts
import type { Recipe, CreateRecipeRequest } from '../types/recipe.types';

const API_BASE = '/api/v1';

export async function getRecipes(): Promise<Recipe[]> {
  const response = await fetch(`${API_BASE}/recipes`);
  if (!response.ok) throw new Error('Failed to fetch recipes');
  return response.json();
}

export async function createRecipe(data: CreateRecipeRequest): Promise<Recipe> {
  const response = await fetch(`${API_BASE}/recipes`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!response.ok) throw new Error('Failed to create recipe');
  return response.json();
}
```

Rules:
- Pure async functions (no React hooks or state)
- Accept and return typed data (TypeScript interfaces)
- Handle HTTP errors with descriptive messages
- Base URL configurable via environment variable or constant
- No direct DOM or React dependencies

### Types Pattern

```tsx
// src/features/recipes/types/recipe.types.ts
export interface Recipe {
  id: string;
  title: string;
  description: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateRecipeRequest {
  title: string;
  description: string;
}

export interface UpdateRecipeRequest {
  title?: string;
  description?: string;
}
```

Rules:
- Use `interface` for object shapes (extendable)
- Use `type` for unions, intersections, and computed types
- Suffix API types with `Request` / `Response`
- Use `string` for dates coming from APIs (parse at the boundary)
- Co-locate types with the feature that owns them

---

## Style Limits

```yaml
limits:
  max_function_lines: 30
  max_file_lines: 300
  max_component_lines: 150
  max_parameters: 5
  max_nesting_depth: 3
```

If a function exceeds 30 lines, extract a helper. If a file exceeds 300 lines, split into modules. If a component exceeds 150 lines, break it into subcomponents. If nesting exceeds 3 levels, use early returns or extract logic.

---

## Dependencies

```yaml
dependencies:
  manager: "npm"
  install: "npm install"
  add: "npm install {pkg}"
  add_dev: "npm install -D {pkg}"
  lock_file: "package-lock.json"
```

---

## Project Structure

```yaml
structure:
  source_root: "src/"
  test_root: "src/__tests__/"
  config_files:
    - package.json
    - tsconfig.json
    - vite.config.ts
  entry_point: "src/main.tsx"
```

### Expected Directory Layout

```
project-root/
  package.json
  tsconfig.json
  vite.config.ts
  src/
    main.tsx
    App.tsx
    features/
      {feature}/
        components/
          {Feature}Page.tsx
          {Feature}Card.tsx
        hooks/
          use{Feature}.ts
          use{Feature}List.ts
        services/
          {feature}Service.ts
        types/
          {feature}.types.ts
        __tests__/
          {Feature}Page.test.tsx
          use{Feature}.test.ts
          {feature}Service.test.ts
    shared/
      components/
      hooks/
      types/
      utils/
```

---

## Pattern Files Reference

Detailed pattern files live alongside this profile for use by code-generation skills:

```
profiles/react-typescript/patterns/
  component.md    # Full component pattern with examples
  hook.md         # Full hook pattern with examples
  service.md      # Full service pattern with examples
  types.md        # Full types pattern with examples
```

Commands and agents reference these patterns by path:
```
$PROFILE_DIR/patterns/component.md
$PROFILE_DIR/patterns/hook.md
$PROFILE_DIR/patterns/service.md
$PROFILE_DIR/patterns/types.md
```

Where `$PROFILE_DIR` resolves to `profiles/react-typescript/` for this profile.

---

## Profile Metadata

```yaml
metadata:
  name: react-typescript
  version: "1.0.0"
  description: "React frontend with TypeScript, Vitest, and TanStack Query"
  authors: ["atelier"]
  tags: ["typescript", "react", "vite", "frontend", "web"]
```
