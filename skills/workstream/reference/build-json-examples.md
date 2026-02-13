# Workstream Build — JSON Examples

## batch_approval.json

Written to `.claude/batch_approval.json` upon approval:

```json
{
  "approved_at": "<ISO timestamp>",
  "tickets": ["PROJ-101", "PROJ-201", "PROJ-401"],
  "pacing": "moderate",
  "concurrent_limit": 2,
  "delay_between_starts": 30,
  "estimated_time_minutes": 47,
  "approved_by": "user"
}
```

## build-queue.json

Written to `.claude/build-queue.json`:

```json
{
  "version": "1.0",
  "created": "<ISO timestamp>",
  "pacing": {
    "preset": "moderate",
    "concurrent_limit": 2,
    "delay_between_starts_seconds": 30,
    "max_runtime_minutes": 120
  },
  "queue": [
    {
      "ticket": "PROJ-101",
      "phase": 1,
      "plan_path": ".claude/plans/PROJ-101.md",
      "branch_name": "JRA_user-login_PROJ-101",
      "worktree_path": null,
      "status": "queued",
      "depends_on": []
    },
    {
      "ticket": "PROJ-201",
      "phase": 2,
      "plan_path": ".claude/plans/PROJ-201.md",
      "branch_name": "JRA_csv-import_PROJ-201",
      "worktree_path": null,
      "status": "queued",
      "depends_on": ["PROJ-101"]
    }
  ]
}
```

Queue statuses: `queued` -> `building` -> `done` | `failed`

## Unified Approval Summary Example

```
Batch Build Approval
====================
Tickets: PROJ-101, PROJ-201, PROJ-401
Workstreams: WS-1 (Auth), WS-2 (Import), WS-3 (Domain)

Files to create (24):
  src/api/auth/routes.py
  src/api/auth/schemas.py
  src/api/auth/service.py
  ... (21 more)

Files to modify (6):
  src/api/routes.py (add router includes)
  src/db/models/__init__.py (add model imports)
  ... (4 more)

Operations:
  - Create 3 git worktrees
  - Create 3 feature branches
  - Run pytest, ruff, mypy per ticket
  - Create 3 pull requests

Estimated total time: ~47 minutes
Pacing: moderate (2 concurrent, 30s delay)

Approve batch build? [yes/no/adjust]:
```
