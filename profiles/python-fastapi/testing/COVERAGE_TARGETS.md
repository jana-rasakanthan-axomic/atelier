# Test Coverage Targets

**Purpose:** Define minimum and target coverage goals by component.

**Used By:** `/build`, `/verify` agent, test generation

---

## Coverage Goals by Component

| Component | Minimum | Target | Why |
|-----------|---------|--------|-----|
| **Services** | 85% | 95% | Business logic must be well-tested |
| **Repositories** | 80% | 90% | Data access needs verification |
| **Routes** | 80% | 90% | API contracts must be tested |
| **Overall** | 80% | 85% | Project-wide baseline |

---

## Service Layer (85% min / 95% target)

**Why high coverage:** Services contain business logic, validation, and orchestration.

### Must Test

```python
class UserService:
    def create_user(self, dto: CreateUserDTO) -> User:
        # MUST TEST:
        # - Happy path (valid user created)
        # - Duplicate email (raises UserAlreadyExistsError)
        # - Invalid email format (validation)
        # - Repository called correctly
        # - Return value correct
        ...
```

**Test categories:**
- Happy paths (successful operations)
- Error conditions (exceptions raised)
- Edge cases (boundary values, empty inputs)
- Business rules (validation logic)

---

## Repository Layer (80% min / 90% target)

**Why slightly lower:** Repositories are thinner, mostly CRUD operations.

### Must Test

```python
class UserRepository:
    def get(self, user_id: int) -> User | None:
        # MUST TEST:
        # - Returns user when exists
        # - Returns None when not found
        # - Correct SQL query generated
        ...

    def list_by_status(self, status: str) -> list[User]:
        # MUST TEST:
        # - Returns filtered users
        # - Returns empty list when none match
        # - Handles invalid status
        ...
```

**Test categories:**
- CRUD operations (create, read, update, delete)
- Query methods (filters, pagination, sorting)
- Edge cases (empty results, invalid IDs)

---

## Route Layer (80% min / 90% target)

**Why 80%:** Routes are thin controllers that delegate to services.

### Must Test

```python
@router.post("/users", status_code=201)
async def create_user(request: CreateUserRequest) -> UserResponse:
    # MUST TEST:
    # - Returns 201 with correct response
    # - Returns 400 for invalid input
    # - Returns 409 for duplicate email
    # - Returns 500 for unexpected errors
    # - DTO validation works
    ...
```

**Test categories:**
- Status codes (200, 201, 400, 404, 409, 500)
- Request/response DTOs (correct shape)
- Error handling (domain exceptions -> HTTP errors)
- Authentication/authorization (if applicable)

---

## Overall Project (80% min / 85% target)

**Why 80%:** Allows for some uncovered utility code, configs, migrations.

---

## What to Test

### Always Test

1. **Happy paths** - Successful operations
2. **Error conditions** - All raised exceptions
3. **Edge cases** - Boundary values, empty inputs, nulls
4. **Business rules** - Validation, authorization, workflow logic

### Skip

1. **Generated code** - Alembic migrations, auto-generated schemas
2. **Simple getters/setters** - `@property` that just returns a field
3. **Third-party library code** - Don't test FastAPI, SQLAlchemy internals
4. **Configuration** - `settings.py` with just constants
5. **Main entry points** - `if __name__ == "__main__"` blocks

---

## Running Coverage

### Generate Report

```bash
# HTML report (opens in browser)
pytest --cov=src --cov-report=html
open htmlcov/index.html

# Terminal report
pytest --cov=src --cov-report=term-missing

# Show which lines are missing
pytest --cov=src --cov-report=term-missing:skip-covered
```

### Fail if Below Threshold

```bash
# Fail build if <80% overall coverage
pytest --cov=src --cov-fail-under=80

# Fail if specific module <85%
pytest --cov=src/services --cov-fail-under=85
```

### Coverage Configuration

**In `pyproject.toml`:**

```toml
[tool.coverage.run]
source = ["src"]
omit = [
    "*/tests/*",
    "*/migrations/*",
    "*/__init__.py",
]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "if __name__ == .__main__.:",
    "raise AssertionError",
    "raise NotImplementedError",
]
```

---

## Coverage by Test Type

| Test Type | Typical Coverage | Why |
|-----------|-----------------|-----|
| **Unit tests** | 70-80% | Test individual components in isolation |
| **Integration tests** | 10-15% | Test component interactions |
| **E2E tests** | 5-10% | Test critical user flows |

**Total:** Should reach 80-85% when combined

---

## When to Stop Writing Tests

### Stop when you've reached target coverage AND:
1. All happy paths tested
2. All error conditions tested
3. All edge cases identified and tested
4. All business rules validated

### Don't chase 100% coverage
- Diminishing returns after 90%
- Some code is not worth testing (simple getters, configs)
- Focus on critical paths and business logic

---

## Examples

### Service with 95% Coverage

```python
# user_service.py (100 lines)
class UserService:
    def create_user(self, dto: CreateUserDTO) -> User:
        ...  # 10 lines

    def get_user(self, user_id: int) -> User | None:
        ...  # 5 lines

    def update_user(self, user_id: int, dto: UpdateUserDTO) -> User:
        ...  # 15 lines

    def delete_user(self, user_id: int) -> None:
        ...  # 5 lines

# test_user_service.py
# Tests cover:
# - create_user: happy path, duplicate email, invalid input
# - get_user: found, not found
# - update_user: happy path, not found, invalid input
# - delete_user: success, not found
# = 95% coverage (5 lines untested: edge case logging)
```

### Repository with 85% Coverage

```python
# user_repository.py (50 lines)
class UserRepository:
    def get(self, user_id: int) -> User | None: ...
    def create(self, user: User) -> User: ...
    def list_all(self) -> list[User]: ...

# test_user_repository.py
# Tests cover:
# - get: found, not found
# - create: success
# - list_all: with data, empty
# = 85% coverage (uncovered: error handling for DB connection loss)
```

### Route with 80% Coverage

```python
# user_routes.py (30 lines)
@router.post("/users", status_code=201)
async def create_user(request: CreateUserRequest) -> UserResponse:
    ...

# test_user_routes.py
# Tests cover:
# - 201 success
# - 400 invalid input
# - 409 duplicate email
# = 80% coverage (uncovered: 500 error handling middleware)
```

---

## Coverage Verification

**In CI/CD:**

```yaml
# .github/workflows/test.yml
- name: Run tests with coverage
  run: |
    pytest \
      --cov=src \
      --cov-fail-under=80 \
      --cov-report=term-missing \
      --cov-report=xml

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage.xml
```

**In `/verify` agent:**
```bash
# Check coverage meets targets
pytest --cov=src --cov-fail-under=80 || {
    echo "Error: Coverage below 80% threshold"
    exit 1
}
```

---

## Troubleshooting Low Coverage

### If Service Coverage <85%

**Check what's missing:**
```bash
pytest --cov=src/services --cov-report=term-missing
```

**Common gaps:**
- Missing error condition tests (exceptions not tested)
- Missing edge case tests (empty inputs, nulls)
- Only testing happy path

**Fix:** Add tests for error conditions and edge cases

---

### If Repository Coverage <80%

**Common gaps:**
- Missing query method tests (filters, pagination)
- Missing negative tests (not found, invalid IDs)

**Fix:** Test all query methods with various inputs

---

### If Route Coverage <80%

**Common gaps:**
- Missing status code tests (400, 404, 409)
- Missing error handling tests

**Fix:** Test all error paths (invalid input, not found, conflicts)

---

## Related Documentation

- [Unit Tests](./unit-tests.md) - How to write unit tests
- [Integration Tests](./integration-tests.md) - How to write integration tests
- [E2E Tests](./e2e-tests.md) - How to write e2e tests

---

**Use these targets to know when to stop writing tests. Aim for target coverage, but don't chase 100%.**
