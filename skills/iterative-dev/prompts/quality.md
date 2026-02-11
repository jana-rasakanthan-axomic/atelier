# Quality Convergence Loop Prompt

You are converging quality gates to zero errors. Each iteration you run gates, fix the highest-priority issue, and verify.

## Context

- **Toolkit:** $TOOLKIT_DIR

## Setup (First Iteration Only)

1. Resolve the active profile:
   ```bash
   PROFILE=$("$TOOLKIT_DIR/scripts/resolve-profile.sh")
   ```
2. Identify the three quality gates from the profile: test runner, linter, type checker.

## State Machine: ASSESS -> DECIDE -> ACT -> VERIFY -> COMPLETE

### ASSESS

Run all three gates and record their output:

1. **Linter:** Run the profile's linter. Record each error with file:line.
2. **Type checker:** Run the profile's type checker. Record each error with file:line.
3. **Tests:** Run the profile's test runner. Record each failure with test name.

### DECIDE

Pick the highest-priority issue to fix:

1. **Test failure** -> Fix first (broken tests block development)
2. **Type error** -> Fix second (type errors often indicate logic bugs)
3. **Lint error** -> Fix third (style and convention issues)
4. **All gates pass** -> Proceed to COMPLETE

When multiple errors exist in the same category, fix them in file order to avoid conflict.

### ACT

Fix the selected issue:

1. Read the affected file
2. Apply the minimal fix
3. Avoid changing unrelated code

### VERIFY

After each fix, re-run ALL three gates (not just the one you fixed):

```
Run tests        -> record results
Run linter       -> record results
Run type checker -> record results
```

If any gate still has errors, return to DECIDE. Cross-gate regressions (fixing a lint error breaks a test) must be caught and resolved.

### COMPLETE

When all three gates report zero errors:

1. Stage and commit the fixes
2. Output the final gate results as confirmation

**Output the following line to signal completion:**

```
QUALITY COMPLETE
```

## Rules

- Fix one issue at a time, then re-run all gates
- Never suppress or ignore errors (no lint-disable, no type-ignore) unless the existing codebase already uses that pattern
- If a fix creates a new error in a different gate, fix the regression immediately
- Do not hardcode tool names -- use the resolved profile for all commands
