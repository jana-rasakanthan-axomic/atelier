# Profile Specification

Profiles are markdown files that define stack-specific tooling for Atelier's process-agnostic commands. They answer "which tools do I use?" while commands answer "what steps do I follow?"

The process (TDD, outside-in build, PR review) never changes. Only the instruments do.

---

## Profile Anatomy

Every profile file (`profiles/{name}.md`) contains these sections:

| Section | Required | Description |
|---------|----------|-------------|
| **Detection** | Yes | Marker files and content patterns for auto-discovery. At least one required marker. |
| **Architecture Layers** | Yes | Ordered list of layers (name, test_dir, src_dir, description). Outside-in: user-facing first, persistence last. |
| **Build Order** | Yes | The sequence layers are built during `/build`. Must match the layers list. |
| **Quality Tools** | Yes | Concrete commands for `test_runner`, `linter`, `type_checker`, `formatter`. Minimum: test_runner + linter. |
| **Allowed Bash Tools** | Yes | Tool permissions for command/agent frontmatter (e.g., `Bash(pytest:*)`). |
| **Test Patterns** | Yes | Unit, integration, and e2e test locations, naming conventions, and structure patterns (AAA, Given-When-Then, etc.). |
| **Naming Conventions** | Yes | Rules for files, classes, functions, test files, constants, and private members. |
| **Code Patterns** | Yes | Reference to `profiles/{name}/patterns/` directory. One pattern file per architecture layer. |
| **Style Limits** | Yes | Numeric limits: max function lines, max file lines, max parameters, max nesting depth. |
| **Dependencies** | Yes | Package manager commands: install, add, add_dev, lock file path. |
| **Project Structure** | Yes | Source root, test root, config files, entry point, expected directory layout. |

---

## Detection

Detection tells `scripts/resolve-profile.sh` how to identify a project's stack.

```yaml
markers:
  required:      # Files that MUST exist (e.g., ["pyproject.toml"])
  optional:      # Files that confirm the match (e.g., ["alembic.ini"])
  content_match: # Patterns inside marker files
    - file: "pyproject.toml"
      pattern: "fastapi"
```

A profile matches when all `required` markers exist and all `content_match` patterns are found. Optional markers increase confidence but are not required.

---

## Architecture Layers

Layers define the building blocks of the stack, ordered outside-in (user-facing first).

```yaml
layers:
  - name: "router"
    test_dir: "tests/unit/api/"
    src_dir: "src/api/"
    description: "API endpoints and request/response schemas"
  - name: "service"
    test_dir: "tests/unit/services/"
    src_dir: "src/services/"
    description: "Business logic, orchestration, DTOs"
```

Commands like `/build` iterate through layers in this order. Each layer gets its own TDD cycle (RED -> GREEN -> VERIFY) before the next layer begins.

---

## Quality Tools

The concrete CLI commands that process-agnostic commands invoke via `${profile.tools.*}`:

```yaml
tools:
  test_runner:
    command: "pytest"               # Base command
    single_file: "pytest {file} -v" # Run one test file
    verbose: "pytest -v"            # Verbose output
    coverage: "pytest --cov=src"    # With coverage
  linter:
    command: "ruff check src/"
    fix: "ruff check --fix src/"
  type_checker:
    command: "mypy src/"
  formatter:
    command: "ruff format src/"
    check: "ruff format --check src/"
```

Commands reference these as `${profile.test_runner}`, `${profile.linter}`, etc. The profile resolves the reference to the concrete command for the active stack.

---

## Built-in Profiles

| Profile | Marker File | Content Match | Layers | Key Tools |
|---------|-------------|---------------|--------|-----------|
| `python-fastapi` | `pyproject.toml` | `"fastapi"` in pyproject.toml | Router -> Service -> Repository -> External -> Models | pytest, ruff, mypy |
| `flutter-dart` | `pubspec.yaml` | `"flutter"` in pubspec.yaml | Screen -> Notifier -> Repository -> Model | flutter test, dart analyze, dart format |
| `react-typescript` | `package.json` | `"react"` in package.json + `tsconfig.json` | Page -> Component -> Hook -> Service -> Model | vitest, eslint, tsc |
| `opentofu-hcl` | `*.tf` | (none) | Module -> Resource -> Data -> Variable | tofu validate, tflint, tofu fmt |

Each profile has a companion patterns directory (e.g., `profiles/python-fastapi/patterns/`) with layer-specific code generation templates.

---

## Creating a New Profile

1. Copy the canonical template: `cp profiles/_template.md profiles/{name}.md`
2. Fill in every section (no `[...]` placeholders or `# TODO:` comments should remain).
3. Create `profiles/{name}/patterns/` with one pattern file per architecture layer.
4. Add detection logic to `scripts/resolve-profile.sh`.
5. Register the profile in `CLAUDE.md` under "Built-in Profiles".

See `docs/CONTRIBUTING.md` "Adding a New Profile" for the full step-by-step walkthrough.

---

## Multi-Stack Workspaces

Projects spanning multiple stacks use `.atelier/config.yaml` to map subdirectories to profiles:

```yaml
# .atelier/config.yaml
workspace:
  repos:
    backend:
      path: ./backend
      profile: python-fastapi
    client:
      path: ./client
      profile: flutter-dart
    web:
      path: ./web
      profile: react-typescript
    infra:
      path: ./infra
      profile: opentofu-hcl
```

Commands auto-resolve the correct profile based on which subdirectory they operate in. A `/build` invoked within `backend/` loads `python-fastapi`; the same `/build` within `client/` loads `flutter-dart`. No manual switching is needed.

---

## Profile Resolution

Resolution follows a 3-step priority order (first match wins):

| Step | Method | Mechanism |
|------|--------|-----------|
| 1 | **Explicit config** | `.atelier/config.yaml` contains a `profile:` field. Highest priority -- overrides auto-detection. |
| 2 | **Auto-detect** | `scripts/resolve-profile.sh` examines marker files in the working directory. Checks required markers and content match patterns against each built-in profile in order. |
| 3 | **User prompt** | If no profile matches (or multiple are ambiguous), the command asks the user to select a profile. |

### Auto-Detection Order

The resolve script checks profiles in this order:

1. `python-fastapi` -- pyproject.toml + "fastapi" content
2. `flutter-dart` -- pubspec.yaml
3. `react-typescript` -- package.json + "react" + tsconfig.json
4. `opentofu-hcl` -- any *.tf file

First match wins. To override, use `.atelier/config.yaml`.

### Verifying Resolution

```bash
# Check which profile is detected for the current directory
scripts/resolve-profile.sh

# Verbose mode shows detection reasoning
scripts/resolve-profile.sh --verbose

# Check a specific directory
scripts/resolve-profile.sh --dir /path/to/project
```

---

## How Commands Consume Profiles

```
/build .claude/plans/PROJ-123.md
  |
  +-- 1. Resolve profile         -> python-fastapi
  +-- 2. Read profile             -> profiles/python-fastapi.md
  |     +-- layers, tools, naming, patterns
  +-- 3. Execute TDD loop         (process from command)
  |     +-- RED:   ${profile.test_runner}   -> pytest -x --tb=short
  |     +-- GREEN: ${profile.test_runner}   -> pytest -v
  +-- 4. Quality gate             (process from command)
        +-- Lint:  ${profile.linter}        -> ruff check src/
        +-- Type:  ${profile.type_checker}  -> mypy src/
```

The process is identical across all profiles. Only the tool invocations change.
