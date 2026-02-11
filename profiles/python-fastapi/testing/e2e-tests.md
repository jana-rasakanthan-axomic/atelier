# E2E Tests Guide

Full API flow testing with HTTP client.

## Location

`tests/e2e/test_{domain}_api.py`

## Key Principles

1. **Real HTTP** - Use TestClient or httpx
2. **Full Stack** - All layers, real database
3. **User Perspective** - Test as API consumer
4. **No Mocks** - Real dependencies (except external services)

## Setup (conftest.py)

```python
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from src.main import app
from src.db.models.base import Base
from src.db.session import get_session


TEST_DATABASE_URL = "postgresql+asyncpg://test:test@localhost:5432/test_db"


@pytest_asyncio.fixture(scope="session")
async def engine():
    """Create engine and tables."""
    engine = create_async_engine(TEST_DATABASE_URL)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture
async def async_session(engine):
    """Session with transaction rollback."""
    async_session_maker = async_sessionmaker(engine, class_=AsyncSession)
    async with async_session_maker() as session:
        async with session.begin():
            yield session
            await session.rollback()


@pytest_asyncio.fixture
async def client(async_session):
    """HTTP client with session override."""
    async def override_session():
        yield async_session

    app.dependency_overrides[get_session] = override_session

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac

    app.dependency_overrides.clear()
```

## E2E Test Pattern

```python
# tests/e2e/test_{domain}_api.py
import pytest


@pytest.mark.asyncio
async def test_create_{entity}_with_valid_input_returns_201(client):
    """POST /{entities} creates new entity."""
    # Act
    response = await client.post(
        "/{entities}",
        json={"name": "E2E Test", "description": "Created via API"},
    )

    # Assert
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "E2E Test"
    assert "id" in data
    assert "created_at" in data


@pytest.mark.asyncio
async def test_get_{entity}_with_valid_id_returns_200(client):
    """GET /{entities}/{{id}} returns entity."""
    # Arrange - Create first
    create_response = await client.post(
        "/{entities}",
        json={"name": "Get Test"},
    )
    entity_id = create_response.json()["id"]

    # Act
    response = await client.get(f"/{entities}/{entity_id}")

    # Assert
    assert response.status_code == 200
    assert response.json()["id"] == entity_id
    assert response.json()["name"] == "Get Test"


@pytest.mark.asyncio
async def test_list_{entities}_returns_paginated_response(client):
    """GET /{entities} returns list."""
    # Arrange - Create multiple
    for i in range(3):
        await client.post("/{entities}", json={"name": f"List Test {i}"})

    # Act
    response = await client.get("/{entities}")

    # Assert
    assert response.status_code == 200
    data = response.json()
    assert "items" in data
    assert "total" in data
    assert len(data["items"]) >= 3


@pytest.mark.asyncio
async def test_update_{entity}_with_valid_input_returns_200(client):
    """PATCH /{entities}/{{id}} updates entity."""
    # Arrange
    create_response = await client.post(
        "/{entities}",
        json={"name": "Original"},
    )
    entity_id = create_response.json()["id"]

    # Act
    response = await client.patch(
        f"/{entities}/{entity_id}",
        json={"name": "Updated"},
    )

    # Assert
    assert response.status_code == 200
    assert response.json()["name"] == "Updated"


@pytest.mark.asyncio
async def test_delete_{entity}_with_valid_id_returns_204(client):
    """DELETE /{entities}/{{id}} removes entity."""
    # Arrange
    create_response = await client.post(
        "/{entities}",
        json={"name": "To Delete"},
    )
    entity_id = create_response.json()["id"]

    # Act
    response = await client.delete(f"/{entities}/{entity_id}")

    # Assert
    assert response.status_code == 204

    # Verify deleted
    get_response = await client.get(f"/{entities}/{entity_id}")
    assert get_response.status_code == 404
```

## Error Scenarios

```python
@pytest.mark.asyncio
async def test_get_{entity}_with_invalid_id_returns_404(client):
    """GET with invalid ID returns 404."""
    response = await client.get(
        "/{entities}/00000000-0000-0000-0000-000000000000"
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_create_{entity}_with_invalid_input_returns_422(client):
    """POST with invalid data returns 422."""
    response = await client.post(
        "/{entities}",
        json={"invalid_field": "value"},
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_update_{entity}_with_invalid_id_returns_404(client):
    """PATCH with invalid ID returns 404."""
    response = await client.patch(
        "/{entities}/00000000-0000-0000-0000-000000000000",
        json={"name": "Updated"},
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_delete_{entity}_with_invalid_id_returns_404(client):
    """DELETE with invalid ID returns 404."""
    response = await client.delete(
        "/{entities}/00000000-0000-0000-0000-000000000000"
    )
    assert response.status_code == 404
```

## Pagination Tests

```python
@pytest.mark.asyncio
async def test_list_{entities}_with_limit_returns_limited_results(client):
    """Pagination respects limit parameter."""
    # Arrange - Create 10 items
    for i in range(10):
        await client.post("/{entities}", json={"name": f"Page Test {i}"})

    # Act
    response = await client.get("/{entities}?limit=5")

    # Assert
    assert response.status_code == 200
    assert len(response.json()["items"]) == 5


@pytest.mark.asyncio
async def test_list_{entities}_with_offset_skips_items(client):
    """Pagination respects offset parameter."""
    # Arrange - Create items
    ids = []
    for i in range(5):
        resp = await client.post("/{entities}", json={"name": f"Offset Test {i}"})
        ids.append(resp.json()["id"])

    # Act - Get page 2
    response = await client.get("/{entities}?limit=2&offset=2")

    # Assert
    items = response.json()["items"]
    assert len(items) == 2
    assert items[0]["id"] != ids[0]  # Different from first page
```

## Authentication Tests

```python
@pytest.mark.asyncio
async def test_get_{entities}_without_token_returns_401(client):
    """Request without token returns 401."""
    response = await client.get("/{entities}")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_{entities}_with_valid_token_returns_200(client, auth_token):
    """Request with valid token succeeds."""
    response = await client.get(
        "/{entities}",
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert response.status_code == 200
```

## Full User Flow

```python
@pytest.mark.asyncio
async def test_{entity}_complete_crud_flow(client):
    """Test complete user workflow."""
    # 1. Create entity
    create_resp = await client.post(
        "/{entities}",
        json={"name": "User Flow", "description": "Initial"},
    )
    assert create_resp.status_code == 201
    entity_id = create_resp.json()["id"]

    # 2. View entity
    get_resp = await client.get(f"/{entities}/{entity_id}")
    assert get_resp.status_code == 200
    assert get_resp.json()["name"] == "User Flow"

    # 3. Update entity
    update_resp = await client.patch(
        f"/{entities}/{entity_id}",
        json={"description": "Updated description"},
    )
    assert update_resp.status_code == 200

    # 4. Verify update
    verify_resp = await client.get(f"/{entities}/{entity_id}")
    assert verify_resp.json()["description"] == "Updated description"

    # 5. Delete entity
    delete_resp = await client.delete(f"/{entities}/{entity_id}")
    assert delete_resp.status_code == 204

    # 6. Confirm deletion
    final_resp = await client.get(f"/{entities}/{entity_id}")
    assert final_resp.status_code == 404
```
