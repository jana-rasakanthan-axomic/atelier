---
name: build
description: Implement a feature from an approved plan
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(git:*), Bash(uuidgen), Bash(~/.claude/scripts/*), Bash(./scripts/*), Bash(${profile.test_runner}), Bash(${profile.linter}), Bash(${profile.type_checker})
---

# /build

Implement a feature from an approved plan using Double-Loop TDD.

## Input Formats

```bash
/build .claude/plans/PROJ-123.md                     # From plan file (recommended)
/build .claude/context/PROJ-123.md                   # From context file (simple features)
/build "Add user export"                             # From description (simple features)
/build --layer repository .claude/plans/PROJ-123.md  # Single layer only
/build --skip-tests .claude/plans/PROJ-123.md        # Prototyping mode (no TDD)
/build --batch .claude/plans/PROJ-123.md             # Batch mode (auto commit/push/PR)
/build .claude/plans/PROJ-123.md --loop              # Self-correcting loop via ralph-loop
```

## When to Use / When NOT to Use

- **Use:** Approved plan from `/plan`, clear requirements, multi-layer changes
- **Don't use:** Requirements unclear (`/plan` first), bug fix (`/fix`), simple one-file edit

## Modes

### Interactive (default)
Standard build with human oversight at each stage. TDD enforced per CLAUDE.md.

### `--loop` (automated via ralph-loop)
Self-correcting build loop: TDD, quality gates, self-review, PR creation. Hydrates prompt from `skills/iterative-dev/prompts/build.md` and launches `/ralph-loop`.
- **Config:** `skills/iterative-dev/configs/defaults.md` (MAX_ITERATIONS=30) | **Permissions:** `skills/iterative-dev/configs/permissions.md`

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
Follow `skills/git-workflow/templates/stage-0-worktree-setup.md`. Create isolated sibling worktree (e.g., `../myproject-PROJ-123/`). All subsequent file operations use `$WORKTREE_PATH` prefix.

### Stage 0.5: PR Feedback Check
If existing PR has unresolved feedback threads, address before building:
- Code defect: fix + commit + reply with SHA
- Intentional design: reply "Won't fix" with rationale
- Out of scope: reply "Deferred"

### Stage 1: Load Plan
Read input, extract implementation phases and contract specs. For context files or descriptions, create quick internal plan.

### Stage 1.5: Pre-Analysis (Dry Run)
**Agent:** Builder. Generate report per `skills/building/templates/pre-analysis-report.md`.

1. Map each implementation phase to concrete files, layers, and test cases
2. Check contract alignment for every endpoint/function
3. Identify all permissions needed
4. Write report to `.claude/builds/<BRANCH_NAME>/pre-analysis.md`
5. Present to user -- **WAIT for explicit approval before proceeding**

In `--batch` mode: write the pre-analysis but check `batch_approval.json` for pre-approval. This stage produces NO code changes.

### Stage 2: Request Permissions
Analyze plan to determine operations needed. Present permission summary. **Wait for user approval** via `ExitPlanMode` before proceeding. In `--batch` mode: check `.claude/workstreams/batch_approval.json` and skip if pre-approved.

### Stage 3: Build (Double-Loop TDD)
**Agent:** Builder. Follow TDD State Machine per CLAUDE.md. Max 3 fix attempts per layer before escalating.

**Outer Loop:** Write integration tests, confirm FAIL (404/not-implemented).
**Inner Loop (per layer, outside-in per profile):** Write unit tests (RED), implement minimum code (GREEN), lint + type check.
**After all layers:** Integration tests PASS. Then run **full regression** via `make test` or `${profile.tools.test_runner.command}`.

### Stage 4: Verify
**Agent:** Verifier. Run full regression suite, lint, type check. Prefer `make test/lint/typecheck` if Makefile targets exist.

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

**STRICT ENFORCEMENT:** When `--loop` is specified, MUST launch `/ralph-loop`. Running the TDD cycle manually when `--loop` was requested is a PROCESS VIOLATION. If ralph-loop is unavailable, STOP and report -- do NOT fall back to interactive mode silently.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Tests/implementation fail after 3 attempts | Stop, rollback layer, report, suggest `/fix tests` |
| Scope exceeds limits | Stop, suggest splitting |

## Scope Limits
- Single domain/feature only
- Max 30 files (20 new + 10 modified)
- Max 500 lines changed per layer
