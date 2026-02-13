# Test-First Development (MANDATORY)

> **This is NOT optional.** All code implementation MUST follow TDD. If you find yourself writing implementation code before tests, STOP and go back.

Write tests before implementation using contract specifications.

## Philosophy

**Test-First = Contract -> Test -> Implement**

```
1. Write test based on contract specification
2. Run test -> MUST FAIL (Red)
3. Write MINIMUM code to pass test
4. Run test -> MUST PASS (Green)
5. Refactor if needed (keep Green)
```

## TDD Enforcement Checklist

Before writing ANY implementation code, verify:

- [ ] Test file exists
- [ ] Test imports the implementation (will cause ImportError)
- [ ] Tests run and FAIL (Red confirmed)

**If any checkbox is unchecked, STOP. Write tests first.**

## When to Use Test-First

| Layer | Test-First? | Mock What? | Test File Pattern |
|-------|-------------|------------|-------------------|
| **Router (API)** | ALWAYS | Service | `tests/unit/api/{domain}/test_routes.py` |
| **Service** | ALWAYS | Repository, External | `tests/unit/api/{domain}/test_service.py` |
| **Repository** | ALWAYS | AsyncSession | `tests/unit/db/repositories/test_{entity}_repository.py` |
| **External Service** | ALWAYS | HTTP Client | `tests/unit/external/test_{service}_client.py` |

## When NOT to Use Test-First

| Component | Why | Alternative |
|-----------|-----|-------------|
| ORM Models | Data structures, not behavior | Integration tests |
| Migrations | Schema changes | Integration tests |
| Configuration | Static values | None needed |
| Trivial DTOs | Pydantic validation sufficient | None needed |

## Test-First Workflow

### Step 1: Read Contract Specification

Extract method signatures, parameters, return types, and exceptions from the plan or ticket.

```python
# Contract format
class UserService:
    async def create_user(self, request: CreateUserRequest) -> User:
        """
        Raises:
            DuplicateEmailError: If email already exists
            ValidationError: If request invalid
        """
```

### Step 2: Write Test First (Red)

Write tests that validate contract behavior using AAA pattern (Arrange, Act, Assert). Test both the happy path and each documented exception path.

### Step 3: Run Test (Expect Red)

```bash
pytest tests/unit/api/users/test_service.py -x --tb=short
# Expected: FAILED - ImportError or AttributeError
```

**Why Red is good:** Proves test is actually testing something, not auto-passing.

### Step 4: Implement Code (Green)

Write the minimum code to make tests pass. No more, no less.

### Step 5: Run Test Again (Expect Green)

```bash
pytest tests/unit/api/users/test_service.py -v
# Expected: All tests PASSED
```

### Step 6: Refactor (if needed)

If implementation is clean, move on. If duplication or complexity exists, refactor while keeping tests green.

## Mocking Hierarchy

```
Router Tests     -> Mock Service
Service Tests    -> Mock Repository + Mock External Services
Repository Tests -> Mock AsyncSession
External Tests   -> Mock HTTP Client (httpx/aiohttp)
```

> See [mocking-patterns.md](mocking-patterns.md) for full layer-by-layer mocking examples.

## Coverage Goals

Each layer should test:

| Layer | Must Test |
|-------|-----------|
| **Router** | Happy path (200/201/204), error paths (400/404/422/500), request validation, service exception mapping |
| **Service** | Happy path per method, each exception path, business logic edge cases, external service failures |
| **Repository** | CRUD operations, query filters, return types match contract |

## Anti-Patterns (FORBIDDEN)

| Anti-Pattern | Correct Approach |
|-------------|-----------------|
| Implementing before writing tests | Write test -> Red -> Implement -> Green |
| Not running tests before implementing | Always confirm Red before writing code |
| Testing implementation details (e.g., `session.flush`) | Test behavior (e.g., `repo.create.assert_called_once`) |

## Red -> Green -> Refactor Cycle

```
1. Red (Write failing test)
   |
2. Green (Implement minimum code to pass)
   |
3. Refactor (Clean up while keeping tests green)
   |
4. Repeat for next behavior
```

## Cross-References

- See `unit-tests.md` for AAA pattern, mocking guidelines, fixture organization
- See `mocking-patterns.md` for layer-by-layer mocking examples
- See `../patterns/router.md` for router contract patterns
- See `../patterns/service.md` for service contract patterns
- See `../patterns/repository.md` for repository contract patterns
- See `../patterns/_shared.md` for three-model strategy
