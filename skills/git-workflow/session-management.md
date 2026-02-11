# Session Management

**Purpose:** Track command state across execution lifecycle.

**State File:** `.claude/sessions.json`

---

## Overview

Session management tracks active command executions, allowing:
- Resume interrupted commands
- List active sessions
- Clean up abandoned worktrees
- Audit command history

---

## Session State File

**Location:** `.claude/sessions.json` (in project root)

**Format:**
```json
{
  "session-abc123": {
    "command": "/build",
    "branch": "JRA_add-user-export_SHRED-2119",
    "worktree_path": ".claude/worktrees/session-abc123",
    "status": "active",
    "context_file": ".claude/context/SHRED-2119.md",
    "created_at": "2026-01-16T10:30:00Z",
    "updated_at": "2026-01-16T10:45:00Z"
  },
  "session-def456": {
    "command": "/fix",
    "branch": "JRA_fix-dockerfile_OA-1655",
    "worktree_path": ".claude/worktrees/session-def456",
    "status": "completed",
    "context_file": null,
    "created_at": "2026-01-16T09:15:00Z",
    "completed_at": "2026-01-16T09:32:00Z"
  }
}
```

---

## Session Lifecycle

```
create → active → completed/failed → cleanup
```

### 1. Create Session

**When:** During worktree setup (Stage 0)

```bash
./scripts/session-manager.sh create \
    "$SESSION_ID" \
    "$BRANCH_NAME" \
    "$WORKTREE_PATH" \
    "$COMMAND" \
    "$CONTEXT_FILE"

# Creates entry with status: "active"
```

**Entry created:**
```json
{
  "session-abc123": {
    "command": "/build",
    "branch": "JRA_add-user-export_SHRED-2119",
    "worktree_path": ".claude/worktrees/session-abc123",
    "status": "active",
    "context_file": ".claude/context/SHRED-2119.md",
    "created_at": "2026-01-16T10:30:00Z",
    "updated_at": "2026-01-16T10:30:00Z"
  }
}
```

---

### 2. Update Session

**When:** During command execution (optional, for progress tracking)

```bash
./scripts/session-manager.sh update \
    "$SESSION_ID" \
    --stage "Stage 2: Generate Tests"

# Updates "updated_at" timestamp and optional stage info
```

---

### 3. Complete Session

**When:** Command finishes successfully

```bash
./scripts/session-manager.sh complete "$SESSION_ID"

# Updates:
# - status: "active" → "completed"
# - completed_at: timestamp
```

**Updated entry:**
```json
{
  "session-abc123": {
    "command": "/build",
    "branch": "JRA_add-user-export_SHRED-2119",
    "worktree_path": ".claude/worktrees/session-abc123",
    "status": "completed",
    "context_file": ".claude/context/SHRED-2119.md",
    "created_at": "2026-01-16T10:30:00Z",
    "completed_at": "2026-01-16T11:15:00Z"
  }
}
```

---

### 4. Fail Session

**When:** Command fails or is interrupted

```bash
./scripts/session-manager.sh fail \
    "$SESSION_ID" \
    --reason "Tests failed"

# Updates:
# - status: "active" → "failed"
# - failed_at: timestamp
# - failure_reason: message
```

---

### 5. Cleanup Session

**When:** User removes worktree (see [cleanup.md](./cleanup.md))

```bash
./scripts/session-manager.sh cleanup "$SESSION_ID"

# Removes session entry from sessions.json
```

---

## Session Operations

### List Active Sessions

```bash
./scripts/session-manager.sh list

# Output:
# Active Sessions:
#   session-abc123 (2h 15m ago)
#     Command:  /build
#     Branch:   JRA_add-user-export_SHRED-2119
#     Worktree: .claude/worktrees/session-abc123
#
#   session-def456 (30m ago)
#     Command:  /fix
#     Branch:   JRA_fix-dockerfile_OA-1655
#     Worktree: .claude/worktrees/session-def456
```

---

### Get Session Info

```bash
./scripts/session-manager.sh get "$SESSION_ID"

# Output (JSON):
{
  "command": "/build",
  "branch": "JRA_add-user-export_SHRED-2119",
  "worktree_path": ".claude/worktrees/session-abc123",
  "status": "active",
  "created_at": "2026-01-16T10:30:00Z"
}
```

---

### Find Session by Branch

```bash
./scripts/session-manager.sh find --branch "JRA_add-user-export_SHRED-2119"

# Returns session ID: session-abc123
```

---

## State Validation

**Before command execution:**
```bash
# Check if session already exists
if ./scripts/session-manager.sh exists "$SESSION_ID"; then
    echo "Error: Session '$SESSION_ID' already exists"
    exit 1
fi

# Check if branch has active session
EXISTING_SESSION=$(./scripts/session-manager.sh find --branch "$BRANCH_NAME")
if [ -n "$EXISTING_SESSION" ]; then
    echo "Error: Branch '$BRANCH_NAME' is already in use by session $EXISTING_SESSION"
    exit 1
fi
```

---

## Cleanup Stale Sessions

**Abandoned sessions** (worktree deleted but session remains):

```bash
./scripts/session-manager.sh cleanup-stale

# For each active session:
#   - Check if worktree path still exists
#   - If not, mark session as "abandoned" or remove it
```

**Example:**
```bash
# Session exists but worktree was manually deleted
# sessions.json shows:
{
  "session-abc123": {
    "worktree_path": ".claude/worktrees/session-abc123",  # doesn't exist
    "status": "active"
  }
}

# After cleanup-stale:
# Session removed or marked abandoned
```

---

## Integration with Commands

**In command workflow:**

```markdown
## Stage 0: Worktree Setup

1. Generate session ID: `SESSION_ID=$(uuidgen)`
2. Create worktree (see worktree-setup.md)
3. **Create session:**
   ```bash
   ./scripts/session-manager.sh create \
       "$SESSION_ID" \
       "$BRANCH_NAME" \
       "$WORKTREE_PATH" \
       "/build" \
       ".claude/context/SHRED-2119.md"
   ```

## Stage 1-N: Implementation

Optional: Update session progress
```bash
./scripts/session-manager.sh update "$SESSION_ID" --stage "Stage 2"
```

## Stage N+1: Completion

Mark session complete:
```bash
./scripts/session-manager.sh complete "$SESSION_ID"
```

Output next steps to user (see cleanup.md)
```

---

## Error Handling

### Session Creation Fails

```bash
if ! ./scripts/session-manager.sh create ...; then
    echo "Error: Failed to create session"
    # Clean up worktree before exiting
    ./scripts/worktree-manager.sh cleanup "$SESSION_ID" --force
    exit 1
fi
```

### Session File Corrupted

```bash
# If sessions.json is invalid JSON
if ! jq empty .claude/sessions.json 2>/dev/null; then
    echo "Error: Session file corrupted"
    echo "Backup: cp .claude/sessions.json .claude/sessions.json.backup"
    echo "Fix: Edit .claude/sessions.json to valid JSON or delete it"
    exit 1
fi
```

---

## Session State Examples

### Active Session
```json
{
  "session-abc123": {
    "command": "/build",
    "branch": "JRA_add-user-export_SHRED-2119",
    "worktree_path": ".claude/worktrees/session-abc123",
    "status": "active",
    "context_file": ".claude/context/SHRED-2119.md",
    "created_at": "2026-01-16T10:30:00Z",
    "updated_at": "2026-01-16T10:45:00Z"
  }
}
```

### Completed Session
```json
{
  "session-abc123": {
    "command": "/build",
    "branch": "JRA_add-user-export_SHRED-2119",
    "worktree_path": ".claude/worktrees/session-abc123",
    "status": "completed",
    "context_file": ".claude/context/SHRED-2119.md",
    "created_at": "2026-01-16T10:30:00Z",
    "completed_at": "2026-01-16T11:15:00Z"
  }
}
```

### Failed Session
```json
{
  "session-def456": {
    "command": "/fix",
    "branch": "JRA_fix-dockerfile_OA-1655",
    "worktree_path": ".claude/worktrees/session-def456",
    "status": "failed",
    "failure_reason": "Tests failed after 3 attempts",
    "created_at": "2026-01-16T09:15:00Z",
    "failed_at": "2026-01-16T09:32:00Z"
  }
}
```

---

## Best Practices

1. **Always create session** during worktree setup
2. **Always mark complete or failed** when command ends
3. **Cleanup session** after removing worktree
4. **Run cleanup-stale** periodically to remove abandoned sessions
5. **Don't manually edit** `.claude/sessions.json` (use session-manager.sh)

---

## Related Documentation

- [Worktree Setup](./worktree-setup.md) - Creates session
- [Cleanup](./cleanup.md) - Removes session
- [Git Workflow](./SKILL.md) - Overview

---

**Next:** Session management is automatic when using [worktree-setup.md](./worktree-setup.md) and [cleanup.md](./cleanup.md).
