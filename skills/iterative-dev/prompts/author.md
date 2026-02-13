# Author Loop Prompt

You are improving toolkit components (commands, agents, skills) through iterative validation and fix cycles. Each iteration you validate, fix, verify, and either loop or complete.

## Context

- **Target files:** $TARGET_FILES
- **Component type:** $COMPONENT_TYPE (command | agent | skill)
- **Toolkit:** $TOOLKIT_DIR
- **Base branch:** $BASE_BRANCH

## Setup (First Iteration Only)

1. Read each target file to understand its current state.
2. Load the relevant checklist from `$TOOLKIT_DIR/skills/authoring/checklists/{type}-checklist.md`.
3. Initialize tracking counters:
   - `finding_retry_counts` = {} (maps finding key to retry count)
   - `previous_finding_count` = null
   - `stall_counter` = 0

## State Machine: ASSESS -> DECIDE -> ACT -> VERIFY -> COMPLETE

### ASSESS

Run both validation layers:

1. **Structural validation:** Run `$TOOLKIT_DIR/scripts/validate-toolkit.sh $TARGET_FILES`. Parse each `[ERROR]` and `[WARN]` line into findings with severity and file reference.
2. **Semantic assessment:** Read each target file and assess against the loaded checklist. Record any checklist failures as findings with severity `medium`.
3. Filter out any findings that have been skipped (retry count exceeded MAX_FINDING_RETRIES).

### DECIDE

Pick the highest-priority finding to fix:

1. **ERROR from validate-toolkit.sh** -> Fix immediately (file too long, missing section, broken cross-reference, missing frontmatter)
2. **WARN from validate-toolkit.sh** -> Fix if straightforward (file approaching size limit, name format, CLAUDE.md consistency)
3. **Checklist failure** -> Fix (conciseness, structure, content quality)
4. **No findings** -> Proceed to COMPLETE

When multiple findings exist at the same severity, fix them in file order.

### ACT

For each finding, apply the minimal fix:

- **File too long (>500 lines):** Extract reference material into subfiles (progressive disclosure). Move examples, detailed tables, or appendices to `reference/` subdirectory and link from the main file.
- **File approaching limit (>200/300 lines):** Tighten prose, remove redundancy, consolidate similar sections.
- **Missing frontmatter or fields:** Add the required `---` block with `name`, `description`, `allowed-tools`.
- **Missing required section:** Add the section with appropriate content following existing patterns in similar components.
- **Broken cross-reference:** Fix the path if the target moved, or remove the reference if the target no longer exists.
- **CLAUDE.md inconsistency:** Add or update the entry in the relevant CLAUDE.md quick reference table.
- **Checklist failure:** Apply the specific fix indicated by the checklist item.

After each fix, increment `finding_retry_counts[finding_key]`.

### VERIFY

After each fix, re-run both validation layers:

```
Run validate-toolkit.sh  -> record results
Re-assess checklist      -> record results
```

If new findings emerge or existing findings remain, return to DECIDE.

### Escalation Rules

After VERIFY, check escalation conditions:

1. **Per-finding retry limit:** If `finding_retry_counts[finding_key] >= MAX_FINDING_RETRIES` (default 3), skip that finding and move on. Log: "Skipping finding {key} after {count} failed fix attempts."
2. **Stall detection:** Compare current finding count to `previous_finding_count`:
   - If findings did not decrease, increment `stall_counter`
   - If findings decreased, reset `stall_counter` to 0
   - If `stall_counter >= 3`, STOP and escalate to user: "Author loop stalled: findings have not decreased across 3 consecutive iterations."
3. Update `previous_finding_count` with current count.

### COMPLETE

When validation produces zero findings and checklist assessment is clean:

1. Stage all changed files: `git add` the relevant files
2. Commit with a message describing what was improved
3. Output a summary of all fixes applied and any skipped findings

**Output the following line to signal completion:**

```
AUTHOR COMPLETE
```

## Rules

- Never introduce new functionality — only fix validation and checklist findings
- Re-run ALL validation after every fix to catch regressions
- If a fix causes a new finding, fix the regression before continuing
- When extracting content to subfiles (progressive disclosure), ensure the main file links to the extracted content
- Skipped findings (retry limit exceeded) are reported in the completion summary
- Do not modify files outside $TARGET_FILES unless fixing a cross-reference requires updating CLAUDE.md
