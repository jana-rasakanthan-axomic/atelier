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
│   │   └── {feature-name}.session.json    ← Session state
│   │
│   ├── {feature-name}-rules.md            ← Stage 1 output
│   ├── {feature-name}-analysis.md         ← Stage 3a output
│   ├── {feature-name}-contracts.md        ← Stage 4 output (complex)
│   └── {feature-name}-bdd.feature         ← Stage 5 output
│
├── tickets/
│   └── {TICKET-ID}.md                     ← Stage 6 output (per ticket)
│
docs/
├── design/
│   └── {feature-name}.md                  ← Stage 3b output (TDD)
│
└── adr/
    └── NNNN-{decision}.md                 ← Stage 3b output (ADRs)
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

  "checkpoints": {
    "stage_0_clarity": {
      "completed_at": "2026-01-28T10:05:00Z",
      "was_clear": false,
      "questions_asked": [
        "What is the expected data volume?",
        "What format should exports support?"
      ],
      "user_answers": {
        "data_volume": "Up to 100k users",
        "export_formats": "CSV and JSON"
      }
    },
    "stage_1_rules": {
      "completed_at": "2026-01-28T10:30:00Z",
      "rules_file": ".claude/design/user-export-rules.md",
      "rules_count": 8,
      "user_approved": true,
      "user_modifications": "Added rate limit rule"
    },
    "stage_2_analysis": {
      "completed_at": "2026-01-28T10:45:00Z",
      "complexity": "complex",
      "reason": "Async processing, external storage, 100k scale"
    },
    "stage_3a_alternatives": {
      "completed_at": "2026-01-28T11:30:00Z",
      "analysis_file": ".claude/design/user-export-analysis.md",
      "alternatives_count": 3,
      "chosen_alternative": 2,
      "choice_rationale": "Best balance of complexity and scalability"
    },
    "stage_3b_design": {
      "completed_at": "2026-01-28T13:00:00Z",
      "tdd_file": "docs/design/user-export.md",
      "adr_files": [
        "docs/adr/0042-async-export-via-celery.md",
        "docs/adr/0043-s3-for-export-storage.md"
      ],
      "user_approved": true
    }
  },

  "artifacts": {
    "rules": ".claude/design/user-export-rules.md",
    "analysis": ".claude/design/user-export-analysis.md",
    "tdd": "docs/design/user-export.md",
    "adrs": ["docs/adr/0042-async-export-via-celery.md"],
    "bdd": null,
    "contracts": ".claude/design/user-export-contracts.md",
    "tickets": [
      ".claude/tickets/EXPORT-001.md",
      ".claude/tickets/EXPORT-002.md"
    ]
  },

  "tickets_progress": {
    "total_planned": 5,
    "created": 2,
    "remaining": ["POST /export", "GET /export/{id}/download", "DELETE /export/{id}"]
  }
}
```

## Checkpoint Definitions

### Checkpoint 1: Business Rules (Stage 1)

**Trigger:** User approves extracted business rules

**Persisted State:**
- Rules markdown file
- User approval status
- Any modifications made

**Files:**
- `.claude/design/{feature}-rules.md`
- Session state updated

**Recovery:** Read rules file, confirm with user, proceed to Stage 2

---

### Checkpoint 2a: Alternatives Analysis (Stage 3a)

**Trigger:** All alternatives generated, before user choice

**Persisted State:**
- Analysis markdown with all alternatives
- Codebase research findings
- Pros/cons for each

**Files:**
- `.claude/design/{feature}-analysis.md`
- Session state updated

**Recovery:** Read analysis file, present alternatives, get user choice

---

### Checkpoint 2b: Design Approval (Stage 3b)

**Trigger:** TDD and ADRs written, user approved

**Persisted State:**
- Complete TDD document
- All ADRs
- User approval

**Files:**
- `docs/design/{feature}.md`
- `docs/adr/NNNN-*.md`
- Session state updated

**Recovery:** Read TDD, confirm with user, proceed to Stage 4

---

### Checkpoint 3: BDD Scenarios (Stage 5)

**Trigger:** All scenarios generated

**Persisted State:**
- Complete Gherkin feature file
- Scenario count

**Files:**
- `.claude/design/{feature}-bdd.feature`
- Session state updated

**Recovery:** Read feature file, proceed to Stage 6

---

### Checkpoint 4: Ticket Generation (Stage 6)

**Trigger:** Each ticket created (incremental)

**Persisted State:**
- All created tickets
- Remaining endpoints to slice
- Dependencies

**Files:**
- `.claude/tickets/{TICKET-ID}.md` (per ticket)
- Session state updated after each

**Recovery:** Count existing tickets, determine remaining, continue creation

---

## Resume Protocol

### Detecting Existing Session

When `/design` is invoked:

```
1. Check for existing session file:
   .claude/design/sessions/{feature-name}.session.json

2. If exists:
   → Parse session state
   → Identify current_stage and stage_status
   → Offer resume options to user

3. If not exists:
   → Create new session
   → Start from Stage 0
```

### Resume Options

Present to user:
```
Found existing design session for "user-export"

Progress:
  ✅ Stage 0: Clarification - Complete
  ✅ Stage 1: Business Rules - Complete (8 rules approved)
  ✅ Stage 2: Analysis - Complete (determined: complex)
  🔄 Stage 3: Design - In Progress (alternatives generated, awaiting choice)
  ⏳ Stage 4-7: Pending

Options:
  1. Resume from Stage 3 (recommended)
  2. Restart from Stage 0 (discard progress)
  3. View current artifacts
```

### Stage-Specific Resume Logic

**Resume Stage 1 (Rules in progress):**
```
1. Read .claude/design/{feature}-rules.md
2. Present rules to user
3. Ask: "These rules were extracted. Do you approve?"
4. On approval → Mark Stage 1 complete, proceed to Stage 2
```

**Resume Stage 3a (Alternatives generated):**
```
1. Read .claude/design/{feature}-analysis.md
2. Present all alternatives
3. Ask: "Which alternative do you want to proceed with?"
4. On choice → Save choice, proceed to Stage 3b (TDD)
```

**Resume Stage 3b (TDD in progress):**
```
1. Check if docs/design/{feature}.md exists
2. If exists and complete → Ask for approval
3. If partial → Continue TDD writing
4. On approval → Proceed to Stage 4
```

**Resume Stage 6 (Tickets in progress):**
```
1. Count existing .claude/tickets/{PREFIX}-*.md files
2. Compare to tickets_progress.total_planned
3. If incomplete → Continue creating remaining tickets
4. If complete → Proceed to Stage 7 (Review)
```

## Implementation

### Session Manager Functions

```python
# Pseudocode for session management

def get_or_create_session(feature_name: str) -> DesignSession:
    """Load existing session or create new one."""
    session_path = f".claude/design/sessions/{feature_name}.session.json"
    if file_exists(session_path):
        return load_session(session_path)
    return create_session(feature_name)

def save_checkpoint(session: DesignSession, checkpoint: str, data: dict):
    """Save checkpoint data and update session state."""
    session.checkpoints[checkpoint] = {
        "completed_at": now(),
        **data
    }
    session.updated_at = now()
    save_session(session)

def get_resume_stage(session: DesignSession) -> int:
    """Determine which stage to resume from."""
    for stage in range(8):
        if session.stage_status[str(stage)] != "complete":
            return stage
    return 7  # All complete, show review

def mark_stage_complete(session: DesignSession, stage: int):
    """Mark a stage as complete and save."""
    session.stage_status[str(stage)] = "complete"
    if stage < 7:
        session.current_stage = stage + 1
    save_session(session)
```

### Command Integration

Add to `/design` command:

```markdown
## Stage 0: Session Check

Before starting any design work:

1. **Check for existing session:**
   - Look for `.claude/design/sessions/{feature-name}.session.json`
   - If found, parse and determine resume point

2. **If resuming:**
   - Show progress summary
   - Use `AskUserQuestion` to confirm resume or restart
   - If resume: Jump to appropriate stage
   - If restart: Archive old session, create new

3. **If new session:**
   - Create session file
   - Initialize all stages as "pending"
   - Proceed to Stage 0 (Clarification)

## After Each Stage

After completing any stage:

1. **Save checkpoint:**
   - Update session file with checkpoint data
   - Mark stage as "complete"
   - Update `current_stage` to next

2. **Save artifacts:**
   - Write output files (rules.md, analysis.md, etc.)
   - Update `artifacts` in session state

3. **Handle interruption:**
   - If context window nearing limit, save state and inform user
   - Provide resume command: `/design {feature-name} --resume`
```

## Resume Command Syntax

```bash
# Start new design
/design .claude/context/EPIC-123.md

# Resume existing design (auto-detected)
/design user-export

# Force resume from specific stage
/design user-export --resume --stage 3

# Restart (discard progress)
/design user-export --restart

# View session status only
/design user-export --status
```

## Error Recovery

### Corrupted Session File

```
1. Attempt to parse session JSON
2. If parse fails:
   → Check for artifact files (rules.md, analysis.md, etc.)
   → Reconstruct session state from existing files
   → Ask user to confirm reconstructed state
```

### Missing Artifact Files

```
1. Session says Stage 1 complete, but rules.md missing
2. Options:
   → Re-run Stage 1 (re-extract rules)
   → Mark Stage 1 incomplete and restart from there
3. Present options to user via AskUserQuestion
```

### Conflicting State

```
1. Session says Stage 3 incomplete, but TDD file exists
2. Likely: Stage completed but session not updated
3. Action:
   → Read TDD file
   → Ask user: "Found existing TDD. Is this approved?"
   → If yes: Update session, proceed
   → If no: Re-run Stage 3
```

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

## Migration

For existing `/design` runs without sessions:

1. Check for artifact files in `.claude/design/`
2. If found, offer to create session from existing artifacts
3. User confirms which stages are complete
4. Create session file with reconstructed state
