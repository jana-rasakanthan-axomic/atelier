---
name: git-workflow
description: Branching, worktrees, and PR conventions. Use when creating worktrees, managing branches, or tracking sessions for code-modifying commands.
allowed-tools: Read, Bash(git:*), Bash(scripts/worktree-manager.sh:*), Bash(scripts/generate-branch-name.sh:*), Bash(scripts/session-manager.sh:*)
---

# Git Workflow Skill

Manage isolated git worktrees for safe, parallel command execution. Used by `/build` and `/fix` commands.

## When to Use

- Command modifies code (e.g., `/build`, `/fix`)
- Need isolated workspace (don't disturb user's working directory)
- Want parallel execution (multiple commands at once)
- Need rollback capability (if command fails)

## When NOT to Use

- Command is read-only (e.g., `/review`, `/analyze`)
- Command doesn't touch code (e.g., `/gather`)
- One-off script execution (use temporary directory instead)

## Overview

The git workflow skill provides worktree management for commands that modify code. All code-modifying commands use **isolated git worktrees** to prevent disrupting the user's main working directory.

## Core Capabilities

1. **Worktree Creation** - Create isolated workspace for command execution
2. **Branch Management** - Generate and create properly-named branches
3. **Session Tracking** - Track command state across execution
4. **Cleanup** - Remove worktrees and clean up state

---

## Skill Components

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| **[worktree-setup.md](./worktree-setup.md)** | Create isolated worktree | Stage 0 of code-modifying commands |
| **[branch-creation.md](./branch-creation.md)** | Generate branch names | When creating new branches |
| **[session-management.md](./session-management.md)** | Track command state | Throughout command lifecycle |
| **[cleanup.md](./cleanup.md)** | Remove worktrees | After command completes or fails |

---

## Templates

Reusable stage templates for commands:

| Template | Purpose |
|----------|---------|
| **[templates/stage-0-worktree-setup.md](./templates/stage-0-worktree-setup.md)** | Stage 0 for code-modifying commands |
| **[templates/completion-stage.md](./templates/completion-stage.md)** | Completion stage with user options |

**Usage:** Commands reference these templates instead of duplicating setup logic. See `/build` and `/fix` for examples.

---

## Typical Command Flow

```
Stage 0: Setup (worktree-setup.md)
├─ Verify git repository
├─ Create worktree in .claude/worktrees/<session-id>/
├─ Create branch (via branch-creation.md)
├─ Initialize session (via session-management.md)
└─ CD into worktree

Stage 1-N: Execute command logic
└─ Work in isolated worktree

Stage N+1: Completion
├─ User chooses: Create PR, Merge locally, or Discard
└─ Cleanup worktree (via cleanup.md)
```

---

## Integration Example

**In a command's Stage 0:**

```markdown
## Stage 0: Setup Worktree

Follow [worktree setup](../skills/git-workflow/worktree-setup.md) to create isolated workspace.

**Inputs:**
- Ticket ID from context file (e.g., SHRED-2119)
- Feature description (e.g., "add user export functionality")
- User initials from `.claude/config.json` (default: CLAUDE)

**Outputs:**
- Worktree path: `.claude/worktrees/<session-id>/`
- Branch name: `<INITIALS>_<description>_<TICKET-ID>`
- Session ID: Stored in `.claude/sessions.json`

**On Success:** Proceed to Stage 1 (implementation)
**On Failure:** Report error and exit (no cleanup needed)
```

---

## Safety Features

1. **Isolation** - Never touches user's working directory
2. **Parallel execution** - Multiple commands run in separate worktrees
3. **Rollback** - Failed commands auto-cleanup
4. **State tracking** - Sessions persist for resume/cleanup

---

## Scripts

The skill uses these scripts (invoked by commands):
- `scripts/worktree-manager.sh` - Create/list/remove worktrees
- `scripts/generate-branch-name.sh` - Generate branch names
- `scripts/session-manager.sh` - Track session state

---

## Configuration

**User config** (`.claude/config.json`):
```json
{
  "user": {
    "initials": "JRA"
  },
  "git": {
    "default_base_branch": "main"
  }
}
```

**Session state** (`.claude/sessions.json`):
```json
{
  "session-abc123": {
    "command": "/build",
    "branch": "JRA_add-export_SHRED-2119",
    "worktree_path": ".claude/worktrees/session-abc123",
    "status": "active",
    "context_file": ".claude/context/SHRED-2119.md",
    "created_at": "2026-01-16T10:30:00Z"
  }
}
```

---

## Related Documentation

- [Worktree Setup](./worktree-setup.md) - Detailed setup procedure
- [Branch Creation](./branch-creation.md) - Branch naming conventions
- [Session Management](./session-management.md) - State tracking
- [Cleanup](./cleanup.md) - Cleanup procedures
- [Axomic Branch Naming Convention](../../docs/standards/conventions/branch-naming.md) - Source of truth for branch format

---

**When in doubt:** Follow the worktree-setup.md procedure for Stage 0 of all code-modifying commands.
