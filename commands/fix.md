---
name: fix
description: Fix code quality issues (lint, type, test errors)
model_hint: sonnet
allowed-tools: Read, Edit, Grep, Glob, Bash(${profile.test_runner}), Bash(${profile.linter}), Bash(${profile.type_checker}), Bash(git:*), Bash(uuidgen), Bash(~/.claude/scripts/*), Bash(./scripts/*)
---

# /fix

Fix code quality issues (lint, type, test errors).

## Input Formats

- `/fix` - Auto-detect and fix all issues
- `/fix lint` - Fix linting only
- `/fix types` - Fix type errors only
- `/fix tests` - Fix failing tests only
- `/fix .claude/context/PROJ-123.md` - Fix based on context file
- `/fix "Remove pass statement"` - From description
- `/fix --dry-run` - Show fixes without applying
- `/fix --auto` - Auto-approve low-risk fixes
- `/fix --verbose` - Show detailed output during execution
- `/fix --loop` - Quality convergence loop (see Loop Mode below)

## When to Use

- Linting errors, type errors, failing tests
- Import issues, simple refactoring tasks

## When NOT to Use

- Complex refactoring needed -> use `/analyze` first
- New feature implementation -> use `/build`
- Security vulnerabilities -> use `/audit`
- Requires architectural changes -> use `/plan` first

## Context File Integration

If first argument is a path to `.claude/context/*.md`, read the context file and extract requirements/tasks as context for fixes.

## Loop Mode (`--loop`)

When `--loop` is passed, run the fix-verify cycle repeatedly until quality converges:

1. Execute Stages 1-5 as normal
2. If Stage 5 (Verify) finds remaining issues, loop back to Stage 1
3. Continue until all quality gates pass or max 5 iterations reached
4. Uses `skills/iterative-dev/prompts/quality.md` for convergence criteria

This is useful for cascading fixes where fixing one issue reveals another.

## Workflow (6 Stages)

### Profile Resolution

Resolve profile before any work. The profile determines linter, type checker, and test runner commands.

```bash
TOOLKIT_DIR="${CLAUDE_TOOLKIT:-$HOME/.claude}"
PROFILE=$("$TOOLKIT_DIR/scripts/resolve-profile.sh")
```

### Stage 0: Worktree Setup

**Procedure:** Follow `skills/git-workflow/templates/stage-0-worktree-setup.md`

Create isolated git worktree. Run pre-execution checks, generate session ID and branch name, create worktree, initialize session tracking. All subsequent file operations use `$WORKTREE_PATH`.

**On Success:** Proceed to Stage 1.
**On Failure:** Report error and exit.

### Stage 1: Analyze

Run diagnostic tools to identify issues:

```bash
cd "$WORKTREE_PATH" && ${profile.tools.linter.command} ${profile.tools.linter.json_output}
cd "$WORKTREE_PATH" && ${profile.tools.type_checker.command}
cd "$WORKTREE_PATH" && ${profile.tools.test_runner.command}
```

Classify findings by priority:

| Priority | Category | Examples |
|----------|----------|----------|
| P0 | Blocking | Tests fail, build breaks, import errors |
| P1 | High | Type errors, security issues |
| P2 | Medium | Lint warnings, unused imports |
| P3 | Low | Style, formatting |

### Stage 2: Plan

For each issue: identify root cause, propose fix, assess risk (safe/risky), group related fixes. Present the plan grouped by priority with estimated change scope.

### Stage 3: Request Permissions (Requires Approval)

Present the list of files to modify and commands to run. Wait for user approval before proceeding. The approved list is a strict contract -- only modify approved files and run approved commands. Standard Claude permission flow applies for anything outside the approved scope.

### Stage 4: Execute

**Agent:** Builder

All file operations MUST use `$WORKTREE_PATH` prefix. All bash commands MUST `cd "$WORKTREE_PATH"` first.

**TDD workflow for bug/test fixes** (see CLAUDE.md for full TDD state machine):
1. Write/update test that reproduces the bug -> confirm RED
2. Fix the code -> confirm GREEN

| Fix Type | TDD Required? | Workflow |
|----------|---------------|----------|
| Test Failures | YES | Understand why test fails, fix code (not test) |
| Bug Fixes | YES | Write failing test first, then fix |
| Type Errors | Partial | Fix type, run type checker to confirm |
| Lint Errors | NO | Direct fix, run linter to confirm |
| Import Errors | NO | Direct fix, run tests to confirm |

Apply fixes in priority order. If a fix causes regression, rollback and flag.

### Stage 5: Verify (Regression Testing)

**Agent:** Verifier

Run the FULL test suite (not targeted tests). Fixes to shared code can break tests in unrelated areas.

Prefer Makefile targets (`make test`, `make lint`, `make typecheck`) if available. Fall back to profile tool commands.

If `--loop` is active and issues remain, loop back to Stage 1 (max 5 iterations).

### Stage 6: Completion

**Procedure:** Follow `skills/git-workflow/templates/completion-stage.md`

Mark session completed. Present user with options: Create PR / Merge locally / Discard changes.

## Error Handling

| Scenario | Action |
|----------|--------|
| Fix causes regression | Rollback with `git checkout -- <file>`, flag for manual review |
| Unable to determine fix | Skip, mark as "requires manual intervention", provide context |
| Too many issues (>50) | Stop, suggest running `/fix lint`, `/fix types`, `/fix tests` separately |
| Context file invalid | Report parsing error, suggest `/gather` to create valid context |

## Agents Used

| Agent | Stage | Purpose |
|-------|-------|---------|
| Builder | 4 | Implements fixes |
| Verifier | 5 | Validates fixes via full regression suite |

## Skills Used

| Skill | Purpose |
|-------|---------|
| `skills/git-workflow/` | Worktree setup and completion |
| `skills/testing/` | TDD workflow, understanding test failures |
| `skills/analysis/` | Code complexity analysis |
| `skills/iterative-dev/prompts/quality.md` | Quality convergence criteria (for `--loop`) |

## Scope Limits

- Max files: 50
- Max issues per run: 50
- Escalate if: security issues found, architectural problems
- For larger scope: run `/fix lint`, `/fix types`, `/fix tests` separately
