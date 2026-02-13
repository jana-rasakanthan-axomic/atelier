# Worktree Cleanup

**Purpose:** Remove git worktree and cleanup session state.

**When:** After command completes (success or failure) and user decides what to do with changes.

---

## Overview

After a command completes, the user decides:
1. **Create PR** - Push branch and create pull request (recommended)
2. **Merge locally** - Merge changes into main branch
3. **Discard** - Delete branch and abandon changes

Then cleanup removes the worktree and session state.

> See [reference/cleanup-options.md](reference/cleanup-options.md) for detailed bash examples of each option.

---

## User Options Summary

| Option | When to Use | Key Command |
|--------|-------------|-------------|
| **A. Create PR** | Standard workflow, code review | `git push && gh pr create && worktree-manager.sh cleanup` |
| **B. Merge locally** | Quick fixes, solo work | `git merge <branch> && worktree-manager.sh cleanup` |
| **C. Discard** | Failed/unwanted changes | `worktree-manager.sh cleanup <session> --force` |

---

## Cleanup Script

**Usage:**
```bash
./scripts/worktree-manager.sh cleanup <SESSION_ID> [--force]
```

**What it does:**
1. Look up worktree path from session ID (via `.claude/worktree-sessions.json`)
2. Remove git worktree: `git worktree remove <path>`
3. Remove session mapping from `.claude/worktree-sessions.json`
4. Remove session from `.claude/sessions.json`

**Force mode** (`--force`): For worktrees in bad state. Attempts `git worktree remove --force`, falls back to `rm -rf`, then `git worktree prune`.

---

## Cleanup After Command Failure

When a command fails mid-execution, the user can inspect the worktree before cleanup:

```bash
# Inspect what went wrong
cd ../mise-SHRED-2119 && git log && git diff

# Then either fix manually or discard
cd ../mise && ./scripts/worktree-manager.sh cleanup session-abc123 --force
```

---

## Verification Checklist

After cleanup, verify:

- [ ] `git worktree list` does not show the removed worktree
- [ ] Sibling directory no longer exists
- [ ] `session-manager.sh list` does not show the session
- [ ] Branch status is as expected (pushed/deleted/preserved)

---

## Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| `worktree is locked` | Lock file left behind | `rm <worktree>/.git/worktree.lock` then retry |
| `Directory not removed` | Files still present | `rm -rf <worktree-dir>` then `git worktree prune` |
| `Session not found` | Already cleaned or wrong ID | `session-manager.sh list` to find correct ID; if worktree exists, remove manually with `git worktree remove --force` |
| `Branch not pushed` | Forgot to push before cleanup | Push first: `git push origin <branch>`, or use `--force` to discard |

---

## Related Documentation

- [Worktree Setup](./worktree-setup.md) - Creates worktree
- [Session Management](./session-management.md) - Tracks session
- [Git Workflow](./SKILL.md) - Overview

---

**Best Practice:** Always cleanup completed sessions to avoid disk space leaks and stale state.
