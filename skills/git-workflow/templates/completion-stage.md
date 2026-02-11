# Completion Stage Template

**Purpose:** Reusable completion stage for code-modifying commands.

**Used By:** `/build`, `/fix` commands

---

## Goal

Present user with options after command completes successfully.

---

## Prerequisites

These variables must be set from Stage 0:
- `WORKTREE_PATH` - Absolute path to **sibling worktree** (e.g., `/path/to/mise-MISE-101`)
- `SESSION_ID` - Session identifier
- `BRANCH_NAME` - Branch name

---

## Procedure

### Step 1: Mark Session Complete

```bash
TOOLKIT_DIR="${CLAUDE_TOOLKIT:-$HOME/.claude}"
"$TOOLKIT_DIR/scripts/session-manager.sh" update "$SESSION_ID" "status" "completed"
```

### Step 2: Get Change Summary

```bash
cd "$WORKTREE_PATH"

# Count changes
FILES_CHANGED=$(git diff --name-only HEAD~1 2>/dev/null | wc -l | tr -d ' ')
INSERTIONS=$(git diff --stat HEAD~1 2>/dev/null | tail -1 | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
DELETIONS=$(git diff --stat HEAD~1 2>/dev/null | tail -1 | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo "0")
```

---

## Output Format

Display completion summary and options:

```markdown
## Command Complete

### Summary
| Field | Value |
|-------|-------|
| Session ID | $SESSION_ID |
| Branch | $BRANCH_NAME |
| Main Project | /path/to/mise |
| Worktree | /path/to/mise-MISE-101 |
| Files Changed | $FILES_CHANGED |
| Lines | +$INSERTIONS / -$DELETIONS |

---

### What's Next?

Choose one of the following options:

#### Option A: Create Pull Request (Recommended)

Push branch and create PR for review.

```bash
# Push branch from sibling worktree
cd $WORKTREE_PATH  # e.g., /path/to/mise-MISE-101
git push -u origin $BRANCH_NAME

# Create PR (requires gh CLI)
gh pr create --title "feat: [description]" --body "## Summary
- [changes made]

## Test Plan
- [how to test]"

# After PR is merged, cleanup (run from main project)
cd ../mise && $TOOLKIT_DIR/scripts/worktree-manager.sh cleanup $SESSION_ID
```

#### Option B: Merge Locally

Merge changes directly to your local main branch.

```bash
# Go to main project and merge
cd ../mise  # or main project path
git checkout main
git merge $BRANCH_NAME

# Cleanup worktree
$TOOLKIT_DIR/scripts/worktree-manager.sh cleanup $SESSION_ID

# Delete branch (optional)
git branch -d $BRANCH_NAME
```

#### Option C: Discard Changes

Remove worktree and branch without keeping changes.

```bash
# Force cleanup (discards uncommitted changes)
$TOOLKIT_DIR/scripts/worktree-manager.sh cleanup $SESSION_ID --force

# Delete branch
git branch -D $BRANCH_NAME
```

---

### Review Changes First

Before choosing, review the changes:

```bash
# View diff (from sibling worktree)
cd $WORKTREE_PATH && git diff HEAD~1

# View changed files
cd $WORKTREE_PATH && git diff --name-only HEAD~1

# View commit log
cd $WORKTREE_PATH && git log --oneline -5
```
```

---

## Important Notes

1. **Commands shown, not executed** - User must copy and run commands
2. **Worktree persists** - Until user explicitly cleans up
3. **Branch persists** - Even after worktree cleanup (unless user deletes)

---

## Error Handling

### Session Update Fails

```
Warning: Could not update session status

Worktree and branch are still available:
- Worktree: $WORKTREE_PATH
- Branch: $BRANCH_NAME

Proceed with manual cleanup when ready.
```

**Action:** Continue showing options. Session tracking is non-critical.

### Worktree Has Uncommitted Changes

If detected during completion:

```
Warning: Worktree has uncommitted changes

Before proceeding, either:
1. Commit changes: cd $WORKTREE_PATH && git add . && git commit -m "message"
2. Discard changes: cd $WORKTREE_PATH && git checkout .

Then return to choose an option above.
```

---

## Integration Notes

**For commands using this template:**

1. Add this as the final stage in workflow
2. Ensure WORKTREE_PATH, SESSION_ID, BRANCH_NAME are available
3. Display all three options - let user choose
4. Do NOT auto-execute any option
5. Do NOT auto-cleanup worktree

---

## Related Documentation

- [cleanup.md](../cleanup.md) - Worktree cleanup procedures
- [stage-0-worktree-setup.md](./stage-0-worktree-setup.md) - Setup template
