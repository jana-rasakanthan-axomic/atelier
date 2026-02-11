# [TICKET-ID]: [Ticket Title]

**Epic:** [EPIC-ID] - [Epic Name]
**Type:** Story | Task | Technical | Bug | Spike
**Priority:** High | Medium | Low
**Points:** [1-8]

## Context

[Brief description of what this ticket is part of, why it's needed]

**Technical Design Reference:**
- Architecture: [Link to TDD section, e.g., docs/design/feature-name.md#architecture]
- Decision rationale: [Link to ADR, e.g., docs/adr/0023-decision-name.md]

## Implementation Details

### Files to Modify/Create

- `path/to/file1.py` - **New file**, [purpose]
- `path/to/file2.py` - **Modify**, [what changes]
- `path/to/file3.py` - **Modify**, [what changes]
- `path/to/migration.py` - **New file**, [database changes]

### Contracts

#### [Layer 1: API/Router]

```python
# path/to/schema.py
class [Feature]Request(BaseModel):
    """[Description]"""
    field1: Type1 = Field(description="[Description]")
    field2: Type2 = Field(default=..., description="[Description]")

    @validator('field1')
    def validate_field1(cls, v):
        # Validation logic
        return v

class [Feature]Response(BaseModel):
    """[Description]"""
    id: UUID
    status: str
    created_at: datetime
```

#### [Layer 2: Service]

```python
# path/to/service.py
class [Feature]Service:
    """[Service description]"""

    def __init__(self, uow: UnitOfWork, dependency: Dependency):
        self.uow = uow
        self.dependency = dependency

    async def method_name(
        self,
        param1: Type1,
        param2: Type2
    ) -> ReturnType:
        """
        [Method description]

        Args:
            param1: [Description]
            param2: [Description]

        Returns:
            [Return value description]

        Raises:
            [Exception1]: [When raised]
            [Exception2]: [When raised]
        """
```

#### [Layer 3: Repository]

```python
# path/to/repository.py
class [Feature]Repository:
    """[Repository description]"""

    async def query_method(
        self,
        param1: Type1,
        param2: Type2
    ) -> list[Entity]:
        """
        [Query description]

        Args:
            param1: [Description]
            param2: [Description]

        Returns:
            [Return value description, e.g., "List of Entity objects, empty if none found"]
        """
```

#### [Layer 4: Other (Tasks, Workers, etc.)]

```python
# path/to/task.py
@celery_app.task(bind=True, max_retries=3)
def task_name(self, param1: str, param2: int) -> None:
    """
    [Task description]

    Args:
        param1: [Description]
        param2: [Description]

    Raises:
        [Exception]: [When raised]
    """
```

### Patterns to Follow

**[Pattern 1: Repository Pattern]**
- Reference: `app/repositories/base.py`
- Key points:
  - Use `select()` not `query()`
  - Use `flush()` not `commit()` (UoW commits)
  - Return `Entity | None` for single, `list[Entity]` for multiple
  - Use `AsyncIterator[list[T]]` for chunked queries

**[Pattern 2: Service Pattern]**
- Reference: `app/services/base.py`
- Key points:
  - Constructor injection of dependencies
  - Raise domain exceptions (not HTTP exceptions)
  - Business logic only (no DB commits)
  - Return entities (not Pydantic models)

**[Pattern 3: Router Pattern]**
- Reference: `app/routers/[existing].py`
- Key points:
  - Use `Depends()` for dependency injection
  - Return Pydantic response models
  - Map domain exceptions to HTTP status codes
  - Use status codes from `fastapi.status`

**[Pattern 4: Other Patterns]**
- Reference: [File path]
- Key points: [List]

### Database Migration

```sql
-- alembic/versions/XXXX_[description].py
"""[Migration description]

Revision ID: [auto-generated]
Revises: [previous revision]
Create Date: [auto-generated]
"""

# Migration up
CREATE TABLE [table_name] (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    field1 VARCHAR(255) NOT NULL,
    field2 INT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

CREATE INDEX idx_[table]_[field] ON [table]([field]);

# Migration down (if needed)
DROP INDEX idx_[table]_[field];
DROP TABLE [table_name];
```

### Testing Requirements

#### Unit Tests

**File:** `tests/[layer]/test_[module].py`

**Test Cases:**
- ✅ Happy path: [Description]
- ✅ Edge case: [Description]
- ✅ Error case: [Description]
- ✅ Validation: [Description]

**Example:**
```python
@pytest.mark.asyncio
async def test_method_name_happy_path(mock_dependency):
    """Test [description]"""
    # Arrange
    service = [Service](mock_dependency)
    input_data = [...]

    # Act
    result = await service.method_name(input_data)

    # Assert
    assert result.[field] == expected_value
    mock_dependency.method.assert_called_once_with(...)
```

#### Integration Tests

**File:** `tests/integration/test_[feature].py`

**Test Cases:**
- ✅ Full flow: [Description, e.g., API → Service → Repository → DB]
- ✅ Error handling: [Description]
- ✅ Concurrent requests: [Description if applicable]

**Example:**
```python
@pytest.mark.asyncio
async def test_full_flow(async_client, db_session):
    """Test [description]"""
    # Arrange
    payload = {...}

    # Act
    response = await async_client.post("/api/endpoint", json=payload)

    # Assert
    assert response.status_code == 200
    assert response.json()["field"] == expected_value
    # Verify DB state
    result = await db_session.execute(select(Entity).where(...))
    assert result.scalars().first() is not None
```

#### Coverage Targets

- **Services:** >90% (critical business logic)
- **Repositories:** >80% (query logic)
- **Routers:** >85% (endpoint handling)
- **Tasks/Workers:** >85% (error handling paths)

### Acceptance Criteria

- [ ] [Functional criterion 1, e.g., "API endpoint returns 200 with valid payload"]
- [ ] [Functional criterion 2, e.g., "Data persisted to database correctly"]
- [ ] [Performance criterion, e.g., "Response time <200ms for 95th percentile"]
- [ ] [Error handling criterion, e.g., "Invalid input returns 400 with clear error"]
- [ ] [Testing criterion, e.g., "All unit tests pass with >85% coverage"]
- [ ] [Integration criterion, e.g., "Integration test covers full flow"]
- [ ] [Documentation criterion, e.g., "OpenAPI spec updated"]

## Dependencies

**Blocked By:**
- [TICKET-ID]: [Reason, e.g., "Needs database migration"]
- [TICKET-ID]: [Reason, e.g., "Needs infrastructure setup"]

**Blocks:**
- [TICKET-ID]: [Reason, e.g., "Provides service interface needed by..."]
- [TICKET-ID]: [Reason, e.g., "Must complete before..."]

## Security Considerations

- ✅ **Authorization:** [How access is controlled, e.g., "Verify user owns resource"]
- ✅ **Input Validation:** [How inputs are validated, e.g., "Pydantic schema validation"]
- ✅ **Rate Limiting:** [If applicable, e.g., "5 requests/minute per user"]
- ✅ **Data Protection:** [How sensitive data is handled, e.g., "Hash passwords with bcrypt"]
- ✅ **Audit Logging:** [What is logged, e.g., "Log all create/update/delete operations"]

**Security Checklist:**
- [ ] All inputs validated (Pydantic schemas, validators)
- [ ] Authorization checks in place (verify user permissions)
- [ ] No sensitive data in logs (mask PII, passwords)
- [ ] SQL injection prevented (use SQLAlchemy, no raw queries)
- [ ] Rate limiting configured (if applicable)

## Performance Notes

**Expected Load:**
- Requests per second: [Number or range]
- Concurrent users: [Number or range]
- Data volume: [Size or range]

**Target Latency:**
- API response: [<Xms]
- Database query: [<Xms]
- Background job: [<Xs]

**Optimization Strategies:**
- [Strategy 1, e.g., "Index on frequently queried fields"]
- [Strategy 2, e.g., "Cache results for 5 minutes"]
- [Strategy 3, e.g., "Process in chunks of 1k rows"]

**Monitoring:**
- Metrics: [What to track, e.g., "request_duration, error_rate"]
- Alerts: [When to alert, e.g., "if p95 latency >500ms or error_rate >1%"]

## Implementation Checklist

- [ ] Database migration created (if needed)
- [ ] Schemas defined (request/response models)
- [ ] Repository methods implemented
- [ ] Service logic implemented
- [ ] Router endpoints implemented
- [ ] Exception handling added
- [ ] Unit tests written (>85% coverage)
- [ ] Integration tests written
- [ ] Error scenarios tested
- [ ] Logging added (key operations, errors)
- [ ] Monitoring metrics added (Prometheus, CloudWatch)
- [ ] API documentation updated (OpenAPI)
- [ ] Code reviewed and approved

## Definition of Done

- [ ] Code reviewed and approved by [role, e.g., "senior engineer"]
- [ ] All tests passing (unit, integration)
- [ ] Coverage meets targets (>85%)
- [ ] No critical security issues (linting, SAST)
- [ ] Performance tested (load test if applicable)
- [ ] Monitoring configured (metrics, alerts)
- [ ] Documentation updated (code comments, API docs)
- [ ] Deployed to staging environment
- [ ] Manual testing completed (QA)
- [ ] Product owner approval (if applicable)

## Notes

[Any additional notes, assumptions, or context]

## Related Resources

- Technical Design: [Link to TDD]
- ADRs: [Links to relevant ADRs]
- PRD: [Link to PRD]
- Related Tickets: [Links to related tickets]
