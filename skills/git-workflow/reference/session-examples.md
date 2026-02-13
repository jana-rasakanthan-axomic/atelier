# Session Management — Detailed Examples

> Referenced from [session-management.md](../session-management.md)

## Session State File Schema

**Location:** `.claude/sessions.json`

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

## Lifecycle Script Examples

### Create Session
```bash
./scripts/session-manager.sh create \
    "$SESSION_ID" \
    "$BRANCH_NAME" \
    "$WORKTREE_PATH" \
    "$COMMAND" \
    "$CONTEXT_FILE"
```

### Update Session Progress
```bash
./scripts/session-manager.sh update \
    "$SESSION_ID" \
    --stage "Stage 2: Generate Tests"
```

### Complete Session
```bash
./scripts/session-manager.sh complete "$SESSION_ID"
```

### Fail Session
```bash
./scripts/session-manager.sh fail \
    "$SESSION_ID" \
    --reason "Tests failed"
```

### Cleanup Session
```bash
./scripts/session-manager.sh cleanup "$SESSION_ID"
```

---

## Session Operations Examples

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

### Find Session by Branch
```bash
./scripts/session-manager.sh find --branch "JRA_add-user-export_SHRED-2119"
# Returns session ID: session-abc123
```

---

## Stale Session Cleanup Example

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

## Integration with Commands Example

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
