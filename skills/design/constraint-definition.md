# Constraint Definition

**Purpose:** Define technical boundaries and limitations for implementation.

**Part of:** Design skill

---

## Overview

Constraints are boundaries that define what implementers must follow, must NOT do, or technical limitations they must work within. Good constraints guide implementation without being prescriptive.

**Key Principle:** Define boundaries, not solutions.

---

## Types of Constraints

### 1. Architectural Constraints

**What they define:** Patterns and structures that must be followed.

**Examples:**
- "Follow repository → service → router layering"
- "Use existing Auth0 integration (no custom auth)"
- "Maintain REST API design (no GraphQL)"
- "Use async/await for all I/O operations"

### 2. Technical Constraints

**What they define:** Technologies, libraries, or approaches that must/must NOT be used.

**Examples:**
- "Must use existing Celery infrastructure"
- "Must use PostgreSQL (no NoSQL)"
- "Must use python-jose for JWT validation"
- "No new external dependencies without approval"

### 3. Performance Constraints

**What they define:** Speed, throughput, or resource limitations.

**Examples:**
- "Complete in <60s for 100k records"
- "API response time <200ms (P95)"
- "Support 1000 concurrent users"
- "Memory usage <512MB per worker"

### 4. Security Constraints

**What they define:** Security requirements and boundaries.

**Examples:**
- "Validate JWT signature using RS256 (not HS256)"
- "All user queries must filter by authenticated user ID"
- "Sensitive data must be encrypted at rest"
- "Rate limit: 100 requests/minute per user"

### 5. Compatibility Constraints

**What they define:** Backwards compatibility and integration requirements.

**Examples:**
- "No breaking changes to existing API endpoints"
- "Must maintain compatibility with v1 clients"
- "Cannot modify existing user model schema"
- "Must work with current database schema"

### 6. Scope Constraints

**What they define:** What is explicitly NOT allowed or included.

**Examples:**
- "Assets can only be reordered within current block (no cross-block)"
- "No cascade deletes (manual cleanup only)"
- "No scheduled/automated operations (manual trigger only)"
- "Backend only (frontend changes out of scope)"

### 7. Exception Constraints (Required for Contract Definition)

**What they define:** How errors are structured for logging and API responses.

**Required Pattern:** All exceptions must follow the structured logging pattern:

```python
class ServiceNameError(Exception):
    """Base exception with message, detail, context for structured logging."""
    def __init__(
        self,
        message: str,
        detail: dict[str, Any] | None = None,
        context: dict[str, Any] | None = None,
    ):
        self.message = message
        self.detail = detail or {"message": message}
        self.context = context or {}  # For structured log queries
        super().__init__(self.message)
```

**Required Hierarchy:**
1. **Base**: `ServiceNameError` (e.g., `MiseServiceError`, `ProposalDraftServiceError`)
2. **Categories**: `NotFoundError`, `ValidationError`, `AuthorizationError`, `ExternalServiceError`
3. **Specific**: Inherit from categories, populate `context` with queryable fields

**Required Features:**
- `context` dict enables structured log queries (`app_context.recipe_id = "..."`)
- `detail` dict provides standardized API response body
- Use `ResourceNotFoundMixin` for DRY "X with id Y not found" patterns
- External service errors include: `service_name`, `status_code`, `response_body`
- Exception handler maps exception types to HTTP status codes

**Reference Implementation:** `AXO492/src/exceptions.py`

**Examples:**
```markdown
## Exception Constraints
- All exceptions inherit from service-specific base (e.g., MiseServiceError)
- Exceptions carry context dict for structured logging
- Use ResourceNotFoundMixin for resource not found errors
- External service errors capture service_name, status_code, response_body
- HTTP status codes mapped in exception handler
```

---

## How to Define Good Constraints

### ✅ Good Constraints (Boundaries)

#### Example 1: Architectural Pattern
```markdown
## Constraints
- Must follow repository → service → router layering
- Use existing UnitOfWork pattern for transactions
- No direct database access from routers
```

**Why good:**
- States pattern to follow (not specific classes/methods)
- Sets clear architectural boundary
- Doesn't prescribe exact implementation

#### Example 2: Technology Choice
```markdown
## Constraints
- Must use existing Celery + Redis infrastructure
- No new message queue systems
- Background tasks must be idempotent (safe to retry)
```

**Why good:**
- States what to use (existing infrastructure)
- States what NOT to do (new systems)
- Adds requirement (idempotency)

#### Example 3: Performance Boundary
```markdown
## Constraints
- Token validation must complete in <100ms (P95)
- JWKS cache must reduce Auth0 API calls by >90%
- No synchronous external API calls in request path
```

**Why good:**
- Specific, measurable targets
- States performance requirement
- Doesn't prescribe caching implementation

### ❌ Bad Constraints (Too Prescriptive)

#### Example 1: Too Implementation-Specific
```markdown
## Constraints
- Create a CeleryTask class inheriting from app.tasks.BaseTask
- Use @task(bind=True, max_retries=3) decorator
- Call self.retry(countdown=60) on failure
```

**Why bad:**
- Prescribes exact class structure
- Specifies decorator parameters
- Dictates error handling implementation

**Better:**
```markdown
## Constraints
- Use existing Celery task infrastructure
- Tasks must support retries with exponential backoff
- Follow error handling pattern from existing tasks
```

#### Example 2: Over-Specific File Structure
```markdown
## Constraints
- Create new file: app/services/export_service.py
- Add method: create_export_job() that returns ExportJob
- Import UnitOfWork from app.core.database
```

**Why bad:**
- Specifies exact file path
- Prescribes method name
- Dictates import structure

**Better:**
```markdown
## Constraints
- Add service layer method for export job creation
- Use existing UnitOfWork pattern
- Follow service pattern from similar features
```

---

## Constraint Categories Template

Use this template for the Constraints section:

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

## Examples

### Example 1: User Authentication

```markdown
## Constraints

### Architecture
- Use FastAPI dependency injection pattern (Depends())
- Follow existing middleware pattern for JWT validation
- Create user record on first login (Auth0 → PostgreSQL sync)

### Technology
- Use Auth0 as authentication provider (no custom auth)
- Use python-jose for JWT decoding
- Support multiple auth methods: magic link, Google OAuth, Apple OAuth

### Performance
- Token verification must complete in <100ms (P95)
- JWKS cache hit rate must be >90%

### Security
- Validate JWT signature using Auth0 JWKS (RS256 algorithm)
- Validate JWT audience and issuer
- All API endpoints except /health require authentication
- User records synced from Auth0 (auth0_id as primary identifier)

### Compatibility
- No breaking changes to existing user model
- Existing API clients must continue to work

### Scope
- All endpoints require authentication (except /health)
- Users can only access their own data (row-level security)
```

### Example 2: Asset Reordering

```markdown
## Constraints

### Architecture
- Follow existing section/block reordering pattern
- Use repository → service → router layering
- Position calculation must be atomic (transaction)

### Technology
- Use same position data type as sections/blocks
- No new libraries or dependencies

### Performance
- Reorder operation must complete in <100ms
- Queries must perform efficiently for blocks with 100+ assets

### Security
- Validate full hierarchy (draft → section → block → asset)
- Maintain tenant isolation (customer_id/user_id validation)
- Users can only reorder assets they own

### Compatibility
- No breaking changes to existing asset endpoints
- GET /assets must return assets in position order

### Scope
- Assets can only be reordered within current block (no cross-block movement)
- No bulk reordering (one asset at a time)
- No automatic sorting or renumbering
```

### Example 3: Recipe Import

```markdown
## Constraints

### Architecture
- Use existing async job pattern (like report generation)
- Store job status for progress tracking
- Import processing must be idempotent (safe to retry)

### Technology
- Use Gemini 1.5 Flash for AI extraction
- Use existing S3 infrastructure for file storage
- No new external services without approval

### Performance
- Import must complete within 10 seconds for URLs
- Import must complete within 15 seconds for images/PDFs
- Support concurrent imports (10+ per minute)

### Security
- Validate file size (<10MB)
- Sanitize URLs (prevent SSRF attacks)
- Users can only import to their own library

### Compatibility
- No changes to existing recipe model
- Must work with current database schema

### Scope
- Backend only (frontend integration separate)
- Single import at a time (no bulk imports)
- No scheduled/automated imports
```

---

## Common Patterns

### Pattern 1: Follow Existing Pattern

When similar feature exists:

```markdown
## Constraints
- Follow existing [feature name] pattern
- Use same [technology/approach] as [feature name]
- Maintain consistency with [feature name] implementation
```

### Pattern 2: Technology Lock-In

When specific tech is required:

```markdown
## Constraints
- Must use existing [infrastructure/library]
- No new [type of dependency] without approval
- Compatible with [existing system]
```

### Pattern 3: Performance Requirements

When speed/scale matters:

```markdown
## Constraints
- Complete in <[time] for [data volume]
- Support [number] concurrent [operations]
- [Resource] usage <[limit]
```

### Pattern 4: Security Boundaries

When security is critical:

```markdown
## Constraints
- Validate [data/token] using [method]
- Users can only access [scope]
- All [data type] must be [protected how]
```

### Pattern 5: No Breaking Changes

When compatibility is critical:

```markdown
## Constraints
- No breaking changes to [API/model/schema]
- Existing [clients/integrations] must continue to work
- Backwards compatible with [version/system]
```

---

## What NOT to Constrain

Avoid constraining these (let implementer decide):

### ❌ Don't Constrain: Variable Names
```markdown
# BAD
## Constraints
- Use variable name `user_id` (not `userId` or `uid`)
- Method parameters must be: draft_id, section_id, block_id
```

Let implementer follow codebase conventions.

### ❌ Don't Constrain: File Organization
```markdown
# BAD
## Constraints
- Create file at: app/services/export_service.py
- Add helper functions in: app/utils/export_helpers.py
```

Let implementer explore and organize appropriately.

### ❌ Don't Constrain: Implementation Details
```markdown
# BAD
## Constraints
- Use for loop to iterate users (not list comprehension)
- Calculate position as: (prev + next) / 2
```

Let implementer write good code.

### ❌ Don't Constrain: Test Structure
```markdown
# BAD
## Constraints
- Create test file: tests/services/test_export_service.py
- Use pytest fixtures: mock_user_repo, mock_s3_service
```

Let implementer write appropriate tests.

---

## Benefits of Good Constraints

### For Implementation:
- **Clear boundaries:** Know what's allowed/required
- **Freedom within boundaries:** Can make good decisions
- **Consistency:** Matches existing codebase
- **Safety:** Avoids violating requirements

### For Code Quality:
- **Architectural consistency:** New code fits existing patterns
- **Technical consistency:** Uses approved technologies
- **Performance requirements:** Meets SLAs
- **Security compliance:** Follows security policies

---

## Checklist

Use this when defining constraints:

- [ ] Constraints are boundaries, not solutions
- [ ] State what must be followed (patterns, technologies)
- [ ] State what must NOT be done (prohibited approaches)
- [ ] Include performance requirements (if applicable)
- [ ] Include security requirements (if applicable)
- [ ] Include compatibility requirements (if applicable)
- [ ] Constraints are verifiable (testable/measurable)
- [ ] No variable names, file paths, or implementation details
- [ ] No over-specification (too prescriptive)

---

## Related

- **Requirements Analysis:** [requirements-analysis.md](requirements-analysis.md)
- **Pattern Referencing:** [pattern-referencing.md](pattern-referencing.md)
- **Main Skill:** [SKILL.md](SKILL.md)
- **Design Guidelines:** [../../docs/design-ticket-optimization-guidelines.md](../../docs/design-ticket-optimization-guidelines.md)
