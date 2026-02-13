# Cleanup Options — Detailed Examples

> Referenced from [cleanup.md](../cleanup.md)

## Option A: Create Pull Request (Recommended)

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
- Branch pushed to remote
- PR created for review
- Worktree removed
- Session cleaned up
- Branch preserved on remote

---

## Option B: Merge Locally

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
- Changes merged to main
- Feature branch deleted
- Worktree removed
- Session cleaned up

---

## Option C: Discard Changes

**When to use:** Command failed, incorrect implementation, no longer needed

```bash
# Cleanup worktree and session
./scripts/worktree-manager.sh cleanup session-abc123 --force

# Optionally delete branch
git branch -D JRA_add-user-export_SHRED-2119
```

**Result:**
- Worktree removed
- Session cleaned up
- Branch preserved (delete manually if unwanted)

---

## Manual Cleanup

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

## Bulk Cleanup (All Completed Sessions)

```bash
# List completed sessions
./scripts/session-manager.sh list --status completed

# Cleanup all completed sessions
for SESSION_ID in $(./scripts/session-manager.sh list --status completed --ids); do
    ./scripts/worktree-manager.sh cleanup "$SESSION_ID"
done
```

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

## Safety Checks (Before Cleanup)

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
