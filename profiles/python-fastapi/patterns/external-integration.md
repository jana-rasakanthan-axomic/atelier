# External Integration Pattern

HTTP client wrappers for external services with abstract base, real/mock implementations, and config-based switching.

## Location

```
src/externals/{service}/
├── base.py           # Abstract base class
├── real.py           # Real implementation
├── mock.py           # Mock for testing
├── dto.py            # Pydantic DTOs
└── {service}_client.py  # HTTP client wrapper
```

## Key Rules

1. **Abstract base class** - defines contract for real/mock implementations
2. **Config flag switches** - `config.USE_MOCKED_SERVICES` via DI
3. **HTTP client wrapper** - encapsulates retry, base URL, auth
4. **Exception mapping** - HTTP status codes → domain exceptions
5. **Pydantic DTOs** - use `BaseModel` for responses

## Abstract Base Class

```python
# src/externals/{service}/base.py
from abc import ABC, abstractmethod

class Abstract{Service}Service(ABC):
    @abstractmethod
    async def get_{entity}(
        self, id: UUID, customer_id: UUID, user_id: UUID
    ) -> {Entity}DTO:
        pass
```

## Real Implementation

```python
# src/externals/{service}/real.py
class {Service}Service(Abstract{Service}Service):
    def __init__(self, client: {Service}Client) -> None:
        self.client = client

    async def get_{entity}(
        self, id: UUID, customer_id: UUID, user_id: UUID
    ) -> {Entity}DTO:
        params = {"customer_id": str(customer_id), "user_id": str(user_id)}
        response = await self.client.get(f"/{entities}/{id}", params=params)
        return {Entity}DTO(**response)
```

## HTTP Client Wrapper

```python
# src/externals/{service}/{service}_client.py
class {Service}Client:
    def __init__(self, microservice_name: str, api_retries: int = 3) -> None:
        self.base_url = SHREDAI_BASE_URL_MAPPING[microservice_name]
        self.api_retries = api_retries

    async def get_rest_client(self) -> AsyncClient:
        return httpx.AsyncClient(
            base_url=self.base_url,
            timeout=30.0,
        )
```

## Mock Switching (DI)

```python
# src/api/dependencies/services.py
def get_{service}_client(config: ConfigDep) -> {Service}Client:
    return {Service}Client(
        microservice_name="{SERVICE}",
        api_retries=config.API_RETRIES,
    )

def get_{service}_service(
    config: ConfigDep,
    client: Annotated[{Service}Client, Depends(get_{service}_client)],
) -> Abstract{Service}Service:
    if config.USE_MOCKED_SERVICES:
        return Mock{Service}Service()
    return {Service}Service(client=client)

{Service}ServiceDep = Annotated[Abstract{Service}Service, Depends(get_{service}_service)]
```

## Exception Mapping

```python
FAILURE_EXCEPTIONS = {
    404: {Entity}NotFoundError,
    422: UnprocessableEntityError,
}

async def _request(self, method: str, url: str, ...) -> dict:
    try:
        response = await client.request(method, url, ...)
    except HTTPStatusError as ex:
        status = ex.response.status_code
        if status in FAILURE_EXCEPTIONS:
            raise FAILURE_EXCEPTIONS[status](...) from ex
        raise ExternalServiceError(...) from ex
```

## Anti-Patterns

```python
# BAD: Hardcoded URLs
client = httpx.AsyncClient(base_url="https://api.example.com")

# GOOD: Config-driven via client wrapper
client = {Service}Client(microservice_name="{SERVICE}")

# BAD: No abstract base
class RealService: ...
class MockService: ...  # Different contract possible

# GOOD: Abstract base enforces contract
class AbstractService(ABC): ...
class RealService(AbstractService): ...
class MockService(AbstractService): ...
```

## Cross-References

- See `_shared.md` for mock switching pattern
- See `config.md` for base URL mappings
- See `exceptions.md` for `ExternalServiceError`
