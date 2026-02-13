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

## Session Schema

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
  }
}
```

> See [reference/session-examples.md](reference/session-examples.md) for full examples of each state and detailed script usage.

---

## Session Lifecycle

```
create --> active --> completed/failed --> cleanup
```

| State | Trigger | Script Command | Key Changes |
|-------|---------|----------------|-------------|
| **create** | Worktree setup (Stage 0) | `session-manager.sh create $ID $BRANCH $PATH $CMD $CTX` | status: "active", created_at set |
| **update** | During execution (optional) | `session-manager.sh update $ID --stage "Stage 2"` | updated_at refreshed |
| **complete** | Command succeeds | `session-manager.sh complete $ID` | status: "completed", completed_at set |
| **fail** | Command fails | `session-manager.sh fail $ID --reason "msg"` | status: "failed", failure_reason set |
| **cleanup** | User removes worktree | `session-manager.sh cleanup $ID` | Entry removed from sessions.json |

---

## Session Operations

| Operation | Command | Output |
|-----------|---------|--------|
| List active | `session-manager.sh list` | Session IDs with age, command, branch, path |
| Get details | `session-manager.sh get $ID` | JSON with full session info |
| Find by branch | `session-manager.sh find --branch $BRANCH` | Session ID |
| Cleanup stale | `session-manager.sh cleanup-stale` | Removes sessions whose worktree no longer exists |

---

## State Validation

Before creating a session, the script validates:

1. **Session ID is unique** - prevents duplicate sessions
2. **Branch is not in use** - prevents two sessions on the same branch

```bash
if ./scripts/session-manager.sh exists "$SESSION_ID"; then
    echo "Error: Session '$SESSION_ID' already exists"
    exit 1
fi

EXISTING=$(./scripts/session-manager.sh find --branch "$BRANCH_NAME")
if [ -n "$EXISTING" ]; then
    echo "Error: Branch '$BRANCH_NAME' in use by session $EXISTING"
    exit 1
fi
```

---

## Error Handling

| Error | Cause | Recovery |
|-------|-------|----------|
| Session creation fails | Disk full, permissions | Clean up worktree: `worktree-manager.sh cleanup $ID --force` |
| sessions.json corrupted | Invalid JSON | Backup file, validate with `jq empty`, fix or delete |
| Stale session | Worktree manually deleted | Run `session-manager.sh cleanup-stale` |

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
