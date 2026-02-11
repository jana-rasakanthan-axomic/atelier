# Stage 0: Worktree Setup Template

**Purpose:** Reusable Stage 0 template for code-modifying commands.

**Used By:** `/build`, `/fix` commands

---

## Goal

Create isolated **sibling git worktree** before code modifications begin.

**Sibling worktrees** are created at the same directory level as the main project:
```
/path/to/repos/
├── mise/                    # Main project
├── mise-MISE-101/           # Worktree for ticket MISE-101
└── mise-MISE-102/           # Worktree for ticket MISE-102
```

---

## Pre-Execution Checks

Run these checks before creating worktree:

```bash
TOOLKIT_DIR="${CLAUDE_TOOLKIT:-$HOME/.claude}"

# 1. Verify git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not a git repository"
    exit 1
fi

# 2. Verify base branch exists
BASE_BRANCH="${GIT_BASE_BRANCH:-main}"
if ! git rev-parse --verify "$BASE_BRANCH" > /dev/null 2>&1; then
    echo "Error: Base branch '$BASE_BRANCH' not found"
    exit 1
fi

# 3. Check disk space (need at least 100MB)
AVAILABLE_MB=$(df -m . | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_MB" -lt 100 ]; then
    echo "Error: Insufficient disk space (need 100MB, have ${AVAILABLE_MB}MB)"
    exit 1
fi

# 4. Warn about uncommitted changes (don't block)
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "Warning: You have uncommitted changes in your working directory"
    echo "These won't be affected (working in isolated worktree)"
fi
```

---

## Setup Procedure

### Step 1: Generate Session ID

```bash
SESSION_ID=$(uuidgen | tr '[:upper:]' '[:lower:]' | head -c 8)
```

### Step 2: Generate Branch Name

```bash
TOOLKIT_DIR="${CLAUDE_TOOLKIT:-$HOME/.claude}"
BRANCH_NAME=$("$TOOLKIT_DIR/scripts/generate-branch-name.sh" "$INPUT_FILE")
```

**Inputs to script:**
- Context file path (e.g., `.claude/context/SHRED-2119.md`)
- Or plan file path (e.g., `.claude/plans/SHRED-2119.md`)
- Or description string

**Output format:** `<INITIALS>_<description>_<TICKET-ID>`

### Step 3: Create Sibling Worktree

```bash
WORKTREE_PATH=$("$TOOLKIT_DIR/scripts/worktree-manager.sh" create "$SESSION_ID" "$BRANCH_NAME" "$BASE_BRANCH")
```

**Creates:**
- **Sibling directory:** `../<project-name>-<ticket-id>/`
- Branch: `<INITIALS>_<description>_<TICKET-ID>`
- Based on: `$BASE_BRANCH` (default: main)

**Example:**
- Main project: `/path/to/mise`
- Worktree: `/path/to/mise-MISE-101`

### Step 4: Initialize Session

```bash
"$TOOLKIT_DIR/scripts/session-manager.sh" create "$SESSION_ID" "$BRANCH_NAME" "$INPUT_FILE" "$COMMAND_NAME"
```

**Tracks in `.claude/sessions.json`:**
- Session ID
- Branch name
- Context/plan file
- Command name
- Worktree path
- Status: `active`

---

## Output Format

On successful setup, display:

```
## Worktree Setup Complete

| Field | Value |
|-------|-------|
| Session ID | $SESSION_ID |
| Branch | $BRANCH_NAME |
| Main Project | /path/to/mise |
| Worktree | /path/to/mise-MISE-101 |
| Base Branch | $BASE_BRANCH |

Working in isolated sibling directory. Your main project is untouched.

Proceeding to Stage 1...
```

---

## Variables for Subsequent Stages

After Stage 0, these variables are available:

| Variable | Description | Example |
|----------|-------------|---------|
| `WORKTREE_PATH` | Absolute path to **sibling worktree** | `/path/to/mise-MISE-101` |
| `SESSION_ID` | Unique session identifier | `a1b2c3d4` |
| `BRANCH_NAME` | Branch name | `JRA_add-user-export_MISE-101` |
| `BASE_BRANCH` | Base branch | `main` |

---

## Error Handling

### Worktree Creation Fails

```
Error: Failed to create worktree

Reason: [git error message]

Suggestions:
- If branch exists: Delete old branch or use different name
- If disk full: Free up disk space
- If git issue: Run 'git fsck' to check repository
```

**Action:** Exit command. No cleanup needed (worktree wasn't created).

### Session Tracking Fails

```
Error: Failed to track session

Worktree was created at: $WORKTREE_PATH
Cleaning up...
```

**Action:** Clean up worktree, then exit.

```bash
"$TOOLKIT_DIR/scripts/worktree-manager.sh" cleanup "$SESSION_ID" --force
exit 1
```

---

## Integration Notes

**For commands using this template:**

1. Add Stage 0 as first stage in workflow
2. Store `WORKTREE_PATH`, `SESSION_ID`, `BRANCH_NAME` for use in later stages
3. Prefix all file operations with `$WORKTREE_PATH`
4. CD into worktree for bash commands: `cd "$WORKTREE_PATH" && <command>`
5. Add completion stage at end (see `completion-stage.md`)

---

## Related Documentation

- [worktree-setup.md](../worktree-setup.md) - Detailed setup procedure
- [branch-creation.md](../branch-creation.md) - Branch naming conventions
- [completion-stage.md](./completion-stage.md) - Completion stage template
