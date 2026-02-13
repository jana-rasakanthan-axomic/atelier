# STRIDE — Code Examples

Mitigation code examples for each STRIDE category.

## Spoofing — JWT Verification

```python
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

## Tampering — Parameterized Queries

```python
# BAD
query = f"SELECT * FROM users WHERE id = '{user_id}'"

# GOOD
query = select(User).where(User.id == user_id)
```

## Repudiation — Audit Logging

```python
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

## Information Disclosure — Secure Error Handling

```python
# BAD
except Exception as e:
    return {"error": str(e)}  # May expose stack trace

# GOOD
except Exception as e:
    logger.exception("Internal error")
    return {"error": "An internal error occurred"}
```

## Denial of Service — Rate Limiting

```python
from slowapi import Limiter

limiter = Limiter(key_func=get_remote_address)

@router.post("/login")
@limiter.limit("5/minute")
async def login(request: Request):
    ...
```

## Elevation of Privilege — Authorization Check

```python
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

## Template Output — JSON Format

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
