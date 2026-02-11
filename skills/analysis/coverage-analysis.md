# Coverage Analysis Guide

Analyze test coverage to identify gaps and prioritize testing efforts.

## Purpose

- Identify untested code paths
- Prioritize testing by risk
- Track coverage trends
- Guide test generation

## Coverage Types

| Type | Description | Target |
|------|-------------|--------|
| Line | Lines executed | 80% |
| Branch | Decision paths | 75% |
| Function | Functions called | 90% |
| Statement | Statements executed | 80% |

## Analysis Process

### 1. Generate Coverage Report

```bash
# Run pytest with coverage
pytest --cov=src --cov-report=json --cov-report=term-missing

# Output: coverage.json and terminal report
```

### 2. Parse Coverage Data

Use `scripts/analyze-coverage.py`:

```bash
python scripts/analyze-coverage.py coverage.json --threshold 80
```

### 3. Identify Gaps

Categorize uncovered code:

| Priority | Category | Action |
|----------|----------|--------|
| P0 | Critical business logic | Must test |
| P1 | Error handling paths | Should test |
| P2 | Edge cases | Consider testing |
| P3 | Trivial code | Low priority |

## Coverage Gap Patterns

### High-Risk Gaps

```python
# Untested error handling
try:
    result = risky_operation()
except SpecificException:
    # This branch not covered
    handle_error()

# Untested conditional
if rare_condition:
    # Never executed in tests
    special_handling()
```

### Acceptable Gaps

```python
# Type checking (mypy handles this)
if TYPE_CHECKING:
    from typing import Protocol

# Debug-only code
if __debug__:
    print_debug_info()

# Abstract methods (covered by implementations)
@abstractmethod
def interface_method(self):
    pass
```

## Prioritization Matrix

| Business Impact | Code Complexity | Priority |
|----------------|-----------------|----------|
| High | High | P0 - Critical |
| High | Low | P1 - High |
| Low | High | P2 - Medium |
| Low | Low | P3 - Low |

## Coverage Report Template

```markdown
## Coverage Analysis: [Module/Feature]

### Summary
- Overall coverage: XX%
- Target: 80%
- Status: PASS/FAIL

### By Component

| Component | Coverage | Target | Status |
|-----------|----------|--------|--------|
| services/ | 85% | 80% | ✅ |
| repositories/ | 78% | 80% | ⚠️ |
| routes/ | 72% | 80% | ❌ |

### Critical Gaps (P0)

| File | Lines | Description | Test Needed |
|------|-------|-------------|-------------|
| user_service.py | 42-48 | Error handling | Unit test for InvalidUserError |

### High Priority Gaps (P1)

| File | Lines | Description | Test Needed |
|------|-------|-------------|-------------|
| auth_service.py | 100-105 | Token refresh | Integration test |

### Recommendations
1. Add unit tests for error handling in user_service.py
2. Create integration test for token refresh flow
3. Consider mocking for external API calls
```

## Integration with CI

```yaml
# GitHub Actions example
- name: Run tests with coverage
  run: pytest --cov=src --cov-fail-under=80

- name: Upload coverage
  uses: codecov/codecov-action@v3
```

## Tools

### analyze-coverage.py Output

```json
{
  "overall_coverage": 82.5,
  "target": 80,
  "status": "PASS",
  "gaps": [
    {
      "file": "src/services/user_service.py",
      "lines": [42, 43, 44, 45],
      "function": "handle_user_error",
      "priority": "P0",
      "reason": "Error handling not tested"
    }
  ],
  "by_directory": {
    "src/services": 85.2,
    "src/repositories": 78.4,
    "src/routes": 72.1
  }
}
```
