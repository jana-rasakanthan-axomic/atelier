# Test-First Development (MANDATORY)

> **This is NOT optional.** All code implementation MUST follow TDD. If you find yourself writing implementation code before tests, STOP and go back.

Write tests before implementation using contract specifications.

## Philosophy

**Test-First = Contract -> Test -> Implement**

```
1. Write test based on contract specification
2. Run test -> MUST FAIL (Red)
3. Write MINIMUM code to pass test
4. Run test -> MUST PASS (Green)
5. Refactor if needed (keep Green)
```

## TDD Enforcement Checklist

Before writing ANY implementation code, verify:

- [ ] Test file exists
- [ ] Test imports the implementation (will cause ImportError)
- [ ] Tests run and FAIL (Red confirmed)

**If any checkbox is unchecked, STOP. Write tests first.**

## When to Use Test-First

| Layer | Test-First? | Mock What? | Test File Pattern |
|-------|-------------|------------|-------------------|
| **Router (API)** | ALWAYS | Service | `tests/unit/api/{domain}/test_routes.py` |
| **Service** | ALWAYS | Repository, External | `tests/unit/api/{domain}/test_service.py` |
| **Repository** | ALWAYS | AsyncSession | `tests/unit/db/repositories/test_{entity}_repository.py` |
| **External Service** | ALWAYS | HTTP Client | `tests/unit/external/test_{service}_client.py` |

## When NOT to Use Test-First

| Component | Why | Alternative |
|-----------|-----|-------------|
| ORM Models | Data structures, not behavior | Integration tests |
| Migrations | Schema changes | Integration tests |
| Configuration | Static values | None needed |
| Trivial DTOs | Pydantic validation sufficient | None needed |

## Test-First Workflow

### Step 1: Read Contract Specification

Extract from plan or ticket:

```python
# Contract spec from ticket
class UserService:
    async def create_user(
        self, request: CreateUserRequest
    ) -> User:
        """
        Creates a new user.

        Raises:
            DuplicateEmailError: If email already exists
            ValidationError: If request invalid
        """
```

### Step 2: Write Test First (Red)

Write test that validates contract behavior:

```python
# tests/unit/api/users/test_service.py
import pytest
from uuid import uuid4

from src.api.users.service import UserService
from src.api.users.schemas import CreateUserRequest
from src.api.users.models import User
from src.exceptions import DuplicateEmailError


@pytest.mark.asyncio
async def test_create_user_with_valid_request_returns_user(
    service,  # Fixture provides UserService with mocked dependencies
    mock_uow,  # Fixture provides mocked UnitOfWork
):
    # Arrange
    request = CreateUserRequest(name="John Doe", email="john@example.com")
    mock_uow.user_repo.get_by_email.return_value = None  # Email not taken
    mock_uow.user_repo.create.return_value = User(
        id=uuid4(),
        name="John Doe",
        email="john@example.com",
    )

    # Act
    result = await service.create_user(request)

    # Assert
    assert isinstance(result, User)
    assert result.name == "John Doe"
    assert result.email == "john@example.com"
    mock_uow.user_repo.get_by_email.assert_called_once_with("john@example.com")
    mock_uow.user_repo.create.assert_called_once()


@pytest.mark.asyncio
async def test_create_user_with_duplicate_email_raises_error(service, mock_uow):
    # Arrange
    request = CreateUserRequest(name="John Doe", email="john@example.com")
    existing_user = User(id=uuid4(), name="Jane Doe", email="john@example.com")
    mock_uow.user_repo.get_by_email.return_value = existing_user

    # Act & Assert
    with pytest.raises(DuplicateEmailError):
        await service.create_user(request)
```

### Step 3: Run Test (Expect Red)

```bash
pytest tests/unit/api/users/test_service.py::test_create_user_with_valid_request_returns_user -v

# Expected output:
# FAILED - ImportError: cannot import name 'UserService'
# OR
# FAILED - AttributeError: 'UserService' has no attribute 'create_user'
```

**Why Red is good:** Proves test is actually testing something, not auto-passing.

### Step 4: Implement Code (Green)

Now implement the minimum code to make test pass:

```python
# src/api/users/service.py
from src.api.users.schemas import CreateUserRequest
from src.api.users.models import User
from src.exceptions import DuplicateEmailError
from src.db.main import DBManager


class UserService:
    def __init__(self, db_manager: DBManager) -> None:
        self.db_manager = db_manager

    async def create_user(self, request: CreateUserRequest) -> User:
        async with self.db_manager.uow() as uow:
            # Check for duplicate email
            existing = await uow.user_repo.get_by_email(request.email)
            if existing:
                raise DuplicateEmailError(request.email)

            # Create user
            user = User(**request.model_dump())
            await uow.user_repo.create(user)
            return user
```

### Step 5: Run Test Again (Expect Green)

```bash
pytest tests/unit/api/users/test_service.py -v

# Expected output:
# PASSED test_create_user_with_valid_request_returns_user
# PASSED test_create_user_with_duplicate_email_raises_error
```

### Step 6: Refactor (if needed)

If implementation is clean, move on. If duplication or complexity exists, refactor while keeping tests green.

## Mocking from Contract Specs

### Mocking Hierarchy

```
Router Tests     -> Mock Service
Service Tests    -> Mock Repository + Mock External Services
Repository Tests -> Mock AsyncSession
External Tests   -> Mock HTTP Client (httpx/aiohttp)
```

### Router Layer: Mock Service

Contract spec defines service interface:

```python
# Contract spec
class UserService:
    async def get_by_id(self, user_id: UUID) -> User:
        ...
```

Test mocks service using contract:

```python
# tests/unit/api/users/test_routes.py
@pytest.mark.asyncio
async def test_get_user_with_valid_id_returns_200(client, mock_service):
    # Arrange
    user_id = uuid4()
    mock_service.get_by_id.return_value = User(
        id=user_id,
        name="Test User",
        email="test@example.com",
    )

    # Act
    response = await client.get(f"/users/{user_id}")

    # Assert
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == str(user_id)
    assert data["name"] == "Test User"
    mock_service.get_by_id.assert_called_once_with(user_id)
```

### Service Layer: Mock Repository AND External Services

Contract spec defines repository and external service interfaces:

```python
# Contract spec (inferred or explicit)
class UserRepository:
    async def get_by_email(self, email: str) -> User | None:
        ...
    async def create(self, user: User) -> User:
        ...

class EmailService:
    async def send_welcome_email(self, user: User) -> None:
        ...
```

Test mocks both repository and external services:

```python
# tests/unit/api/users/test_service.py
@pytest.mark.asyncio
async def test_create_user_with_valid_request_returns_user(service, mock_uow, mock_email_service):
    # Arrange
    request = CreateUserRequest(name="John", email="john@example.com")
    mock_uow.user_repo.get_by_email.return_value = None
    mock_uow.user_repo.create.return_value = User(id=uuid4(), name="John", email="john@example.com")
    mock_email_service.send_welcome_email.return_value = None

    # Act
    result = await service.create_user(request)

    # Assert
    assert isinstance(result, User)
    mock_uow.user_repo.get_by_email.assert_called_once_with("john@example.com")
    mock_uow.user_repo.create.assert_called_once()
    mock_email_service.send_welcome_email.assert_called_once()
```

### Repository Layer: Mock Session (or use integration tests)

Repository tests can either:
1. Mock AsyncSession (unit test)
2. Use real test database (integration test - preferred for repositories)

For unit tests:

```python
# tests/unit/db/repositories/test_user_repository.py
@pytest.mark.asyncio
async def test_get_by_email_with_existing_user_returns_user(mock_session):
    # Arrange
    repo = UserRepository(mock_session)
    user = User(id=uuid4(), name="Test", email="test@example.com")
    mock_result = MagicMock()
    mock_result.scalars.return_value.first.return_value = user
    mock_session.execute.return_value = mock_result

    # Act
    result = await repo.get_by_email("test@example.com")

    # Assert
    assert result == user
    mock_session.execute.assert_called_once()
```

### External Service Layer: Mock HTTP Client

External service tests mock the HTTP client (httpx, aiohttp):

```python
# tests/unit/external/test_payment_client.py
@pytest.mark.asyncio
async def test_process_payment_with_valid_card_returns_success(mock_http_client):
    # Arrange
    client = PaymentClient(mock_http_client)
    mock_http_client.post.return_value = httpx.Response(
        200,
        json={"transaction_id": "txn_123", "status": "success"}
    )

    # Act
    result = await client.process_payment(amount=100, card_token="tok_123")

    # Assert
    assert result.status == "success"
    assert result.transaction_id == "txn_123"
    mock_http_client.post.assert_called_once_with(
        "/v1/charges",
        json={"amount": 100, "source": "tok_123"}
    )


@pytest.mark.asyncio
async def test_process_payment_with_network_error_raises_exception(mock_http_client):
    # Arrange
    client = PaymentClient(mock_http_client)
    mock_http_client.post.side_effect = httpx.NetworkError("Connection refused")

    # Act & Assert
    with pytest.raises(PaymentServiceError):
        await client.process_payment(amount=100, card_token="tok_123")
```

## Coverage Goals

Each layer should test:

### Router Layer
- Happy path (200/201/204)
- Error paths (400/404/422/500)
- Request validation (Pydantic catches invalid input)
- Service exceptions mapped to HTTP status

### Service Layer
- Happy path for each method
- Each exception path (NotFoundError, ValidationError, etc.)
- Business logic edge cases
- External service failures (if applicable)

### Repository Layer
- CRUD operations (create, read, update, delete)
- Query filters (if applicable)
- Return types match contract (Entity | None, list[Entity])

## Anti-Patterns (FORBIDDEN)

```python
# BAD: Implementing before writing tests
# 1. Write UserService.create_user()
# 2. Write tests for create_user()  # Wrong order!

# GOOD: Test-first
# 1. Write test for create_user()
# 2. Run test (Red)
# 3. Write UserService.create_user()
# 4. Run test (Green)

# BAD: Not running tests before implementing
def test_create_user_returns_user(service):
    result = service.create_user(...)  # Implementation already exists!
    assert result is not None

# GOOD: Run test first, expect Red
def test_create_user_returns_user(service):
    result = service.create_user(...)
    assert isinstance(result, User)

# Then implement, run again, expect Green

# BAD: Testing implementation details
def test_create_user_calls_flush(service, mock_uow):
    await service.create_user(...)
    mock_uow.session.flush.assert_called_once()  # Implementation detail

# GOOD: Testing behavior
def test_create_user_returns_persisted_user(service, mock_uow):
    result = await service.create_user(...)
    assert isinstance(result, User)
    mock_uow.user_repo.create.assert_called_once()  # Behavior
```

## Red -> Green -> Refactor Cycle

```
1. Red (Write failing test)
   |
2. Green (Implement minimum code to pass)
   |
3. Refactor (Clean up while keeping tests green)
   |
4. Repeat for next behavior
```

## Benefits of Test-First

1. **Design clarity**: Writing tests first clarifies interface design
2. **Contract validation**: Tests prove implementation matches contract
3. **Catch issues early**: Test failures reveal mismatches before integration
4. **Confidence**: Green tests mean implementation satisfies requirements
5. **Refactoring safety**: Tests protect against regressions during cleanup

## Cross-References

- See `unit-tests.md` for AAA pattern, mocking guidelines, fixture organization
- See `../patterns/router.md` for router contract patterns
- See `../patterns/service.md` for service contract patterns
- See `../patterns/repository.md` for repository contract patterns
- See `../patterns/_shared.md` for three-model strategy
