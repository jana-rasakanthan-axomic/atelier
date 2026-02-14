---
name: worklog
description: Capture session summary and append to work log. Use when ending a session, before compacting, or to record progress.
allowed-tools: Read, Write, Edit, Bash(git:*), Bash(date:*), Bash(mkdir:*), Grep, Glob
---

# /worklog

Capture a session summary and append it to a persistent work log.

## Input Formats

- `/worklog` — Draft session summary, show for approval, then append
- `/worklog --auto` — Skip approval, append directly (for auto-trigger)
- `/worklog --dry-run` — Preview entry without appending
- `/worklog --path ~/custom/log.md` — Override output path for this invocation

## When to Use

- Ending a session (before compact, clear, or exit)
- Switching context to a different project
- Recording progress at a natural stopping point

## When NOT to Use

- No meaningful work was done (only read-only commands or simple questions)
- Session was purely exploratory with nothing worth recording

---

## Workflow (4 Stages)

### Stage 1: Resolve & Gather

Determine the output path and collect context for the entry.

**Path Resolution:**
1. `--path` flag — if provided, use directly
2. Default — `~/.config/atelier/worklog.md`

Create `~/.config/atelier/` directory if it doesn't exist: `mkdir -p ~/.config/atelier`

**Gather Context:**
- Repo name: `basename $(git rev-parse --show-toplevel 2>/dev/null)` (fallback: `no-repo`)
- Branch: `git rev-parse --abbrev-ref HEAD 2>/dev/null` (fallback: `none`)
- Recent commits on this branch: `git log --oneline -5 2>/dev/null`
- Diff stat: `git diff --stat HEAD~5..HEAD 2>/dev/null`
- Current date/time: `date '+%Y-%m-%d %H:%M'`

**Synthesize from conversation:**
- What was discussed, researched, or decided
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

## Error Handling

| Scenario | Action |
|----------|--------|
| Not in a git repo | Use `no-repo` and `none` for repo/branch. Proceed normally. |
| Output directory doesn't exist | Create it with `mkdir -p` |
| File write fails | Report error, suggest checking permissions |
| User cancels at approval | Abort without writing |

## Scope Limits

- One entry per invocation
- Does not read or modify the existing log (append-only)
- Does not sync or push the log anywhere
