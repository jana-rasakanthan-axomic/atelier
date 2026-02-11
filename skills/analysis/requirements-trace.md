# Requirements Traceability Guide

Track requirements through design, implementation, and testing.

## Purpose

- Ensure all requirements are implemented
- Verify tests cover requirements
- Track changes to requirements
- Support audit and compliance

## Traceability Levels

```
Business Need
    ↓
Product Requirement (PRD)
    ↓
Technical Requirement (Spec)
    ↓
Implementation (Code)
    ↓
Verification (Tests)
```

## Traceability Matrix

### Forward Traceability (Requirement → Code → Test)

| Req ID | Requirement | Implementation | Test | Status |
|--------|-------------|----------------|------|--------|
| REQ-001 | User login | auth_service.py:login() | test_login.py | ✅ |
| REQ-002 | Password reset | auth_service.py:reset_password() | test_reset.py | ⚠️ |
| REQ-003 | MFA | - | - | ❌ |

### Backward Traceability (Test → Code → Requirement)

| Test | Implementation | Requirement | Notes |
|------|----------------|-------------|-------|
| test_login_success | auth_service.py:login() | REQ-001 | Happy path |
| test_login_invalid_password | auth_service.py:login() | REQ-001 | Error case |
| test_orphan_function | utils.py:helper() | ??? | No linked requirement |

## Trace Links

### Linking in Code

```python
# Requirement: REQ-001 - User can login with email and password
# Acceptance Criteria: AC-001.1, AC-001.2, AC-001.3
def login(email: str, password: str) -> Session:
    """
    Authenticate user and create session.

    Links:
        - PRD: Section 3.1 Authentication
        - Spec: AUTH-001
        - Tests: test_login.py
    """
    ...
```

### Linking in Tests

```python
class TestLogin:
    """
    Tests for REQ-001: User Login

    Requirements covered:
        - AC-001.1: Valid credentials return session
        - AC-001.2: Invalid password returns error
        - AC-001.3: Non-existent user returns error
    """

    def test_login_success(self):
        """AC-001.1: Valid credentials return session"""
        ...

    def test_login_invalid_password(self):
        """AC-001.2: Invalid password returns error"""
        ...
```

## Coverage Analysis

### Requirements Coverage

```markdown
## Requirements Coverage Report

### Summary
- Total requirements: 50
- Fully covered: 40 (80%)
- Partially covered: 7 (14%)
- Not covered: 3 (6%)

### By Category

| Category | Total | Covered | Partial | Missing |
|----------|-------|---------|---------|---------|
| Authentication | 10 | 8 | 1 | 1 |
| User Management | 15 | 14 | 1 | 0 |
| Orders | 12 | 10 | 2 | 0 |
| Reporting | 8 | 5 | 2 | 1 |
| Admin | 5 | 3 | 1 | 1 |
```

### Test Coverage per Requirement

```markdown
| Req ID | Unit Tests | Integration | E2E | Coverage |
|--------|------------|-------------|-----|----------|
| REQ-001 | 5 | 2 | 1 | 100% |
| REQ-002 | 3 | 1 | 0 | 80% |
| REQ-003 | 0 | 0 | 0 | 0% |
```

## Change Impact Analysis

When a requirement changes:

1. **Identify affected items**
   - Code files implementing the requirement
   - Tests covering the requirement
   - Documentation referencing the requirement

2. **Assess impact**
   - Breaking change?
   - Scope of code changes
   - Test updates needed

3. **Update trace links**
   - Mark old requirement as superseded
   - Create new trace links
   - Update tests

### Change Impact Template

```markdown
## Change Impact: REQ-001 → REQ-001-v2

### Requirement Change
- Old: "User can login with email and password"
- New: "User can login with email/password or SSO"

### Impact Assessment

| Item | File | Change Required |
|------|------|-----------------|
| Code | auth_service.py | Add SSO login method |
| Code | auth_routes.py | Add SSO endpoint |
| Test | test_login.py | Add SSO test cases |
| Doc | API.md | Document SSO endpoint |

### Effort: Medium
### Risk: Low (additive change)
```

## Orphan Detection

### Orphan Code (No Requirement)

```python
# Finding: Function exists but no requirement traces to it
def unused_helper():
    # Why does this exist?
    pass
```

Action:
- Link to requirement, OR
- Mark as utility, OR
- Remove if truly unused

### Orphan Tests (No Requirement)

```python
def test_random_scenario():
    # No clear requirement being tested
    assert some_function() == expected
```

Action:
- Link to requirement, OR
- Convert to regression test, OR
- Remove if no value

### Orphan Requirements (No Implementation)

```markdown
REQ-099: System shall support dark mode
- Implementation: None
- Tests: None
- Status: NOT STARTED
```

Action:
- Implement, OR
- Defer and document, OR
- Remove from scope

## Output Format

```json
{
  "trace_report": {
    "date": "2024-01-15",
    "scope": "Authentication Module",
    "summary": {
      "requirements": 10,
      "fully_traced": 7,
      "partially_traced": 2,
      "not_traced": 1
    },
    "traces": [
      {
        "requirement_id": "REQ-001",
        "requirement": "User login",
        "implementations": [
          {"file": "auth_service.py", "function": "login", "line": 42}
        ],
        "tests": [
          {"file": "test_login.py", "function": "test_login_success"},
          {"file": "test_login.py", "function": "test_login_invalid"}
        ],
        "coverage": "full"
      }
    ],
    "orphans": {
      "code": ["utils.py:helper_function"],
      "tests": ["test_misc.py:test_random"],
      "requirements": ["REQ-099"]
    }
  }
}
```
