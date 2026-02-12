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

| Type | Location | Naming |
|------|----------|--------|
| Unit | `src/__tests__/` or co-located | `*.test.ts`, `*.test.tsx` |
| Component | `src/__tests__/components/` or co-located | `*.test.tsx` |
| Integration | `src/__tests__/integration/` | `*.integration.test.ts` |
| E2E | `e2e/` or `cypress/` | `*.spec.ts` |

Pattern: `describe-it` with AAA (Arrange, Act, Assert). Naming: `it('should {behavior} when {scenario}')`

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

> See [patterns/component.md](patterns/component.md) for the Component pattern with examples.

> See [patterns/hook.md](patterns/hook.md) for the Hook pattern with examples.

> See [patterns/service.md](patterns/service.md) for the Service pattern with examples.

> See [patterns/types.md](patterns/types.md) for the Types pattern with examples.

Commands and agents reference these patterns by path: `$PROFILE_DIR/patterns/{layer}.md`

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

Source root: `src/` | Test root: `src/__tests__/` | Entry: `src/main.tsx` | Config: `package.json`, `tsconfig.json`, `vite.config.ts`

```
project-root/
  src/
    main.tsx, App.tsx
    features/{feature}/ -> components/, hooks/, services/, types/, __tests__/
    shared/ -> components/, hooks/, types/, utils/
```

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
