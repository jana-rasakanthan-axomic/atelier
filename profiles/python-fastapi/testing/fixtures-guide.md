# Fixture Composition Guide

Detailed examples of pytest fixture organization, composition, and factory patterns for python-fastapi projects.

> Referenced from [unit-tests.md](unit-tests.md)

## Fixture Composition Pattern

Build complex fixtures from simple ones:

```python
# tests/unit/fixtures/users.py
import pytest
from uuid import uuid4


@pytest.fixture
def user_id():
    """Generate a consistent user ID for tests."""
    return uuid4()


@pytest.fixture
def user_data(user_id):
    """Base user data dictionary."""
    return {
        "id": user_id,
        "name": "Test User",
        "email": "test@example.com",
    }


@pytest.fixture
def user_entity(user_data):
    """User ORM entity from data."""
    from src.api.users.models import User
    return User(**user_data)


@pytest.fixture
def user_dto(user_data):
    """User DTO from data."""
    from src.api.users.dto import UserDTO
    return UserDTO(**user_data)
```

## Factory Fixtures for Variability

When tests need variations of the same data:

```python
# tests/unit/fixtures/users.py
@pytest.fixture
def user_factory():
    """Factory to create users with custom attributes."""
    def _create_user(**overrides):
        from src.api.users.models import User
        defaults = {
            "id": uuid4(),
            "name": "Test User",
            "email": "test@example.com",
            "is_active": True,
        }
        return User(**{**defaults, **overrides})
    return _create_user


# Usage in test:
def test_inactive_user_cannot_login(user_factory, service):
    user = user_factory(is_active=False)
    # ...
```
