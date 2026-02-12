# Mocking Patterns by Layer

Extracted from TEST_FIRST.md. Contains layer-by-layer mocking examples for TDD.

## Mocking Hierarchy

```
Router Tests     -> Mock Service
Service Tests    -> Mock Repository + Mock External Services
Repository Tests -> Mock AsyncSession
External Tests   -> Mock HTTP Client (httpx/aiohttp)
```

## Router Layer: Mock Service

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

## Service Layer: Mock Repository AND External Services

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

## Repository Layer: Mock Session

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

## External Service Layer: Mock HTTP Client

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
