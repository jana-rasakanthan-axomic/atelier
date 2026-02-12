# Test Code Examples

Full test examples for python-fastapi service and route layers.

> Referenced from [unit-tests.md](unit-tests.md)

## Contract-Based Mocking Example

When implementing from contract specifications, use type signatures to guide mocking:

### Service Contract

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

For services with external dependencies, inject mock via fixture and assert both the external call and the repository call:

```python
@pytest.fixture
def service_with_external(mock_db_manager, mocker):
    return {Entity}Service(db_manager=mock_db_manager, external_service=mocker.AsyncMock())

@pytest.mark.asyncio
async def test_create_with_external_calls_service(service_with_external, mock_uow):
    # Arrange
    request = Create{Entity}Request(name="Test", external_id=uuid4())
    service_with_external._external_service.get_data.return_value = ExternalDTO(id=uuid4())
    mock_uow.{entity}_repo.create.return_value = {Entity}(id=uuid4(), name="Test")

    # Act
    result = await service_with_external.create(request)

    # Assert - verify both external and repo calls
    service_with_external._external_service.get_data.assert_called_once()
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
