# Ticket Generation Guide

Instructions for populating the [detailed-ticket.md](detailed-ticket.md) template.

## Field Descriptions

### Header Fields

- **Epic:** Link to parent epic for traceability
- **Type:** Story (user-facing), Task (technical), Bug (defect), Spike (research)
- **Points:** Fibonacci-ish: 1 (trivial), 2 (small), 3 (medium), 5 (large), 8 (extra-large)

### Contracts Section

Define the **exact** function/method signatures for each architectural layer. This is the builder's specification -- they implement these signatures, not their own.

- **Layer 1 (API/Router):** Request/response Pydantic models with all fields, validators, and field descriptions
- **Layer 2 (Service):** Method signatures with full docstrings including Args, Returns, and Raises
- **Layer 3 (Repository):** Query method signatures with return type annotations
- **Layer 4 (Other):** Background tasks, workers, or other infrastructure

### Patterns to Follow

Reference existing code patterns in the repo. Key conventions per layer:

| Layer | Key Points |
|-------|-----------|
| Repository | `select()` not `query()`, `flush()` not `commit()`, return `Entity \| None` or `list[Entity]` |
| Service | Constructor injection, domain exceptions (not HTTP), business logic only, return entities |
| Router | `Depends()` for DI, return Pydantic models, map domain exceptions to HTTP status codes |

### Testing Requirements

Write test case names using the pattern: `test_<method>_<scenario>`. Example:

```python
@pytest.mark.asyncio
async def test_method_name_happy_path(mock_dependency):
    # Arrange
    service = [Service](mock_dependency)
    # Act
    result = await service.method_name(input_data)
    # Assert
    assert result.field == expected_value
    mock_dependency.method.assert_called_once_with(...)
```

Integration tests should cover the full request flow (API -> Service -> Repository -> DB).

### Security Considerations

Address these categories for every ticket:
- **Authorization:** Who can access? How is it enforced?
- **Input Validation:** Pydantic schemas, custom validators
- **Data Protection:** PII handling, password hashing
- **Audit Logging:** What operations are logged?

### Performance Notes

Provide concrete targets, not vague goals. Include:
- Expected load (requests/sec, concurrent users, data volume)
- Latency targets per component
- Optimization strategies (indexes, caching, chunking)
- Monitoring metrics and alert thresholds

### Definition of Done vs Acceptance Criteria

- **Acceptance Criteria:** Functional requirements that the feature must satisfy
- **Definition of Done:** Quality gates that all tickets must pass (tests, coverage, review, deployment)
