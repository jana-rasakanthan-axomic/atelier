# Worktree Setup — Detailed Examples

> Referenced from [worktree-setup.md](../worktree-setup.md)

## Pre-Execution Check Scripts

### Git repository exists
```bash
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not a git repository"
    exit 1
fi
```

### Check uncommitted changes (warn, don't block)
```bash
if ! git diff-index --quiet HEAD --; then
    echo "Warning: You have uncommitted changes in your working directory"
    echo "These won't be affected by this command (working in isolated worktree)"
fi
```

### Verify base branch exists
```bash
BASE_BRANCH="${GIT_BASE_BRANCH:-main}"
if ! git show-ref --verify --quiet "refs/heads/$BASE_BRANCH"; then
    echo "Error: Base branch '$BASE_BRANCH' not found"
    exit 1
fi
```

### Check disk space (at least 100MB free)
```bash
AVAILABLE_MB=$(df -m . | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_MB" -lt 100 ]; then
    echo "Error: Insufficient disk space (need 100MB, have ${AVAILABLE_MB}MB)"
    exit 1
fi
```

---

## Step-by-Step Setup Scripts

### Step 1: Extract Context
```bash
TICKET_ID=$(extract_ticket_id_from_context)    # e.g., "SHRED-2119"
DESCRIPTION=$(extract_description)              # e.g., "add user export functionality"
SESSION_ID=$(generate_session_id)               # e.g., "abc123-def456" (uuidgen or similar)
```

### Step 2: Get User Initials
```bash
if [ -f ".claude/config.json" ]; then
    INITIALS=$(jq -r '.user.initials // "CLAUDE"' .claude/config.json)
else
    INITIALS="CLAUDE"
fi
```

Config file format (`.claude/config.json`):
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

### Step 3: Generate Branch Name
```bash
# Format: <INITIALS>_<description>_<TICKET-ID>
if [[ -n "$TICKET_ID" ]]; then
    BRANCH_NAME="${INITIALS}_${DESCRIPTION}_${TICKET_ID}"
else
    SHORT_ID=$(echo "$SESSION_ID" | head -c 4)
    BRANCH_NAME="${INITIALS}_${DESCRIPTION}_TOOLKIT-${SHORT_ID}"
fi
```

### Step 4: Create Worktree
```bash
WORKTREE_PATH=$(./scripts/worktree-manager.sh create "$SESSION_ID" "$BRANCH_NAME")
# Returns sibling path like: /path/to/mise-MISE-101
```

### Step 5: Initialize Session
```bash
./scripts/session-manager.sh create \
    "$SESSION_ID" \
    "$BRANCH_NAME" \
    "$WORKTREE_PATH" \
    "/build" \
    ".claude/context/SHRED-2119.md"
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
├── project/              # Main project (untouched)
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
