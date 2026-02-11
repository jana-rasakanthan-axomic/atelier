# Repository Pattern

Data access layer using SQLAlchemy 2.0 async patterns.

## Location

`src/db/repositories/{domain}_repository.py`

## Key Rules

1. **Contract-first**: Implement from contract specifications (method signatures with type hints)
2. **Use `select()` not `query()`** - SQLAlchemy 2.0 style
3. **Use `flush()` not `commit()`** - UoW handles commit
4. **Strict type annotations**: `Entity | None` for single, `list[Entity]` for multiple, `AsyncIterator[list[Entity]]` for streaming
5. **No business logic** - pure data access only

## Type Annotations (CRITICAL)

All repository methods MUST have:
- **Parameter types**: e.g., `id: UUID`, `email: str`, `limit: int`
- **Return types**: e.g., `-> User | None`, `-> list[User]`, `-> AsyncIterator[list[User]]`
- **Async markers**: `async def` for async methods

Type hints enable:
- mypy validation (catches type errors before runtime)
- IDE autocomplete and type checking
- Self-documenting code (contract is in the signature)

## Minimal Example (Contract-First with Type Annotations)

```python
# src/db/repositories/user_repository.py
from uuid import UUID
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.users.models import User


class UserRepository:
    """User data access layer.

    All methods have strict type annotations for contract validation.
    """

    def __init__(self, session: AsyncSession) -> None:
        """Initialize repository with async session."""
        self.session = session

    async def get_by_id(self, id: UUID) -> User | None:
        """Get user by ID.

        Args:
            id: User UUID

        Returns:
            User if found, None otherwise
        """
        query = select(User).where(User.id == id)
        result = await self.session.execute(query)
        return result.scalars().first()

    async def get_by_email(self, email: str) -> User | None:
        """Get user by email (unique constraint).

        Args:
            email: User email address

        Returns:
            User if found, None otherwise
        """
        query = select(User).where(User.email == email)
        result = await self.session.execute(query)
        return result.scalars().first()

    async def get_all(self, limit: int = 100, offset: int = 0) -> list[User]:
        """Get all users with pagination.

        Args:
            limit: Maximum number of users to return
            offset: Number of users to skip

        Returns:
            List of users (may be empty)
        """
        query = select(User).limit(limit).offset(offset)
        result = await self.session.execute(query)
        return list(result.scalars().all())

    async def create(self, entity: User) -> User:
        """Create new user.

        Args:
            entity: User entity to create

        Returns:
            Created user with ID populated
        """
        self.session.add(entity)
        await self.session.flush()
        await self.session.refresh(entity)
        return entity

    async def delete(self, entity: User) -> None:
        """Delete user.

        Args:
            entity: User entity to delete
        """
        self.session.delete(entity)  # Note: NOT async
        await self.session.flush()
```

## Common Methods

| Method | Return Type | Purpose |
|--------|-------------|---------|
| `get_by_id(id)` | `Entity \| None` | Single lookup |
| `get_all(limit, offset)` | `list[Entity]` | Paginated list |
| `create(entity)` | `Entity` | Insert new |
| `update(entity)` | `Entity` | Update existing |
| `delete(entity)` | `None` | Remove |

## Anti-Patterns

```python
# BAD: query() - SQLAlchemy 1.x
result = await self.session.query(Entity).filter_by(id=id).first()

# GOOD: select() - SQLAlchemy 2.0
query = select(Entity).where(Entity.id == id)
result = await self.session.execute(query)

# BAD: Committing in repository
await self.session.commit()

# GOOD: Flushing only
await self.session.flush()
```

## Cross-References

- See `unit-of-work.md` for UoW that manages repos
- See `models.md` for ORM entity definitions
- See `../../testing/TEST_FIRST.md` for test-first workflow with contract specs
- See `../../testing/unit-tests.md` for repository testing patterns
