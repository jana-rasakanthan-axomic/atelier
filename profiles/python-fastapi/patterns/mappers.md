# Mappers Pattern

Transform DTOs between layers with explicit mapping functions.

## Location

`src/api/{domain}/mappers.py`

## Key Rules

1. **Use `model_validate`** when fields match 1:1
2. **Use explicit mappers** when: nested transforms, field name differences, computed fields
3. **Mapper functions** are pure - no side effects

## When to Use model_validate

```python
# Simple case - no mapper needed
@router.get("/{id}", response_model={Entity}Response)
async def get_{entity}(id: UUID, service: {Entity}ServiceDep) -> {Entity}Response:
    dto = await service.get_by_id(id)
    return {Entity}Response.model_validate(dto)
```

## When to Use Explicit Mappers

```python
def dto_to_response(dto: {Entity}DTO) -> {Entity}Response:
    return {Entity}Response(
        id=dto.id,
        full_name=f"{dto.first_name} {dto.last_name}",  # Computed
        member_since=dto.created_at.strftime("%B %Y"),  # Formatted
    )
```

## Hiding Internal Fields

```python
class UserDTO(BaseModel):
    password_hash: str  # Internal only

class UserResponse(BaseModel):
    # No password_hash

def dto_to_response(dto: UserDTO) -> UserResponse:
    return UserResponse(id=dto.id, email=dto.email)
```

## Anti-Patterns

```python
# BAD: Inline transformation in router
return {Entity}Response(full_name=f"{dto.first_name} {dto.last_name}")

# GOOD: Mapper function
return dto_to_response(dto)
```

## Cross-References

- See `_shared.md` for three-model strategy
- See `router.md` for response transformation
