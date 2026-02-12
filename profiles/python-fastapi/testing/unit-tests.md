# Unit Tests Guide

Isolated component testing with mocks using pytest and pytest-mock.

## Location

```
tests/
  unit/
    conftest.py                    # Registers fixture modules via pytest_plugins
    fixtures/
      __init__.py
      core.py                      # Core/common fixtures
      database.py                  # Database fixtures (mock_db_manager)
      external_services.py         # External API mocks
    api/
      {domain}/
        test_service.py
        test_routes.py
```

## Key Principles

1. **Use pytest-mock** - `mocker` fixture, not `unittest.mock`
2. **Standalone functions** - avoid test classes
3. **Isolated** - mock all dependencies
4. **Fast** - no I/O, no database
5. **One behavior per test** - split complex tests
6. **AAA Pattern** - Arrange, Act, Assert
7. **Descriptive names** - `test_<function>_<scenario>_<expected>`
8. **Contract-based mocking** - Mock using contract specifications (type signatures)

## Contract-Based Mocking

When implementing from contract specifications, use type signatures to guide mock setup. The contract's return types define what mocks return; the contract's exceptions define error test cases.

- Tests validate implementation matches contract
- Type hints in contract guide mock setup
- Contract violations are caught early (before integration)

> See [test-examples.md](test-examples.md) for full contract-based mocking examples.

## Fixture Organization (pytest_plugins)

Use `pytest_plugins` to load fixtures from modular files. This keeps fixtures organized and avoids a bloated `conftest.py`.

```python
# tests/unit/conftest.py
"""Unit test configuration and fixture loading."""

pytest_plugins = [
    "tests.unit.fixtures.core",
    "tests.unit.fixtures.database",
    "tests.unit.fixtures.external_services",
    # Add domain-specific fixtures as needed
    "tests.unit.fixtures.users",
    "tests.unit.fixtures.orders",
]
```

### Fixture Module Structure

```
tests/
  unit/
    conftest.py                      # Only pytest_plugins list
    fixtures/
      __init__.py
      core.py                        # Shared utilities (freezegun, faker)
      database.py                    # mock_db_manager, mock_uow
      external_services.py           # External API mocks
      users.py                       # User domain fixtures
      orders.py                      # Order domain fixtures
```

### Fixture Placement Rules

| Location | When to Use | Example |
|----------|-------------|---------|
| Test file | < 10 lines, used ONLY in that file | `@pytest.fixture def specific_user_state()` |
| `fixtures/{domain}.py` | Used across multiple tests in domain | `user_factory`, `mock_user_service` |
| `fixtures/database.py` | DB mocks used by all domains | `mock_db_manager`, `mock_uow` |
| `fixtures/core.py` | Cross-cutting utilities | `frozen_time`, `fake` (faker instance) |
| `fixtures/external_services.py` | Third-party API mocks | `mock_stripe_client`, `mock_sendgrid` |

> See [fixtures-guide.md](fixtures-guide.md) for fixture composition and factory patterns with examples.

### DBManager Mock Fixture

```python
# tests/unit/fixtures/database.py
import pytest


@pytest.fixture
def mock_db_manager(mocker):
    """Mock DBManager for unit tests.

    UoW auto-commits on context exit - no commit assertions needed.
    """
    db_manager = mocker.MagicMock()
    mock_uow = mocker.AsyncMock()

    # Setup async context manager
    db_manager.uow.return_value.__aenter__.return_value = mock_uow
    db_manager.uow.return_value.__aexit__.return_value = False

    return db_manager


@pytest.fixture
def mock_uow(mock_db_manager):
    """Get the mock UoW from mock_db_manager."""
    return mock_db_manager.uow.return_value.__aenter__.return_value
```

## Service Tests

Mock the repository (via UoW) and any external services. Verify:
- Happy path returns correct DTO type
- Missing entities raise domain-specific `NotFoundError`
- Validation rules are enforced
- External service failures are handled
- Repository methods are called with correct arguments

> See [test-examples.md](test-examples.md) for full service and route test code examples.

## Route Tests

Mock the service layer via FastAPI dependency overrides. Verify:
- Success status codes (200, 201, 204)
- Error status codes (400, 404, 422)
- Response JSON shape matches schema
- Request validation errors return 422

## Mocking Guidelines

### What MUST be mocked

- Database connections (DBManager)
- External API calls
- File system operations
- Time-dependent operations (`datetime.now`)
- Random number generation

### Mock Boundaries

| Test Type | Mock At |
|-----------|---------|
| Route tests | Service layer |
| Service tests | Repository (via UoW) + External services |
| Repository tests | Use real session (integration) |

## Anti-Patterns (FORBIDDEN)

```python
# BAD: Using unittest.mock
from unittest.mock import AsyncMock, MagicMock  # DON'T

# GOOD: Using pytest-mock
def test_something(mocker):
    mock = mocker.AsyncMock()

# BAD: Test classes
class TestUserService:  # DON'T
    def test_something(self):
        ...

# GOOD: Standalone functions
def test_get_user_with_valid_id_returns_user(mock_db_manager):
    ...

# BAD: Manual commit assertion (UoW auto-commits)
mock_uow.commit.assert_called_once()  # DON'T

# GOOD: No commit assertion needed
mock_uow.{entity}_repo.create.assert_called_once()

# BAD: Generic test names
def test_service_works():  # DON'T
def test_error():  # DON'T

# GOOD: Descriptive names
def test_get_by_id_with_invalid_id_raises_not_found():
def test_create_with_valid_input_returns_dto():

# BAD: Testing private methods
def test__validate_name():  # DON'T

# GOOD: Test through public interface
def test_create_with_invalid_name_raises_validation_error():
```

## Test Coverage Checklist

### Service Layer
- [ ] Happy path for each method
- [ ] Each exception path
- [ ] Validation rules
- [ ] External service failures

### Route Layer
- [ ] Success status codes (200, 201, 204)
- [ ] Error status codes (400, 404, 422)
- [ ] Request validation errors

## Related Patterns

- See `TEST_FIRST.md` for test-first workflow with contract specifications
- See `../patterns/service.md` for service implementation
- See `../patterns/router.md` for router implementation
- See `../patterns/repository.md` for repository implementation
- See `../patterns/_shared.md` for three-model strategy and outside-in flow
- See `../patterns/exceptions.md` for exception patterns
- See `../patterns/unit-of-work.md` for DBManager/UoW mocking
