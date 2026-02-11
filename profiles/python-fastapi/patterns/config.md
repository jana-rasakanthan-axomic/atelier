# Config Pattern

Environment configuration using `axomic_python_basics.config.EnvironConfig`.

## Location

`src/config.py`

## Key Rules

1. **Use EnvironConfig** - not `pydantic_settings`
2. **Instantiate for DI** - `Config()` when passing to dependencies
3. **Class attributes available** - can also access `Config.ATTR` directly
4. **ConfigDep for injection** - type alias for DI chain

## Config Class

```python
from axomic_python_basics import config, logging

class Config(config.EnvironConfig):
    class Meta:
        prefix = ""

    # Required (no default)
    DB_NAME: str
    DB_USERNAME: str
    DB_PASSWORD: str

    # Optional (with defaults)
    DB_HOST: str = "localhost"
    DB_PORT: int = 5432
    USE_MOCKED_SERVICES: bool = False
    DEBUG: bool = False

log = logging.setup_logging(
    loglevel=Config.LOG_LEVEL,
    log_to_console=Config.LOG_TO_CONSOLE,
)
```

## Config Dependency

```python
# src/api/dependencies/config.py
from typing import Annotated
from fastapi import Depends
from src.config import Config

def get_config() -> Config:
    return Config()

ConfigDep = Annotated[Config, Depends(get_config)]
```

## Usage Patterns

```python
# In DI chain - use ConfigDep
def get_db_manager(config: ConfigDep) -> DBManager:
    return DBManager(config)

# In module-level singleton
db_manager = DBManager(Config())

# Direct access for constants
from src.config import Config
if Config.DEBUG:
    print("Debug mode")
```

## Anti-Patterns

```python
# BAD: pydantic_settings
from pydantic_settings import BaseSettings
class Settings(BaseSettings): ...

# GOOD: EnvironConfig
from axomic_python_basics import config
class Config(config.EnvironConfig): ...
```

## Cross-References

- See `dependency-injection.md` for DI chain
- See `unit-of-work.md` for DBManager(Config())
