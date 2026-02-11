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

For use in command and agent frontmatter `allowed-tools` fields:

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

```yaml
test_patterns:
  unit:
    location: "tests/unit/"
    naming: "test_*.py"
    pattern: "AAA (Arrange, Act, Assert)"
    markers: []
  integration:
    location: "tests/integration/"
    naming: "test_*.py"
    markers: ["integration"]
  e2e:
    location: "tests/e2e/"
    naming: "test_*.py"
    markers: ["e2e"]
```

### Test Function Naming

```
test_{method}_{scenario}_{expected}
```

Examples:
- `test_create_recipe_with_valid_data_returns_recipe`
- `test_create_recipe_with_duplicate_title_raises_conflict`
- `test_get_recipe_when_not_found_raises_not_found`

---

## Naming Conventions

```yaml
naming:
  files: "snake_case.py"
  classes: "PascalCase"
  functions: "snake_case"
  constants: "UPPER_SNAKE_CASE"
  test_files: "test_{module}.py"
  test_functions: "test_{method}_{scenario}_{expected}"
  schemas: "{Entity}Create, {Entity}Update, {Entity}Response"
  services: "{Entity}Service"
  repositories: "{Entity}Repository"
  routers: "{entity}_routes.py"
```

---

## Code Patterns

### Repository Pattern

```python
class RecipeRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get_by_id(self, recipe_id: UUID) -> Recipe | None:
        stmt = select(Recipe).where(Recipe.id == recipe_id)
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_all(self, *, limit: int = 50, offset: int = 0) -> list[Recipe]:
        stmt = select(Recipe).limit(limit).offset(offset)
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def create(self, recipe: Recipe) -> Recipe:
        self._session.add(recipe)
        await self._session.flush()
        return recipe
```

Rules:
- Use `select()` not `query()` (SQLAlchemy 2.0 style)
- Use `flush()` not `commit()` (UnitOfWork owns the transaction)
- Return `Entity | None` for single lookups, `list[Entity]` for collections
- Accept and return ORM entities, not Pydantic models

### Service Pattern

```python
class RecipeService:
    def __init__(self, db_manager: DBManager) -> None:
        self._db_manager = db_manager

    async def create_recipe(self, data: RecipeCreate) -> Recipe:
        async with self._db_manager.uow() as uow:
            existing = await uow.recipes.get_by_title(data.title)
            if existing:
                raise RecipeAlreadyExistsError(title=data.title)

            recipe = Recipe(**data.model_dump())
            created = await uow.recipes.create(recipe)
            return created
```

Rules:
- Constructor injection of UnitOfWork (DBManager)
- Use `async with db_manager.uow()` for transaction scope
- Raise domain exceptions for business rule violations
- Return entities; let routers transform to Pydantic response models
- Never import or return Pydantic schemas

### Router Pattern

```python
router = APIRouter(prefix="/recipes", tags=["recipes"])

@router.post("", response_model=RecipeResponse, status_code=status.HTTP_201_CREATED)
async def create_recipe(
    data: RecipeCreate,
    service: RecipeServiceDep,
) -> RecipeResponse:
    recipe = await service.create_recipe(data)
    return RecipeResponse.model_validate(recipe)
```

Rules:
- Dependency injection via `Depends()`
- Return Pydantic response models (never raw entities)
- Map domain exceptions to HTTP status codes via global exception handlers
- Use type aliases for dependencies: `RecipeServiceDep = Annotated[RecipeService, Depends(get_recipe_service)]`
- Keep route functions thin (delegate to service)

### Exception Pattern

```python
class ServiceError(Exception):
    """Base for all service-layer exceptions."""
    def __init__(self, message: str, detail: str, context: dict[str, Any] | None = None) -> None:
        super().__init__(message)
        self.detail = detail        # Returned in API response
        self.context = context or {} # Used for structured logging / log filtering

class RecipeNotFoundError(ServiceError):
    def __init__(self, recipe_id: UUID) -> None:
        super().__init__(
            message=f"Recipe {recipe_id} not found",
            detail="Recipe not found",
            context={"recipe_id": str(recipe_id)},
        )
```

Rules:
- Three-part structure: `message` (logs), `detail` (API response), `context` (log filtering)
- Hierarchy: `ServiceError` -> `CategoryError` -> `SpecificError`
- Never expose internal IDs or stack traces in `detail`

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

```yaml
structure:
  source_root: "src/"
  test_root: "tests/"
  config_files:
    - pyproject.toml
    - alembic.ini
  migration_dir: "alembic/versions/"
```

### Expected Directory Layout

```
project-root/
  pyproject.toml
  alembic.ini
  alembic/
    env.py
    versions/
  src/
    main.py
    config.py
    db/
      session.py
      repositories/
        __init__.py
    api/
      {domain}/
        routes.py
        schemas.py
        service.py
        repository.py
        exceptions.py
    models/
      {domain}.py
  tests/
    conftest.py
    unit/
      api/
        {domain}/
          test_routes.py
          test_service.py
          test_repository.py
    integration/
    e2e/
```

---

## Pattern Files Reference

Detailed pattern files live alongside this profile for use by code-generation skills:

```
profiles/python-fastapi/patterns/
  router.md        # Full router pattern with examples
  service.md       # Full service pattern with examples
  repository.md    # Full repository pattern with examples
  external.md      # External integration pattern with examples
  models.md        # ORM entity pattern with examples
```

Commands and agents reference these patterns by path:
```
$PROFILE_DIR/patterns/router.md
$PROFILE_DIR/patterns/service.md
```

Where `$PROFILE_DIR` resolves to `profiles/python-fastapi/` for this profile.

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
