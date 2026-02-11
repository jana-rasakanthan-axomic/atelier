# Exceptions Pattern

Domain exception hierarchy with global FastAPI handlers.

## Location

- `src/exceptions.py` - All domain exceptions
- `src/exception_handlers.py` - Global FastAPI handlers

## Key Rules

1. **Single base exception** - All inherit from `{Service}Error`
2. **Use `message`, `detail`, `context`** - structured error data
3. **ResourceNotFoundMixin** - DRY pattern for "X with id Y not found"
4. **Global handlers** - translate exceptions to HTTP responses
5. **No HTTP concerns in domain** - services raise domain exceptions

## Base Exception

```python
class {Service}Error(Exception):
    def __init__(
        self,
        message: str,
        detail: dict[str, Any] | None = None,
        context: dict[str, Any] | None = None,
    ):
        self.message = message
        self.detail = detail or {"message": message}
        self.context = context or {}
        super().__init__(self.message)
```

## ResourceNotFoundMixin

```python
class ResourceNotFoundMixin:
    RESOURCE_NAME: str = "Resource"
    ID_FIELD_NAME: str = "id"

    def __init__(self, resource_id: UUID | str):
        message = f"{self.RESOURCE_NAME} with id {resource_id} not found"
        context = {self.ID_FIELD_NAME: str(resource_id)}
        super().__init__(message=message, context=context)

class {Entity}NotFoundError(ResourceNotFoundMixin, NotFoundError):
    RESOURCE_NAME = "{Entity}"
    ID_FIELD_NAME = "{entity}_id"
```

## Exception Handler Registration

```python
# src/exception_handlers.py
exception_handlers: dict[type, callable] = {
    {Service}Error: known_exception_handler,
    RequestValidationError: request_validation_error_handler,
    Exception: generic_exception_handler,
}

# src/main.py
app = FastAPI(exception_handlers=exception_handlers)
```

## Exception Hierarchy

```
{Service}Error (base)
├── NotFoundError → 404
│   └── {Entity}NotFoundError (via ResourceNotFoundMixin)
├── InvalidOperationError → 422
├── DuplicateResourceError → 422
├── UnauthorizedAccessError → 403
└── ExternalServiceError → 502
```

## Anti-Patterns

```python
# BAD: HTTP concerns in service
raise HTTPException(status_code=404)

# GOOD: Domain exceptions
raise {Entity}NotFoundError(id)

# BAD: Try/except in routes
try:
    return await service.get(id)
except NotFoundError:
    raise HTTPException(404)

# GOOD: Global handlers
return await service.get(id)  # Exception handled globally
```

## Cross-References

- See `router.md` for clean routes
- See `service.md` for exception usage
