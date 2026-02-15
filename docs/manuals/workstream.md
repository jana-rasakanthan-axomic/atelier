# User Manual: /workstream

## Overview

Workstreams manage parallel development of multiple tickets. Instead of building one ticket at a time, you create a workstream from a batch of tickets, plan them in parallel, and build them with dependency-aware ordering -- ideal for overnight batch runs.

## When to Use

- You have multiple tickets from `/design` and want to build them as a batch.
- You want to run builds overnight and review PRs in the morning.
- You need dependency-aware ordering across related tickets.

## When NOT to Use

- Single ticket: use `/plan` and `/build` directly.
- Interactive development requiring per-ticket feedback.

## Creating a Workstream

```bash
/workstream create                    # From existing .claude/tickets/*.md
/workstream create --from-sources     # Decompose from raw source docs (PRDs, contracts)
/workstream create --prefix PROJ      # Use custom ticket prefix
/workstream create --dry-run          # Preview without writing files
```

The `create` subcommand analyzes tickets for dependencies, groups them into workstreams, and writes a `status.json` file to track progress.

**Prerequisite:** Run `/gather` then `/specify` then `/design` first to generate tickets. Or use `--from-sources` to decompose directly from PRDs or contracts.

## Planning Phase

```bash
/workstream plan --all       # Plan all unplanned tickets in parallel
/workstream plan WS-1        # Plan a specific workstream only
```

Each ticket gets a plan (via `/plan`) written to `.claude/plans/`. Plans are created in parallel for speed.

After planning, review the plans:

```bash
/workstream approve --all    # Approve all completed plans
/workstream approve WS-1     # Approve a specific workstream
```

No ticket will build until its plan is approved.

## Building Phase

```bash
/workstream build --approved                        # Build all approved tickets
/workstream build --approved --pacing conservative  # Overnight mode (max 2 parallel, 20min intervals)
```

The build phase resolves dependencies, queues tickets in the correct order, and creates PRs for each completed ticket.

For fully autonomous overnight runs:

```bash
/workstream run --continuous   # Build, check PRs, unblock dependents, repeat
```

## Monitoring Progress

```bash
/workstream status              # Show all tickets and their current state
/workstream status --actionable # Show only items needing attention
/workstream pr-check            # Check open PRs for conflicts, CI failures, review comments
/workstream retry TICKET-42     # Retry a failed ticket
/workstream retry TICKET-42 --reset  # Reset retry counter and try again
```

## Typical Schedule

```
Night 1:  /workstream plan --all          # Plans created in parallel
Day 1:    /workstream approve --all       # Human reviews plans
Night 2:  /workstream build --approved    # Dependency-aware builds, PRs created
Day 2:    Review PRs, /fix --loop         # Address review feedback
Night 3:  /workstream pr-check            # Resolve conflicts and CI issues
```

## Tips

- **Keep tickets small.** Smaller tickets build faster and produce cleaner PRs.
- **Use worktrees.** Each ticket builds in its own git worktree, so parallel builds do not conflict.
- **Review daily.** Check `/workstream status --actionable` each morning for items needing attention.
- **Use conservative pacing overnight.** The `--pacing conservative` flag adds intervals between builds to avoid overwhelming CI.
- **Retry before escalating.** Failed tickets get up to 3 retries before escalation. Use `--reset` if the root cause has been fixed.
- **Max limits.** 100 tickets per creation run, 50 per plan run, 3 workstreams building in parallel.
