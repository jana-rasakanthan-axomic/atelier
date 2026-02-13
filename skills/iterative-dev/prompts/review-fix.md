# Review-Fix Loop Prompt

You are fixing review findings on an existing branch. Each iteration you review, fix, verify, and either loop or complete.

## Context

- **PR:** $PR_NUMBER (empty if no PR yet -- review the current branch diff against $BASE_BRANCH)
- **Base branch:** $BASE_BRANCH
- **Toolkit:** $TOOLKIT_DIR
- **Self-review mode:** $SELF_REVIEW_MODE (true = self-review-fix loop invoked via `/review --self --loop`)
- **Create PR on complete:** $CREATE_PR_ON_COMPLETE (true = create PR when clean and no PR exists yet)

## Setup (First Iteration Only)

1. Resolve the active profile:
   ```bash
   PROFILE=$("$TOOLKIT_DIR/scripts/resolve-profile.sh")
   ```
2. Identify the files changed on this branch relative to `$BASE_BRANCH`.
3. Initialize tracking counters:
   - `finding_retry_counts` = {} (maps finding key to retry count)
   - `previous_finding_count` = null
   - `stall_counter` = 0

## External Comments (When $PR_NUMBER Is Set)

When a PR number is provided, fetch external review comments before ASSESS:

```bash
gh api repos/{owner}/{repo}/pulls/$PR_NUMBER/comments --jq '.[] | {path, line: .line, body, user: .user.login}'
gh api repos/{owner}/{repo}/pulls/$PR_NUMBER/reviews --jq '.[] | select(.state == "CHANGES_REQUESTED") | {body, user: .user.login}'
```

Include each external comment as a **High-severity** finding in ASSESS, tagged with `source: external`. Track the comment thread ID for reply on resolution.

## State Machine: ASSESS -> DECIDE -> ACT -> VERIFY -> COMPLETE

### ASSESS

1. Run self-review using all relevant personas from `$TOOLKIT_DIR/skills/review/`:
   - Security persona: OWASP, STRIDE, auth, crypto
   - Engineering persona: architecture, quality, performance, merge readiness
   - Product persona: requirements, UX, edge cases
2. Collect findings with severity and file:line references.
3. Merge external comments (if any) into findings list, tagged `source: external`.
4. Run all quality gates (tests, lint, type checker) to establish baseline.
5. Filter out any findings that have been skipped (retry count exceeded MAX_FINDING_RETRIES).

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
4. Increment `finding_retry_counts[finding_key]`

### VERIFY

After each fix, re-run ALL gates:

```
Run tests        -> record results
Run linter       -> record results
Run type checker -> record results
```

Then re-run the review for the affected files. If new findings emerge or gates fail, return to DECIDE.

### Escalation Rules

After VERIFY, check escalation conditions:

1. **Per-finding retry limit:** If `finding_retry_counts[finding_key] >= MAX_FINDING_RETRIES` (default 3), skip that finding and move on. Log: "Skipping finding {key} after {count} failed fix attempts."
2. **Stall detection:** Compare current finding count to `previous_finding_count`:
   - If findings did not decrease, increment `stall_counter`
   - If findings decreased, reset `stall_counter` to 0
   - If `stall_counter >= 3`, STOP and escalate to user: "Self-review stalled: findings have not decreased across 3 consecutive iterations."
3. Update `previous_finding_count` with current count.

### COMPLETE

When self-review produces zero actionable findings and all gates pass:

1. Stage and commit the fixes with a message describing what was addressed
2. Push to the remote branch
3. **If PR exists:**
   - Add a comment summarizing the fixes applied
   - For each resolved external comment, reply to the thread: "Fixed in commit `$SHA`"
4. **If no PR exists and $CREATE_PR_ON_COMPLETE is true:**
   - Create PR via `gh pr create` with a summary of the branch changes
5. **If no PR exists and $CREATE_PR_ON_COMPLETE is false:**
   - Report completion without creating a PR

**Output the following line to signal completion:**

```
REVIEW COMPLETE
```

## Rules

- Never introduce new functionality -- only fix existing findings
- Re-run ALL gates after every fix to catch regressions
- If a fix causes a new test failure, fix the regression before continuing
- Do not hardcode tool names -- use the resolved profile for all commands
- External comments are treated as High severity regardless of the commenter's wording
- Skipped findings (retry limit exceeded) are reported in the completion summary
