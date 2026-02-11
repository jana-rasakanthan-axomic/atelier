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

When implementing from contract specifications, use type signatures to guide mocking:

### Example: Service Contract

```python
# Contract specification from ticket/plan
class UserService:
    async def create_user(self, request: CreateUserRequest) -> User:
        """
        Raises:
            DuplicateEmailError: If email already exists
        """
```

### Test Using Contract

```python
# tests/unit/api/users/test_service.py
@pytest.mark.asyncio
async def test_create_user_with_valid_request_returns_user(service, mock_uow):
    # Arrange - mock based on contract return type (User)
    request = CreateUserRequest(name="John", email="john@example.com")
    mock_uow.user_repo.get_by_email.return_value = None  # No duplicate
    mock_uow.user_repo.create.return_value = User(
        id=uuid4(),
        name="John",
        email="john@example.com",
    )

    # Act - call method from contract
    result = await service.create_user(request)

    # Assert - verify contract return type
    assert isinstance(result, User)  # Contract says returns User
    assert result.email == "john@example.com"


@pytest.mark.asyncio
async def test_create_user_with_duplicate_email_raises_error(service, mock_uow):
    # Arrange - mock to trigger exception from contract
    request = CreateUserRequest(name="John", email="john@example.com")
    mock_uow.user_repo.get_by_email.return_value = User(id=uuid4(), email="john@example.com")

    # Act & Assert - verify contract exception
    with pytest.raises(DuplicateEmailError):  # Contract says raises this
        await service.create_user(request)
```

**Benefits:**
- Tests validate implementation matches contract
- Type hints in contract guide mock setup
- Catching contract violations early (before integration)

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

### Fixture Composition Pattern

Build complex fixtures from simple ones:

```python
# tests/unit/fixtures/users.py
import pytest
from uuid import uuid4


@pytest.fixture
def user_id():
    """Generate a consistent user ID for tests."""
    return uuid4()


@pytest.fixture
def user_data(user_id):
    """Base user data dictionary."""
    return {
        "id": user_id,
        "name": "Test User",
        "email": "test@example.com",
    }


@pytest.fixture
def user_entity(user_data):
    """User ORM entity from data."""
    from src.api.users.models import User
    return User(**user_data)


@pytest.fixture
def user_dto(user_data):
    """User DTO from data."""
    from src.api.users.dto import UserDTO
    return UserDTO(**user_data)
```

### Factory Fixtures for Variability

When tests need variations of the same data:

```python
# tests/unit/fixtures/users.py
@pytest.fixture
def user_factory():
    """Factory to create users with custom attributes."""
    def _create_user(**overrides):
        from src.api.users.models import User
        defaults = {
            "id": uuid4(),
            "name": "Test User",
            "email": "test@example.com",
            "is_active": True,
        }
        return User(**{**defaults, **overrides})
    return _create_user


# Usage in test:
def test_inactive_user_cannot_login(user_factory, service):
    user = user_factory(is_active=False)
    # ...
```

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

```python
# tests/unit/api/{domain}/test_service.py
import pytest
from uuid import uuid4

from src.api.{domain}.service import {Entity}Service
from src.api.{domain}.schemas import Create{Entity}Request
from src.api.{domain}.dto import {Entity}DTO
from src.exceptions import {Entity}NotFoundError


@pytest.fixture
def service(mock_db_manager):
    """Service with mocked dependencies."""
    return {Entity}Service(db_manager=mock_db_manager)


# Test naming: test_<function>_<scenario>_<expected>
@pytest.mark.asyncio
async def test_get_by_id_with_valid_id_returns_dto(service, mock_uow):
    # Arrange
    entity_id = uuid4()
    mock_uow.{entity}_repo.get_by_id.return_value = {Entity}(
        id=entity_id,
        name="Test",
    )

    # Act
    result = await service.get_by_id(entity_id)

    # Assert
    assert isinstance(result, {Entity}DTO)
    assert result.id == entity_id
    mock_uow.{entity}_repo.get_by_id.assert_called_once_with(entity_id)


@pytest.mark.asyncio
async def test_get_by_id_with_invalid_id_raises_not_found(service, mock_uow):
    # Arrange
    entity_id = uuid4()
    mock_uow.{entity}_repo.get_by_id.return_value = None

    # Act & Assert
    with pytest.raises({Entity}NotFoundError):
        await service.get_by_id(entity_id)


@pytest.mark.asyncio
async def test_create_with_valid_input_returns_dto(service, mock_uow):
    # Arrange
    request = Create{Entity}Request(name="Test")
    created = {Entity}(id=uuid4(), name="Test")
    mock_uow.{entity}_repo.create.return_value = created

    # Act
    result = await service.create(request)

    # Assert
    assert result.name == "Test"
    mock_uow.{entity}_repo.create.assert_called_once()
    # No commit assertion - UoW auto-commits
```

## Service with External Dependencies

```python
# tests/unit/api/{domain}/test_service.py
import pytest
from uuid import uuid4


@pytest.fixture
def mock_external_service(mocker):
    """Mock external service."""
    return mocker.AsyncMock()


@pytest.fixture
def service_with_external(mock_db_manager, mock_external_service):
    """Service with external dependency."""
    return {Entity}Service(
        db_manager=mock_db_manager,
        external_service=mock_external_service,
    )


@pytest.mark.asyncio
async def test_create_with_external_calls_service(
    service_with_external,
    mock_uow,
    mock_external_service,
):
    # Arrange
    request = Create{Entity}Request(name="Test", external_id=uuid4())
    mock_external_service.get_data.return_value = ExternalDTO(id=uuid4())
    mock_uow.{entity}_repo.create.return_value = {Entity}(id=uuid4(), name="Test")

    # Act
    result = await service_with_external.create(request)

    # Assert
    mock_external_service.get_data.assert_called_once()
    mock_uow.{entity}_repo.create.assert_called_once()
```

## Route Tests

```python
# tests/unit/api/{domain}/test_routes.py
import pytest
from uuid import uuid4
from httpx import AsyncClient

from src.api.{domain}.dto import {Entity}DTO
from src.exceptions import {Entity}NotFoundError


@pytest.fixture
def mock_service(mocker):
    """Mock service for route tests."""
    return mocker.AsyncMock()


@pytest.fixture
async def client(mock_service, mocker):
    """Test client with mocked service."""
    from src.main import app
    from src.api.dependencies.services import get_{entity}_service

    app.dependency_overrides[get_{entity}_service] = lambda: mock_service

    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_get_{entity}_with_valid_id_returns_200(client, mock_service):
    # Arrange
    entity_id = uuid4()
    mock_service.get_by_id.return_value = {Entity}DTO(
        id=entity_id,
        name="Test",
    )

    # Act
    response = await client.get(f"/{entities}/{entity_id}")

    # Assert
    assert response.status_code == 200
    assert response.json()["id"] == str(entity_id)


@pytest.mark.asyncio
async def test_get_{entity}_with_invalid_id_returns_404(client, mock_service):
    # Arrange
    entity_id = uuid4()
    mock_service.get_by_id.side_effect = {Entity}NotFoundError(entity_id)

    # Act
    response = await client.get(f"/{entities}/{entity_id}")

    # Assert
    assert response.status_code == 404
```

## Parametrized Tests

```python
@pytest.mark.parametrize("name,expected_valid", [
    ("Valid Name", True),
    ("", False),
    (None, False),
    ("A" * 256, False),
])
def test_name_validation(name, expected_valid):
    if expected_valid:
        request = Create{Entity}Request(name=name)
        assert request.name == name
    else:
        with pytest.raises(ValidationError):
            Create{Entity}Request(name=name)
```

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
