# Iterative Development Permissions

Permission manifests per pattern. The `/build --loop` and `/fix --loop` commands check these against `.claude/settings.json` during pre-flight validation. Missing permissions cause approval prompts that stall unattended loops.

## Build Pattern

Full lifecycle: TDD + quality + review + PR creation.

| # | Permission | Purpose |
|---|-----------|---------|
| 1 | Read | Read source files, plans, patterns |
| 2 | Write | Create new source and test files |
| 3 | Edit | Modify existing source and test files |
| 4 | Glob | Find files by pattern |
| 5 | Grep | Search file contents |
| 6 | Bash(git status:*) | Check working tree state |
| 7 | Bash(git add:*) | Stage files for commit |
| 8 | Bash(git commit:*) | Create commits |
| 9 | Bash(git push:*) | Push branch to remote |
| 10 | Bash(git checkout:*) | Switch branches |
| 11 | Bash(git branch:*) | Create and list branches |
| 12 | Bash(git diff:*) | View changes |
| 13 | Bash(git log:*) | View commit history |
| 14 | Bash(git worktree:*) | Create isolated worktrees |
| 15 | Bash(gh pr create:*) | Create pull requests |
| 16 | Bash(gh pr view:*) | View pull request details |
| 17 | Bash(${profile.tools.test_runner.command}:*) | Run tests |
| 18 | Bash(${profile.tools.linter.command}:*) | Run linter |
| 19 | Bash(${profile.tools.type_checker.command}:*) | Run type checker |
| 20 | Bash(~/.claude/scripts/*) | Toolkit scripts |
| 21 | Bash(cat:*) | Template variable substitution |
| 22 | Bash(uuidgen) | Generate session IDs |
| 23 | Bash(make:*) | Project build targets |
| 24 | Bash(git stash:*) | Stash uncommitted changes |

**Total: 24 permissions**

## Review-Fix Pattern

Review and fix cycle on an existing branch. No worktree creation or PR creation needed.

| # | Permission | Purpose |
|---|-----------|---------|
| 1 | Read | Read source files and review checklists |
| 2 | Write | Create new files if review requires |
| 3 | Edit | Fix code based on review findings |
| 4 | Glob | Find files by pattern |
| 5 | Grep | Search file contents |
| 6 | Bash(git status:*) | Check working tree state |
| 7 | Bash(git add:*) | Stage fixes |
| 8 | Bash(git commit:*) | Commit fixes |
| 9 | Bash(git push:*) | Push fixes to remote |
| 10 | Bash(git diff:*) | View changes |
| 11 | Bash(git log:*) | View commit history |
| 12 | Bash(gh pr view:*) | View PR details |
| 13 | Bash(${profile.tools.test_runner.command}:*) | Run tests |
| 14 | Bash(${profile.tools.linter.command}:*) | Run linter |
| 15 | Bash(${profile.tools.type_checker.command}:*) | Run type checker |
| 16 | Bash(~/.claude/scripts/*) | Toolkit scripts |
| 17 | Bash(cat:*) | Template variable substitution |
| 18 | Bash(make:*) | Project build targets |

**Total: 18 permissions**

## Quality Pattern

Lint, type-check, and test convergence only. No review, PR, or branch management.

| # | Permission | Purpose |
|---|-----------|---------|
| 1 | Read | Read source files |
| 2 | Write | Create files if fixes require |
| 3 | Edit | Fix lint, type, and test issues |
| 4 | Glob | Find files by pattern |
| 5 | Grep | Search file contents |
| 6 | Bash(git status:*) | Check working tree state |
| 7 | Bash(git add:*) | Stage fixes |
| 8 | Bash(git commit:*) | Commit fixes |
| 9 | Bash(${profile.tools.test_runner.command}:*) | Run tests |
| 10 | Bash(${profile.tools.linter.command}:*) | Run linter |
| 11 | Bash(${profile.tools.type_checker.command}:*) | Run type checker |
| 12 | Bash(make:*) | Project build targets |

**Total: 12 permissions**
