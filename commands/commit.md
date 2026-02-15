---
name: commit
description: Generate meaningful commit message for staged changes
model_hint: haiku
allowed-tools: Read, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
---

# /commit

Generate meaningful commit message for staged changes.

## Input Formats

- `/commit` - Generate commit message for staged changes
- `/commit --amend` - Amend last commit (use carefully)
- `/commit --scope api` - Specify scope explicitly
- `/commit --breaking` - Mark as breaking change
- `/commit --dry-run` - Preview message without committing
- `/commit .claude/context/PROJ-123.md` - Include ticket context in message

## When to Use

- Changes ready to commit
- Need clear commit message
- Following conventional commits

## When NOT to Use

- No changes staged -> stage changes first with `git add`
- Changes not ready (tests failing) -> fix issues first with `/fix`
- Need to commit specific files only -> stage specific files first
- Amending pushed commits -> requires explicit `--amend` and will warn

## Context File Integration

If first argument is a path to `.claude/context/*.md`, read the context file, extract ticket number, include relevant context in commit body, and link to ticket in footer.

---

## Workflow (4 Stages)

### Stage 1: Gather

Collect information about staged changes and commit style.

**Branch Protection Check (CRITICAL):**
1. Get current branch: `git rev-parse --abbrev-ref HEAD`
2. If branch is `main` or `master`: **STOP immediately**. Display error telling user to create a feature branch first. Exit without committing.

**Actions:**
- `git status` -- check staged status
- `git diff --cached --name-only` -- view staged files
- `git diff --cached` -- view staged diff
- `git log --oneline -10` -- recent commit style for consistency
- If context file provided: read and extract ticket details

**Checks:**
- Verify changes are staged
- Check for secrets/sensitive files (.env, credentials, API keys)
- Warn if large commit (>500 lines or >30 files)

---

### Stage 2: Draft

Generate commit message following Conventional Commits format.

**Format:** `<type>(<scope>): <description>`

| Type | Use For |
|------|---------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation |
| style | Formatting |
| refactor | Code restructuring |
| perf | Performance |
| test | Tests |
| chore | Maintenance |

**Guidelines:**
- Subject line: max 50 characters, imperative mood
- Body: explain **what** and **why**, not **how**
- Wrap body at 72 characters
- Reference issues/tickets in footer

---

### Stage 3: Approve

Present the proposed commit message, staged files, and stats to the user. Wait for approval.

If `--dry-run`: stop here and report message only.

User can: approve as-is, request edits, or cancel.

---

### Stage 4: Execute

Create the commit using HEREDOC format:

```bash
git commit -m "$(cat <<'EOF'
<commit message here>
EOF
)"
```

Post-commit: verify with `git log -1 --oneline` and `git status`.

---

## Safety Rules

- **CRITICAL:** Never commit to main/master -- these are protected branches
- Always verify current branch before staging
- Never amend pushed commits without explicit request and warning
- Never use `--no-verify` unless explicitly requested
- Never force push to main/master
- Never commit secrets or sensitive files
- Always verify staged files before commit
- Always use HEREDOC for multi-line commit messages

## Error Handling

| Scenario | Action |
|----------|--------|
| No changes staged | Report, suggest `git add <files>`, show `git status` |
| Pre-commit hook fails | Report output, do NOT use `--no-verify`, suggest `/fix lint`, create NEW commit after fixing (don't amend) |
| Commit fails (other) | Report error, suggest checking hooks and merge conflicts |
| Secrets detected | STOP and warn, list suspicious files, suggest `.gitignore`, do NOT commit until user confirms |
| Amend on pushed commit | Check with `git log origin/main..HEAD`, WARN about force push, require explicit confirmation |
| Commit too large | Warn (>500 lines or >30 files), suggest splitting, proceed only with confirmation |

## Scope Limits

- Max files per commit: 30 (warn and suggest splitting)
- Max lines changed: 500 (warn and suggest splitting)
- Escalate if: breaking changes across multiple modules
