# Dependency Injection Pattern

FastAPI DI chain with type aliases and module-level singletons.

## Location

`src/api/dependencies/`

## Key Rules

1. **Config via DI** - `ConfigDep` for functions needing config
2. **Module-level singletons** - DBManager created with `Config()`
3. **Type aliases** - `Annotated[X, Depends(...)]` for clean signatures
4. **Mock switching via config** - `config.USE_MOCKED_SERVICES`

## DI Chain

```
Config (instantiated, passed via DI)
    │
    ├── DBManager (module-level singleton with Config())
    │       └── Service (request-scoped)
    │
    └── External Services
            ├── config.USE_MOCKED_SERVICES → MockService
            └── else → RealService(client)
```

## Config Dependency

```python
# src/api/dependencies/config.py
def get_config() -> Config:
    return Config()

ConfigDep = Annotated[Config, Depends(get_config)]
```

## Database Dependency

```python
# src/api/dependencies/database.py
from src.config import Config

db_manager = DBManager(Config())  # Module-level singleton

def get_db_manager() -> DBManager:
    return db_manager

DBManagerDep = Annotated[DBManager, Depends(get_db_manager)]
```

## External Service with Config

```python
# src/api/dependencies/services.py
def get_remote_{service}_service(
    config: ConfigDep,
    client: Annotated[{Service}Client, Depends(get_client)],
) -> Abstract{Service}Service:
    if config.USE_MOCKED_SERVICES:
        return Mock{Service}Service()
    return {Service}Service(client=client)

{Service}ServiceDep = Annotated[Abstract{Service}Service, Depends(get_remote_{service}_service)]
```

## Service Dependency

```python
def get_{entity}_service(
    db_manager: DBManagerDep,
    {service}: {Service}ServiceDep,
) -> {Entity}Service:
    return {Entity}Service(db_manager=db_manager, {service}={service})

{Entity}ServiceDep = Annotated[{Entity}Service, Depends(get_{entity}_service)]
```

## Component Lifecycle

| Component | Lifecycle | Why |
|-----------|-----------|-----|
| Config | Instantiated per call | Stateless |
| DBManager | Module singleton | Holds connection pool |
| External Service | Per-request | May have request state |
| Domain Service | Per-request | Fresh UoW per request |

## Anti-Patterns

```python
# BAD: Inline Depends()
service: Service = Depends(get_service)

# GOOD: Type alias
service: {Entity}ServiceDep

# BAD: @lru_cache for singletons
@lru_cache
def get_db_manager(): ...

# GOOD: Module-level singleton
db_manager = DBManager(Config())
```

## Cross-References

- See `config.md` for Config class and ConfigDep
- See `unit-of-work.md` for DBManager
- See `_shared.md` for mock switching pattern
