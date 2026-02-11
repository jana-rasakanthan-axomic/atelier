# PR Review Checklist

Structured checklist for pull request merge readiness.

## PR Quality (PR)

- [ ] **PR-01** PR size is appropriate (<400 lines)
- [ ] **PR-02** Single concern/feature per PR
- [ ] **PR-03** No unrelated changes mixed in
- [ ] **PR-04** PR title is descriptive
- [ ] **PR-05** PR description explains the change
- [ ] **PR-06** Breaking changes clearly marked

> **Note on PR Size (PR-01):** We follow vertical slicing principles. A single ticket implements a complete resource (endpoint → service → repository). If a feature exceeds 400 lines, split by layer (multiple smaller PRs) rather than by incomplete functionality.

## Tests (TEST)

- [ ] **TEST-01** Tests included for new code
- [ ] **TEST-02** All tests pass locally
- [ ] **TEST-03** CI tests pass
- [ ] **TEST-04** Coverage maintained or improved
- [ ] **TEST-05** No skipped tests without reason
- [ ] **TEST-06** Test names describe behavior

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

## CI/CD (CI)

- [ ] **CI-01** Build passes
- [ ] **CI-02** Tests pass
- [ ] **CI-03** Lint passes
- [ ] **CI-04** Type check passes
- [ ] **CI-05** Security scan passes
- [ ] **CI-06** No new warnings introduced

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

## Pre-Review Checklist (Author)

Before requesting review:

```markdown
- [ ] Self-review completed
- [ ] Tests pass locally
- [ ] Linting passes
- [ ] Type checking passes
- [ ] PR description complete
- [ ] Screenshots attached (UI changes)
- [ ] Linked to issue/ticket
- [ ] Assigned reviewers
```

## Common Issues to Flag

```python
# Debug code left in
print(f"DEBUG: {variable}")
console.log('test')

# Commented code
# def old_function():
#     pass

# TODO without ticket
# TODO: fix this later

# Hardcoded values
TIMEOUT = 30  # should be from config
BASE_URL = "https://api.example.com"

# Unused imports
from typing import List, Dict, Optional  # Optional unused
```

## Review Response Template

```markdown
## PR Review Summary

### Status: APPROVE / REQUEST CHANGES / BLOCK

### Checks
- [x] Tests pass
- [x] Lint passes
- [ ] Documentation updated

### Findings
- **[file:line]** Issue → Suggested fix

### Questions
- Why was this approach chosen over X?

### Notes
- Nice refactoring of the auth module!
```
