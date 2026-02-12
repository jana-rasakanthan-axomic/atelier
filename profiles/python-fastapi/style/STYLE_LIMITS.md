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
| **Cyclomatic complexity** | <=5 | <=10 | >10 |

---

## Line Length

**Default:** 88 characters (black/ruff default)

```python
# Bad - over 120 chars, must break
result = service.process_payment(user_id=user_id, amount=total_amount, currency=selected_currency, payment_method=user_payment_method, additional_metadata=request_metadata)

# Good - arguments on separate lines or extracted to a DTO
result = service.process_payment(
    user_id=user_id,
    amount=total_amount,
    currency=selected_currency,
)
```

---

## Function Length

**Target:** 5-15 lines (ideal), 25 lines (warning), >50 lines (refactor)

Functions should fit on one screen. If you need to scroll, extract helpers.

```python
# Good (12 lines)
def create_user(self, dto: CreateUserDTO) -> User:
    if self.repository.exists_by_email(dto.email):
        raise UserAlreadyExistsError(dto.email)

    user = User(
        name=dto.name,
        email=dto.email,
        created_at=datetime.now(UTC),
    )
    return self.repository.create(user)
```

> See [refactoring-guide.md](./refactoring-guide.md) for before/after examples of extracting long functions.

---

## Function Parameters

**Target:** 0-2 args (ideal), 3 args (warning), >3 args (use DTO)

```python
# Good - 2 args
def authenticate(self, email: str, password: str) -> User | None: ...

# Too many - use a DTO
def create_user(self, dto: CreateUserDTO) -> User: ...
```

---

## Class Length

**Target:** <200 lines (ideal), 300 lines (warning), >400 lines (refactor)

**Single Responsibility:** A class should have one reason to change. If a class handles users, auth, notifications, and analytics -- split it into `UserService`, `AuthService`, `NotificationService`, `UserAnalyticsService`.

---

## File / Module Size

**Target:** 200-300 lines (ideal), 400 lines (warning), >500 lines (refactor)

Group cohesive items in one file (e.g., related exceptions, related Pydantic models). Split when a file contains unrelated classes.

---

## Cyclomatic Complexity

**Target:** <=5 (ideal), <=10 (warning), >10 (refactor)

**What it measures:** Number of decision points (if, elif, else, for, while, and, or, try/except).

```python
# Low complexity (2) - good
def is_adult(age: int) -> bool:
    if age >= 18:
        return True
    return False
```

For high-complexity refactoring, extract decision logic into separate functions.

> See [refactoring-guide.md](./refactoring-guide.md) for complexity refactoring examples.

---

## Comments

**Rule:** Comments explain WHY, not WHAT. Code should be self-documenting.

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

### Examples

```python
# Bad - repeats the code
# Get the user by email
user = repository.get_by_email(email)

# Good - explains why
# Auth0 user must be deleted if local DB fails to prevent orphaned accounts
await self._auth0_gateway.delete_user(auth0_id)

# Good - documents non-obvious constraint
# Password validated by Pydantic schema, never stored locally
access_token = await gateway.get_access_token(email, password)
```

### Docstrings

Use docstrings for public API methods with Args, Returns, and Raises sections. Use inline comments only for non-obvious implementation details.

---

## Import Organization

**Order:** Standard library, then third-party, then local. **Enforced by:** `ruff` with `I` (isort) rules.

---

## Enforcement with Ruff

Ruff configuration lives in `pyproject.toml`. See your project's `pyproject.toml` for the active rule set.

---

## When to Break the Rules

**Rarely.** If you must, add `# ruff: noqa: <rule>` with a justification and ensure the PR reviewer agrees.

---

## Related Documentation

- [Naming Conventions](./NAMING_CONVENTIONS.md) - How to name things
- [Refactoring Guide](./refactoring-guide.md) - Detailed before/after refactoring examples
- [Repository Pattern](../patterns/repository.md) - Repository examples
- [Service Pattern](../patterns/service.md) - Service examples

---

**Use these limits when generating code to ensure all code meets quality standards.**
