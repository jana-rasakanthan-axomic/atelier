# Worktree Cleanup

**Purpose:** Remove git worktree and cleanup session state.

**When:** After command completes (success or failure) and user decides what to do with changes.

---

## Overview

After a command completes, the user decides:
1. **Create PR** - Push branch and create pull request
2. **Merge locally** - Merge changes into main branch
3. **Discard** - Delete branch and abandon changes

Then cleanup removes the worktree and session state.

---

## User Options After Command Completes

### Option A: Create Pull Request ✅ (Recommended)

**When to use:** Standard workflow for code review

```bash
# Navigate to sibling worktree
cd ../mise-SHRED-2119

# Review changes
git diff main
git log main..HEAD

# Push branch
git push origin JRA_add-user-export_SHRED-2119

# Create PR (using gh CLI)
gh pr create \
    --title "SHRED-2119 - Add user export functionality" \
    --body "Implements user export in JSON and CSV formats"

# Cleanup worktree (from main project directory)
cd ../mise
./scripts/worktree-manager.sh cleanup session-abc123
```

**Result:**
- ✅ Branch pushed to remote
- ✅ PR created for review
- ✅ Worktree removed
- ✅ Session cleaned up
- ✅ Branch preserved on remote

---

### Option B: Merge Locally

**When to use:** Quick fixes, urgent changes, working alone

```bash
# Ensure changes are committed in sibling worktree
cd ../mise-SHRED-2119
git status  # Should be clean

# Switch to main project and merge
cd ../mise
git checkout main

# Merge feature branch
git merge JRA_add-user-export_SHRED-2119

# Delete feature branch
git branch -d JRA_add-user-export_SHRED-2119

# Cleanup worktree
./scripts/worktree-manager.sh cleanup session-abc123
```

**Result:**
- ✅ Changes merged to main
- ✅ Feature branch deleted
- ✅ Worktree removed
- ✅ Session cleaned up

---

### Option C: Discard Changes

**When to use:** Command failed, incorrect implementation, no longer needed

```bash
# Cleanup worktree and session
./scripts/worktree-manager.sh cleanup session-abc123 --force

# Optionally delete branch
git branch -D JRA_add-user-export_SHRED-2119
```

**Result:**
- ✅ Worktree removed
- ✅ Session cleaned up
- ⚠️ Branch preserved (delete manually if unwanted)

---

## Cleanup Procedure

### Automatic Cleanup (Script)

**Usage:**
```bash
./scripts/worktree-manager.sh cleanup <SESSION_ID> [--force]
```

**What it does:**
1. Look up worktree path from session ID (via `.claude/worktree-sessions.json`)
2. Remove git worktree: `git worktree remove <path>`
3. Remove session mapping from `.claude/worktree-sessions.json`
4. Remove session from `.claude/sessions.json`

**Example:**
```bash
./scripts/worktree-manager.sh cleanup session-abc123

# Output:
# ✓ Removed sibling worktree: /path/to/mise-SHRED-2119
# ✓ Removed session: session-abc123
# ✓ Cleanup complete
```

---

### Force Cleanup

**When to use:** Worktree in bad state, git errors, manual intervention needed

```bash
./scripts/worktree-manager.sh cleanup session-abc123 --force

# Forces removal even if:
# - Worktree has uncommitted changes
# - Git worktree remove fails
# - Directory already deleted
```

**What --force does:**
1. Attempts `git worktree remove --force <path>`
2. If that fails, manually removes directory: `rm -rf <path>`
3. Prunes stale worktree entries: `git worktree prune`
4. Removes session from `sessions.json`

---

### Manual Cleanup

**If script fails:**

```bash
# 1. List all worktrees (including siblings)
git worktree list

# 2. Remove specific sibling worktree
git worktree remove ../mise-SHRED-2119 --force

# 3. Prune stale entries
git worktree prune

# 4. Remove directory if still exists
rm -rf ../mise-SHRED-2119

# 5. Clean up session state
./scripts/session-manager.sh cleanup session-abc123

# 6. Clean up worktree-sessions.json mapping
jq 'del(.["session-abc123"])' .claude/worktree-sessions.json > tmp && mv tmp .claude/worktree-sessions.json
```

---

## Cleanup After Command Failure

**Automatic rollback:**

When a command fails mid-execution:

```bash
# Command detects failure (e.g., tests fail, build error)
echo "Error: Command failed"

# Automatic cleanup
./scripts/worktree-manager.sh cleanup "$SESSION_ID" --force

# Mark session as failed
./scripts/session-manager.sh fail "$SESSION_ID" --reason "Tests failed"

exit 1
```

**User can inspect:**
```bash
# Before cleanup, user can:
# 1. Review what went wrong in sibling worktree
cd ../mise-SHRED-2119
git log
git diff

# 2. Decide: fix manually or discard
# Fix manually: continue working in worktree
# Discard: go back to main project and run cleanup
cd ../mise && ./scripts/worktree-manager.sh cleanup session-abc123 --force
```

---

## Cleanup All Completed Sessions

**Bulk cleanup:**

```bash
# List completed sessions
./scripts/session-manager.sh list --status completed

# Cleanup all completed sessions
for SESSION_ID in $(./scripts/session-manager.sh list --status completed --ids); do
    ./scripts/worktree-manager.sh cleanup "$SESSION_ID"
done
```

---

## Cleanup Stale Worktrees

**Stale worktrees** = Worktree deleted but session still exists

```bash
# Find and cleanup stale sessions
./scripts/session-manager.sh cleanup-stale

# Or manual:
./scripts/session-manager.sh list | while read SESSION_ID; do
    WORKTREE_PATH=$(./scripts/session-manager.sh get "$SESSION_ID" | jq -r '.worktree_path')
    if [ ! -d "$WORKTREE_PATH" ]; then
        echo "Stale session: $SESSION_ID"
        ./scripts/session-manager.sh cleanup "$SESSION_ID"
    fi
done
```

---

## Safety Checks

**Before cleanup:**

```bash
# 1. Check for uncommitted changes
cd "$WORKTREE_PATH"
if ! git diff-index --quiet HEAD --; then
    echo "Warning: Worktree has uncommitted changes"
    echo "Review changes before cleanup:"
    git status
    read -p "Continue cleanup? (y/n) " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 2. Check branch pushed (if user wants to keep changes)
if ! git branch -r | grep -q "origin/$(git branch --show-current)"; then
    echo "Warning: Branch not pushed to remote"
    echo "Push now: git push origin $(git branch --show-current)"
    read -p "Continue cleanup without pushing? (y/n) " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
```

---

## Verification After Cleanup

**Verify cleanup successful:**

```bash
# 1. Check worktree removed from git
git worktree list | grep -v "$SESSION_ID"  # Should not appear

# 2. Check directory removed
ls .claude/worktrees/ | grep -v "$SESSION_ID"  # Should not appear

# 3. Check session removed
./scripts/session-manager.sh list | grep -v "$SESSION_ID"  # Should not appear

# 4. Check branch status
git branch | grep "$(git branch --show-current)"  # Branch exists?
git branch -r | grep "origin/$(git branch --show-current)"  # Pushed?
```

---

## Troubleshooting

### Cleanup Fails with "Worktree is Locked"

```bash
Error: worktree is locked

Solution:
1. Check lock file: cat .claude/worktrees/session-abc123/.git/worktree.lock
2. Remove lock: rm .claude/worktrees/session-abc123/.git/worktree.lock
3. Retry: ./scripts/worktree-manager.sh cleanup session-abc123
```

### Directory Not Empty After Cleanup

```bash
Error: Directory not removed

Solution:
1. Check what's in directory: ls -la .claude/worktrees/session-abc123
2. Remove manually: rm -rf .claude/worktrees/session-abc123
3. Prune stale worktrees: git worktree prune
```

### Session Not Found

```bash
Error: Session 'session-abc123' not found

Possible causes:
1. Already cleaned up (check: ./scripts/session-manager.sh list)
2. Wrong session ID (list all: ./scripts/session-manager.sh list)
3. sessions.json corrupted (check: cat .claude/sessions.json)

Solution:
- If worktree still exists, remove manually:
  git worktree remove .claude/worktrees/session-abc123 --force
```

---

## Integration with Commands

**In command markdown (final stage):**

```markdown
## Stage N+1: Completion and Cleanup

**Goal:** Guide user through next steps and cleanup.

**On Success:**
1. Mark session complete:
   ```bash
   ./scripts/session-manager.sh complete "$SESSION_ID"
   ```

2. Show user their options:
   ```
   ✓ Feature implementation complete!

   Branch:      JRA_add-user-export_SHRED-2119
   Main:        /path/to/mise
   Worktree:    /path/to/mise-SHRED-2119

   Next steps:
     A. Create PR (recommended):
        cd ../mise-SHRED-2119
        git push origin JRA_add-user-export_SHRED-2119
        gh pr create --title "SHRED-2119 - Add user export functionality"
        cd ../mise && ./scripts/worktree-manager.sh cleanup session-abc123

     B. Merge locally:
        git checkout main
        git merge JRA_add-user-export_SHRED-2119
        ./scripts/worktree-manager.sh cleanup session-abc123

     C. Discard:
        ./scripts/worktree-manager.sh cleanup session-abc123 --force
   ```

**On Failure:**
1. Cleanup automatically:
   ```bash
   ./scripts/worktree-manager.sh cleanup "$SESSION_ID" --force
   ./scripts/session-manager.sh fail "$SESSION_ID" --reason "Error message"
   ```

2. Report error to user
```

---

## Related Documentation

- [Worktree Setup](./worktree-setup.md) - Creates worktree
- [Session Management](./session-management.md) - Tracks session
- [Git Workflow](./SKILL.md) - Overview

---

**Best Practice:** Always cleanup completed sessions to avoid disk space leaks and stale state.
