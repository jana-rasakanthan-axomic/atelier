# Build Log Template

## When to Write

- Created at start of Stage 3 (Build)
- Appended at EVERY TDD phase transition
- Summary appended at Stage 4 (Verify) completion
- Output to: `.claude/builds/<BRANCH_NAME>/build.log.md`

## Log File Structure

### Header

- Ticket ID(s), branch, worktree, plan file
- Started timestamp, base branch

### Phase Entries (appended per transition)

Each entry:
- [TIMESTAMP] PHASE -- Layer Name
- Action: what was done (1-2 lines)
- Files: created/modified (list)
- Result: test counts (X passed, Y failed), lint errors, type errors
- Duration: time since previous entry

Phase types:
- RED: wrote tests, ran them, confirmed failure
- GREEN: wrote implementation, ran tests, confirmed pass
- GREEN-RETRY: implementation fix attempt (attempt N of 3)
- VERIFY: ran lint + type check after a layer
- LINT-FIX: fixed lint errors
- TYPE-FIX: fixed type errors
- REGRESSION: ran full test suite

### Summary Table (appended at completion)

| Metric | Value |
|--------|-------|
| Duration | X min |
| Files created | N |
| Files modified | N |
| Lines added | N |
| Tests written | N |
| Tests passing | N/N |
| Lint fixes | N |
| Type fixes | N |
| GREEN retries | N |
| Layers completed | N/N |

### Plan Alignment Checklist (appended at completion)

For each endpoint/function from the plan:
- [x] or [ ] -- description
- Deferred items noted

### Pre-Existing Issues

- List any pre-existing test failures (not caused by this build)
- Separated from new issues to avoid confusion
