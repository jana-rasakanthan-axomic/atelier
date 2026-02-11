# Gap Analysis Guide

Identify gaps between requirements and implementation.

## Purpose

- Ensure all requirements are implemented
- Identify missing functionality
- Track implementation progress
- Prioritize remaining work

## Gap Types

| Type | Description | Example |
|------|-------------|---------|
| Missing | Feature not implemented | No password reset |
| Partial | Feature incomplete | Reset works, no email |
| Incorrect | Implementation wrong | Wrong validation rules |
| Untested | No test coverage | Auth flow untested |

## Analysis Process

### 1. Gather Requirements

Sources:
- PRD/Product Requirements Document
- User stories / Acceptance criteria
- API specifications
- Design documents

### 2. Map to Implementation

For each requirement:

```markdown
Requirement: REQ-001 User can reset password
- Implementation: src/services/auth_service.py:reset_password()
- Tests: tests/test_auth_service.py::test_reset_password
- Status: COMPLETE / PARTIAL / MISSING
```

### 3. Identify Gaps

Create gap matrix:

| Req ID | Requirement | Status | Gap | Priority |
|--------|-------------|--------|-----|----------|
| REQ-001 | Password reset | Partial | No email notification | P1 |
| REQ-002 | MFA | Missing | Not implemented | P0 |

### 4. Prioritize

| Priority | Criteria | Action |
|----------|----------|--------|
| P0 | Critical for launch | Must implement |
| P1 | Important feature | Should implement |
| P2 | Nice to have | Consider |
| P3 | Future enhancement | Backlog |

## Gap Matrix Template

```markdown
## Gap Analysis: [Feature/Module]

### Summary
- Total requirements: 25
- Implemented: 20 (80%)
- Partial: 3 (12%)
- Missing: 2 (8%)

### Critical Gaps (P0)

| ID | Requirement | Gap | Impact | Effort | Owner |
|----|-------------|-----|--------|--------|-------|
| GAP-001 | MFA support | Not implemented | Security compliance | Large | Auth team |

### High Priority Gaps (P1)

| ID | Requirement | Gap | Impact | Effort | Owner |
|----|-------------|-----|--------|--------|-------|
| GAP-002 | Email notifications | Missing for password reset | User experience | Medium | Notifications team |

### Implementation Mapping

| Requirement | File(s) | Test(s) | Status |
|-------------|---------|---------|--------|
| User login | auth_service.py | test_login.py | ✅ Complete |
| Password reset | auth_service.py | test_reset.py | ⚠️ Partial |
| MFA | - | - | ❌ Missing |
```

## Traceability Matrix

Link requirements → code → tests:

```
PRD-001: User Authentication
├── REQ-001: Login with email/password
│   ├── Code: src/services/auth_service.py::login()
│   ├── Test: tests/unit/test_auth.py::test_login_success
│   └── Status: ✅ Complete
├── REQ-002: Password reset
│   ├── Code: src/services/auth_service.py::reset_password()
│   ├── Test: tests/unit/test_auth.py::test_reset_password
│   └── Status: ⚠️ Partial (no email)
└── REQ-003: MFA
    ├── Code: -
    ├── Test: -
    └── Status: ❌ Missing
```

## Common Gap Patterns

### Partial Implementation

```python
# Requirement: Users can export their data in CSV or JSON format

def export_user_data(user_id: int, format: str):
    user = get_user(user_id)
    if format == "json":
        return json.dumps(user.to_dict())
    # GAP: CSV format not implemented
    raise NotImplementedError(f"Format {format} not supported")
```

### Missing Error Handling

```python
# Requirement: Invalid login attempts are limited to 5

def login(email: str, password: str):
    user = get_user_by_email(email)
    # GAP: No attempt tracking or rate limiting
    if not verify_password(password, user.password_hash):
        raise InvalidCredentials()
    return create_session(user)
```

## Output Format

```json
{
  "analysis_date": "2024-01-15",
  "scope": "User Authentication Module",
  "summary": {
    "total_requirements": 25,
    "complete": 20,
    "partial": 3,
    "missing": 2,
    "completion_percentage": 80
  },
  "gaps": [
    {
      "id": "GAP-001",
      "requirement_id": "REQ-003",
      "requirement": "MFA support",
      "status": "missing",
      "priority": "P0",
      "impact": "Security compliance requirement",
      "effort": "large",
      "recommendation": "Implement TOTP-based MFA",
      "owner": "Auth team"
    }
  ],
  "next_steps": [
    "Implement MFA (GAP-001)",
    "Add email notification to password reset (GAP-002)"
  ]
}
```
