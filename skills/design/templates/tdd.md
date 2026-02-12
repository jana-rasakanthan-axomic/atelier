# Technical Design: [Feature Name]

> See [tdd-generation-guide.md](tdd-generation-guide.md) for section guidance.

**Date:** [YYYY-MM-DD]
**Author:** [Name]
**Status:** Draft | Under Review | Approved
**Context:** [Link to PRD, Epic, or Jira ticket]

## Problem Statement

[Describe the problem from the user/business perspective]

## Goals

- Goal 1: [Specific, measurable outcome]
- Goal 2: [Specific, measurable outcome]

## Non-Goals

- [Explicitly out of scope for this iteration]

## Proposed Solution

### Architecture Overview

```
Client -> API Gateway -> Service -> Repository
                          |            |
                     Business Logic  Database
                          |
                     External APIs
```

### Component Design

#### [Component 1: API Layer]

**Responsibility:** [What this component does]

**Endpoints:**
- `POST /api/[resource]` - [Description]
- `GET /api/[resource]/{id}` - [Description]

**Schemas:**
```python
class [Feature]Request(BaseModel):
    field1: str

class [Feature]Response(BaseModel):
    id: UUID
    status: str
```

**Error codes:** 400 (invalid request), 404 (not found), 429 (rate limit)

#### [Component 2: Service Layer]

**Responsibility:** [What this component does]

```python
class [Feature]Service:
    async def method_name(self, param1: Type1) -> ReturnType:
        """[Method description]. Raises: [Exception1], [Exception2]"""
```

**Business Rules:**
- Rule 1: [Description]
- Rule 2: [Description]

#### [Component 3: Repository Layer]

**Responsibility:** [What this component does]

```python
class [Feature]Repository:
    async def query_method(self, param1: Type1) -> list[Entity]:
        """[Query description]"""
```

**Indexes needed:** [List database indexes]

#### [Component 4: Infrastructure]

- Job Queue: [Technology]
- Storage: [Technology]
- Cache: [Technology]

### Alternatives Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| **Option 1** | [Pros] | [Cons] | Rejected: [Reason] |
| **Option 2** | [Pros] | [Cons] | **Chosen**: [Reason] |

### Data Schema

```sql
CREATE TABLE [table_name] (
    id UUID PRIMARY KEY,
    field1 VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_[table]_[field] ON [table]([field]);
```

### Security Considerations

- **Authorization:** [Who can access? How enforced?]
- **Authentication:** [API keys, JWT, OAuth?]
- **Data Protection:** [How sensitive data is protected]
- **Input Validation:** [How inputs are validated]

### Performance Considerations

| Metric | Target |
|--------|--------|
| Concurrent users | [Number] |
| Requests/sec | [Number] |
| API response | <[X]ms |
| Background job | <[X]s |

**Optimization Strategies:** [List strategies]
**Monitoring:** [Metrics and alerts]

### Error Handling

| Error Scenario | Handling Strategy |
|----------------|-------------------|
| [Scenario 1] | [How we handle it] |
| [Scenario 2] | [How we handle it] |

**Retry Logic:** [Number] retries with [backoff strategy], timeout [duration]

### Implementation Plan

#### Phase 1: [Name] ([Ticket ID]) - [Story Points]

**Goal:** [What this phase accomplishes]
**Tasks:** [Task list]
**Files:** `path/to/file.py` (new/modify) - [Description]

#### Phase 2: [Name] ([Ticket ID]) - [Story Points]

[Repeat structure]

### Out of Scope (Future Iterations)

- [Feature 1] -> [Future ticket ID]
- [Feature 2] -> [Future ticket ID]

## Open Questions

1. **Q:** [Question] **A:** [Answer or TBD]

## Success Metrics

- **Functionality:** [Metric]
- **Performance:** [Metric]
- **Reliability:** [Metric]

## References

- PRD: [Link]
- Epic: [Ticket ID]
- Related ADRs: [Links]
