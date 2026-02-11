# Unit of Work Pattern

DBManager with async context manager for transaction management.

## Location

`src/db/main.py`

## Key Rules

1. **Auto-commit on success** - `__aexit__` commits if no exception
2. **Auto-rollback on exception** - context manager handles cleanup
3. **Eager repository init** - repos in `__init__`, not lazy properties
4. **No manual commit** - context exit handles transaction
5. **DBManager takes Config** - `DBManager(config)` not direct access

## UnitOfWork Pattern

```python
class UnitOfWork:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session
        self.{entity}_repo = {Entity}Repository(session)  # Eager init

    async def __aenter__(self) -> "UnitOfWork":
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> bool:
        if exc_type:
            await self.rollback()
        else:
            await self.commit()
        await self.session.close()
        return False
```

## DBManager Pattern

```python
from typing import Optional

class DBManager:
    def __init__(self, config: Config) -> None:
        self.config = config
        self._engine: Optional[AsyncEngine] = None

    @property
    def db_url(self) -> str:
        return f"postgresql+asyncpg://{self.config.DB_USERNAME}:{self.config.DB_PASSWORD}@{self.config.DB_HOST}:{self.config.DB_PORT}/{self.config.DB_NAME}"

    def uow(self) -> UnitOfWork:
        return UnitOfWork(self.session_maker())
```

## Module-Level Singleton

```python
# src/api/dependencies/database.py
from src.config import Config
from src.db.main import DBManager

db_manager = DBManager(Config())

def get_db_manager() -> DBManager:
    return db_manager

DBManagerDep = Annotated[DBManager, Depends(get_db_manager)]
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

# BAD: Lazy repo initialization
@property
def entity_repo(self):
    if "entity" not in self._repos: ...

# GOOD: Eager in __init__
self.entity_repo = EntityRepository(session)
```

## Cross-References

- See `config.md` for Config class
- See `dependency-injection.md` for singleton setup
- See `repository.md` for repository implementation
