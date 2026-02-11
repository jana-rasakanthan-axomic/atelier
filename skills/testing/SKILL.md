---
name: testing
description: Process-only testing patterns. Stack-specific test tools and conventions come from the active profile.
allowed-tools: Read, Write, Edit, Bash(${profile.test_runner})
---

# Testing Skill

Generate and execute tests following test-first methodology for any stack.

## When to Use

- Unit tests for new code
- Integration tests across layers
- E2E tests for user flows
- Running existing test suites

## When NOT to Use

**Only for test generation and execution.** Do not use for fixing code or analyzing coverage.

- Tests already exist and pass → run them instead
- Prototyping → skip temporarily
- External service testing → use mocks

## Test Types

| Type | Guide | Use Case |
|------|-------|----------|
| Unit | `unit-tests.md` | Isolated component testing |
| Integration | `integration-tests.md` | Cross-layer with real dependencies |
| E2E | `e2e-tests.md` | Full flow testing |

## Running Tests

Use the project's build tool (preferred):
```bash
# Check for Makefile targets first
make test           # Run all tests
make test-unit      # Run unit tests only
make test-coverage  # Run with coverage report

# Or use profile tools directly
${profile.tools.test_runner.command}           # Run all tests
${profile.tools.test_runner.single_file}       # Run single file
${profile.tools.test_runner.coverage}          # Run with coverage
```

## Test Structure

Test directory structure depends on the active profile. Read `$TOOLKIT_DIR/profiles/{active_profile}.md` for the specific layout.

Common patterns:
```
tests/
├── unit/           # Isolated component tests
├── integration/    # Cross-layer tests
└── e2e/           # Full flow tests
```

## AAA Pattern (Universal)

Every test follows **Arrange-Act-Assert**:

```
// Arrange - Set up test data and mocks
setup test dependencies

// Act - Execute the code under test
result = call_function_under_test()

// Assert - Verify the result
assert result matches expected
```

This pattern applies to ALL testing frameworks.

## Naming Convention

```
test_{method}_{scenario}_{expected_result}
```

Examples:
- `test_create_valid_input_returns_entity`
- `test_get_by_id_not_found_raises_error`
- `test_update_invalid_status_raises_validation_error`

## Coverage Targets

| Priority | Layer | Target |
|----------|-------|--------|
| P0 | Business logic (happy path + errors) | 90% |
| P1 | Data access, validation | 85% |
| P2 | Entry points, status codes | 80% |
