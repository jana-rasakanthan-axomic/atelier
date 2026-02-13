---
name: build
description: Implement a feature from an approved plan
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(git:*), Bash(uuidgen), Bash(~/.claude/scripts/*), Bash(./scripts/*), Bash(${profile.test_runner}), Bash(${profile.linter}), Bash(${profile.type_checker})
---

# /build

Implement a feature from an approved plan using Double-Loop TDD.

## Input Formats

```bash
/build .claude/plans/PROJ-123.md                   # From plan file (recommended)
/build .claude/context/PROJ-123.md                 # From context file (simple features)
/build "Add user export"                           # From description (simple features)
/build --layer repository .claude/plans/PROJ-123.md  # Single layer only
/build --skip-tests .claude/plans/PROJ-123.md      # Prototyping mode (no TDD)
/build --batch .claude/plans/PROJ-123.md           # Batch mode (auto commit/push/PR)
/build .claude/plans/PROJ-123.md --loop            # Self-correcting loop via ralph-loop
```

## When to Use

- Have an approved plan from `/plan`
- Simple feature with clear requirements
- Multi-layer changes with tests required

## When NOT to Use

- Requirements unclear → `/plan` first
- Bug fix → `/fix`
- Simple one-file change → edit directly

## Modes

### Interactive (default)

Standard build with human oversight at each stage. TDD enforced per CLAUDE.md.

### `--loop` (automated via ralph-loop)

Self-correcting build loop: TDD → quality gates → self-review → PR creation. Hydrates prompt from `skills/iterative-dev/prompts/build.md` and launches `/ralph-loop`.

**Config:** `skills/iterative-dev/configs/defaults.md` (MAX_ITERATIONS=30)
**Permissions:** `skills/iterative-dev/configs/permissions.md`

### `--batch` (workstream mode)

Auto commit/push/PR on success. Checks for already-built tickets and PR feedback before starting.

---

## Profile Resolution

```bash
TOOLKIT_DIR="${CLAUDE_TOOLKIT:-$HOME/.claude}"
PROFILE=$("$TOOLKIT_DIR/scripts/resolve-profile.sh")
```

Determines: test runner, linter, type checker, build order, code patterns, style limits.

## Workflow (5 Stages)

### Stage 0: Worktree Setup

Follow `skills/git-workflow/templates/stage-0-worktree-setup.md`

Create isolated sibling worktree (e.g., `../myproject-PROJ-123/`). All subsequent file operations use `$WORKTREE_PATH` prefix.

### Stage 0.5: PR Feedback Check

If existing PR has unresolved feedback threads, address them before building:
- Code defect → fix + commit + reply with SHA
- Intentional design → reply "Won't fix" with rationale
- Out of scope → reply "Deferred"

### Stage 1: Load Plan

Read input, extract implementation phases and contract specs. For context files or descriptions, create quick internal plan.

### Stage 1.5: Pre-Analysis (Dry Run)

**Agent:** Builder

Generate a pre-analysis report following `skills/building/templates/pre-analysis-report.md`.

1. Read the plan and map each implementation phase to concrete files, layers, and test cases
2. Check contract alignment for every endpoint/function
3. Identify all permissions needed
4. Write the report to `.claude/builds/<BRANCH_NAME>/pre-analysis.md`
5. Present the report to the user
6. **WAIT for explicit user approval before proceeding**

In `--batch` mode: write the pre-analysis but check `batch_approval.json` for pre-approval.

This stage produces NO code changes -- it is read-only analysis.

### Stage 2: Request Permissions

Analyze plan to determine operations needed. Present permission summary. **Wait for user approval** via `ExitPlanMode` before proceeding.

In `--batch` mode: check `.claude/workstreams/batch_approval.json` and skip if pre-approved.

### Stage 3: Build (Double-Loop TDD)

**Agent:** Builder

**Outer Loop:** Write integration tests → confirm FAIL (404/not-implemented).

**Inner Loop (per layer, outside-in per profile):**
1. Write unit tests → run → confirm **RED**
2. Implement minimum code → run → confirm **GREEN**
3. Lint + type check → fix issues

**After all layers:** Run integration tests → confirm **PASS**.

**After feature complete:** Run **REGRESSION TESTS** (full suite via `make test` or `${profile.tools.test_runner.command}`).

Max 3 fix attempts per layer before escalating. See CLAUDE.md TDD State Machine for enforcement rules.

### Stage 4: Verify

**Agent:** Verifier

Run full regression suite, lint, type check. Prefer `make test/lint/typecheck` if Makefile targets exist.

### Stage 5: Completion

Follow `skills/git-workflow/templates/completion-stage.md`

- **Interactive:** Present options (PR / Merge / Discard)
- **Batch:** Auto commit, push, create PR, update status.json

---

### `--loop` Mode Procedure

1. Resolve profile and validate plan file exists
2. Read defaults from `skills/iterative-dev/configs/defaults.md`
3. Check permissions from `skills/iterative-dev/configs/permissions.md`
4. Hydrate prompt template from `skills/iterative-dev/prompts/build.md`
5. Launch `/ralph-loop` with hydrated prompt, `--completion-promise "BUILD COMPLETE"`, `--max-iterations N`

**STRICT ENFORCEMENT:** When `--loop` is specified, the build command MUST launch `/ralph-loop`. Running the TDD cycle manually (interactive mode) when `--loop` was requested is a PROCESS VIOLATION. If ralph-loop cannot be launched (e.g., plugin not available), STOP and report the error to the user -- do NOT fall back to interactive mode silently.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Tests fail after 3 attempts | Stop, report, suggest `/fix tests` |
| Layer implementation fails | Rollback layer, report, continue if independent |
| Scope exceeds limits | Stop, suggest splitting |

## Scope Limits

- Single domain/feature only
- Max 30 files (20 new + 10 modified)
- Max 500 lines changed per layer
