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

**Benefits of sibling worktrees:**
- **True isolation:** Each ticket gets its own directory, no file conflicts
- **Safe parallel builds:** Multiple builder agents can work simultaneously
- **Clear identification:** Directory name shows which ticket is being built
- **Easy navigation:** `cd ../mise-MISE-101` to switch between worktrees

---

## Pre-Execution Checks

**Before creating worktree, verify:**

1. **Git repository exists**
   ```bash
   if ! git rev-parse --git-dir > /dev/null 2>&1; then
       echo "Error: Not a git repository"
       exit 1
   fi
   ```

2. **Check uncommitted changes** (warn, don't block)
   ```bash
   if ! git diff-index --quiet HEAD --; then
       echo "Warning: You have uncommitted changes in your working directory"
       echo "These won't be affected by this command (working in isolated worktree)"
   fi
   ```

3. **Verify base branch exists and is accessible**
   ```bash
   BASE_BRANCH="${GIT_BASE_BRANCH:-main}"
   if ! git show-ref --verify --quiet "refs/heads/$BASE_BRANCH"; then
       echo "Error: Base branch '$BASE_BRANCH' not found"
       exit 1
   fi
   ```

4. **Check disk space** (at least 100MB free)
   ```bash
   AVAILABLE_MB=$(df -m . | awk 'NR==2 {print $4}')
   if [ "$AVAILABLE_MB" -lt 100 ]; then
       echo "Error: Insufficient disk space (need 100MB, have ${AVAILABLE_MB}MB)"
       exit 1
   fi
   ```

---

## Setup Procedure

### Step 1: Extract Context

```bash
# From context file or command arguments
TICKET_ID=$(extract_ticket_id_from_context)    # e.g., "SHRED-2119"
DESCRIPTION=$(extract_description)              # e.g., "add user export functionality"
SESSION_ID=$(generate_session_id)               # e.g., "abc123-def456" (uuidgen or similar)
```

**Examples:**
- Context file: `.claude/context/SHRED-2119.md` → Ticket: `SHRED-2119`
- User input: `/build "Add rate limiting"` → Description: `add-rate-limiting`

---

### Step 2: Get User Initials

```bash
# Read from .claude/config.json or default to CLAUDE
INITIALS=$(get_user_initials_or_default)

# Implementation:
if [ -f ".claude/config.json" ]; then
    INITIALS=$(jq -r '.user.initials // "CLAUDE"' .claude/config.json)
else
    INITIALS="CLAUDE"
fi
```

**Config file format** (`.claude/config.json`):
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

---

### Step 3: Generate Branch Name

See [branch-creation.md](./branch-creation.md) for full details.

**Quick reference:**
```bash
# Format: <INITIALS>_<description>_<TICKET-ID>
if [[ -n "$TICKET_ID" ]]; then
    BRANCH_NAME="${INITIALS}_${DESCRIPTION}_${TICKET_ID}"
else
    # Auto-generate ticket ID if none provided
    SHORT_ID=$(echo "$SESSION_ID" | head -c 4)
    BRANCH_NAME="${INITIALS}_${DESCRIPTION}_TOOLKIT-${SHORT_ID}"
fi
```

**Examples:**
- `JRA_add-user-export_SHRED-2119`
- `ABC_fix-dockerfile_OA-1655`
- `CLAUDE_add-rate-limiting_TOOLKIT-a7f3`

---

### Step 4: Create Worktree

```bash
# Use worktree-manager.sh script
WORKTREE_PATH=$(./scripts/worktree-manager.sh create "$SESSION_ID" "$BRANCH_NAME")

# Returns sibling path like: /path/to/mise-MISE-101
```

**What the script does:**
1. Extracts ticket ID from branch name (e.g., `MISE-101` from `JRA_auth-signup_MISE-101`)
2. Creates sibling directory: `../<project-name>-<ticket-id>/`
3. Runs: `git worktree add <path> -b <branch-name> <base-branch>`
4. Stores session-to-worktree mapping in `.claude/worktree-sessions.json`
5. Returns absolute path to worktree

**Sibling directory naming:**
- Main project: `/path/to/mise`
- Worktree: `/path/to/mise-MISE-101`

---

### Step 5: Initialize Session

```bash
# Track session in .claude/sessions.json
./scripts/session-manager.sh create \
    "$SESSION_ID" \
    "$BRANCH_NAME" \
    "$WORKTREE_PATH" \
    "/build" \
    ".claude/context/SHRED-2119.md"

# Creates entry in .claude/sessions.json:
{
  "session-abc123": {
    "command": "/build",
    "branch": "JRA_add-user-export_SHRED-2119",
    "worktree_path": ".claude/worktrees/session-abc123",
    "status": "active",
    "context_file": ".claude/context/SHRED-2119.md",
    "created_at": "2026-01-16T10:30:00Z"
  }
}
```

---

### Step 6: Change to Worktree

```bash
cd "$WORKTREE_PATH"

# All subsequent file operations (Read, Write, Edit) happen here
# User's main working directory remains untouched
```

---

## Output to User

After successful setup, inform the user:

```
✓ Sibling worktree created successfully

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

### If Worktree Creation Fails

```bash
# DO NOT proceed to Stage 1
# Clean up any partial state
# Report error to user

echo "Error: Failed to create worktree"
echo "Reason: [specific error from git worktree add]"
exit 1
```

**Common errors:**
- Branch name already exists → Suggest different description or delete old branch
- Disk space full → Ask user to free space
- Git repo corrupted → Suggest `git fsck`

### If Session Tracking Fails

```bash
# Worktree was created but session tracking failed
# Clean up worktree before exiting

./scripts/worktree-manager.sh cleanup "$SESSION_ID" --force
echo "Error: Failed to track session"
exit 1
```

---

## Parallel Execution Example

**Multiple commands can run simultaneously with sibling worktrees:**

```bash
# Terminal 1: Build feature
/build SHRED-2119
# Creates: /path/to/project-SHRED-2119/
# Branch: JRA_add-export_SHRED-2119

# Terminal 2: Fix bug (runs in parallel)
/fix OA-1655
# Creates: /path/to/project-OA-1655/
# Branch: JRA_fix-dockerfile_OA-1655

# Each command has isolated sibling worktree, no conflicts
```

**Directory structure during parallel execution:**
```
/path/to/
├── project/           # Main project (untouched)
├── project-SHRED-2119/   # Terminal 1 worktree
└── project-OA-1655/      # Terminal 2 worktree
```

---

## Integration with Commands

**In command markdown (e.g., `commands/build.md`):**

```markdown
## Stage 0: Worktree Setup

**Goal:** Create isolated git worktree for safe execution.

**Procedure:** Follow [skills/git-workflow/worktree-setup.md](../skills/git-workflow/worktree-setup.md)

**Inputs:**
- Ticket ID from context file or command args
- Feature description
- User initials from `.claude/config.json` (default: CLAUDE)

**Outputs:**
- Worktree path (stored in `$WORKTREE_PATH`)
- Branch name (stored in `$BRANCH_NAME`)
- Session ID (stored in `$SESSION_ID`)

**On Success:** Proceed to Stage 1
**On Failure:** Exit command (no cleanup needed, worktree not created)
```

---

## Verification

After setup, verify worktree is correct:

```bash
# Check we're in sibling worktree
git rev-parse --show-toplevel  # Should be /path/to/<project>-<TICKET>

# Check branch
git branch --show-current      # Should be <INITIALS>_<desc>_<TICKET>

# Check base branch
git log -1 --oneline           # Should show latest commit from base branch

# List all worktrees
git worktree list              # Shows main project + all sibling worktrees
```

---

## Related Documentation

- [Branch Creation](./branch-creation.md) - Branch naming logic
- [Session Management](./session-management.md) - Session tracking
- [Cleanup](./cleanup.md) - Worktree removal
- [Axomic Git Workflow](../../docs/standards/GIT_WORKFLOW.md) - Full workflow documentation

---

**Next:** After worktree setup, proceed to Stage 1 (implementation) of the command.
