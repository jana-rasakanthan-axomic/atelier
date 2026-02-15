---
name: atelier-feedback
description: Capture toolkit improvement ideas and append to IMPROVEMENTS.md
model_hint: haiku
allowed-tools: Read, Edit, Grep, Glob, AskUserQuestion
---

# /atelier-feedback

Capture improvement ideas for the atelier toolkit and append them to `IMPROVEMENTS.md`.

## Input Formats

- `/atelier-feedback` — Interactive mode (ask what the user wants to improve)
- `/atelier-feedback "the /build command should..."` — From inline text
- `/atelier-feedback path/to/notes.md` — From a file containing ideas

## When to Use

- You noticed something that could be better in atelier during a session
- You have an idea for a new command, skill, hook, or script
- Something didn't work as expected and you want to log it
- You want to suggest a process improvement

## When NOT to Use

- The idea is about the project you're building (not atelier itself)
- The improvement is already tracked — check the Status Tracker first

---

## Workflow (4 Stages)

### Stage 1: Capture

Accept the user's raw idea in whatever form it arrives.

**Input Detection:**

| Pattern | Type | Action |
|---------|------|--------|
| No arguments | Interactive | Ask: "What would you like to improve about atelier?" |
| Quoted string | Inline text | Parse directly |
| Path to file | Document | Read file contents |

**If interactive**, ask a focused question:
> What would you like to improve about atelier? Describe the problem you hit and what you think the fix should be.

---

### Stage 2: Check for Duplicates

Read `IMPROVEMENTS.md` and scan the Status Tracker table for existing items that match the user's idea.

1. Read the Status Tracker table from `IMPROVEMENTS.md`
2. Compare the user's idea against existing titles and descriptions
3. If a likely duplicate is found, show it to the user and ask:
   - "This looks similar to ID {N}: {title}. Is this the same idea, or something different?"
   - If same: STOP. Report the existing item ID and current status.
   - If different: proceed to Stage 3.

---

### Stage 3: Format and Confirm

Reformat the raw idea into the standard structure.

**Determine the next ID:** Count existing rows in the Status Tracker table and add 1.

**Choose a category** from the existing set: Hooks, State, Context, Scripts, Integration, Profiles, Testing, Commands, Config, Docs, Architecture. If none fit, use the closest match or suggest a new category.

**Draft two artifacts:**

**Table row:**
```
| {ID} | {Title} | {Category} | {Brief description} | — | backlog |
```

**Detail entry:**
```markdown
### {ID}. {Title}

**Problem:** {What's wrong or missing — 1-2 sentences}

**Solution:** {What should be built or changed — 1-3 sentences}
```

**Present both to the user for confirmation.** The user can:
- Approve as-is
- Request edits (re-draft and show again)
- Cancel

---

### Stage 4: Append

Append the approved idea to `IMPROVEMENTS.md`. Three edits in this order:

**1. Append table row:** Add the new row at the end of the Status Tracker table (before the `---` separator after the table).

**2. Append detail entry:** Add the new detail section at the end of the Details section (before the final `---` and `*Last updated*` line).

**3. Update summary counts:** Increment the relevant Priority row (—) and Category row in both summary tables. Increment the Total row in both tables. New items always land in the Backlog column.

**Confirmation:** Report the new item ID and title.

---

## Rules

- **Append-only.** Never remove or reorder existing items. New items go at the end of both the table and details section.
- **Priority is always `—` for new items.** Prioritization happens separately.
- **Status is always `backlog` for new items.**
- **One idea per invocation.** If the user has multiple ideas, tell them to run the command again.

## Error Handling

| Scenario | Action |
|----------|--------|
| `IMPROVEMENTS.md` not found | Look for it at the atelier plugin root. If not found, STOP and report. |
| User cancels at confirmation | Abort without writing. |
| Duplicate detected | Show existing item and confirm before proceeding. |
