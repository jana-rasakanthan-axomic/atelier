# Pagination Pattern

Cursor-based pagination with encoded cursors for stable navigation.

## Location

- `src/api/shared/pagination.py` - Cursor utilities
- `src/api/{domain}/schemas.py` - Paginated responses

## Key Rules

1. **Cursor encoding** - `base64(uuid:position)` for stable navigation
2. **PageInfo DTO** - `end_cursor`, `has_next_page`
3. **No offset-based** - cursor avoids issues with changing data

## Cursor Encoding

```python
def encode_cursor(entity_id: UUID, position: int) -> str:
    cursor_data = f"{entity_id}:{position}"
    return base64.urlsafe_b64encode(cursor_data.encode()).decode()

def decode_cursor(cursor: str) -> tuple[UUID, int]:
    decoded = base64.urlsafe_b64decode(cursor.encode()).decode()
    entity_id_str, position_str = decoded.split(":")
    return UUID(entity_id_str), int(position_str)
```

## PageInfo DTO

```python
class PageInfoDTO(BaseModel):
    end_cursor: str | None = None
    has_next_page: bool = False
```

## Service Usage

```python
async def get_all(self, *, after: str | None = None, first: int = 20) -> {Entity}ListDTO:
    after_id = decode_cursor(after)[0] if after else None
    async with self.db_manager.uow() as uow:
        entities, has_next = await uow.repo.get_page(after_id=after_id, first=first)
        items = [{Entity}DTO.model_validate(e) for e in entities]
        end_cursor = encode_cursor(items[-1].id, len(items) - 1) if items else None
        return {Entity}ListDTO(items=items, page_info=PageInfoDTO(end_cursor=end_cursor, has_next_page=has_next))
```

## Anti-Patterns

```python
# BAD: Offset-based
@router.get("")
async def list(page: int = 1, page_size: int = 20):
    offset = (page - 1) * page_size  # Problems with changing data

# GOOD: Cursor-based
@router.get("")
async def list(after: str | None = None, first: int = 20): ...
```

## Cross-References

- See `repository.md` for `get_page` implementation
- See `service.md` for pagination in service layer
