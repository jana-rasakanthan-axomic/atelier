---
name: worklog
description: Capture incremental session summary and append to work log. Use anytime to record progress — each run captures changes since the last entry.
model_hint: haiku
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(date:*), Bash(mkdir:*), Bash(scripts/session-manager.sh:*), Grep, Glob
---

# /worklog

Capture an incremental session summary and append it to a persistent work log. Each invocation captures the **delta since the last `/worklog` run**, so it is safe to run multiple times per session.

## Input Formats

- `/worklog` — Draft session summary, show for approval, then append
- `/worklog --auto` — Skip approval, append directly
- `/worklog --dry-run` — Preview entry without appending
- `/worklog --path ~/custom/log.md` — Override output path for this invocation

## When to Use

- Anytime you want to checkpoint your progress
- Before stepping away, switching context, or ending a session
- After completing a meaningful piece of work

## When NOT to Use

- No meaningful work was done (only read-only commands or simple questions)
- Session was purely exploratory with nothing worth recording

---

## Workflow (5 Stages)

### Stage 1: Resolve & Gather

Determine the output path, check for a previous checkpoint, and collect context for the entry.

**Path Resolution:**
1. `--path` flag — if provided, use directly
2. Default — `~/.config/atelier/worklog.md`

Create `~/.config/atelier/` directory if it doesn't exist: `mkdir -p ~/.config/atelier`

**Checkpoint Resolution:**

Check for a previous worklog timestamp:
```bash
LAST_RUN=$(cat .claude/worklog-last 2>/dev/null || echo "")
```

- If `LAST_RUN` is set, this is an **incremental** run — gather only changes since that timestamp.
- If `LAST_RUN` is empty, this is the **first** run in this session — gather everything available.

**Gather Context:**
- Repo name: `basename $(git rev-parse --show-toplevel 2>/dev/null)` (fallback: `no-repo`)
- Branch: `git rev-parse --abbrev-ref HEAD 2>/dev/null` (fallback: `none`)
- Current date/time: `date '+%Y-%m-%d %H:%M'`

If `LAST_RUN` is set (incremental):
- Commits since last run: `git log --oneline --since="$LAST_RUN" 2>/dev/null`
- Diff stat since last run: `git diff --stat $(git log --format=%H --since="$LAST_RUN" | tail -1)..HEAD 2>/dev/null`

If `LAST_RUN` is empty (first run):
- Recent commits on this branch: `git log --oneline -5 2>/dev/null`
- Diff stat: `git diff --stat HEAD~5..HEAD 2>/dev/null`

**Synthesize from conversation:**
- What was discussed, researched, or decided **since the last `/worklog` run** (or since session start if first run)
- Code changes made and their purpose
- Problems encountered and how they were resolved
- What remains to be done

---

### Stage 2: Draft Entry

Compose the worklog entry from gathered context.

**Format:**
```markdown
## YYYY-MM-DD HH:MM — repo-name (branch-name)

**Context:** One-line session description

**What was done:**
- Bullet points covering conversations, research, code changes, etc.

**Decisions:**
- Key decisions and rationale (omit section if none)

**Next steps:**
- What remains

---
```

**Guidelines:**
- Target 10–25 lines per entry
- Omit sections with nothing to report (e.g., skip "Decisions" if none were made)
- Be specific — mention file names, command names, ticket IDs
- Focus on information that would be useful when resuming work

---

### Stage 3: Approve

Present the draft entry to the user for review.

- If `--auto`: skip this stage entirely
- If `--dry-run`: display the draft and **STOP** — do not write anything

User can: approve as-is, request edits, or cancel.

---

### Stage 4: Append

Write the entry to the work log file.

**If file does not exist:** Create it with a header:
```markdown
# Work Log

---

```

**Append strategy:** Insert the new entry immediately after the header (after the first `---`), so newest entries appear first.

**Confirmation:** Report the file path and timestamp of the appended entry.

---

### Stage 5: Save Checkpoint & Session State

After appending the worklog entry, record the checkpoint timestamp and persist session state.

**Write checkpoint timestamp:**
```bash
mkdir -p .claude && date '+%Y-%m-%d %H:%M:%S' > .claude/worklog-last
```

This ensures the next `/worklog` run only captures the delta from this point forward.

**Save session state:**

Run: `scripts/session-manager.sh save`

This captures phase, feature, branch, commit, uncommitted file count, locked files, and workstream state to `.atelier/sessions/<session_id>.json`. The session ID is auto-generated from the current date and branch name.

If the save fails (e.g., not in a git repo), log a warning and continue -- session persistence is best-effort and should not block the worklog.

---


## Error Handling

| Scenario | Action |
|----------|--------|
| Not in a git repo | Use `no-repo` and `none` for repo/branch. Proceed normally. |
| Output directory doesn't exist | Create it with `mkdir -p` |
| File write fails | Report error, suggest checking permissions |
| User cancels at approval | Abort without writing |

## Scope Limits

- One entry per invocation
- Each entry covers the delta since the last `/worklog` run (or session start if first run)
- Does not read or modify the existing log (append-only)
- Does not sync or push the log anywhere
- Checkpoint file (`.claude/worklog-last`) is local and not committed to git
