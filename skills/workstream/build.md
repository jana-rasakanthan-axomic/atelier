# Workstream Build

Reference documentation for the `/workstream build` subcommand. Builds approved plans into PRs with dependency awareness, resource estimation, and batch permission collection.

---

## Purpose

Execute approved implementation plans as isolated builds, each producing a PR. Handles dependency ordering, resource estimation, user approval, and pacing to manage parallel workload.

---

## Stage 1: Parse Scope

Determine which tickets to build:

| Argument | Behavior |
|----------|----------|
| `--all` | Build all tickets with `plan_status: approved` |
| `WS-N` | Build all approved tickets in workstream N |
| `PROJ-101 PROJ-201` | Build specific tickets by ID |
| *(no argument)* | Build all approved tickets in the next buildable phase |

A ticket is buildable when:
- `plan_status` is `approved`
- `build_status` is `none` or `failed`
- All `blocked_by` tickets have `build_status: done` (PR merged)

---

## Stage 1.4: Resource Estimation

Before requesting approval, estimate the resource cost of the build batch.

### Estimation Script

```bash
estimate-build-resources.py --tickets PROJ-101 PROJ-201 PROJ-401
```

The script reads each ticket's plan and estimates:
- Lines of code (new + modified)
- Number of files (new + modified)
- Number of test cases
- Estimated build time (based on layer count and complexity)

### Per-Ticket Breakdown

```
Resource Estimation
===================
Ticket        Layers  Files  Lines   Tests  Est. Time
-----------------------------------------------------
PROJ-101      4       8      320     24     ~15 min
PROJ-201      3       6      240     18     ~12 min
PROJ-401      5       10     450     30     ~20 min
-----------------------------------------------------
Total         12      24     1010    72     ~47 min
```

### Pacing Recommendation

Based on total resource usage, recommend a pacing preset:

```
Recommendation: moderate pacing (2 concurrent builds, 30s delay)
Reason: 24 files across 3 tickets; moderate resource usage
```

See pacing presets table below.

---

## Stage 1.5: Batch Permission Collection

Aggregate all permissions needed across all tickets in the batch and present a single approval prompt.

### Aggregate Permissions

For each ticket's plan, collect:
- Files to be created (with paths)
- Files to be modified (with paths)
- External tools to be invoked (test runner, linter, type checker)
- Git operations (branch creation, commits, PR creation)

### Unified Summary

Present a single summary showing: tickets and workstreams, files to create/modify (with counts), operations (worktrees, branches, test runs, PRs), estimated time, and pacing preset. End with `Approve batch build? [yes/no/adjust]:` prompt.

See `reference/build-json-examples.md` for the full summary format example.

### ExitPlanMode Approval

This is the critical gate. The user must explicitly approve before any builds begin. Options:

| Response | Action |
|----------|--------|
| `yes` | Write `batch_approval.json`, proceed to Stage 2 |
| `no` | Abort. No changes made. |
| `adjust` | Modify scope (remove tickets), re-estimate, re-prompt |

### batch_approval.json

Written to `.claude/batch_approval.json` upon approval. Contains: `approved_at`, `tickets`, `pacing`, `concurrent_limit`, `delay_between_starts`, `estimated_time_minutes`, `approved_by`. See `reference/build-json-examples.md` for the full schema.

---

## Stage 2: Dependency Resolution

Read the dependency graph from `.claude/status.json` and determine execution order.

### Sort Execution Order

1. Read `dependency_graph` from status.json
2. Perform topological sort
3. Group tickets by phase (depth level)
4. Within each phase, tickets can run in parallel up to the concurrency limit

```
Execution Order:
  Phase 1 (parallel): PROJ-101, PROJ-901
  Phase 2 (parallel): PROJ-201, PROJ-401
  Phase 3 (parallel): PROJ-301
```

Tickets in later phases do not start until all their dependencies in earlier phases have `build_status: done`.

---

## Stage 3: Write Build Queue

Generate the build queue file consumed by the runner.

### build-queue.json

Written to `.claude/build-queue.json`. Contains `version`, `created`, `pacing` config, and `queue` array where each entry has: `ticket`, `phase`, `plan_path`, `branch_name`, `worktree_path`, `status`, `depends_on`.

Queue statuses: `queued` -> `building` -> `done` | `failed`

See `reference/build-json-examples.md` for the full JSON schema and examples.

---

## Stage 4: Runner Instructions

After writing the build queue, output instructions for the workstream runner.

### Runner Commands

```bash
# Start the build queue
workstream-runner.sh start

# Check progress
workstream-runner.sh status

# Stop gracefully (finish current builds, do not start new ones)
workstream-runner.sh stop
```

The runner reads `build-queue.json`, respects pacing configuration, and invokes `/build` for each ticket in order.

---

## Pacing Presets

| Preset | Concurrent Limit | Delay Between Starts | Max Runtime | Use Case |
|--------|------------------|---------------------|-------------|----------|
| `conservative` | 1 | 60s | 180 min | Small machines, limited resources, first run |
| `moderate` | 2 | 30s | 120 min | Standard development machine, typical batch |
| `aggressive` | 4 | 10s | 90 min | Powerful machine, CI environment, urgent delivery |

### Selecting a Preset

The pacing recommendation is based on:
- Total number of files in the batch (< 15: conservative, 15-40: moderate, > 40: aggressive)
- Number of tickets (< 3: conservative, 3-6: moderate, > 6: aggressive)
- User can override with `--pacing <preset>` flag

### Custom Pacing

```bash
/workstream build --pacing custom --concurrent 3 --delay 20
```

Custom pacing writes the values directly to `build-queue.json` without using a preset name.
