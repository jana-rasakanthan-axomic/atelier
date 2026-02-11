# Shared Patterns

Common concepts used across multiple patterns.

## Implementation Order: Outside-In (Contract-First)

Build from user-facing API down to database:

```
1. Router (API Layer)   - Request/Response schemas (contract)
         ↓
2. Service Layer        - Business logic, DTOs
         ↓
3. Repository Layer     - Data access, queries
         ↓
4. Models Layer         - ORM entities (if needed)
```

**Rationale:** Start with what the user sees (API contract) and drive implementation from requirements, not database schema.

## Three-Model Strategy

```
Outside-In Data Flow:

Request Schema  →  Service  →  Service DTO  →  Response Schema
(API Input)        (Logic)     (Internal)      (API Output)
                      ↕
                 Repository
                      ↕
                 ORM Entity
                 (Database)
```

- **Request Schema** (API Layer): What client sends (no id, timestamps) - *Define first*
- **Response Schema** (API Layer): Public API contract (may hide fields) - *Define first*
- **Service DTO** (Service Layer): Internal representation (full data) - *Define when needed*
- **ORM Entity** (Models Layer): Database model (relationships, constraints) - *Define last*

**Contract-First Principle:**
- API schemas define the contract (Pydantic models)
- Type hints propagate contract through layers
- mypy validates implementation matches contract

Note: Simple CRUD operations may return ORM entities directly. Use DTOs for complex nested structures.

## Type Alias Pattern

```python
# src/api/dependencies/services.py
from typing import Annotated
from fastapi import Depends

{Entity}ServiceDep = Annotated[{Entity}Service, Depends(get_{entity}_service)]
```

Use in routes: `service: {Entity}ServiceDep` not `service = Depends(...)`.

## Config Dependency Pattern

```python
# src/api/dependencies/config.py
from src.config import Config

def get_config() -> Config:
    return Config()

ConfigDep = Annotated[Config, Depends(get_config)]
```

Use `config: ConfigDep` when function needs config in DI chain.

## Mock Switching Pattern

```python
# src/api/dependencies/services.py
def get_{service}_service(
    config: ConfigDep,
    client: {Service}ClientDep,
) -> Abstract{Service}Service:
    if config.USE_MOCKED_SERVICES:
        return Mock{Service}Service()
    return {Service}Service(client=client)
```

Controlled by `config.USE_MOCKED_SERVICES` flag.

## Module-Level Singletons

```python
# src/api/dependencies/database.py
from src.config import Config
from src.db.main import DBManager

db_manager = DBManager(Config())

def get_db_manager() -> DBManager:
    return db_manager
```

## Union Syntax

Use `X | None` for new code, `Optional[X]` is also acceptable:

```python
# Both acceptable
name: str | None = None
name: Optional[str] = None
```
