# Constraint Definition

**Purpose:** Define technical boundaries and limitations for implementation.

**Part of:** Design skill

**Checklist:** Boundaries not solutions | What must/must NOT be done | Performance/security/compatibility if applicable | Verifiable | No variable names, file paths, or implementation details

---

## Overview

Constraints are boundaries that define what implementers must follow, must NOT do, or technical limitations they must work within. Good constraints guide implementation without being prescriptive.

**Key Principle:** Define boundaries, not solutions.

---

## Types of Constraints

### 1. Architectural Constraints

Patterns and structures that must be followed.
- "Follow repository -> service -> router layering"
- "Use existing Auth0 integration (no custom auth)"
- "Use async/await for all I/O operations"

### 2. Technical Constraints

Technologies, libraries, or approaches that must/must NOT be used.
- "Must use existing Celery infrastructure"
- "Must use PostgreSQL (no NoSQL)"
- "No new external dependencies without approval"

### 3. Performance Constraints

Speed, throughput, or resource limitations.
- "API response time <200ms (P95)"
- "Support 1000 concurrent users"
- "Memory usage <512MB per worker"

### 4. Security Constraints

Security requirements and boundaries.
- "Validate JWT signature using RS256 (not HS256)"
- "All user queries must filter by authenticated user ID"
- "Rate limit: 100 requests/minute per user"

### 5. Compatibility Constraints

Backwards compatibility and integration requirements.
- "No breaking changes to existing API endpoints"
- "Must maintain compatibility with v1 clients"
- "Cannot modify existing user model schema"

### 6. Scope Constraints

What is explicitly NOT allowed or included.
- "Assets can only be reordered within current block (no cross-block)"
- "No cascade deletes (manual cleanup only)"
- "Backend only (frontend changes out of scope)"

### 7. Exception Constraints (Required for Contract Definition)

How errors are structured for logging and API responses.

**Required Pattern:**
```python
class ServiceNameError(Exception):
    """Base exception with message, detail, context for structured logging."""
    def __init__(self, message: str, detail: dict[str, Any] | None = None,
                 context: dict[str, Any] | None = None):
        self.message = message
        self.detail = detail or {"message": message}
        self.context = context or {}
        super().__init__(self.message)
```

**Required Hierarchy:** Base (`ServiceNameError`) -> Categories (`NotFoundError`, `ValidationError`, `AuthorizationError`, `ExternalServiceError`) -> Specific (inherit from categories, populate `context`).

**Required Features:**
- `context` dict for structured log queries
- `detail` dict for standardized API response body
- `ResourceNotFoundMixin` for DRY "X with id Y not found" patterns
- External service errors include: `service_name`, `status_code`, `response_body`
- Exception handler maps exception types to HTTP status codes

**Reference Implementation:** `AXO492/src/exceptions.py`

---

## Good vs Bad Constraints

### Good Constraints (Boundaries)

```markdown
## Constraints
- Must follow repository -> service -> router layering
- Use existing UnitOfWork pattern for transactions
- No direct database access from routers
```

Why good: States pattern (not specific classes/methods), sets clear boundary, doesn't prescribe implementation.

### Bad Constraints (Too Prescriptive)

These are things you should NOT constrain -- let the implementer decide:

| Don't Constrain | Bad Example | Why |
|-----------------|-------------|-----|
| Implementation details | "Use for loop, not list comprehension" | Let implementer write good code |
| Variable names | "Use `user_id` not `userId`" | Let implementer follow codebase conventions |
| File organization | "Create file at app/services/export.py" | Let implementer explore and organize |
| Test structure | "Create test file: tests/test_export.py" | Let implementer write appropriate tests |
| Exact method signatures | "Add method: create_export_job()" | Prescribes what should emerge from design |

**Better alternatives:**
- "Use existing Celery task infrastructure" (not "Create a CeleryTask class inheriting from...")
- "Add service layer method for export" (not "Create file: app/services/export_service.py")
- "Tasks must support retries with exponential backoff" (not "Use @task(bind=True, max_retries=3)")

---

## Constraint Categories Template

```markdown
## Constraints

### Architecture
- [Pattern to follow]
- [Structure to maintain]

### Technology
- [Required technologies/libraries]
- [Prohibited technologies]

### Performance
- [Speed/throughput requirements]
- [Resource limitations]

### Security
- [Security requirements]
- [Data protection rules]

### Compatibility
- [Backwards compatibility needs]
- [Integration requirements]

### Scope
- [What must NOT be done]
- [Explicit limitations]
```

---

## Example: User Authentication

```markdown
## Constraints

### Architecture
- Use FastAPI dependency injection pattern (Depends())
- Follow existing middleware pattern for JWT validation
- Create user record on first login (Auth0 -> PostgreSQL sync)

### Technology
- Use Auth0 as authentication provider (no custom auth)
- Use python-jose for JWT decoding

### Performance
- Token verification must complete in <100ms (P95)
- JWKS cache hit rate must be >90%

### Security
- Validate JWT signature using Auth0 JWKS (RS256 algorithm)
- Validate JWT audience and issuer
- All API endpoints except /health require authentication

### Compatibility
- No breaking changes to existing user model
- Existing API clients must continue to work

### Scope
- Users can only access their own data (row-level security)
```

---

## Common Constraint Patterns

| Pattern | Template |
|---------|----------|
| Follow existing | "Follow existing [feature] pattern; use same [tech] as [feature]" |
| Technology lock-in | "Must use existing [infra]; no new [type] without approval" |
| Performance | "Complete in <[time] for [volume]; support [N] concurrent [ops]" |
| Security | "Validate [data] using [method]; users can only access [scope]" |
| No breaking changes | "No breaking changes to [API/model]; existing [clients] must work" |

---

## Benefits

- **Clear boundaries** -- implementers know what's allowed/required while retaining freedom within those boundaries
- **Consistency** -- new code fits existing patterns, technologies, and security policies
- **Verifiability** -- constraints are testable and measurable, not subjective

---

## Related

- **Requirements Analysis:** [requirements-analysis.md](requirements-analysis.md)
- **Pattern Referencing:** [pattern-referencing.md](pattern-referencing.md)
- **Main Skill:** [SKILL.md](SKILL.md)
- **Design Guidelines:** [../../docs/design-ticket-optimization-guidelines.md](../../docs/design-ticket-optimization-guidelines.md)
