# Profile: python-fastapi

Python backend with FastAPI framework, SQLAlchemy ORM, and PostgreSQL.

## Detection

How Atelier identifies a project as python-fastapi:

```yaml
markers:
  required:
    - pyproject.toml
  content_match:
    - file: pyproject.toml
      pattern: "fastapi"
  optional:
    - alembic.ini
    - src/main.py
```

If `pyproject.toml` exists AND contains the string `fastapi`, this profile activates.

---

## Stack

| Component       | Requirement            |
|-----------------|------------------------|
| **Language**    | Python >= 3.11         |
| **Framework**   | FastAPI >= 0.104.0     |
| **ORM**         | SQLAlchemy >= 2.0.0    |
| **Validation**  | Pydantic >= 2.0        |
| **Database**    | PostgreSQL + Alembic   |
| **Testing**     | pytest >= 7.4.0, pytest-asyncio |
| **Quality**     | ruff, mypy (strict mode) |

---

## Architecture Layers

Ordered outside-in (the order you read contracts, write tests, and build implementation).

| # | Layer               | Responsibility                                                                 |
|---|---------------------|--------------------------------------------------------------------------------|
| 1 | **Router**          | FastAPI endpoints, Pydantic request/response schemas, dependency injection via `Depends()` |
| 2 | **Service**         | Business logic, UnitOfWork injection, domain exceptions, returns entities       |
| 3 | **Repository**      | Data access via SQLAlchemy `select()`, `flush()` not `commit()`, returns `Entity \| None` or `list[Entity]` |
| 4 | **External/Gateway**| Third-party HTTP clients, SDK wrappers, mock switching for tests               |
| 5 | **Models**          | SQLAlchemy ORM entities, mixins (built last, tested via integration tests)     |

---

## Build Order

```
Router --> Service --> Repository --> External/Gateway --> Models
```

**Rationale:** Start from the user-facing API contract and drive implementation inward from requirements, not from the database schema.

**Note:** If the layer requires schema changes, run `alembic revision --autogenerate` to create the migration *before* implementing the Models layer.

---

## Quality Tools

```yaml
tools:
  test_runner:
    command: "pytest"
    single_file: "pytest {file} -v"
    verbose: "pytest -v"
    coverage: "pytest --cov=src --cov-report=term-missing"
    confirm_red: "pytest {test_file} -x --tb=short"
    confirm_green: "pytest {test_file} -v"

  linter:
    command: "ruff check src/"
    fix: "ruff check --fix src/"

  type_checker:
    command: "mypy src/"

  formatter:
    command: "ruff format src/"
    check: "ruff format --check src/"
```

### Verify Step (run after every layer)

```bash
pytest {test_file} -v && ruff check src/ && mypy src/
```

All three must pass before a layer is considered complete.

---

## Allowed Bash Tools

```
Bash(pytest:*), Bash(ruff:*), Bash(mypy:*), Bash(git:*), Bash(uuidgen), Bash(alembic:*)
```

---

## Test Patterns

### What Gets Tested First (TDD Applicability)

| Layer            | Test First? | Mock Target          | Rationale                          |
|------------------|-------------|----------------------|------------------------------------|
| Router           | YES         | Service              | Contract-driven; validates API shape before logic exists |
| Service          | YES         | Repository + External| Business rules verified in isolation |
| Repository       | YES         | AsyncSession         | Data access logic verified without DB |
| External/Gateway | YES         | HTTP Client          | Third-party calls verified without network |
| Models (ORM)     | NO          | --                   | Covered by integration tests       |
| DTOs/Schemas     | NO          | --                   | Pydantic validation is sufficient  |
| Migrations       | NO          | --                   | Covered by integration tests       |

### Mocking Strategy

Each layer mocks the layer directly below it. Never mock two layers down.

```
Router Tests           --> Mock Service
Service Tests          --> Mock Repository + Mock External Services
Repository Tests       --> Mock AsyncSession
External Service Tests --> Mock HTTP Client (httpx / aiohttp)
```

### Test Organization

| Type | Location | Naming | Markers |
|------|----------|--------|---------|
| Unit | `tests/unit/` | `test_*.py` | -- |
| Integration | `tests/integration/` | `test_*.py` | `integration` |
| E2E | `tests/e2e/` | `test_*.py` | `e2e` |

Pattern: AAA (Arrange, Act, Assert). Naming: `test_{method}_{scenario}_{expected}`

---

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files | `snake_case.py` | `user_service.py` |
| Classes | `PascalCase` | `UserService` |
| Functions | `snake_case` | `create_user` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_RETRIES` |
| Test files | `test_{module}.py` | `test_service.py` |
| Test functions | `test_{method}_{scenario}_{expected}` | `test_create_user_with_valid_data_returns_user` |
| Schemas | `{Entity}Create`, `{Entity}Update`, `{Entity}Response` | `RecipeCreate` |
| Services | `{Entity}Service` | `RecipeService` |
| Repositories | `{Entity}Repository` | `RecipeRepository` |
| Routers | `{entity}_routes.py` | `recipe_routes.py` |

---

## Code Patterns

> See [patterns/router.md](profiles/python-fastapi/patterns/router.md) for the Router pattern with examples.

> See [patterns/service.md](profiles/python-fastapi/patterns/service.md) for the Service pattern with examples.

> See [patterns/repository.md](profiles/python-fastapi/patterns/repository.md) for the Repository pattern with examples.

> See [patterns/external.md](profiles/python-fastapi/patterns/external.md) for the External integration pattern.

> See [patterns/exceptions.md](profiles/python-fastapi/patterns/exceptions.md) for the Exception pattern.

> See [patterns/models.md](profiles/python-fastapi/patterns/models.md) for the ORM entity pattern.

Commands and agents reference these patterns by path: `$PROFILE_DIR/patterns/{layer}.md`

---

## Style Limits

```yaml
limits:
  max_function_lines: 30
  max_file_lines: 300
  max_class_lines: 200
  max_parameters: 5
  max_nesting_depth: 3
```

If a function exceeds 30 lines, extract a helper. If a file exceeds 300 lines, split into modules. If nesting exceeds 3 levels, use early returns or extract logic.

---

## Dependencies

```yaml
dependencies:
  manager: "uv"
  install: "uv sync"
  add: "uv add {package}"
  add_dev: "uv add --dev {package}"
  lock_file: "uv.lock"
  run: "uv run {command}"
```

---

## Project Structure

Source root: `src/` | Test root: `tests/` | Config: `pyproject.toml`, `alembic.ini` | Migrations: `alembic/versions/`

```
project-root/
  src/
    main.py, config.py
    db/session.py, db/repositories/
    api/{domain}/ -> routes.py, schemas.py, service.py, repository.py, exceptions.py
    models/{domain}.py
  tests/
    conftest.py
    unit/api/{domain}/ -> test_routes.py, test_service.py, test_repository.py
    integration/, e2e/
```

---

## Profile Metadata

```yaml
metadata:
  name: python-fastapi
  version: "1.0.0"
  description: "Python backend with FastAPI, SQLAlchemy, and PostgreSQL"
  authors: ["atelier"]
  tags: ["python", "fastapi", "sqlalchemy", "postgresql", "backend", "api"]
```
