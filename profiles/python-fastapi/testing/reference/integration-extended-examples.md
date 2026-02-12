# Integration Tests: Extended Examples

Additional integration test patterns for python-fastapi.

> Referenced from [integration-tests.md](../integration-tests.md)

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
