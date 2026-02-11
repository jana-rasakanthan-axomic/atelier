# Review-Fix Loop Prompt

You are fixing review findings on an existing branch. Each iteration you review, fix, verify, and either loop or complete.

## Context

- **PR:** $PR_NUMBER (empty if no PR yet -- review the current branch diff against $BASE_BRANCH)
- **Base branch:** $BASE_BRANCH
- **Toolkit:** $TOOLKIT_DIR

## Setup (First Iteration Only)

1. Resolve the active profile:
   ```bash
   PROFILE=$("$TOOLKIT_DIR/scripts/resolve-profile.sh")
   ```
2. Identify the files changed on this branch relative to `$BASE_BRANCH`.

## State Machine: ASSESS -> DECIDE -> ACT -> VERIFY -> COMPLETE

### ASSESS

1. Run self-review using all relevant personas from `$TOOLKIT_DIR/skills/review/`:
   - Engineering persona: architecture, quality, performance
   - Security persona: OWASP, auth, data handling
   - PR persona: merge readiness, size, test coverage
2. Collect findings with severity and file:line references.
3. Run all quality gates (tests, lint, type checker) to establish baseline.

### DECIDE

Pick the highest-priority action:

1. **Critical or high severity finding** -> Fix immediately
2. **Medium severity finding** -> Fix if straightforward
3. **Quality gate failing** -> Fix the gate issue
4. **Low severity finding** -> Fix if no risk of regression
5. **No findings, all gates pass** -> Proceed to COMPLETE

### ACT

For each finding:

1. Read the affected file and understand the context
2. Apply the fix with the smallest change possible
3. If the fix touches logic, verify the relevant tests still pass

### VERIFY

After each fix, re-run ALL gates:

```
Run tests        -> record results
Run linter       -> record results
Run type checker -> record results
```

Then re-run the review for the affected files. If new findings emerge or gates fail, return to DECIDE.

### COMPLETE

When self-review produces zero findings and all gates pass:

1. Stage and commit the fixes with a message describing what was addressed
2. Push to the remote branch
3. If a PR exists, add a comment summarizing the fixes applied

**Output the following line to signal completion:**

```
REVIEW COMPLETE
```

## Rules

- Never introduce new functionality -- only fix existing findings
- Re-run ALL gates after every fix to catch regressions
- If a fix causes a new test failure, fix the regression before continuing
- Do not hardcode tool names -- use the resolved profile for all commands
