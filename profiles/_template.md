# Profile: [STACK_NAME]

<!--
  TEMPLATE — Copy this file to create a new profile.
  Replace every [...] placeholder and "# TODO:" comment with real values.
  Delete this comment block when done.
-->

---

## How to Create a New Profile

1. **Copy this template** to `profiles/[name].md` (e.g., `profiles/fastapi-python.md`).
2. **Fill in detection markers** so the profile can be auto-discovered from project files.
3. **Define architecture layers** in outside-in order (user-facing first, persistence last).
4. **Configure quality tools** — test runner, linter, type checker, formatter.
5. **Set test patterns** — where tests live, how they are named, what structure they follow.
6. **Document naming conventions** — file names, classes, functions, test files.
7. **Create a patterns directory** at `profiles/[name]/patterns/` and add layer-specific
   code generation patterns (router.md, service.md, repository.md, etc.).
8. **Validate** — ensure every placeholder is replaced and no `# TODO:` comments remain.

---

## Detection

<!-- How commands auto-detect this profile from project files. -->
<!-- At least one required marker must be present for the profile to match. -->

```yaml
markers:
  required: []          # Files that MUST exist for this profile to match
                        # e.g., ["pyproject.toml"], ["pubspec.yaml"], ["package.json"]

  optional: []          # Files that help confirm the match but are not required
                        # e.g., ["alembic.ini", "src/main.py"], ["lib/main.dart"]

  content_match: []     # Content patterns found inside marker files
                        # Format: "pattern" in filename
                        # e.g., ["fastapi" in "pyproject.toml", "flutter" in "pubspec.yaml"]
```

---

## Architecture Layers

<!-- Ordered list of layers for outside-in development. -->
<!-- First layer = closest to the user. Last layer = closest to the database/infra. -->
<!-- Commands like /build iterate through these in order. -->

```yaml
layers:
  - name: ""            # TODO: Layer name (e.g., "router", "controller", "widget")
    test_dir: ""        # TODO: Where tests for this layer live (e.g., "tests/unit/api/")
    src_dir: ""         # TODO: Where source for this layer lives (e.g., "src/api/")
    description: ""     # TODO: What this layer does (e.g., "API endpoints and request/response schemas")

  - name: ""            # TODO: Next layer (e.g., "service")
    test_dir: ""        # TODO: e.g., "tests/unit/services/"
    src_dir: ""         # TODO: e.g., "src/services/"
    description: ""     # TODO: e.g., "Business logic, orchestration, DTOs"

  - name: ""            # TODO: Next layer (e.g., "repository")
    test_dir: ""        # TODO: e.g., "tests/unit/repositories/"
    src_dir: ""         # TODO: e.g., "src/repositories/"
    description: ""     # TODO: e.g., "Data access, queries, persistence"

  # Add or remove layers as needed for your stack.
  # Common patterns:
  #   Backend API:  router -> service -> repository -> model
  #   Mobile app:   screen/widget -> bloc/provider -> repository -> model
  #   Full-stack:   page -> api-route -> service -> repository -> model
```

---

## Build Order

<!-- The order layers are built in during /build. -->
<!-- Outside-in: start from the user-facing contract, drive inward to persistence. -->
<!-- This MUST match the layers list above (top = built first). -->

```yaml
build_order:
  # TODO: List layer names in build order, e.g.:
  # - router        # 1st — API contract (what the user sees)
  # - service       # 2nd — Business logic (how it works)
  # - repository    # 3rd — Data access (where it's stored)
  # - model         # 4th — ORM entities (only if new tables needed)
```

---

## Quality Tools

<!-- Tools invoked by /fix, /build, and the verifier agent. -->
<!-- Every profile MUST define at least test_runner and linter. -->

```yaml
tools:
  test_runner:
    command: ""         # TODO: Base test command (e.g., "pytest", "flutter test", "jest")
    single_file: ""     # TODO: Run one test file (e.g., "pytest {file} -v", "flutter test {file}")
    verbose: ""         # TODO: Verbose output (e.g., "pytest -v", "jest --verbose")
    coverage: ""        # TODO: With coverage (e.g., "pytest --cov=src", "jest --coverage")

  linter:
    command: ""         # TODO: Lint command (e.g., "ruff check src/", "dart analyze", "eslint src/")
    fix: ""             # TODO: Auto-fix mode (e.g., "ruff check --fix src/", "eslint --fix src/")

  type_checker:
    command: ""         # TODO: Type check command (e.g., "mypy src/", "tsc --noEmit")
                        # Leave empty string if the stack has no separate type checker

  formatter:
    command: ""         # TODO: Format command (e.g., "ruff format src/", "dart format lib/", "prettier --write .")
    check: ""           # TODO: Check-only mode (e.g., "ruff format --check src/", "dart format --set-exit-if-changed lib/")
```

---

## Allowed Bash Tools

<!-- Permissions granted in commands/agents frontmatter. -->
<!-- These control which CLI tools agents are allowed to invoke via Bash. -->
<!-- Use the pattern: Bash(tool:*) for full access, Bash(tool:subcommand) for specific. -->

```yaml
allowed_tools: []
  # TODO: List allowed tools, e.g.:
  # - "Bash(pytest:*)"
  # - "Bash(ruff:*)"
  # - "Bash(mypy:*)"
  # - "Bash(uv:*)"
  # - "Bash(alembic:*)"
  # - "Bash(git:*)"
```

---

## Test Patterns

<!-- How tests are organized, named, and structured. -->
<!-- Used by /build (TDD), /build --loop (automated), and the verifier agent. -->

```yaml
test_patterns:
  unit:
    location: ""        # TODO: Directory for unit tests (e.g., "tests/unit/", "test/unit/")
    naming: ""          # TODO: File naming convention (e.g., "test_*.py", "*_test.dart", "*.test.ts")
    pattern: ""         # TODO: Test structure pattern (e.g., "AAA" for Arrange-Act-Assert,
                        #       "Given-When-Then", "describe-it")

  integration:
    location: ""        # TODO: Directory for integration tests (e.g., "tests/integration/")
    naming: ""          # TODO: File naming convention (e.g., "test_*.py", "*.integration.test.ts")

  e2e:
    location: ""        # TODO: Directory for end-to-end tests (e.g., "tests/e2e/", "integration_test/")
    naming: ""          # TODO: File naming convention (e.g., "test_*.py", "*_test.dart")
```

---

## Naming Conventions

<!-- File, class, function, and variable naming rules for this stack. -->
<!-- Used by code generation patterns and the reviewer agent. -->

```yaml
naming:
  files: ""             # TODO: Source file naming (e.g., "snake_case.py", "PascalCase.dart", "kebab-case.ts")
  classes: ""           # TODO: Class naming (e.g., "PascalCase", "PascalCase")
  functions: ""         # TODO: Function/method naming (e.g., "snake_case", "camelCase")
  test_files: ""        # TODO: Test file naming (e.g., "test_*.py", "*_test.dart", "*.test.ts")
  constants: ""         # TODO: Constant naming (e.g., "UPPER_SNAKE_CASE", "camelCase", "kPrefixed")
  private: ""           # TODO: Private member convention (e.g., "_prefixed", "#private", "no convention")
```

---

## Code Patterns

<!-- Reference to layer-specific code generation pattern files. -->
<!-- These are Markdown files that contain templates/examples for each layer. -->
<!-- Create them in the patterns directory when you create the profile. -->

```yaml
patterns_dir: "profiles/[name]/patterns/"
  # TODO: Replace [name] with the profile name.
  #
  # Expected pattern files (create the ones relevant to your stack):
  #   router.md       — API endpoint / route handler patterns
  #   service.md      — Business logic / use-case patterns
  #   repository.md   — Data access / query patterns
  #   model.md        — ORM entity / data model patterns
  #   schema.md       — Request/response schema patterns
  #   widget.md       — UI component patterns (mobile/frontend)
  #   bloc.md         — State management patterns (mobile/frontend)
  #   external.md     — Third-party integration / gateway patterns
```

---

## Style Limits

<!-- Code size and complexity limits enforced by the reviewer agent. -->
<!-- Adjust these to match your team's standards. -->

```yaml
limits:
  max_function_lines: 30    # TODO: Max lines per function/method (default: 30)
  max_file_lines: 300       # TODO: Max lines per source file (default: 300)
  max_parameters: 5         # TODO: Max parameters per function (default: 5)
  max_nesting_depth: 3      # TODO: Max nesting depth (default: 3)
```

---

## Dependencies

<!-- Package manager and dependency management commands. -->
<!-- Used by /setup, /build, and environment initialization. -->

```yaml
dependencies:
  manager: ""           # TODO: Package manager name (e.g., "uv", "pub", "npm", "pnpm", "cargo")
  install: ""           # TODO: Install all deps (e.g., "uv sync", "pub get", "npm install")
  add: ""               # TODO: Add a dependency (e.g., "uv add {pkg}", "pub add {pkg}", "npm install {pkg}")
  add_dev: ""           # TODO: Add a dev dependency (e.g., "uv add --dev {pkg}", "pub add --dev {pkg}", "npm install -D {pkg}")
  lock_file: ""         # TODO: Lock file name (e.g., "uv.lock", "pubspec.lock", "package-lock.json")
```

---

## Project Structure

<!-- Expected directory structure for this stack. -->
<!-- Used by /build to know where to place new files. -->

```yaml
structure:
  source_root: ""       # TODO: Root directory for source code (e.g., "src/", "lib/", "app/")
  test_root: ""         # TODO: Root directory for tests (e.g., "tests/", "test/")
  config_files: []      # TODO: Key config files (e.g., ["pyproject.toml", "alembic.ini"],
                        #       ["pubspec.yaml"], ["package.json", "tsconfig.json"])
  entry_point: ""       # TODO: Application entry point (e.g., "src/main.py", "lib/main.dart", "src/index.ts")
```
