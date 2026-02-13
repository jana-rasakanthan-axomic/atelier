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

## What to Test per Layer

### Service Layer (85% min / 95% target)

**Why high coverage:** Services contain business logic, validation, and orchestration.

```python
class UserService:
    def create_user(self, dto: CreateUserDTO) -> User:
        # MUST TEST: happy path, duplicate email, invalid email, return value
        ...
```

**Categories:** Happy paths, error conditions, edge cases, business rules

### Repository Layer (80% min / 90% target)

```python
class UserRepository:
    def get(self, user_id: int) -> User | None:
        # MUST TEST: returns user when exists, returns None when not found
        ...
```

**Categories:** CRUD operations, query methods (filters, pagination), edge cases (empty results)

### Route Layer (80% min / 90% target)

```python
@router.post("/users", status_code=201)
async def create_user(request: CreateUserRequest) -> UserResponse:
    # MUST TEST: 201 success, 400 invalid, 409 duplicate, 422 validation
    ...
```

**Categories:** Status codes, request/response DTOs, error handling, auth (if applicable)

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

```bash
# Terminal report with missing lines
pytest --cov=src --cov-report=term-missing

# Fail build if below threshold
pytest --cov=src --cov-fail-under=80

# HTML report
pytest --cov=src --cov-report=html
```

### Coverage Configuration (pyproject.toml)

```toml
[tool.coverage.run]
source = ["src"]
omit = ["*/tests/*", "*/migrations/*", "*/__init__.py"]

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

**Total:** Should reach 80-85% when combined.

---

## Coverage Verification (CI/CD)

```yaml
# .github/workflows/test.yml
- name: Run tests with coverage
  run: |
    pytest \
      --cov=src \
      --cov-fail-under=80 \
      --cov-report=term-missing \
      --cov-report=xml
```

---

## Troubleshooting Low Coverage

| Symptom | Common Gap | Fix |
|---------|-----------|-----|
| Service < 85% | Missing error/edge case tests | Add tests for exceptions and boundary values |
| Repository < 80% | Missing query method / negative tests | Test all query methods with various inputs |
| Route < 80% | Missing status code / error tests | Test all error paths (400, 404, 409) |

---

## Related Documentation

- [Unit Tests](./unit-tests.md) - How to write unit tests
- [Integration Tests](./integration-tests.md) - How to write integration tests
- [E2E Tests](./e2e-tests.md) - How to write e2e tests
