# [TICKET-ID]: [Ticket Title]

> See [ticket-generation-guide.md](ticket-generation-guide.md) for field descriptions and generation guidance.

**Epic:** [EPIC-ID] - [Epic Name]
**Type:** Story | Task | Technical | Bug | Spike
**Priority:** High | Medium | Low
**Points:** [1-8]

## Context

[Brief description of what this ticket is part of, why it's needed]

**Technical Design Reference:**
- Architecture: [Link to TDD section]
- Decision rationale: [Link to ADR]

## Implementation Details

### Files to Modify/Create

- `path/to/file1.py` - **New file**, [purpose]
- `path/to/file2.py` - **Modify**, [what changes]

### Contracts

#### [Layer 1: API/Router]

```python
# path/to/schema.py
class [Feature]Request(BaseModel):
    field1: Type1 = Field(description="[Description]")

class [Feature]Response(BaseModel):
    id: UUID
    status: str
    created_at: datetime
```

#### [Layer 2: Service]

```python
# path/to/service.py
class [Feature]Service:
    def __init__(self, uow: UnitOfWork, dependency: Dependency):
        self.uow = uow
        self.dependency = dependency

    async def method_name(self, param1: Type1, param2: Type2) -> ReturnType:
        """[Method description]"""
```

#### [Layer 3: Repository]

```python
# path/to/repository.py
class [Feature]Repository:
    async def query_method(self, param1: Type1) -> list[Entity]:
        """[Query description]"""
```

#### [Layer 4: Other (Tasks, Workers, etc.)]

```python
# path/to/task.py
@celery_app.task(bind=True, max_retries=3)
def task_name(self, param1: str, param2: int) -> None:
    """[Task description]"""
```

### Patterns to Follow

- **[Pattern 1]:** Reference: `app/path/base.py` -- [Key points]
- **[Pattern 2]:** Reference: `app/path/base.py` -- [Key points]

### Database Migration

```sql
-- alembic/versions/XXXX_[description].py
CREATE TABLE [table_name] (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    field1 VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_[table]_[field] ON [table]([field]);
```

### Testing Requirements

**Unit Tests:** `tests/[layer]/test_[module].py`
- Happy path: [Description]
- Edge case: [Description]
- Error case: [Description]
- Validation: [Description]

**Integration Tests:** `tests/integration/test_[feature].py`
- Full flow: [Description]
- Error handling: [Description]

**Coverage Targets:** Services >90%, Repositories >80%, Routers >85%, Tasks >85%

### Acceptance Criteria

- [ ] [Functional criterion]
- [ ] [Performance criterion]
- [ ] [Error handling criterion]
- [ ] [Testing criterion]

## Dependencies

**Blocked By:**
- [TICKET-ID]: [Reason]

**Blocks:**
- [TICKET-ID]: [Reason]

## Security Considerations

- [ ] All inputs validated (Pydantic schemas, validators)
- [ ] Authorization checks in place
- [ ] No sensitive data in logs
- [ ] SQL injection prevented (use ORM)
- [ ] Rate limiting configured (if applicable)

## Performance Notes

| Metric | Target |
|--------|--------|
| API response | <[X]ms |
| Database query | <[X]ms |
| Background job | <[X]s |
| Requests/sec | [Number] |

## Implementation Checklist

- [ ] Database migration created
- [ ] Schemas defined
- [ ] Repository methods implemented
- [ ] Service logic implemented
- [ ] Router endpoints implemented
- [ ] Unit tests written (>85% coverage)
- [ ] Integration tests written
- [ ] Logging and monitoring added
- [ ] Code reviewed and approved

## Definition of Done

- [ ] All tests passing (unit, integration)
- [ ] Coverage meets targets
- [ ] No critical security issues
- [ ] Documentation updated
- [ ] Deployed to staging

## Notes

[Any additional notes, assumptions, or context]

## Related Resources

- Technical Design: [Link]
- ADRs: [Links]
- PRD: [Link]
- Related Tickets: [Links]
