# Workstream Continuous

Reference documentation for the `/workstream continuous` subcommand. Enables autonomous overnight operation.

---

## Purpose

Run an autonomous loop that continuously builds approved plans, resolves PR issues, unblocks dependents after merges, and generates progress reports. Designed for unattended overnight execution.

---

## Loop

Each iteration of the continuous loop performs these steps in order:

```
┌──────────────────────────────────────────────┐
│  1. Check approved plans --> build            │
│  2. Check open PRs --> resolve issues         │
│  3. Check merged PRs --> unblock dependents   │
│  4. Generate progress report                  │
│  5. Sleep for interval                        │
│  6. Check max runtime --> exit if exceeded    │
└──────────────────────────────────────────────┘
```

### Step 1: Build Approved Plans

- Query `status.json` for tickets with `plan_status: approved` and `build_status: none`
- Filter to tickets whose dependencies are all `build_status: done`
- Invoke `/workstream build` for each buildable ticket (respecting pacing limits)

### Step 2: Resolve Open PRs

- Query `status.json` for tickets with open PRs (`pr_status` not in `merged`, `closed`)
- Invoke `/workstream pr-check` for each
- Handle merge conflicts, review comments, and CI failures automatically
- Respect retry limits (max 3 per ticket before escalating)

### Step 3: Unblock Dependents

- Query `status.json` for tickets with `pr_status: merged` since last iteration
- For each merged ticket, check its `blocks` list
- Update blocked tickets: if all their `blocked_by` tickets are now `done`, mark them as buildable
- These newly unblocked tickets will be picked up in Step 1 on the next iteration

### Step 4: Generate Report

Write a progress report to the configured report path:

```
Continuous Run Report — 2026-02-11T06:00:00Z
=============================================
Runtime: 4h 32m / 8h max
Iterations: 54

Built:    PROJ-101, PROJ-201, PROJ-401 (3 tickets)
Merged:   PROJ-101, PROJ-201 (2 tickets)
Pending:  PROJ-401 (PR #47, awaiting review)
Failed:   PROJ-801 (escalated after 3 retries)
Blocked:  PROJ-301 (waiting on PROJ-201 merge)

Next actions:
  - PROJ-401: PR needs review
  - PROJ-801: Manual intervention required (CI infra failure)
  - PROJ-301: Will auto-build once PROJ-201 merges
```

### Step 5: Sleep

Wait for the configured interval before starting the next iteration.

### Step 6: Runtime Check

If elapsed time exceeds `max_runtime`, generate a final report and exit gracefully. All in-progress builds are allowed to complete; no new builds are started.

---

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `interval` | 5 min | Time between loop iterations |
| `max_runtime` | 8h | Maximum total runtime before graceful exit |
| `report_path` | `.claude/continuous-report.md` | Path for progress reports |
| `pacing` | `moderate` | Pacing preset for builds (conservative/moderate/aggressive) |

Override via flags:

```bash
/workstream continuous --interval 10m --max-runtime 12h --report .claude/overnight-report.md
```

Or set in `.atelier/config.yaml`:

```yaml
workstream:
  continuous:
    interval: 5m
    max_runtime: 8h
    report_path: .claude/continuous-report.md
    pacing: moderate
```
