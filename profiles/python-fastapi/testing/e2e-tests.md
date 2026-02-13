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
    engine = create_async_engine(TEST_DATABASE_URL)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()

@pytest_asyncio.fixture
async def async_session(engine):
    async_session_maker = async_sessionmaker(engine, class_=AsyncSession)
    async with async_session_maker() as session:
        async with session.begin():
            yield session
            await session.rollback()

@pytest_asyncio.fixture
async def client(async_session):
    async def override_session():
        yield async_session
    app.dependency_overrides[get_session] = override_session
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test",
    ) as ac:
        yield ac
    app.dependency_overrides.clear()
```

## Full CRUD Test Pattern

```python
# tests/e2e/test_{domain}_api.py
import pytest


@pytest.mark.asyncio
async def test_{entity}_complete_crud_flow(client):
    """Test complete CRUD workflow as API consumer."""
    # 1. Create
    create_resp = await client.post(
        "/{entities}",
        json={"name": "E2E Test", "description": "Created via API"},
    )
    assert create_resp.status_code == 201
    entity_id = create_resp.json()["id"]
    assert "created_at" in create_resp.json()

    # 2. Read
    get_resp = await client.get(f"/{entities}/{entity_id}")
    assert get_resp.status_code == 200
    assert get_resp.json()["name"] == "E2E Test"

    # 3. Update
    update_resp = await client.patch(
        f"/{entities}/{entity_id}",
        json={"name": "Updated"},
    )
    assert update_resp.status_code == 200
    assert update_resp.json()["name"] == "Updated"

    # 4. Delete
    delete_resp = await client.delete(f"/{entities}/{entity_id}")
    assert delete_resp.status_code == 204

    # 5. Confirm deletion
    final_resp = await client.get(f"/{entities}/{entity_id}")
    assert final_resp.status_code == 404
```

## Error Scenarios

```python
@pytest.mark.asyncio
async def test_get_{entity}_with_invalid_id_returns_404(client):
    response = await client.get("/{entities}/00000000-0000-0000-0000-000000000000")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_create_{entity}_with_invalid_input_returns_422(client):
    response = await client.post("/{entities}", json={"invalid_field": "value"})
    assert response.status_code == 422
```

## Pagination Tests

> See [patterns/pagination.md](../patterns/pagination.md) for pagination query parameter patterns and test examples.

```python
@pytest.mark.asyncio
async def test_list_{entities}_with_limit_returns_limited_results(client):
    for i in range(5):
        await client.post("/{entities}", json={"name": f"Page Test {i}"})

    response = await client.get("/{entities}?limit=3")
    assert response.status_code == 200
    assert len(response.json()["items"]) == 3
```

## Authentication Tests

```python
@pytest.mark.asyncio
async def test_get_{entities}_without_token_returns_401(client):
    response = await client.get("/{entities}")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_{entities}_with_valid_token_returns_200(client, auth_token):
    response = await client.get(
        "/{entities}",
        headers={"Authorization": f"Bearer {auth_token}"},
    )
    assert response.status_code == 200
```
