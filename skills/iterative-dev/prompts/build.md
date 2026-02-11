# Build Loop Prompt

You are implementing a plan through iterative TDD cycles. Each iteration you assess, decide, act, verify, and either loop or complete.

## Context

- **Plan:** $PLAN_FILE
- **Toolkit:** $TOOLKIT_DIR
- **Base branch:** $BASE_BRANCH
- **Worktree:** $WORKTREE_PATH

## Setup (First Iteration Only)

1. Resolve the active profile:
   ```bash
   PROFILE=$("$TOOLKIT_DIR/scripts/resolve-profile.sh")
   ```
2. Read the plan from `$PLAN_FILE`. Identify all layers to implement and their order.
3. If `$WORKTREE_PATH` does not exist yet, create it from `$BASE_BRANCH`.

## State Machine: ASSESS -> DECIDE -> ACT -> VERIFY -> COMPLETE

### ASSESS

Determine current state by running all gates:

- **Tests:** Run the profile's test runner. Record pass/fail counts.
- **Lint:** Run the profile's linter. Record error count.
- **Types:** Run the profile's type checker. Record error count.
- **Layers:** Check which layers from the plan are implemented and passing.
- **Review:** If all layers are done and gates pass, run self-review using `$TOOLKIT_DIR/skills/review/` personas.

### DECIDE

Based on assessment, pick the highest-priority action:

1. **Next layer needs tests** -> Write tests for the next unimplemented layer (TDD RED phase)
2. **Tests written but failing (RED confirmed)** -> Write implementation to make tests pass (TDD GREEN phase)
3. **GREEN attempt failing** (attempt < MAX_GREEN_RETRIES) -> Fix implementation and retry
4. **GREEN attempt failing** (attempt = MAX_GREEN_RETRIES) -> Escalate to user and stop
5. **All layers done, lint errors** -> Fix lint issues
6. **All layers done, type errors** -> Fix type errors
7. **All layers done, test failures** -> Fix failing tests
8. **All gates pass, review has findings** -> Fix review findings
9. **All gates pass, review is clean** -> Proceed to COMPLETE

### ACT

Execute the decided action:

- **TDD RED:** Read the layer pattern from `$TOOLKIT_DIR/profiles/{profile}/patterns/{layer}.md`. Write test file following `$TOOLKIT_DIR/skills/testing/` conventions. Run tests to confirm they fail.
- **TDD GREEN:** Write minimum implementation to pass the failing tests. Follow the layer pattern from the profile.
- **Quality fix:** Fix the specific lint, type, or test error. Make the smallest change possible.
- **Review fix:** Address the finding, re-run affected gates to ensure no regressions.

### VERIFY

After every ACT, re-run ALL gates (not just the one you fixed). This catches cross-gate regressions:

```
Run tests       -> record results
Run linter      -> record results
Run type checker -> record results
```

If any gate fails, return to DECIDE. If all pass, check if more work remains (layers, review).

### COMPLETE

When all layers are implemented, all gates pass, and self-review is clean:

1. Stage all changes: `git add` the relevant files
2. Commit with a descriptive message summarizing the implementation
3. Push the branch to the remote
4. Create a PR against `$BASE_BRANCH` using `gh pr create`
5. Output the PR URL

**Output the following line to signal completion:**

```
BUILD COMPLETE
```

## Rules

- Follow TDD strictly: write tests BEFORE implementation for every layer
- Confirm RED (tests fail) before writing implementation
- After each GREEN confirmation, run ALL gates, not just tests
- Never skip the self-review phase -- it catches issues automated gates miss
- If MAX_GREEN_RETRIES is reached for a layer, stop and escalate
- Commit only when all gates pass and review is clean
- Do not hardcode tool names -- use the resolved profile for all commands
