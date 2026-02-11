---
name: workstream
description: Create workstreams from source documents and orchestrate batch planning/building
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(gh:*), Bash(git:*), Bash(jq:*), Bash($TOOLKIT_DIR/scripts/*), AskUserQuestion, Task
---

# /workstream

Create workstreams from design tickets or source documents, then orchestrate batch planning, building, and PR management.

## Input Formats

```bash
# Creation
/workstream create                          # From existing .claude/tickets/*.md (default)
/workstream create --from-sources           # Decompose from raw source docs
/workstream create --prefix PROJ --dry-run  # Preview with custom prefix

# Planning
/workstream plan --all                      # Plan all unplanned tickets (parallel)
/workstream plan WS-1                       # Plan specific workstream

# Approval
/workstream approve --all                   # Approve all completed plans
/workstream approve WS-1                    # Approve specific workstream

# Building
/workstream build --approved                         # Build all approved tickets
/workstream build --approved --pacing conservative   # Overnight (max 2 parallel, 20min intervals)

# Monitoring
/workstream status                          # Show all tickets
/workstream pr-check                        # Check/fix all open PRs
/workstream retry MISE-102                  # Retry failed ticket

# Autonomous
/workstream run --continuous                # Overnight mode
```

## When to Use

- Orchestrating multiple tickets from `/design`
- Batch planning and building overnight
- Monitoring and maintaining open PRs
- Decomposing epics into dependency-aware tickets

## When NOT to Use

- Single ticket → `/plan` + `/build` directly
- Interactive development requiring per-ticket feedback

## Prerequisites

- **Default:** Existing `.claude/tickets/*.md` from `/design`
- **With `--from-sources`:** At least one source doc (PRD, stories, or contracts)
- Recommended: `/gather` → `/specify` → `/design` → `/workstream create`

---

## Subcommand Router

Each subcommand's full procedure is in `skills/workstream/`:

### `create`

**Reference:** `skills/workstream/create.md`

Two entry points:
- **Default** (from `/design` tickets): Stages 3→4→5 (dependency analysis → grouping → output)
- **`--from-sources`**: All 5 stages (source analysis → decomposition → dependencies → grouping → output)

### `plan`

**Reference:** `skills/workstream/plan.md`

Plan tickets in parallel. Invokes `/plan` per ticket, updates status.json.

### `approve`

Mark plans as approved. Validates plan file exists, updates `plan.status = "approved"` in status.json.

### `build`

**Reference:** `skills/workstream/build.md`

Resource estimation → batch permission collection → dependency resolution → write build queue → provide runner instructions.

### `status`

**Reference:** `skills/workstream/status.md`

Display ticket status across workstreams. Use `--actionable` for items needing action.

### `pr-check`

**Reference:** `skills/workstream/status.md`

Monitor open PRs: resolve conflicts, address review comments, fix CI failures. Max 3 retries before escalation.

### `retry`

**Reference:** `skills/workstream/status.md`

Retry failed or escalated tickets. Use `--reset` to reset retry counter.

### `run --continuous`

**Reference:** `skills/workstream/continuous.md`

Autonomous overnight loop: build approved → check PRs → unblock dependents → report → sleep.

---

## Workflow Overview

```
Night 1: /workstream plan --all         → Plans created in parallel
Day 1:   /workstream approve --all      → Human reviews plans
Night 2: /workstream build --approved   → Dependency-aware builds → PRs
Night 3: /workstream pr-check           → Resolve conflicts, reviews, CI
```

## Error Handling

| Scenario | Action |
|----------|--------|
| No tickets found | Guide to `/design` or `--from-sources` |
| Plan failure | Record in status.json, continue others |
| Build failure | Mark failed, block dependents, continue |
| PR failure (3 retries) | Escalate, add to report |

## Scope Limits

- Max 100 tickets per creation run
- Max 50 tickets per plan run
- Max 3 workstreams building in parallel
- Max 3 retry attempts before escalation
