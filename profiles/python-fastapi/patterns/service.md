# Service Pattern

Business logic layer with DBManager injection.

## Location

`src/api/{domain}/service.py` - Service implementation
`src/api/{domain}/dto.py` - Service DTOs (Data Transfer Objects)

## Key Rules

1. **Contract-first**: Implement from contract specifications (method signatures)
2. **Inject DBManager** - not UnitOfWork directly
3. **Use context manager** - `async with db_manager.uow() as uow:`
4. **No manual commit** - UoW auto-commits on context exit
5. **Return types vary** - ORM entities for simple ops, DTOs for complex nested data
6. **Raise domain exceptions** - no HTTP concerns
7. **Use mappers** - Transform ORM → DTO for complex structures

## Simple CRUD (Returns ORM Entity)

```python
class {Entity}Service:
    def __init__(self, db_manager: DBManager) -> None:
        self.db_manager = db_manager

    async def create(self, request: Create{Entity}Request) -> {Entity}:
        async with self.db_manager.uow() as uow:
            entity = {Entity}(**request.model_dump())
            await uow.{entity}_repo.add(entity)
            return entity  # ORM entity for simple ops
```

## Complex Operations (Returns DTO)

### When to Use DTOs

Use DTOs (not ORM entities) when:
- Complex nested structures (lists, relationships)
- Aggregated data from multiple entities
- Computed/derived fields
- Response needs different shape than ORM

### DTO Definition

```python
# src/api/users/dto.py
from pydantic import BaseModel
from uuid import UUID
from datetime import datetime


class UserDTO(BaseModel):
    """User data transfer object."""
    id: UUID
    name: str
    email: str
    created_at: datetime

    class Config:
        from_attributes = True  # For ORM compatibility


class UserDetailsDTO(BaseModel):
    """User with details."""
    id: UUID
    name: str
    email: str
    created_at: datetime
    post_count: int  # Computed field
    recent_posts: list["PostSummaryDTO"]

    class Config:
        from_attributes = True


class PostSummaryDTO(BaseModel):
    """Post summary for nested data."""
    id: UUID
    title: str
    created_at: datetime

    class Config:
        from_attributes = True
```

### Service with DTO Return

```python
# src/api/users/service.py
async def get_with_details(self, id: UUID) -> UserDetailsDTO:
    async with self.db_manager.uow() as uow:
        user = await uow.user_repo.get_by_id_with_posts(id)
        if not user:
            raise UserNotFoundError(id)

        # Use mapper to transform ORM → DTO
        return self._map_to_details_dto(user)


def _map_to_details_dto(self, user: User) -> UserDetailsDTO:
    """Map ORM entity to DTO with nested data."""
    return UserDetailsDTO(
        id=user.id,
        name=user.name,
        email=user.email,
        created_at=user.created_at,
        post_count=len(user.posts),  # Computed
        recent_posts=[
            PostSummaryDTO(
                id=post.id,
                title=post.title,
                created_at=post.created_at,
            )
            for post in user.posts[:5]  # Recent 5
        ],
    )
```

## External Service Integration

```python
class {Entity}Service:
    def __init__(
        self,
        db_manager: DBManager,
        external_service: Abstract{Service}Service,
    ) -> None:
        self.db_manager = db_manager
        self.external_service = external_service

    async def create_from_external(self, external_id: UUID) -> {Entity}:
        # Call external service first
        external_data = await self.external_service.get(external_id)

        # Then use UoW for DB operations
        async with self.db_manager.uow() as uow:
            entity = {Entity}(external_id=external_data.id, ...)
            await uow.{entity}_repo.add(entity)
            return entity
```

## Anti-Patterns

```python
# BAD: Manual commit
async with db_manager.uow() as uow:
    await uow.repo.create(entity)
    await uow.commit()  # Unnecessary

# GOOD: Auto-commit on context exit
async with db_manager.uow() as uow:
    await uow.repo.create(entity)

# BAD: HTTP concerns
raise HTTPException(status_code=404)

# GOOD: Domain exceptions
raise {Entity}NotFoundError(id)
```

## Cross-References

- See `_shared.md` for three-model strategy and data flow
- See `unit-of-work.md` for DBManager + UoW
- See `exceptions.md` for domain exceptions
- See `external-integration.md` for external service dependencies
- See `../../testing/TEST_FIRST.md` for test-first workflow with contract specs
- See `../../testing/unit-tests.md` for service testing with mocked repositories
