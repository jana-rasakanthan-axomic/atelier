# Design Command Checkpointing System

Enable `/design` to persist progress across context windows, allowing seamless resumption.

## Overview

The `/design` command is a multi-stage process that can exceed context window limits. This checkpointing system:

1. **Tracks progress** via a session state file
2. **Persists artifacts** at natural breakpoints
3. **Enables resumption** from any checkpoint
4. **Preserves user decisions** across sessions

## Architecture

```
.claude/
├── design/
│   ├── sessions/
│   │   └── {feature-name}.session.json    <- Session state
│   │
│   ├── {feature-name}-rules.md            <- Stage 1 output
│   ├── {feature-name}-analysis.md         <- Stage 3a output
│   ├── {feature-name}-contracts.md        <- Stage 4 output (complex)
│   └── {feature-name}-bdd.feature         <- Stage 5 output
│
├── tickets/
│   └── {TICKET-ID}.md                     <- Stage 6 output (per ticket)
│
docs/
├── design/
│   └── {feature-name}.md                  <- Stage 3b output (TDD)
│
└── adr/
    └── NNNN-{decision}.md                 <- Stage 3b output (ADRs)
```

## Session State Schema

**File:** `.claude/design/sessions/{feature-name}.session.json`

```json
{
  "version": "1.0",
  "feature_name": "user-export",
  "prd_source": ".claude/context/EPIC-123.md",
  "created_at": "2026-01-28T10:00:00Z",
  "updated_at": "2026-01-28T14:30:00Z",

  "current_stage": 3,
  "stage_status": {
    "0": "complete",
    "1": "complete",
    "2": "complete",
    "3": "in_progress",
    "4": "pending",
    "5": "pending",
    "6": "pending",
    "7": "pending"
  },

  "checkpoints": { },

  "artifacts": {
    "rules": ".claude/design/user-export-rules.md",
    "analysis": ".claude/design/user-export-analysis.md",
    "tdd": "docs/design/user-export.md",
    "adrs": ["docs/adr/0042-async-export-via-celery.md"],
    "bdd": null,
    "contracts": ".claude/design/user-export-contracts.md",
    "tickets": [".claude/tickets/EXPORT-001.md"]
  },

  "tickets_progress": {
    "total_planned": 5,
    "created": 2,
    "remaining": ["POST /export", "GET /export/{id}/download"]
  }
}
```

Each checkpoint entry in `checkpoints` records `completed_at`, relevant file paths, user approval status, and any user modifications.

## Checkpoint Definitions

| # | Checkpoint | Trigger | What's Saved | Key Files | How to Resume |
|---|-----------|---------|--------------|-----------|---------------|
| 1 | Business Rules | User approves extracted rules | Rules file, approval status, modifications | `.claude/design/{feature}-rules.md` | Read rules file, confirm with user, proceed to Stage 2 |
| 2a | Alternatives Analysis | All alternatives generated | Analysis markdown, research findings, pros/cons | `.claude/design/{feature}-analysis.md` | Read analysis file, present alternatives, get user choice |
| 2b | Design Approval | TDD and ADRs written, user approved | TDD document, all ADRs, approval | `docs/design/{feature}.md`, `docs/adr/NNNN-*.md` | Read TDD, confirm with user, proceed to Stage 4 |
| 3 | BDD Scenarios | All scenarios generated | Gherkin feature file, scenario count | `.claude/design/{feature}-bdd.feature` | Read feature file, proceed to Stage 6 |
| 4 | Ticket Generation | Each ticket created (incremental) | Created tickets, remaining endpoints, dependencies | `.claude/tickets/{TICKET-ID}.md` | Count existing tickets, create remaining |

## Resume Protocol

### Detecting Existing Session

When `/design` is invoked:

1. Check for `.claude/design/sessions/{feature-name}.session.json`
2. If exists: parse session state, identify `current_stage`, offer resume options
3. If not exists: create new session, start from Stage 0

### Resume Options

Present to user:
```
Found existing design session for "user-export"

Progress:
  [done] Stage 0: Clarification - Complete
  [done] Stage 1: Business Rules - Complete (8 rules approved)
  [done] Stage 2: Analysis - Complete (determined: complex)
  [wip]  Stage 3: Design - In Progress (alternatives generated, awaiting choice)
  [wait] Stage 4-7: Pending

Options:
  1. Resume from Stage 3 (recommended)
  2. Restart from Stage 0 (discard progress)
  3. View current artifacts
```

### Stage-Specific Resume Logic

| Resume At | Steps |
|-----------|-------|
| Stage 1 (Rules in progress) | Read rules file, present to user, ask for approval, on approval proceed to Stage 2 |
| Stage 3a (Alternatives generated) | Read analysis file, present alternatives, get user choice, proceed to Stage 3b |
| Stage 3b (TDD in progress) | Check if TDD file exists; if complete ask approval, if partial continue writing |
| Stage 6 (Tickets in progress) | Count existing ticket files, compare to total planned, continue creating remaining |

## Resume Command Syntax

| Command | Purpose |
|---------|---------|
| `/design .claude/context/EPIC-123.md` | Start new design |
| `/design user-export` | Resume existing (auto-detected) |
| `/design user-export --resume --stage 3` | Force resume from specific stage |
| `/design user-export --restart` | Restart (discard progress) |
| `/design user-export --status` | View session status only |

## Command Integration

After completing any stage, the `/design` command must:

1. **Save checkpoint:** Update session file with checkpoint data, mark stage complete, advance `current_stage`
2. **Save artifacts:** Write output files (rules.md, analysis.md, etc.), update `artifacts` in session state
3. **Handle interruption:** If context window nearing limit, save state and inform user. Provide resume command: `/design {feature-name} --resume`

> Session management is implemented via bash scripts in `scripts/`. See `scripts/design-session.sh` for the session manager functions (get_or_create, save_checkpoint, get_resume_stage, mark_stage_complete).

## Error Recovery

| Scenario | Detection | Resolution |
|----------|-----------|------------|
| Corrupted session file | JSON parse fails | Reconstruct state from existing artifact files, confirm with user |
| Missing artifact file | Session says stage complete but file missing | Re-run the stage, or mark incomplete and restart from there |
| Conflicting state | Session says incomplete but artifact exists | Read artifact, ask user if it is approved, update session accordingly |

In all cases, present recovery options to the user via `AskUserQuestion` before taking action.

## Best Practices

### For Users

1. **Let it checkpoint** - Don't interrupt mid-stage
2. **Review artifacts** - Check generated files between stages
3. **Use --status** - Check progress before resuming
4. **Commit checkpoints** - Git commit after major stages for backup

### For the Agent

1. **Save early, save often** - Update session after each significant action
2. **Verify artifacts exist** - Check files before marking complete
3. **Inform user** - "Checkpoint saved. You can safely resume later."
4. **Handle gracefully** - If context limit approaching, save and exit cleanly
