# Integration Tests Guide

Cross-layer testing with real database.

## Location

`tests/integration/api/{domain}/test_{domain}_flow.py`

## Key Principles

1. **Real Database** - Use test database, not mocks
2. **Cross-Layer** - Test service + repository together
3. **Transactions** - Rollback after each test
4. **Isolation** - Each test is independent

## Setup (conftest.py)

```python
import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from src.db.models.base import Base


TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests."""
    import asyncio
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session")
async def engine():
    """Create async engine for tests."""
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture
async def async_session(engine):
    """Create session with transaction rollback."""
    async_session_maker = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )

    async with async_session_maker() as session:
        async with session.begin():
            yield session
            await session.rollback()


@pytest_asyncio.fixture
async def uow(async_session):
    """Create Unit of Work with real session."""
    from src.db.uow import UnitOfWork
    return UnitOfWork(async_session)
```

## Integration Test Pattern

```python
# tests/integration/api/{domain}/test_{domain}_flow.py
import pytest
from uuid import uuid4

from src.api.{domain}.service import {Entity}Service
from src.api.{domain}.schemas import Create{Entity}Request, Update{Entity}Request
from src.api.{domain}.exceptions import {Entity}NotFoundError


@pytest.mark.asyncio
async def test_create_{entity}_and_get_returns_same_entity(uow):
    """Test creating and retrieving an entity."""
    # Arrange
    service = {Entity}Service(uow=uow)
    request = Create{Entity}Request(name="Integration Test")

    # Act - Create
    created = await service.create(request)

    # Act - Get
    retrieved = await service.get_by_id(created.id)

    # Assert
    assert retrieved.id == created.id
    assert retrieved.name == "Integration Test"


@pytest.mark.asyncio
async def test_update_{entity}_persists_changes(uow):
    """Test updating an existing entity."""
    # Arrange
    service = {Entity}Service(uow=uow)
    created = await service.create(Create{Entity}Request(name="Original"))

    # Act
    update_request = Update{Entity}Request(name="Updated")
    updated = await service.update(created.id, update_request)

    # Assert
    assert updated.name == "Updated"

    # Verify persistence
    retrieved = await service.get_by_id(created.id)
    assert retrieved.name == "Updated"


@pytest.mark.asyncio
async def test_delete_{entity}_removes_from_database(uow):
    """Test deleting an existing entity."""
    # Arrange
    service = {Entity}Service(uow=uow)
    created = await service.create(Create{Entity}Request(name="To Delete"))

    # Act
    await service.delete(created.id)

    # Assert
    with pytest.raises({Entity}NotFoundError):
        await service.get_by_id(created.id)


@pytest.mark.asyncio
async def test_get_all_{entities}_with_pagination_returns_correct_pages(uow):
    """Test listing with pagination."""
    # Arrange
    service = {Entity}Service(uow=uow)
    for i in range(5):
        await service.create(Create{Entity}Request(name=f"Item {i}"))

    # Act - First page
    page1 = await service.get_all(limit=2, offset=0)

    # Act - Second page
    page2 = await service.get_all(limit=2, offset=2)

    # Assert
    assert len(page1) == 2
    assert len(page2) == 2
    assert page1[0].id != page2[0].id
```

## Full Flow Test

```python
@pytest.mark.asyncio
async def test_{entity}_complete_lifecycle(uow):
    """Test complete entity lifecycle."""
    service = {Entity}Service(uow=uow)

    # 1. Create
    created = await service.create(Create{Entity}Request(name="Lifecycle Test"))
    assert created.id is not None

    # 2. Read
    retrieved = await service.get_by_id(created.id)
    assert retrieved.name == "Lifecycle Test"

    # 3. Update
    updated = await service.update(
        created.id,
        Update{Entity}Request(name="Updated Name"),
    )
    assert updated.name == "Updated Name"

    # 4. List
    all_items = await service.get_all()
    assert any(item.id == created.id for item in all_items)

    # 5. Delete
    await service.delete(created.id)

    # 6. Verify deleted
    with pytest.raises({Entity}NotFoundError):
        await service.get_by_id(created.id)
```

## Database State Verification

```python
@pytest.mark.asyncio
async def test_transaction_rollback_preserves_original_state(uow, async_session):
    """Verify transaction rollback on error."""
    service = {Entity}Service(uow=uow)

    # Create entity
    created = await service.create(Create{Entity}Request(name="Test"))

    # Force an error
    try:
        await service.update(
            created.id,
            Update{Entity}Request(name=""),  # Invalid, should fail
        )
    except {Entity}ValidationError:
        pass

    # Verify original state preserved
    retrieved = await service.get_by_id(created.id)
    assert retrieved.name == "Test"  # Unchanged
```

## External Service Integration

```python
import respx


@pytest.mark.asyncio
async def test_create_{entity}_with_external_service_stores_external_id(uow):
    """Test integration with external service."""
    service = {Entity}Service(uow=uow, gateway=real_gateway)

    with respx.mock:
        # Mock external API
        respx.post("https://api.external.com/endpoint").respond(
            json={"id": "ext-123", "status": "success"}
        )

        # Act
        result = await service.create_with_external(
            Create{Entity}Request(name="External Test")
        )

        # Assert
        assert result.external_id == "ext-123"
```

## Performance Considerations

```python
@pytest.mark.asyncio
async def test_bulk_create_{entities}_completes_within_threshold(uow):
    """Test bulk operations complete in reasonable time."""
    import time

    service = {Entity}Service(uow=uow)

    start = time.time()

    # Create 100 entities
    for i in range(100):
        await service.create(Create{Entity}Request(name=f"Bulk {i}"))

    duration = time.time() - start

    # Should complete in under 5 seconds
    assert duration < 5.0
```
