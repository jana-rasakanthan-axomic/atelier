# Self-Review Loop Test Procedure

Validates that `/review --self --loop` correctly finds issues, fixes them, re-reviews, and converges to a clean state.

---

## Prerequisites

1. A git branch with **known code quality issues** (see `evals/fixtures/review-test-branch.md` for setup)
2. Active profile configured for the project (test runner, linter, type checker all functional)
3. Ralph-loop installed and operational
4. Clean working tree on the test branch (no uncommitted changes)

## Steps

1. **Checkout the test branch**
   ```bash
   git checkout <test-branch-name>
   ```

2. **Run the self-review loop**
   ```
   /review --self --loop
   ```

3. **Observe iteration behavior** -- the loop should cycle through:
   - ASSESS: Multi-persona review finds issues (lint errors, missing tests, style violations)
   - DECIDE: Prioritizes highest-severity issue
   - ACT: Applies the fix (edit code, add tests, fix lint)
   - VERIFY: Re-runs all gates (test runner, linter, type checker)
   - Repeat until clean or max iterations reached

4. **Record results** after the loop completes:
   - Total iterations taken
   - Issues found per iteration (should decrease monotonically)
   - Final gate status (all pass / some remain)
   - Whether a PR was created

## Success Criteria

| Criterion | Required |
|-----------|----------|
| Converges within 5 iterations | Yes |
| All lint errors resolved | Yes |
| All missing tests added and passing | Yes |
| All style violations fixed | Yes |
| No regressions introduced (existing tests still pass) | Yes |
| Final VERIFY passes all gates | Yes |
| Outputs `REVIEW COMPLETE` promise text | Yes |
| PR created (if configured) | Yes |

## Failure Modes

| Failure | Diagnosis |
|---------|-----------|
| Does not converge within 5 iterations | Issues too numerous or fixes introduce new issues -- reduce fixture complexity |
| Fix introduces regression | ACT step not scoped narrowly enough -- check VERIFY catches it and DECIDE re-prioritizes |
| Loop exits early with issues remaining | Check max iteration config in `skills/iterative-dev/configs/defaults.md` |
| Ralph-loop not found | Confirm installation; `/review --self --loop` must STOP and report, not silently fall back |

## Known Limitations

- The test exercises the loop machinery, not specific code review quality -- review depth depends on model capability
- Fixture branches must be manually created and maintained; they are not auto-generated
- Network-dependent operations (gh CLI for PR creation) may fail in offline environments
- Convergence speed varies with fixture complexity; 5 iterations assumes a moderate issue count (5-10 issues)
