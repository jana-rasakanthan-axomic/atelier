---
name: update
description: Update atelier to the latest version
allowed-tools: Bash(git:*), Bash(bash:*), Read
---

# /update

Update Atelier to the latest version by detecting the install type and pulling changes.

## Input Formats

- `/update` - Update to latest version
- `/update --check` - Check for updates without applying them
- `/update --verify` - Run plugin verification after update

## When to Use

- Before starting a new session to get latest features
- After seeing a notice that updates are available
- Periodically to stay current

## When NOT to Use

- In the middle of a workflow (finish current work first)
- If you have local modifications to atelier files (commit or stash first)

## Workflow

### Stage 1: Detect and Update

Run the update script to detect install type and fetch changes.

**Actions:**
1. Run `bash scripts/update.sh` (or `bash scripts/update.sh --check` if `--check` flag given)
2. Report the result: install type, current version, changes available/applied

### Stage 2: Verify (optional)

If `--verify` flag provided, run plugin verification after update.

**Actions:**
1. Run `bash scripts/verify-plugin.sh --verbose`
2. Report any warnings or errors with repair suggestions

### Stage 3: Report

Present summary to user.

**Output:**
```
Update Complete
- Install type: [global/project/development]
- Version: [commit hash] ([date])
- Changes: [N commits applied / up to date / check only]
```

If `--verify` was used, include plugin health status.

## Error Handling

| Scenario | Action |
|----------|--------|
| Not a git repo | Report error, suggest re-clone |
| No remote configured | Report error, show `git remote add` command |
| Network failure | Report error, suggest checking connection |
| Merge conflict on pull | Report error, suggest manual resolution |
| Development install | Show available changes but do not auto-pull |

## Scope Limits

- Updates Atelier toolkit files only
- Does NOT update project dependencies or configurations
- Does NOT modify project-level `.claude/settings.json`
