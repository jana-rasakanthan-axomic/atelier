# STRIDE Threat Modeling

Systematic threat identification using STRIDE framework.

## Overview

STRIDE is a threat modeling methodology that categorizes threats into six types:

- **S**poofing Identity
- **T**ampering with Data
- **R**epudiation
- **I**nformation Disclosure
- **D**enial of Service
- **E**levation of Privilege

## Process

### 1. Identify Assets

```markdown
## Assets

| Asset | Type | Sensitivity |
|-------|------|-------------|
| User credentials | Data | Critical |
| Session tokens | Data | Critical |
| User PII | Data | High |
| API keys | Secrets | Critical |
| Business data | Data | Medium |
```

### 2. Identify Entry Points

```markdown
## Entry Points

| Entry Point | Protocol | Authentication |
|-------------|----------|----------------|
| /api/auth/login | HTTPS | None |
| /api/users | HTTPS | JWT |
| /api/admin | HTTPS | JWT + Admin Role |
| Database | TCP | Username/Password |
```

### 3. Apply STRIDE

For each asset and entry point combination:

#### Spoofing

**Question**: Can an attacker impersonate a legitimate user or system?

**Mitigations**:
- Strong authentication (MFA, WebAuthn)
- Certificate pinning
- API key rotation
- Session management

```python
# Example: Verify JWT signature
from jose import jwt, JWTError

def verify_token(token: str) -> dict:
    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM],
        )
        return payload
    except JWTError:
        raise InvalidTokenError()
```

#### Tampering

**Question**: Can an attacker modify data in transit or at rest?

**Mitigations**:
- HTTPS for transport
- Input validation
- Parameterized queries
- Integrity checks (HMAC)

```python
# Example: Parameterized query (prevent SQL injection)
# BAD
query = f"SELECT * FROM users WHERE id = '{user_id}'"

# GOOD
query = select(User).where(User.id == user_id)
```

#### Repudiation

**Question**: Can a user deny performing an action?

**Mitigations**:
- Comprehensive audit logging
- Non-repudiation signatures
- Immutable logs
- Timestamps

```python
# Example: Audit logging
import structlog

logger = structlog.get_logger()

async def delete_user(user_id: UUID, actor_id: UUID) -> None:
    logger.info(
        "user_deleted",
        user_id=str(user_id),
        actor_id=str(actor_id),
        timestamp=datetime.utcnow().isoformat(),
    )
    await repository.delete(user_id)
```

#### Information Disclosure

**Question**: Can sensitive data be exposed?

**Mitigations**:
- Encryption at rest and transit
- Access control
- Data masking
- Secure error handling

```python
# Example: Don't expose internal errors
# BAD
except Exception as e:
    return {"error": str(e)}  # May expose stack trace

# GOOD
except Exception as e:
    logger.exception("Internal error")
    return {"error": "An internal error occurred"}
```

#### Denial of Service

**Question**: Can an attacker disrupt service availability?

**Mitigations**:
- Rate limiting
- Input validation (size limits)
- Resource quotas
- Auto-scaling

```python
# Example: Rate limiting
from slowapi import Limiter

limiter = Limiter(key_func=get_remote_address)

@router.post("/login")
@limiter.limit("5/minute")
async def login(request: Request):
    ...
```

#### Elevation of Privilege

**Question**: Can a user gain unauthorized access?

**Mitigations**:
- Principle of least privilege
- Role-based access control
- Input validation
- Authorization checks

```python
# Example: Authorization check
async def delete_resource(
    resource_id: UUID,
    current_user: User = Depends(get_current_user),
) -> None:
    resource = await repository.get(resource_id)

    # Check ownership
    if resource.owner_id != current_user.id:
        if not current_user.is_admin:
            raise ForbiddenError()

    await repository.delete(resource_id)
```

### 4. Document Findings

```markdown
## STRIDE Analysis Results

| ID | Category | Asset | Threat | Likelihood | Impact | Risk | Mitigation |
|----|----------|-------|--------|------------|--------|------|------------|
| T-001 | Spoofing | Auth | Credential stuffing | High | Critical | High | MFA, rate limiting |
| T-002 | Injection | API | SQL injection | Medium | Critical | High | Parameterized queries |
| T-003 | Info Disclosure | Logs | PII in logs | Medium | High | Medium | Log sanitization |
```

### 5. Risk Score

```
Risk = Likelihood × Impact

Likelihood: 1 (Low), 2 (Medium), 3 (High)
Impact: 1 (Low), 2 (Medium), 3 (High), 4 (Critical)

Risk Score:
- 1-3: Low
- 4-6: Medium
- 7-9: High
- 10-12: Critical
```

## Template Output

```json
{
  "analysis_date": "2024-01-15",
  "feature": "User Authentication",
  "assets": [...],
  "entry_points": [...],
  "threats": [
    {
      "id": "T-001",
      "category": "Spoofing",
      "asset": "User credentials",
      "description": "Credential stuffing attack",
      "likelihood": 3,
      "impact": 4,
      "risk_score": 12,
      "risk_level": "Critical",
      "mitigations": [
        "Implement MFA",
        "Add rate limiting",
        "Use breach detection"
      ]
    }
  ],
  "recommendations": [...]
}
```
