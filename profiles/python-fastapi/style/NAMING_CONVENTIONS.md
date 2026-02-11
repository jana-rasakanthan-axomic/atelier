# Naming Conventions

**Purpose:** Consistent naming patterns for all generated code.

**Applies To:** Modules, classes, functions, variables, constants

---

## Quick Reference

| Type | Convention | Example |
|------|------------|---------|
| **Module** | snake_case | `user_service.py`, `payment_gateway.py` |
| **Class** | PascalCase | `UserService`, `PaymentGateway` |
| **Function** | snake_case | `get_user_by_id`, `calculate_total` |
| **Variable** | snake_case | `user_count`, `total_amount` |
| **Constant** | UPPER_SNAKE | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |
| **Private** | _leading_underscore | `_internal_method`, `_cache` |
| **DTO/Model** | PascalCase + suffix | `UserResponse`, `CreateUserRequest` |

---

## Modules (Files)

**Format:** `snake_case.py`

### Good Examples

```python
# Descriptive, lowercase, underscores
user_service.py
payment_gateway.py
email_notifications.py
order_repository.py
```

### Bad Examples

```python
# PascalCase (Java style)
UserService.py

# Abbreviations
usrsvc.py

# Camel case
userService.py
```

---

## Classes

**Format:** `PascalCase`

### Good Examples

```python
# Noun, descriptive, PascalCase
class UserService:
    ...

class PaymentGateway:
    ...

class OrderRepository:
    ...

class EmailNotificationService:
    ...
```

### Bad Examples

```python
# snake_case
class user_service:
    ...

# Abbreviations
class UsrSvc:
    ...

# Generic names
class Manager:  # Manager of what?
    ...
```

---

## Functions / Methods

**Format:** `snake_case` (verb + object)

### Good Examples

```python
# Verb + object, descriptive
def get_user_by_id(user_id: int) -> User | None:
    ...

def calculate_total_amount(items: list[OrderItem]) -> Decimal:
    ...

def send_welcome_email(user: User) -> None:
    ...

def validate_email_format(email: str) -> bool:
    ...
```

### Bad Examples

```python
# Too generic
def get(id):  # Get what?
    ...

# Abbreviations
def calc_tot(items):
    ...

# PascalCase (Java style)
def GetUserById(user_id):
    ...

# Single letter
def x(a, b):
    ...
```

---

## Variables

**Format:** `snake_case` (noun, descriptive)

### Good Examples

```python
# Descriptive, clear purpose
user_count = 10
total_amount = Decimal("99.99")
active_users = [u for u in users if u.is_active]
payment_method = "credit_card"
```

### Bad Examples

```python
# Single letter (except loops)
x = 10

# Abbreviations
usr_cnt = 10

# Generic
data = fetch_something()  # What data?
result = process()         # Result of what?

# PascalCase
UserCount = 10
```

---

## Constants

**Format:** `UPPER_SNAKE_CASE`

### Good Examples

```python
# Configuration, limits, defaults
MAX_RETRIES = 3
DEFAULT_TIMEOUT_SECONDS = 30
API_BASE_URL = "https://api.example.com"
CACHE_TTL_MINUTES = 60
```

### Bad Examples

```python
# lowercase
max_retries = 3

# PascalCase
MaxRetries = 3

# Not truly constant (mutable)
DEFAULT_CONFIG = {}  # Can be modified
```

---

## Private Methods/Attributes

**Format:** `_leading_underscore`

### Good Examples

```python
class UserService:
    def __init__(self):
        self._cache = {}  # Private attribute

    def get_user(self, user_id: int) -> User:
        return self._fetch_from_cache_or_db(user_id)  # Public calls private

    def _fetch_from_cache_or_db(self, user_id: int) -> User:  # Private helper
        if user_id in self._cache:
            return self._cache[user_id]
        return self._fetch_from_db(user_id)

    def _fetch_from_db(self, user_id: int) -> User:  # Private helper
        ...
```

### When to Use Private

- Internal helper methods not part of public API
- Implementation details
- Cache or state variables
- Methods called only by other methods in the class

---

## DTOs / Pydantic Models

**Format:** `PascalCase` + suffix (`Request`, `Response`)

### Pattern

```python
# Response DTOs (read operations)
class UserResponse(BaseModel):          # Not: GetUserResponse
    ...

class OrderResponse(BaseModel):
    ...

# Request DTOs (write operations)
class CreateUserRequest(BaseModel):     # Create
    ...

class UpdateUserRequest(BaseModel):     # Update
    ...

# No DTO for DELETE (uses ID in path)
```

### Examples

```python
# Clear, consistent
class UserResponse(BaseModel):
    id: int
    name: str
    email: str

class CreateUserRequest(BaseModel):
    name: str
    email: EmailStr

class UpdateUserRequest(BaseModel):
    name: str | None = None
    email: EmailStr | None = None
```

### Bad Examples

```python
# Generic
class UserDTO:  # DTO for what operation?
    ...

# Abbreviated
class UsrResp:
    ...

# Get prefix (unnecessary)
class GetUserResponse:  # Just UserResponse
    ...

# Input/Output (unclear)
class UserInput:   # Use CreateUserRequest
    ...
```

---

## Repositories

**Format:** `<Entity>Repository`

### Good Examples

```python
class UserRepository:
    def get(self, user_id: int) -> User | None:
        ...

    def list_all(self) -> list[User]:
        ...

class OrderRepository:
    def get_by_user(self, user_id: int) -> list[Order]:
        ...
```

---

## Services

**Format:** `<Domain>Service`

### Good Examples

```python
class UserService:
    ...

class PaymentService:
    ...

class NotificationService:
    ...

class OrderProcessingService:  # OK if multiple words needed
    ...
```

---

## Exceptions

**Format:** `<Error>Error` or `<Error>Exception`

### Good Examples

```python
class UserNotFoundError(Exception):
    ...

class InvalidCredentialsError(Exception):
    ...

class InsufficientStockError(Exception):
    ...

class PaymentFailedException(Exception):  # Exception suffix also OK
    ...
```

### Bad Examples

```python
# Missing Error/Exception suffix
class UserNotFound:
    ...

# Redundant
class UserNotFoundErrorException:
    ...
```

---

## Descriptive Names

**Principle:** Code should read like English.

### Good Examples

```python
# Clear what it does
def get_user_by_id(user_id: int) -> User | None:
    ...

active_users = [user for user in users if user.is_active]

total_amount_with_tax = calculate_total(items) * TAX_RATE
```

### Bad Examples

```python
# Unclear
def get(id):  # Get what? ID of what?
    ...

x = [u for u in users if u.a]  # What is 'a'?

tot = calc(items) * r  # What is 'tot', 'r'?
```

---

## Loop Variables

**Acceptable short names** in short loops:

```python
# OK for short loops
for i in range(10):
    print(i)

for user in users:
    process(user)

for key, value in items.items():
    cache[key] = value
```

**Use descriptive names** in longer loops:

```python
# Better for complex loops
for user_index in range(len(users)):
    user = users[user_index]
    # 20 lines of logic
    ...
```

---

## Booleans

**Format:** Start with `is_`, `has_`, `can_`, `should_`

### Good Examples

```python
is_active: bool
has_subscription: bool
can_edit: bool
should_retry: bool

def is_valid_email(email: str) -> bool:
    ...

def has_permission(user: User, resource: str) -> bool:
    ...
```

### Bad Examples

```python
# Not clear it's boolean
active: bool     # Use: is_active
subscribed: bool # Use: has_subscription
permission: bool # Use: has_permission or can_access
```

---

## Acronyms

**Rule:** Treat acronyms as words, not all-caps.

### Good Examples

```python
# Treat as word
class HttpClient:     # Not: HTTPClient
    ...

api_url = "..."       # Not: API_URL (unless constant)
user_id = 123         # Not: userID
```

### Exceptions

```python
# OK for constants
API_BASE_URL = "https://api.example.com"
HTTP_TIMEOUT_SECONDS = 30
```

---

## Type Aliases

**Format:** `PascalCase` (like classes)

### Good Examples

```python
UserId = int
UserEmail = str
Timestamp = int

async def get_user(user_id: UserId) -> User | None:
    ...
```

---

## Avoid These Patterns

```python
# Single-letter variables (except i, j, k in loops)
x = get_user()

# Numbered variables
user1, user2, user3 = ...

# Hungarian notation
str_name = "John"
int_count = 10

# Type in name (redundant)
user_dict = {}      # Just: users or user_map
items_list = []     # Just: items

# Manager/Handler/Processor without context
class Manager:      # Manager of what?
class Handler:      # Handles what?
```

---

## Complete Example

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

---

## Checklist

When naming, ask:

- Is it descriptive? (Can someone understand without context?)
- Is it consistent with pattern? (snake_case for functions, PascalCase for classes)
- Is it pronounceable? (Can you say it out loud?)
- Is it searchable? (Can you grep for it?)
- Does it avoid abbreviations? (Unless very common: HTTP, API, ID)

---

## Related Documentation

- [Style Limits](./STYLE_LIMITS.md) - Size and formatting limits
- [Models Pattern](../patterns/models.md) - Pydantic model examples

---

**Use these conventions for all generated code to ensure consistency across the codebase.**
