# Engineering Review Checklist

Structured checklist for code quality and architecture reviews.

## Architecture (ARCH)

- [ ] **ARCH-01** Follows repository/service/external/router pattern
- [ ] **ARCH-02** Business logic in service layer (not routes)
- [ ] **ARCH-03** Data access in repository layer (not service)
- [ ] **ARCH-04** No circular dependencies
- [ ] **ARCH-05** Dependencies flow inward (clean architecture)
- [ ] **ARCH-06** Appropriate abstraction level
- [ ] **ARCH-07** Clear module boundaries

## Code Quality (QUAL)

- [ ] **QUAL-01** Functions are focused (<20 lines ideal)
- [ ] **QUAL-02** Single Responsibility Principle followed
- [ ] **QUAL-03** No code duplication (DRY)
- [ ] **QUAL-04** Clear, descriptive naming
- [ ] **QUAL-05** Comments explain "why" not "what"
- [ ] **QUAL-06** No magic numbers/strings
- [ ] **QUAL-07** Consistent code style

## Import Conventions (IMPORT)

- [ ] **IMPORT-01** All imports at top of file, not within code blocks
- [ ] **IMPORT-02** Use absolute import paths (e.g., `from app.config import Config`)
- [ ] **IMPORT-03** No relative imports (avoid `from ..config import Config`)
- [ ] **IMPORT-04** Imports organized: stdlib, third-party, local

## Type Safety (TYPE)

- [ ] **TYPE-01** Type hints on public functions
- [ ] **TYPE-02** Return types specified
- [ ] **TYPE-03** No `Any` without justification
- [ ] **TYPE-04** Pydantic models at boundary interfaces (router ↔ service ↔ external)
- [ ] **TYPE-05** Optional types properly handled
- [ ] **TYPE-06** Generic types used appropriately

## Error Handling (ERR)

- [ ] **ERR-01** Domain-specific exceptions used
- [ ] **ERR-02** Exceptions have clear messages
- [ ] **ERR-03** Errors logged with context
- [ ] **ERR-04** No bare `except:` clauses
- [ ] **ERR-05** Failed operations don't leave partial state
- [ ] **ERR-06** Retry logic where appropriate

## Performance (PERF)

- [ ] **PERF-01** No N+1 query patterns
- [ ] **PERF-02** Appropriate eager/lazy loading
- [ ] **PERF-03** Database queries use indexes
- [ ] **PERF-04** Large datasets paginated
- [ ] **PERF-05** Async used for I/O operations
- [ ] **PERF-06** No blocking calls in async code
- [ ] **PERF-07** Caching where appropriate

## Database (DB)

- [ ] **DB-01** Transactions scoped correctly
- [ ] **DB-02** Session lifecycle managed (no leaks)
- [ ] **DB-03** Migrations are reversible
- [ ] **DB-04** Indexes on frequently queried columns
- [ ] **DB-05** Foreign keys have ON DELETE behavior
- [ ] **DB-06** No raw SQL without justification
- [ ] **DB-07** Uses SQLAlchemy 2.0 syntax (`select()` not `query()`)

## Testing (TEST)

- [ ] **TEST-01** Tests exist for new code
- [ ] **TEST-02** Unit tests for business logic
- [ ] **TEST-03** Integration tests for cross-layer
- [ ] **TEST-04** Edge cases covered
- [ ] **TEST-05** Tests are independent
- [ ] **TEST-06** Mocks used appropriately
- [ ] **TEST-07** Test names describe behavior

## Async Code (ASYNC)

- [ ] **ASYNC-01** Async functions awaited
- [ ] **ASYNC-02** No sync blocking in async context
- [ ] **ASYNC-03** Proper timeout handling
- [ ] **ASYNC-04** Resource cleanup in finally/context manager
- [ ] **ASYNC-05** Concurrent operations use gather

## API Design (API)

- [ ] **API-01** RESTful conventions followed
- [ ] **API-02** Consistent response format
- [ ] **API-03** Appropriate HTTP status codes
- [ ] **API-04** Pagination for list endpoints
- [ ] **API-05** Versioning strategy clear
- [ ] **API-06** Request validation complete

## Complexity Thresholds

| Metric | Good | Warning | Action |
|--------|------|---------|--------|
| Function lines | <20 | 20-30 | >30: Split |
| Cyclomatic complexity | <10 | 10-15 | >15: Refactor |
| Parameters | <5 | 5-7 | >7: Use object |
| File lines | <300 | 300-500 | >500: Split |
| Nesting depth | <3 | 3-4 | >4: Extract |
| Class methods | <10 | 10-15 | >15: Split |

## PR Quality (PR)

- [ ] **PR-01** PR size is appropriate (<400 lines)
- [ ] **PR-02** Single concern/feature per PR
- [ ] **PR-03** No unrelated changes mixed in
- [ ] **PR-04** PR title is descriptive
- [ ] **PR-05** PR description explains the change
- [ ] **PR-06** Breaking changes clearly marked

> **Note on PR Size (PR-01):** We follow vertical slicing principles. A single ticket implements a complete resource (endpoint → service → repository). If a feature exceeds 400 lines, split by layer (multiple smaller PRs) rather than by incomplete functionality.

## Code Hygiene (HYGIENE)

- [ ] **HYGIENE-01** No debug code (print, console.log)
- [ ] **HYGIENE-02** No commented-out code
- [ ] **HYGIENE-03** No TODO without ticket reference
- [ ] **HYGIENE-04** No hardcoded values (should be config)
- [ ] **HYGIENE-05** Imports organized
- [ ] **HYGIENE-06** No unused imports/variables
- [ ] **HYGIENE-07** Linting passes

## Documentation (DOC)

- [ ] **DOC-01** Code comments where non-obvious
- [ ] **DOC-02** API changes documented
- [ ] **DOC-03** README updated (if needed)
- [ ] **DOC-04** CHANGELOG entry (if applicable)
- [ ] **DOC-05** Migration guide (for breaking changes)

## Git History (GIT)

- [ ] **GIT-01** Commit messages are clear
- [ ] **GIT-02** Follows conventional commits (use `/commit` command for generation)
- [ ] **GIT-03** No "WIP" or "fix" commits
- [ ] **GIT-04** Logical commit grouping
- [ ] **GIT-05** No merge commits in feature branch
- [ ] **GIT-06** Commits are atomic

## Deployment Safety (DEPLOY)

- [ ] **DEPLOY-01** Backwards compatible
- [ ] **DEPLOY-02** Migration provided (if needed)
- [ ] **DEPLOY-03** Feature flag for risky changes
- [ ] **DEPLOY-04** Rollback plan exists
- [ ] **DEPLOY-05** No secrets in code
- [ ] **DEPLOY-06** Config externalized

## PR Size Guidelines

| Size | Lines Changed | Recommendation |
|------|---------------|----------------|
| XS | <50 | Excellent - fast review |
| S | 50-200 | Good - reviewable |
| M | 200-400 | Acceptable - allow time |
| L | 400-800 | Consider splitting |
| XL | >800 | Must split |

## Merge Criteria

### Required

- [ ] At least one approval
- [ ] CI passes (all checks green)
- [ ] No unresolved comments
- [ ] No merge conflicts
- [ ] Branch up to date with base

### Recommended

- [ ] Two approvals for critical paths
- [ ] Security review for auth changes
- [ ] Performance review for data-heavy code
- [ ] Product review for UX changes

## Priority Classification

| Priority | Description | Timeline |
|----------|-------------|----------|
| P0 | Blocking issue, cannot merge | Before merge |
| P1 | Significant issue | Before merge |
| P2 | Should fix | Next PR ok |
| P3 | Nice to have | Backlog |
