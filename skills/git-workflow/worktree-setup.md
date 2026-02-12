# Worktree Setup

**Purpose:** Create isolated git worktree for safe command execution.

**Used By:** Stage 0 of `/build`, `/fix` commands

---

## Overview

Commands that modify code must create an isolated git worktree to avoid disrupting the user's working directory. Worktrees are created as **sibling directories** at the same level as the main project:

```
/path/to/repos/
├── mise/                    # Main project (your working directory)
├── mise-MISE-101/           # Worktree for ticket MISE-101
├── mise-MISE-102/           # Worktree for ticket MISE-102
└── mise-MISE-901/           # Worktree for ticket MISE-901
```

**Benefits:** True isolation per ticket, safe parallel builds, clear identification by directory name, easy navigation (`cd ../mise-MISE-101`).

---

## Pre-Execution Checklist

Before creating a worktree, `worktree-manager.sh` verifies:

- [ ] Current directory is a git repository
- [ ] No uncommitted changes (warns but does not block)
- [ ] Base branch exists and is accessible
- [ ] At least 100MB disk space available

> See [reference/worktree-setup-examples.md](reference/worktree-setup-examples.md) for the bash implementation of each check.

---

## Setup Procedure

All steps are handled by `scripts/worktree-manager.sh`. The procedure is:

### Step 1: Extract Context
From context file or command arguments: ticket ID, description, session ID.

### Step 2: Get User Initials
Read from `.claude/config.json` (`user.initials`) or default to `CLAUDE`.

### Step 3: Generate Branch Name
Format: `<INITIALS>_<description>_<TICKET-ID>` (see [branch-creation.md](./branch-creation.md) for details).

Examples: `JRA_add-user-export_SHRED-2119`, `CLAUDE_add-rate-limiting_TOOLKIT-a7f3`

### Step 4: Create Worktree
```bash
WORKTREE_PATH=$(./scripts/worktree-manager.sh create "$SESSION_ID" "$BRANCH_NAME")
```

The script:
1. Extracts ticket ID from branch name
2. Creates sibling directory: `../<project-name>-<ticket-id>/`
3. Runs: `git worktree add <path> -b <branch-name> <base-branch>`
4. Stores session-to-worktree mapping in `.claude/worktree-sessions.json`
5. Returns absolute path to worktree

### Step 5: Initialize Session
Tracks session in `.claude/sessions.json` (see [session-management.md](./session-management.md)).

### Step 6: Change to Worktree
All subsequent file operations happen in `$WORKTREE_PATH`. User's main working directory remains untouched.

---

## Output to User

```
Session ID:  abc123-def456
Branch:      JRA_add-user-export_SHRED-2119
Ticket:      SHRED-2119
Main:        /path/to/project
Worktree:    /path/to/project-SHRED-2119
Base:        main

Working in isolated sibling directory. Your main project is untouched.
Proceeding to Stage 1: Implementation...
```

---

## Error Handling

| Error | Cause | Recovery |
|-------|-------|----------|
| Branch already exists | Duplicate name | Suggest different description or delete old branch |
| Disk space full | No room for worktree | Ask user to free space |
| Git repo corrupted | Bad git state | Suggest `git fsck` |
| Session tracking fails | Worktree created but session failed | Clean up worktree: `worktree-manager.sh cleanup $ID --force` |

On any failure: do NOT proceed to Stage 1. Clean up partial state and report the error.

---

## Verification

After setup, verify worktree is correct:

```bash
git rev-parse --show-toplevel      # Should be /path/to/<project>-<TICKET>
git branch --show-current          # Should be <INITIALS>_<desc>_<TICKET>
git log -1 --oneline               # Should show latest commit from base branch
git worktree list                  # Shows main project + all sibling worktrees
```

---

## Related Documentation

- [Branch Creation](./branch-creation.md) - Branch naming logic
- [Session Management](./session-management.md) - Session tracking
- [Cleanup](./cleanup.md) - Worktree removal
- [Axomic Git Workflow](../../docs/standards/GIT_WORKFLOW.md) - Full workflow documentation

---

**Next:** After worktree setup, proceed to Stage 1 (implementation) of the command.
