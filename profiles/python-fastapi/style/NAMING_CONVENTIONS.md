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

**Format:** `snake_case.py` -- descriptive, lowercase, underscores. Not `UserService.py`, not `usrsvc.py`.

---

## Classes

**Format:** `PascalCase` -- nouns describing the entity.

```python
class UserService: ...
class PaymentGateway: ...
class OrderRepository: ...
```

Avoid: snake_case classes, abbreviations (`UsrSvc`), generic names (`Manager`).

---

## Functions / Methods

**Format:** `snake_case` (verb + object)

```python
def get_user_by_id(user_id: int) -> User | None: ...
def calculate_total_amount(items: list[OrderItem]) -> Decimal: ...
def send_welcome_email(user: User) -> None: ...
```

Avoid: generic names (`get`, `calc_tot`), PascalCase, single-letter names.

---

## Variables

**Format:** `snake_case` (noun, descriptive)

```python
user_count = 10
total_amount = Decimal("99.99")
active_users = [u for u in users if u.is_active]
```

Avoid: single-letter variables (`x`), abbreviations (`usr_cnt`), generic names (`data`, `result`).

---

## Constants

**Format:** `UPPER_SNAKE_CASE`

```python
MAX_RETRIES = 3
DEFAULT_TIMEOUT_SECONDS = 30
API_BASE_URL = "https://api.example.com"
```

---

## Private Methods/Attributes

**Format:** `_leading_underscore` -- for internal helpers, implementation details, cache/state variables.

```python
class UserService:
    def __init__(self):
        self._cache = {}

    def _fetch_from_cache_or_db(self, user_id: int) -> User: ...
```

---

## DTOs / Pydantic Models

**Format:** `PascalCase` + suffix (`Request`, `Response`)

| Operation | Name | Anti-pattern |
|-----------|------|-------------|
| Read | `UserResponse` | `GetUserResponse`, `UserDTO` |
| Create | `CreateUserRequest` | `UserInput` |
| Update | `UpdateUserRequest` | `UsrResp` |
| Delete | (uses ID in path) | -- |

---

## Repositories

**Format:** `<Entity>Repository` -- e.g., `UserRepository`, `OrderRepository`.

---

## Services

**Format:** `<Domain>Service` -- e.g., `UserService`, `PaymentService`, `NotificationService`.

---

## Exceptions

**Format:** `<Error>Error` or `<Error>Exception`

```python
class UserNotFoundError(Exception): ...
class InvalidCredentialsError(Exception): ...
```

Avoid: missing suffix (`UserNotFound`), redundant suffix (`UserNotFoundErrorException`).

---

## Booleans

**Format:** Start with `is_`, `has_`, `can_`, `should_`

```python
is_active: bool
has_subscription: bool
can_edit: bool

def is_valid_email(email: str) -> bool: ...
```

---

## Loop Variables

Short names (`i`, `key`, `value`) are acceptable in short loops. Use descriptive names in complex loops (>10 lines).

---

## Descriptive Names

Code should read like English. Prefer `total_amount_with_tax` over `tot`. Prefer `get_user_by_id(user_id)` over `get(id)`.

---

## Acronyms

Treat acronyms as words: `HttpClient` not `HTTPClient`, `api_url` not `API_URL` (unless a constant).

---

## Type Aliases

**Format:** `PascalCase` -- `UserId = int`, `UserEmail = str`, `Timestamp = int`.

---

## Anti-Patterns to Avoid

- Single-letter variables (except `i`, `j`, `k` in loops)
- Numbered variables (`user1`, `user2`)
- Hungarian notation (`str_name`, `int_count`)
- Type-in-name (`user_dict`, `items_list` -- just use `users`, `items`)
- Context-free names (`Manager`, `Handler`, `Processor`)

---

> See [naming-example.md](./naming-example.md) for a complete file demonstrating all conventions together.

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
