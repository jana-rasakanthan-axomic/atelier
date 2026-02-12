# Naming Conventions: Complete Example

A full file demonstrating all naming conventions applied together.

```python
# user_service.py

from datetime import datetime
from typing import Protocol

from src.domains.user.models import User
from src.domains.user.repository import UserRepository

# Constants
MAX_LOGIN_ATTEMPTS = 3
DEFAULT_USER_ROLE = "user"

# Type alias
UserId = int

# Exception
class UserNotFoundError(Exception):
    """Raised when user doesn't exist."""

# Service
class UserService:
    """Manages user business logic."""

    def __init__(self, repository: UserRepository):
        self._repository = repository  # Private attribute
        self._cache: dict[UserId, User] = {}

    def get_user_by_id(self, user_id: UserId) -> User | None:
        """Get user by ID, with caching."""
        if user_id in self._cache:
            return self._cache[user_id]

        user = self._fetch_from_db(user_id)  # Private helper
        if user:
            self._cache[user_id] = user
        return user

    def create_user(self, request: CreateUserRequest) -> User:
        """Create new user."""
        is_email_taken = self._repository.exists_by_email(request.email)
        if is_email_taken:
            raise EmailAlreadyExistsError(request.email)

        user = User(
            name=request.name,
            email=request.email,
            role=DEFAULT_USER_ROLE,
            created_at=datetime.now(),
        )

        return self._repository.create(user)

    def _fetch_from_db(self, user_id: UserId) -> User | None:
        """Private helper to fetch from database."""
        return self._repository.get(user_id)

# DTO
class CreateUserRequest(BaseModel):
    """Request to create new user."""
    name: str
    email: EmailStr

class UserResponse(BaseModel):
    """User response DTO."""
    id: int
    name: str
    email: str
    role: str
```
