# Risk Analysis Guide

Identify and assess technical risks in code and architecture.

## Purpose

- Identify technical risks before they become problems
- Prioritize risk mitigation efforts
- Document risks for stakeholders
- Track risk remediation

## Risk Categories

| Category | Description | Examples |
|----------|-------------|----------|
| Security | Vulnerabilities, data exposure | SQL injection, hardcoded secrets |
| Performance | Scalability issues | N+1 queries, memory leaks |
| Reliability | Failure points | No retry logic, missing validation |
| Maintainability | Tech debt, complexity | High cyclomatic complexity |
| Dependency | External dependencies | Outdated libraries, vendor lock-in |
| Operational | Deployment, monitoring | Missing logs, no health checks |

## Risk Assessment Matrix

| Likelihood | Impact | Risk Level | Action |
|------------|--------|------------|--------|
| High | High | Critical | Immediate action |
| High | Medium | High | Plan mitigation |
| Medium | High | High | Plan mitigation |
| Medium | Medium | Medium | Monitor |
| Low | High | Medium | Monitor |
| Low | Medium | Low | Accept |
| Any | Low | Low | Accept |

## Analysis Process

### 1. Identify Risks

Sources:
- Code review findings
- Static analysis results
- Dependency audit
- Architecture review
- Incident history

### 2. Assess Each Risk

For each risk, determine:
- **Likelihood**: How likely is it to occur?
- **Impact**: What's the damage if it occurs?
- **Mitigation**: What can reduce the risk?
- **Effort**: How hard is mitigation?

### 3. Prioritize

```
Risk Score = Likelihood × Impact × (1 - Mitigation Effectiveness)
```

### 4. Create Mitigation Plan

For each significant risk:
- Define mitigation actions
- Assign ownership
- Set timeline
- Define success criteria

## Risk Identification Patterns

### Security Risks

```python
# Risk: SQL Injection
query = f"SELECT * FROM users WHERE id = {user_id}"  # Critical

# Risk: Hardcoded secret
API_KEY = "sk-12345"  # Critical

# Risk: Missing authentication
@router.get("/admin/users")  # No auth check
def get_users():
    return db.query(User).all()
```

### Performance Risks

```python
# Risk: N+1 Query
for order in orders:
    print(order.customer.name)  # Query per order

# Risk: Unbounded query
users = db.query(User).all()  # No limit

# Risk: Blocking in async
async def fetch_data():
    time.sleep(1)  # Should use asyncio.sleep
```

### Reliability Risks

```python
# Risk: No retry on transient failure
response = requests.get(external_api)  # May fail

# Risk: No timeout
db.execute(complex_query)  # Could hang

# Risk: Silent failure
try:
    risky_operation()
except:
    pass  # Error swallowed
```

### Maintainability Risks

```python
# Risk: High complexity
def process_data(data):
    # 200 lines of nested conditionals
    # Cyclomatic complexity > 20

# Risk: No tests
# New 500-line module with 0% coverage

# Risk: Circular dependency
# module_a imports module_b
# module_b imports module_a
```

## Risk Register Template

```markdown
## Risk Register: [Project/Module]

### Summary
| Risk Level | Count | Trend |
|------------|-------|-------|
| Critical | 2 | ⬆️ |
| High | 5 | ➡️ |
| Medium | 8 | ⬇️ |
| Low | 12 | ➡️ |

### Critical Risks

| ID | Risk | Category | Likelihood | Impact | Status |
|----|------|----------|------------|--------|--------|
| RISK-001 | SQL injection in search | Security | High | Critical | Open |

**RISK-001: SQL injection in search**
- Location: src/repositories/search_repo.py:42
- Description: User input directly interpolated in SQL
- Mitigation: Use parameterized queries
- Owner: Backend team
- Due: 2024-01-20
- Status: In Progress

### High Risks

| ID | Risk | Category | Likelihood | Impact | Status |
|----|------|----------|------------|--------|--------|
| RISK-002 | N+1 queries in order list | Performance | High | High | Open |

### Mitigation Plan

| Risk ID | Action | Owner | Due | Status |
|---------|--------|-------|-----|--------|
| RISK-001 | Refactor to use ORM | Dev A | Jan 20 | In Progress |
| RISK-002 | Add eager loading | Dev B | Jan 22 | Planned |
```

## Output Format

```json
{
  "analysis_date": "2024-01-15",
  "scope": "Order Processing Module",
  "summary": {
    "critical": 2,
    "high": 5,
    "medium": 8,
    "low": 12
  },
  "risks": [
    {
      "id": "RISK-001",
      "title": "SQL injection in search",
      "category": "security",
      "location": "src/repositories/search_repo.py:42",
      "description": "User input directly interpolated in SQL query",
      "likelihood": "high",
      "impact": "critical",
      "risk_level": "critical",
      "mitigation": "Use parameterized queries or ORM",
      "effort": "medium",
      "owner": "Backend team",
      "status": "open"
    }
  ],
  "recommendations": [
    "Address all critical risks within 1 week",
    "Add security scanning to CI pipeline",
    "Schedule quarterly risk review"
  ]
}
```

## Integration with Other Skills

- **Security Skill**: Detailed security risk analysis
- **Review Skill**: Risk identification during code review
- **Testing Skill**: Risk-based test prioritization
