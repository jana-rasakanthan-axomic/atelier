---
name: workstream
description: Workstream subcommand procedures for batch ticket lifecycle. Use when orchestrating parallel workstreams, managing build queues, or tracking PR status.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(git:*), Bash(gh:*)
---

# Workstream Skill

Orchestrate batch ticket lifecycle: creation, planning, building, and PR management across parallel workstreams.

## When to Use

- Orchestrating batch ticket lifecycle (create, plan, build)
- Managing parallel workstreams across multiple tickets
- Tracking build queue status and PR management

## When NOT to Use

- Single ticket work → use `/build` or `/fix` directly
- Manual, interactive development → use individual commands
- Read-only analysis → use `/audit` or `/analyze`

## Subcommand Reference

| Subcommand | Reference Doc | Purpose |
|------------|---------------|---------|
| `create` | `create.md` | Generate workstreams from tickets or source docs |
| `plan` | `plan.md` | Parallel planning orchestration |
| `build` | `build.md` | Resource estimation, permissions, dependency-aware builds |
| `status` | `status.md` | Status display, PR maintenance, retry logic |
| `continuous` | `continuous.md` | Autonomous overnight mode |

## File Structure

```
.claude/
├── tickets/
│   ├── WORKSTREAMS.md          # Master workstream definitions
│   └── TICKET-*.md             # Individual ticket specs
├── plans/
│   └── TICKET-*.md             # Generated plans
└── workstreams/
    ├── status.json             # Global status tracking
    ├── build-queue.json        # Build execution queue
    ├── batch_approval.json     # Batch permission approvals
    └── reports/
        └── YYYY-MM-DD.md       # Daily reports
```

## Status Schema

- `plan.status`: pending | in_progress | completed | approved | rejected
- `build.status`: pending | blocked | in_progress | completed | failed
- `pr.status`: open | conflict | changes_requested | approved | merged | escalated
- `pr.retry_count`: 0-3 (escalate after 3)
