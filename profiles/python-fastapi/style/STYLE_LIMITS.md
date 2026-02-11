# Code Style Limits

**Purpose:** Size and formatting limits for generated code.

**Enforced By:** ruff, mypy, commands (`/fix`, `/build`)

---

## Quick Reference

| Metric | Ideal (Green) | Warning (Yellow) | Refactor (Red) |
|--------|---------------|------------------|----------------|
| **Line length** | 79-88 chars | 100 chars | >120 chars |
| **Function length** | 5-15 lines | 25 lines | >50 lines |
| **Function args** | 0-2 args | 3 args | >3 args |
| **Class length** | <200 lines | 300 lines | >400 lines |
| **File length** | <300 lines | 400 lines | >500 lines |
| **Cyclomatic complexity** | ≤5 | ≤10 | >10 |

---

## Line Length

**Default:** 88 characters (black/ruff default)

```python
# Good - 88 chars or less
user = repository.get_by_email(email)

# Warning - approaching 100 chars, consider breaking
result = service.process_payment(user_id, amount, currency, payment_method, metadata)

# Bad - over 120 chars, must break
result = service.process_payment(user_id=user_id, amount=total_amount, currency=selected_currency, payment_method=user_payment_method, additional_metadata=request_metadata)
```

**How to break long lines:**
```python
# Option 1: Arguments on separate lines
result = service.process_payment(
    user_id=user_id,
    amount=total_amount,
    currency=selected_currency,
    payment_method=user_payment_method,
)

# Option 2: Extract to variable
payment_data = PaymentRequest(
    user_id=user_id,
    amount=total_amount,
    currency=selected_currency,
)
result = service.process_payment(payment_data)
```

---

## Function Length

**Target:** 5-15 lines (ideal), 25 lines (warning), >50 lines (refactor)

**Why:** Functions should fit on one screen without scrolling. If you need to scroll, cognitive context is lost.

### Good Example (12 lines)

```python
def create_user(self, dto: CreateUserDTO) -> User:
    """Create new user with validation."""
    if self.repository.exists_by_email(dto.email):
        raise UserAlreadyExistsError(dto.email)

    user = User(
        name=dto.name,
        email=dto.email,
        created_at=datetime.now(UTC),
    )

    return self.repository.create(user)
```

### Needs Refactoring (>50 lines)

```python
# Too long - extract helpers
def process_order(self, dto: CreateOrderDTO) -> Order:
    # Validation (10 lines)
    if not dto.items:
        raise ValidationError("No items")
    if dto.total < 0:
        raise ValidationError("Negative total")
    # ... more validation

    # User lookup (5 lines)
    user = self.user_repository.get(dto.user_id)
    if not user:
        raise UserNotFoundError(dto.user_id)

    # Inventory check (10 lines)
    for item in dto.items:
        stock = self.inventory.get(item.product_id)
        if stock < item.quantity:
            raise InsufficientStockError(item.product_id)

    # Payment processing (15 lines)
    payment = self.payment_gateway.charge(...)
    # ... payment logic

    # Order creation (10 lines)
    order = Order(...)
    # ... order logic

    return order  # Total: 50+ lines
```

### Refactored (3 functions, each <15 lines)

```python
# Good - each function does one thing
def process_order(self, dto: CreateOrderDTO) -> Order:
    self._validate_order(dto)
    self._ensure_inventory(dto.items)
    payment = self._process_payment(dto)
    return self._create_order(dto, payment)

def _validate_order(self, dto: CreateOrderDTO) -> None:
    if not dto.items:
        raise ValidationError("No items")
    if dto.total < 0:
        raise ValidationError("Negative total")
    # ... other validation

def _ensure_inventory(self, items: list[OrderItem]) -> None:
    for item in items:
        stock = self.inventory.get(item.product_id)
        if stock < item.quantity:
            raise InsufficientStockError(item.product_id)

def _process_payment(self, dto: CreateOrderDTO) -> Payment:
    return self.payment_gateway.charge(
        amount=dto.total,
        currency=dto.currency,
        user_id=dto.user_id,
    )
```

---

## Function Parameters

**Target:** 0-2 args (ideal), 3 args (warning), >3 args (use DTO)

### Good Examples

```python
# 0 args (query method)
def list_all_users(self) -> list[User]:
    return self.repository.list_all()

# 1 arg
def get_user(self, user_id: int) -> User | None:
    return self.repository.get(user_id)

# 2 args
def authenticate(self, email: str, password: str) -> User | None:
    return self.auth_service.authenticate(email, password)
```

### Use DTO for >3 Parameters

```python
# Too many parameters
def create_user(
    self,
    name: str,
    email: str,
    password: str,
    role: str,
    department: str,
    manager_id: int | None,
    hire_date: date,
) -> User:
    ...

# Use Pydantic DTO
def create_user(self, dto: CreateUserDTO) -> User:
    ...
```

---

## Class Length

**Target:** <200 lines (ideal), 300 lines (warning), >400 lines (refactor)

**Single Responsibility Principle:** A class should have one reason to change.

### Good Example (<200 lines)

```python
class UserService:
    """Manages user business logic."""

    def __init__(self, repository: UserRepository):
        self.repository = repository

    def create_user(self, dto: CreateUserDTO) -> User:
        # 10 lines

    def get_user(self, user_id: int) -> User | None:
        # 5 lines

    def update_user(self, user_id: int, dto: UpdateUserDTO) -> User:
        # 15 lines

    def delete_user(self, user_id: int) -> None:
        # 5 lines

    def list_users(self, filters: UserFilters) -> list[User]:
        # 10 lines
```

### Needs Refactoring (>400 lines)

If a class exceeds 400 lines, it's doing too much. **Extract** related methods into separate classes:

```python
# UserService is too large (handles users, auth, notifications, analytics)

# Split into focused classes:
class UserService:           # User CRUD
class AuthService:           # Authentication/authorization
class NotificationService:   # User notifications
class UserAnalyticsService:  # User metrics
```

---

## File / Module Size

**Target:** 200-300 lines (ideal), 400 lines (warning), >500 lines (refactor)

**Python allows multiple classes per file** if they're cohesive.

### When to Group in One File

```python
# exceptions.py - related exceptions
class UserNotFoundError(Exception): ...
class UserAlreadyExistsError(Exception): ...
class InvalidCredentialsError(Exception): ...

# models.py - related Pydantic models
class UserBase(BaseModel): ...
class CreateUserRequest(UserBase): ...
class UpdateUserRequest(BaseModel): ...
class UserResponse(UserBase): ...
```

### When to Split Files

```python
# service.py is 600 lines with UserService + OrderService + PaymentService

# Split:
# services/user_service.py
# services/order_service.py
# services/payment_service.py
```

---

## Cyclomatic Complexity

**Target:** ≤5 (ideal), ≤10 (warning), >10 (refactor)

**What it measures:** Number of decision points (if, elif, else, for, while, and, or, try/except)

### Low Complexity (2)

```python
def is_adult(age: int) -> bool:
    if age >= 18:        # 1 decision
        return True
    return False
```

### High Complexity (>10) - Refactor

```python
# Complexity: 12
def calculate_discount(user, order, promo_code):
    if user.is_premium:                      # 1
        if order.total > 100:                # 2
            discount = 0.20
        elif order.total > 50:               # 3
            discount = 0.15
        else:
            discount = 0.10
    elif promo_code:                         # 4
        if promo_code == "SAVE20":           # 5
            discount = 0.20
        elif promo_code == "SAVE10":         # 6
            discount = 0.10
        else:
            discount = 0.05
    elif order.total > 200:                  # 7
        discount = 0.10
    elif order.total > 100:                  # 8
        discount = 0.05
    else:
        discount = 0.0

    if user.first_order:                     # 9
        discount += 0.05

    if order.has_subscription:               # 10
        discount += 0.05

    return min(discount, 0.50)
```

### Refactored (Complexity: 3 per function)

```python
# Extract logic
def calculate_discount(user, order, promo_code):
    base_discount = self._get_base_discount(user, order, promo_code)
    bonus_discount = self._get_bonus_discount(user, order)
    return min(base_discount + bonus_discount, 0.50)

def _get_base_discount(user, order, promo_code):
    if user.is_premium:
        return self._premium_discount(order.total)
    if promo_code:
        return self._promo_discount(promo_code)
    return self._order_total_discount(order.total)
```

---

## Comments

**Rule:** Comments explain WHY, not WHAT. Code should be self-documenting.

### Bad Comments (Redundant)

```python
# Repeats what the code says
# Get the user by email
user = repository.get_by_email(email)

# States the obvious
# Check if user exists
if user is None:

# Describes the operation
# Create a new user with the given data
user = User(name=dto.name, email=dto.email)

# Compensating transaction comment that repeats the method name
# Delete Auth0 user on local failure
await self._auth0_gateway.delete_user(auth0_id)
```

### Good Comments (Add Value)

```python
# Explains WHY, not WHAT
# Auth0 user must be deleted if local DB fails to prevent orphaned accounts
await self._auth0_gateway.delete_user(auth0_id)

# Documents non-obvious constraint
# Password validated by Pydantic schema, never stored locally
access_token = await gateway.get_access_token(email, password)

# Explains business rule
# Premium users get priority queue processing regardless of order time
if user.is_premium:
    queue = self.priority_queue

# Documents edge case
# Empty list is valid - user may have no recipes yet
return recipes or []

# Explains technical decision
# Using selectinload to avoid N+1 queries on recipe.ingredients
query = select(Recipe).options(selectinload(Recipe.ingredients))
```

### When Comments Are Needed

| Scenario | Comment Type |
|----------|--------------|
| Non-obvious business logic | Explain the rule |
| Workaround for bug/limitation | Link to issue |
| Performance optimization | Explain why faster |
| Security consideration | Document the risk |
| API contract constraint | Document requirement |

### When Comments Are NOT Needed

| Scenario | Instead |
|----------|---------|
| What a variable holds | Use descriptive name |
| What a function does | Use clear function name |
| What a loop iterates | Self-evident from code |
| Simple conditionals | Code is self-documenting |
| Type information | Use type hints |

### Docstrings vs Inline Comments

```python
# Docstring for public API
def create_user(self, dto: CreateUserDTO) -> User:
    """Create a new user with email verification.

    Args:
        dto: User creation data with email and password.

    Returns:
        Created user with generated ID.

    Raises:
        EmailAlreadyExistsError: If email is registered.
    """
    ...

# Inline comment for non-obvious implementation detail
async def signup(self, email: str, password: str) -> User:
    auth0_user = await self._auth0.create_user(email, password)

    try:
        user = await self._repository.create(User(auth0_id=auth0_user.id))
    except Exception:
        # Rollback Auth0 user to prevent orphaned external accounts
        await self._auth0.delete_user(auth0_user.id)
        raise

    return user
```

---

## Import Organization

**Order:** Standard library → Third-party → Local

```python
# Correct order
# Standard library
from datetime import datetime
from typing import Any
from uuid import UUID

# Third-party
import sqlalchemy as sa
from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel, EmailStr

# Local
from src.domains.user.models import User
from src.domains.user.repository import UserRepository
from src.infrastructure.database import get_session
```

**Enforced by:** `ruff` with `I` (isort) rules

---

## Enforcement with Ruff

**Configuration** (in `pyproject.toml`):

```toml
[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = [
    "E",       # pycodestyle errors
    "W",       # pycodestyle warnings
    "F",       # Pyflakes
    "I",       # isort (import organization)
    "C4",      # flake8-comprehensions
]

extend-select = [
    "C901",    # McCabe complexity (≤10)
    "PLR0911", # Too many return statements
    "PLR0912", # Too many branches
    "PLR0913", # Too many arguments (≤5)
    "PLR0915", # Too many statements (≤50)
]

[tool.ruff.lint.mccabe]
max-complexity = 10

[tool.ruff.lint.pylint]
max-args = 5
max-statements = 50
```

---

## When to Break the Rules

**Rarely.** These limits exist for good reasons:
- Readability
- Maintainability
- Cognitive load
- Testing ease

**If you must:**
1. Add `# ruff: noqa: <rule>` comment with justification
2. Ensure PR reviewer agrees

```python
# Complex algorithm that can't be simplified
def calculate_tax(  # ruff: noqa: PLR0913
    income: float,
    deductions: float,
    credits: float,
    state: str,
    filing_status: str,
    dependents: int,
) -> float:
    # Tax calculation requires all parameters
    ...
```

---

## Related Documentation

- [Naming Conventions](./NAMING_CONVENTIONS.md) - How to name things
- [Repository Pattern](../patterns/repository.md) - Repository examples
- [Service Pattern](../patterns/service.md) - Service examples

---

**Use these limits when generating code to ensure all code meets quality standards.**
