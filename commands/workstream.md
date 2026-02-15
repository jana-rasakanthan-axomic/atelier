---
name: workstream
description: Create workstreams from source documents and orchestrate batch planning/building
model_hint: sonnet
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(gh:*), Bash(git:*), Bash(jq:*), Bash($TOOLKIT_DIR/scripts/*), AskUserQuestion, Task
---

# /workstream

Create workstreams from design tickets or source documents, then orchestrate batch planning, building, and PR management.

## Input Formats

```bash
/workstream create <source_file>            # Parse PRD/plan into tickets
/workstream status                          # Show all tickets
/workstream next                            # Get next unblocked ticket
/workstream depends <ticket> <depends_on>   # Add dependency
/workstream update <ticket> <status>        # Update ticket status
/workstream plan --all                      # Plan all unplanned tickets
/workstream approve --all                   # Approve all completed plans
/workstream build --approved                # Build all approved tickets
/workstream pr-check                        # Check/fix all open PRs
/workstream run --continuous                # Overnight mode
```

## When to Use

- Orchestrating multiple tickets from `/design`
- Batch planning and building overnight
- Decomposing epics into dependency-aware tickets

## When NOT to Use

- Single ticket -- use `/plan` + `/build` directly
- Interactive development requiring per-ticket feedback

---

## Engine

Deterministic operations (create, status, next, depends, update) are handled by `scripts/workstream_engine.py`. State lives in `.claude/workstreams/status.json`.

```bash
scripts/workstream_engine.py create <source_file>
scripts/workstream_engine.py status
scripts/workstream_engine.py next
scripts/workstream_engine.py depends <ticket_id> <depends_on_id>
scripts/workstream_engine.py update <ticket_id> <status>
```

Exit codes: 0 success, 1 no tickets available, 2 error.

---

## Subcommand Router

### `create`

Run `scripts/workstream_engine.py create <source_file>`. The engine parses the file, extracts tickets, resolves dependencies, detects cycles, and writes status.json.

**Large batches (>10 tickets):** Delegate dependency resolution to the workstream engine script (`scripts/workstream_engine.py`) rather than computing inline. For batches requiring custom logic beyond the engine's capabilities, use a subagent via the Task tool for graph computation (topological sort, cycle detection, critical path). See `docs/reference/subagent-patterns.md`.

**Reference:** `skills/workstream/create.md`

### `status`

Run `scripts/workstream_engine.py status`. Prints a phase-grouped table with ticket status, build state, and blockers.

### `next`

Run `scripts/workstream_engine.py next`. Returns JSON with the highest-priority unblocked ticket respecting dependency order.

### `depends`

Run `scripts/workstream_engine.py depends <ticket_id> <depends_on_id>`. Validates both tickets exist, checks for cycles, recomputes phases.

### `update`

Run `scripts/workstream_engine.py update <ticket_id> <status>`. Valid statuses: pending, in_progress, done, blocked.

### `plan` / `approve` / `build`

Plan: invoke `/plan` per ticket (`skills/workstream/plan.md`). Approve: validate plan file, set `plan_status = "approved"`. Build: resource estimation, permissions, dependency-aware builds (`skills/workstream/build.md`).

### `pr-check` / `retry` / `run --continuous`

PR-check and retry: `skills/workstream/status.md`. Continuous: `skills/workstream/continuous.md`.

---

## Workflow Overview

```
Night 1: /workstream plan --all         --> Plans created in parallel
Day 1:   /workstream approve --all      --> Human reviews plans
Night 2: /workstream build --approved   --> Dependency-aware builds --> PRs
Night 3: /workstream pr-check           --> Resolve conflicts, reviews, CI
```

## Error Handling

| Scenario | Action |
|----------|--------|
| No tickets found | Guide to `/design` or `create <source_file>` |
| Dependency cycle | Engine exits with code 2 and cycle path |
| Plan failure | Record in status.json, continue others |
| Build failure | Mark failed, block dependents, continue |
| PR failure (3 retries) | Escalate, add to report |

## Scope Limits

- Max 100 tickets per creation run
- Max 50 tickets per plan run
- Max 3 workstreams building in parallel
- Max 3 retry attempts before escalation
