# Workstream PR-Check Integration Test Procedure

Validates that `/workstream pr-check` correctly identifies open PRs, runs self-review, and produces actionable results.

---

## Prerequisites

1. An active workstream with at least **one ticket that has an open PR**
2. `.claude/workstreams/status.json` initialized and tracking the workstream tickets
3. The open PR should have at least one reviewable change (not an empty diff)
4. `gh` CLI authenticated and able to access the repository
5. Ralph-loop installed (required for the `/review --self --loop` invocation)

## Steps

1. **Verify workstream state**
   ```bash
   scripts/workstream-status.sh list
   ```
   Confirm at least one ticket shows `pr.status: open`.

2. **Run pr-check for a specific ticket**
   ```
   /workstream pr-check <TICKET-ID>
   ```

3. **Observe the pr-check pipeline**:
   - Fetches PR metadata via `gh pr view`
   - Identifies PR state (mergeable, review decision, check status)
   - Invokes `/review --self --loop <PR#>` for review
   - Updates `status.json` with results

4. **Verify the review output**:
   - Review findings are reported (issues found or clean)
   - Any fixes are committed and pushed to the PR branch
   - `status.json` reflects updated PR state

5. **Run pr-check for all open PRs** (optional, broader coverage)
   ```
   /workstream pr-check --all
   ```

## Success Criteria

| Criterion | Required |
|-----------|----------|
| PR metadata fetched successfully via `gh pr view` | Yes |
| `/review --self --loop` invoked for the open PR | Yes |
| Review completes without crashing | Yes |
| Issues found are specific and actionable (file, line, description) | Yes |
| Fixes (if any) are committed to the PR branch | Yes |
| `status.json` updated with current PR state | Yes |
| PR-Check report printed with per-PR summary | Yes |

## Failure Modes

| Failure | Diagnosis |
|---------|-----------|
| `gh pr view` fails | Check `gh auth status`; ensure repo access |
| Self-review loop does not start | Confirm ralph-loop is installed; check `--loop` flag handling |
| Review finds no issues on a PR with known problems | Check that the active profile's linter and test runner are configured |
| `status.json` not updated | Verify write permissions on `.claude/workstreams/status.json` |
| Retry count exceeds 3 | Ticket should be marked `escalated`; confirm escalation logic |

## Notes

- This test validates the integration between workstream orchestration and the self-review loop; it does not test review quality itself (see `self-review-loop-test.md` for that)
- For a controlled test, create a PR with 1-2 minor lint issues so the loop converges quickly
- The pr-check subcommand also handles merge conflicts and CI failures, but those paths require specific repo states to trigger and are not covered by this basic procedure
