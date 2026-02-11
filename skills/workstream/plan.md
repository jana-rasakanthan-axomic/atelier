# Workstream Plan

Reference documentation for the `/workstream plan` subcommand. Plans tickets for implementation in parallel by invoking `/plan` for each plannable ticket.

---

## Purpose

Batch-plan multiple tickets from a workstream. Reads the dependency graph and status tracking to determine which tickets are ready to plan, invokes `/plan` for each one, and updates status.

---

## Workflow

```
Parse Scope --> Get Plannable Tickets --> Parallel Planning --> Update Status --> Report
```

### Step 1: Parse Scope

The scope determines which tickets to plan:

| Argument | Behavior |
|----------|----------|
| `--all` | Plan all tickets with `plan_status: none` and `status: ready` |
| `WS-N` | Plan all plannable tickets in workstream N |
| `PROJ-101 PROJ-201` | Plan specific tickets by ID |
| *(no argument)* | Plan all plannable tickets in the current phase |

### Step 2: Get Plannable Tickets

A ticket is plannable when:
- `plan_status` is `none` (not yet planned)
- `status` is `ready` (not draft, not in-progress, not done)
- All `blocked_by` tickets have `plan_status: approved` or `build_status: done`

Read from `.claude/status.json`:

```bash
# Pseudocode
for ticket in scope:
    if ticket.plan_status != "none": skip
    if ticket.status != "ready": skip
    if any(dep.plan_status not in ["approved"] and dep.build_status != "done" for dep in ticket.blocked_by): skip
    plannable.append(ticket)
```

### Step 3: Parallel Planning

For each plannable ticket, invoke the `/plan` command:

```
/plan PROJ-101    # Generates .claude/plans/PROJ-101.md
/plan PROJ-201    # Generates .claude/plans/PROJ-201.md
```

Plans are generated in parallel where possible (tickets in the same phase with no mutual dependencies).

### Step 4: Update Status

After each plan is generated:

```json
{
  "PROJ-101": {
    "plan_status": "draft",
    "plan_path": ".claude/plans/PROJ-101.md"
  }
}
```

Plan status transitions: `none` -> `draft` -> `approved` -> `building` -> `done`

Plans in `draft` status require user approval before building.

### Step 5: Generate Report

```
Planning Report
===============
Scope: WS-1 (Authentication)
Plannable: 3 tickets
Planned: 3 tickets
Skipped: 0 tickets

Results:
  PROJ-101  User login ............... planned (draft)
  PROJ-102  Token refresh ............ planned (draft)
  PROJ-103  Password reset ........... planned (draft)

Next: Review plans in .claude/plans/ and approve with /workstream approve
```

---

## Output

| Artifact | Path | Content |
|----------|------|---------|
| Plan files | `.claude/plans/<TICKET-ID>.md` | Layered implementation plan |
| Status updates | `.claude/status.json` | `plan_status` set to `draft` |
| Planning report | stdout | Summary table |
