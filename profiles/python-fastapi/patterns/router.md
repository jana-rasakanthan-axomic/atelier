# Router Pattern

FastAPI endpoints with type aliases and global exception handling.

## Location

`src/api/{domain}/routes.py` - API endpoints
`src/api/{domain}/schemas.py` - Request/Response Pydantic models

## Key Rules

1. **Contract-first**: Start with request/response schemas (Pydantic models)
2. **Type aliases for DI** - `{Entity}ServiceDep` not inline `Depends()`
3. **Global exception handlers** - no try/except in routes
4. **Transform DTO → Response** - don't return DTOs directly
5. **Appropriate status codes** - 201 for create, 204 for delete

## Contract-First Workflow

When implementing from contract specifications:

1. **Create schemas first** (`schemas.py`) - Request/Response Pydantic models from contract specs
2. **Write route tests** (`tests/unit/api/{domain}/test_routes.py`) - Mock service layer
3. **Implement routes** (`routes.py`) - Use schemas, call service
4. **Run tests** - Validate API contract

## Contract-First Example

### Step 1: Schemas (from contract specs)

```python
# src/api/users/schemas.py
from pydantic import BaseModel, EmailStr, Field
from uuid import UUID
from datetime import datetime


class CreateUserRequest(BaseModel):
    """User creation request (from contract spec)."""
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr


class UpdateUserRequest(BaseModel):
    """User update request."""
    name: str | None = Field(None, min_length=1, max_length=100)
    email: EmailStr | None = None


class UserResponse(BaseModel):
    """User response (public API contract)."""
    id: UUID
    name: str
    email: str
    created_at: datetime

    class Config:
        from_attributes = True  # For ORM compatibility
```

### Step 2: Routes (implement after schemas)

```python
# src/api/users/routes.py
from fastapi import APIRouter, status
from uuid import UUID

from src.api.users.schemas import (
    CreateUserRequest,
    UpdateUserRequest,
    UserResponse,
)
from src.api.dependencies.services import UserServiceDep


router = APIRouter(prefix="/users", tags=["users"])


@router.get("/{id}", response_model=UserResponse)
async def get_user(
    id: UUID,
    service: UserServiceDep,
) -> UserResponse:
    """Get user by ID."""
    user = await service.get_by_id(id)
    return UserResponse.model_validate(user)


@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    request: CreateUserRequest,
    service: UserServiceDep,
) -> UserResponse:
    """Create new user."""
    user = await service.create(request)
    return UserResponse.model_validate(user)


@router.patch("/{id}", response_model=UserResponse)
async def update_user(
    id: UUID,
    request: UpdateUserRequest,
    service: UserServiceDep,
) -> UserResponse:
    """Update user."""
    user = await service.update(id, request)
    return UserResponse.model_validate(user)


@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(id: UUID, service: UserServiceDep) -> None:
    """Delete user."""
    await service.delete(id)
```

## HTTP Status Code Mapping

| Domain Exception | HTTP Status |
|------------------|-------------|
| `NotFoundError` | 404 |
| `InvalidOperationError` | 422 |
| `DuplicateResourceError` | 422 |
| `UnauthorizedAccessError` | 403 |
| `ExternalServiceError` | 502 |

## Anti-Patterns

```python
# BAD: Try/except in routes
@router.get("/{id}")
async def get(id: UUID, service = Depends(get_service)):
    try:
        return await service.get(id)
    except NotFoundError:
        raise HTTPException(404)

# GOOD: Global handlers
@router.get("/{id}")
async def get(id: UUID, service: ServiceDep):
    return await service.get(id)

# BAD: Inline Depends()
service: Service = Depends(get_service)

# GOOD: Type alias
service: {Entity}ServiceDep

# BAD: Return DTO directly
return await service.get_by_id(id)

# GOOD: Transform to Response
dto = await service.get_by_id(id)
return {Entity}Response.model_validate(dto)
```

## Cross-References

- See `_shared.md` for type alias pattern and three-model strategy
- See `exceptions.md` for global handlers
- See `service.md` for service layer
- See `../../testing/TEST_FIRST.md` for test-first workflow with contract specs
- See `../../testing/unit-tests.md` for route testing with mocked services
