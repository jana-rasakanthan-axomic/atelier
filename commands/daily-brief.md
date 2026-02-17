---
name: daily-brief
description: Start your day — aggregate PR reviews, worklog next steps, and workstream status into an actionable checklist
model_hint: haiku
allowed-tools: Read, Write, Grep, Glob, Bash(gh:*), Bash(git:*), Bash(date:*), Bash(mkdir:*), Bash(code:*), Bash(open:*), Bash(scripts/daily-brief-gather.sh:*), Bash(scripts/resolve-config.sh:*), mcp__atlassian__searchJiraIssuesUsingJql, mcp__atlassian__searchConfluenceUsingCql, mcp__atlassian__getAccessibleAtlassianResources
---

# /daily-brief

Start your engineering day with a structured checklist. Aggregates PR reviews, worklog carry-forward items, workstream status, and optionally Jira/Confluence context into a single actionable brief.

## Input Formats

```bash
/daily-brief                       # Default (senior level)
/daily-brief --level ic            # IC-focused (code tasks only)
/daily-brief --level staff         # Staff-focused (adds cross-team deps)
/daily-brief --dry-run             # Preview without writing file
/daily-brief --path ~/custom/dir/  # Override output directory
```

## When to Use

- Start of each workday to establish priorities
- After returning from time off to catch up
- Before standup to review what needs attention

## When NOT to Use

- Mid-session — use `/worklog` to checkpoint progress instead
- For detailed investigation of a single PR or ticket — use `/gather`

---

## Workflow (4 Stages)

### Stage 1: Configure

Resolve configuration and prepare the output location.

**Resolve settings:**
```bash
LEVEL="${--level flag or $(scripts/resolve-config.sh get daily_brief.level 2>/dev/null) or 'senior'}"
OUTPUT_DIR="${--path flag or $(scripts/resolve-config.sh get daily_brief.output_dir 2>/dev/null) or ~/worklogs/daily-briefs}"
EDITOR="$(scripts/resolve-config.sh get daily_brief.editor 2>/dev/null || echo 'code')"
REPOS="$(scripts/resolve-config.sh get daily_brief.repos 2>/dev/null || echo '')"
JIRA_JQL="$(scripts/resolve-config.sh get daily_brief.jira_jql 2>/dev/null || echo '')"
CONFLUENCE_SPACES="$(scripts/resolve-config.sh get daily_brief.confluence_spaces 2>/dev/null || echo '')"
CONFLUENCE_LABELS="$(scripts/resolve-config.sh get daily_brief.confluence_labels 2>/dev/null || echo '')"
CONFLUENCE_DAYS="$(scripts/resolve-config.sh get daily_brief.confluence_days 2>/dev/null || echo '1')"
DATE="$(date '+%Y-%m-%d')"
OUTPUT_FILE="$OUTPUT_DIR/$DATE.md"
```

**Create output directory if needed:**
```bash
mkdir -p "$OUTPUT_DIR"
```

**Check for existing brief:** If `$OUTPUT_FILE` already exists, inform the user and ask whether to overwrite or append.

---

### Stage 2: Gather

Collect data from all available sources. Each source degrades gracefully if unavailable.

**GitHub data (via gather script):**
```bash
scripts/daily-brief-gather.sh github      # PRs awaiting review, authored PRs, failed CI
scripts/daily-brief-gather.sh worktrees   # Uncommitted work across git worktrees
scripts/daily-brief-gather.sh worklog     # "Next steps" from most recent worklog entry
scripts/daily-brief-gather.sh repos       # Recent merge activity in configured repos
```

If `REPOS` is empty, the script auto-detects from the current directory's git remote.

**Jira (via MCP — optional):**

Check if MCP tools are available (look for `mcp__atlassian__searchJiraIssues` in your tool list).

- **MCP available:**
  - If `JIRA_JQL` is set: use it as the JQL query directly.
  - If `JIRA_JQL` is empty: use default `assignee = currentUser() AND status != Done`.
- **MCP not available:** Skip this section. Add a note: `> Jira: Not configured. See docs/manuals/mcp-setup.md for setup.`

**Confluence (via MCP — optional):**

- **MCP available:**
  - Build a CQL query from config filters:
    - If `CONFLUENCE_SPACES` is set: add `space in ("SPACE1","SPACE2")` (split on comma).
    - If `CONFLUENCE_LABELS` is set: add `label in ("label1","label2")` (split on comma).
    - Always add: `lastModified >= now("-${CONFLUENCE_DAYS}d")`.
    - If no spaces or labels are configured: skip Confluence. Add a note: `> Confluence: No spaces configured. Set daily_brief.confluence_spaces in config.`
- **MCP not available:** Skip this section. Add a note: `> Confluence: Not configured. See docs/manuals/mcp-setup.md for setup.`

**Workstream status:**

Check for `.atelier/workstreams/` files. If found, parse ticket status. If not, skip this section.

---

### Stage 3: Synthesize

Compose the brief using the gathered data. Adjust sections based on `--level`.

**Output Template:**

```markdown
# Daily Brief: {{DATE}}

## Action Items (Must Do)
- [ ] **PR Review:** [Title] (Waiting since [Time]) - [Link]
- [ ] **Unblock:** [Ticket-ID] [Title] - [Link]
- [ ] **Fix Build:** [Repo Name] - [Link]

## Carry Forward (From Last Session)
- [ ] [Next step items from worklog]

## In Progress
| Item | Branch | Status | Notes |
|------|--------|--------|-------|
| ... | ... | ... | ... |

## Knowledge & Context (Read/Verify)
- [ ] **Read:** [Page Title] (Updated by [Author]) - [Link]
- [ ] **Check:** [Repo] had [N] merges yesterday

## Workstream Status
| Ticket | Status | Branch | PR |
|--------|--------|--------|----|
| ... | ... | ... | ... |

## Ad-hoc Notes
_Space for notes during the day._

---
*Generated by /daily-brief at {{TIME}}*
```

**Level adjustments:**

| Section | IC | Senior (default) | Staff |
|---------|-----|-------------------|-------|
| Action Items | Code tasks only | + PR reviews, build fixes | + cross-team blockers |
| Carry Forward | Yes | Yes | Yes |
| In Progress | Yes | Yes | Yes |
| Knowledge & Context | Skip | Yes | + architecture docs |
| Workstream Status | Skip | If workstreams exist | Always (expand deps) |
| Ad-hoc Notes | Yes | Yes | Yes |

**Guidelines:**
- Order action items by urgency: build failures > blocking PRs > assigned tickets
- Include links for every actionable item
- Keep the brief scannable — no prose paragraphs
- Omit sections that have no data (don't show empty tables)

---

### Stage 4: Deliver

Write the file and open it.

- If `--dry-run`: Display the composed brief and **STOP** — do not write.
- Write to `$OUTPUT_FILE`
- Open in editor: `$EDITOR "$OUTPUT_FILE"` (fallback to `open "$OUTPUT_FILE"` on macOS)
- Print confirmation:
  ```
  Daily brief written to: $OUTPUT_FILE
  Level: $LEVEL | Sources: GitHub, Worklog[, Jira, Confluence]
  ```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `gh` CLI not authenticated | Skip GitHub sections, note: "Run `gh auth login` to enable GitHub integration" |
| No git repo in current dir | Use configured repos list or skip repo-specific data |
| MCP tools unavailable | Skip Jira/Confluence, add setup note |
| No worklog exists | Skip "Carry Forward" section |
| No workstreams configured | Skip "Workstream Status" section |
| Output directory not writable | Report error, suggest checking permissions |

## Scope Limits

- One brief per day per output directory (overwrite or append on re-run)
- Does not create tickets, PRs, or take action — purely informational
- Jira/Confluence queries are read-only
- GitHub queries use authenticated user's context only
