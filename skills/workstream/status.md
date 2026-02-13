# Workstream Status, PR-Check, and Retry

Reference documentation for the `/workstream status`, `/workstream pr-check`, and `/workstream retry` subcommands.

---

## Status Subcommand

```
/workstream status [--actionable]
```

### Read and Display Status

1. Read `.claude/status.json`
2. Format a summary table grouped by workstream and phase

### Default Output

```
Workstream Status
=================
Phase 1 — Foundation
  PROJ-101  User login .............. build: done     PR: #42 merged
  PROJ-901  CI pipeline ............. build: done     PR: #43 merged

Phase 2 — Core Features
  PROJ-201  CSV import .............. build: done     PR: #44 review
  PROJ-401  Create asset ............ build: running  PR: --
  PROJ-801  Auth0 integration ....... plan: approved  build: queued

Phase 3 — Advanced Features
  PROJ-301  PDF export .............. plan: draft     build: --
  PROJ-402  Update asset ............ plan: none      build: --

Summary: 7 tickets | 2 done | 2 in-progress | 3 pending
Critical path: PROJ-101 -> PROJ-201 -> PROJ-301 (1/3 complete)
```

### Actionable Filter

`/workstream status --actionable` shows only tickets that require user action:

| Actionable State | Required Action |
|-----------------|-----------------|
| `plan_status: draft` | Review and approve the plan |
| `build_status: failed` | Investigate failure, retry or fix |
| `pr_status: changes_requested` | Address review feedback |
| `pr_status: failing_checks` | Fix CI failures |
| `pr_status: merge_conflicts` | Rebase the branch |

```
Actionable Items
================
  PROJ-301  PDF export .............. ACTION: Approve plan (.claude/plans/PROJ-301.md)
  PROJ-201  CSV import .............. ACTION: PR #44 has review comments (2 threads)
  PROJ-401  Create asset ............ ACTION: Build failed (test_asset_create, attempt 2/3)

3 items need attention.
```

---

## PR-Check Subcommand

```
/workstream pr-check [PROJ-101] [--all]
```

Checks the status of open PRs and takes corrective action.

### Fetch PR Status

For each ticket with an open PR:

```bash
gh pr view <pr_number> --json state,reviewDecision,statusCheckRollup,mergeable
```

### Handle Merge Conflicts

When `mergeable: CONFLICTING`:

1. Navigate to the ticket's worktree
2. Attempt rebase onto the base branch:
   ```bash
   cd <worktree_path> && git fetch origin && git rebase origin/main
   ```
3. If rebase succeeds, force-push the branch:
   ```bash
   git push --force-with-lease
   ```
4. If rebase fails (manual resolution needed), mark as `needs_manual_rebase` and report to user

### Handle Review Comments

When `reviewDecision: CHANGES_REQUESTED`:

1. Invoke `/review --self --loop <pr_number>` to address feedback
   - The self-review loop fetches external comments from the PR automatically
   - Runs multi-persona self-review alongside external comment resolution
   - Fixes all findings iteratively via ASSESS -> FIX -> VERIFY loop
   - Pushes fixes and replies to resolved comment threads with commit SHAs
2. Update `status.json` with new commit SHA

### Handle CI Failures

When status checks fail:

1. Identify failing checks from `statusCheckRollup`
2. Read CI logs to determine failure cause
3. Classify failure:
   - **Test failure**: Re-run `/build` for the failing layer
   - **Lint failure**: Run linter fix and commit
   - **Type error**: Fix type annotation and commit
   - **Infra failure**: Report to user (cannot auto-fix)

### Retry Logic

Each corrective action increments `retry_count` in `status.json`:

| Retry Count | Action |
|-------------|--------|
| 1 | Attempt automatic fix |
| 2 | Attempt automatic fix with different strategy |
| 3 | Escalate to user with full diagnostic report |

After 3 failed retries, the ticket is marked `build_status: escalated` and excluded from further automatic processing.

```
PR-Check Report
===============
  PR #42 (PROJ-101) .... merged
  PR #44 (PROJ-201) .... rebased (was conflicting)
  PR #45 (PROJ-401) .... iterated (2 comments addressed)
  PR #46 (PROJ-801) .... ESCALATED (3 retries, CI infra failure)
```

---

## Retry Subcommand

```
/workstream retry PROJ-101
```

Manually retry a failed or escalated ticket.

### Reset and Re-Run

1. Reset `retry_count` to 0 in `status.json`
2. Determine failure type from status:
   - `build_status: failed` -> Re-run `/build` for the ticket
   - `pr_status: failing_checks` -> Re-run `/workstream pr-check` for the ticket
   - `pr_status: changes_requested` -> Re-run `/review --self --loop` for the ticket
   - `pr_status: merge_conflicts` -> Attempt rebase
3. Update status based on outcome

```
Retry: PROJ-101
  Reset retry_count: 3 -> 0
  Failure type: build_status: failed
  Action: Re-running /build PROJ-101
  Result: build: done, PR #47 created
```

### Bulk Retry

```
/workstream retry --all-failed
```

Retries all tickets with `build_status: failed` or `build_status: escalated`, resetting their retry counts and re-running the appropriate action.
