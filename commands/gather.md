---
name: gather
description: Gather context from Jira, Confluence, or GitHub and save to file
model_hint: haiku
allowed-tools: Write, mcp__atlassian__getJiraIssue, mcp__atlassian__getConfluencePage, mcp__atlassian__getJiraIssueRemoteIssueLinks, Bash(gh:*)
---

# /gather

Gather context from external sources (Jira, Confluence, GitHub) and save to `.claude/context/` for review/edit before use.

## MCP Availability Check

Before fetching from Jira or Confluence, check if MCP tools are available (look for `mcp__atlassian__getJiraIssue` in your tool list).

- **MCP available:** Proceed with Jira/Confluence fetching as described below.
- **MCP not available and source is Jira/Confluence:** STOP. Tell the user: "Atlassian MCP server is not configured. See `docs/manuals/mcp-setup.md` for setup instructions." Do not attempt to fetch.
- **MCP not available and source is GitHub or plain text:** Proceed normally -- these do not require MCP.

## Input Formats

```bash
/gather PROJ-123                    # Jira ticket by ID
/gather https://...atlassian.net/browse/PROJ-123  # Jira URL
/gather https://...atlassian.net/wiki/spaces/*/pages/*  # Confluence page
/gather https://github.com/org/repo/issues/123   # GitHub issue
/gather https://github.com/org/repo/pull/456     # GitHub PR
/gather "Add user export with CSV support"        # Structure user input
/gather PROJ-123 PROJ-124           # Multiple sources combined
/gather --dry-run PROJ-123          # Preview what will be fetched
/gather --refresh PROJ-123          # Force refetch (ignore cache)
/gather --output custom/path.md     # Custom output path
```

## When to Use

- Before planning or implementing from a Jira ticket
- When you need requirements from Confluence or GitHub
- To format unstructured requirements into structured context

## When NOT to Use

- Context is already in conversation → use directly
- Working from local requirements → no external fetch needed

## Output Location

Default: `.claude/context/`

| Source Type | Filename Pattern |
|-------------|------------------|
| Jira ticket | `PROJ-123.md` |
| Confluence page | `confluence-{pageId}.md` |
| GitHub issue | `gh-{repo}-issue-{number}.md` |
| GitHub PR | `gh-{repo}-pr-{number}.md` |
| User input | `{derived-from-content}.md` |
| Multiple sources | `{first-source}-combined.md` |

## Workflow (3 Stages)

### Stage 1: Detect & Fetch

If `--dry-run`: report what would be fetched and stop.

| Pattern | Source | Tool |
|---------|--------|------|
| `[A-Z]+-\d+` | Jira ticket | `mcp__atlassian__getJiraIssue` |
| `*/browse/[A-Z]+-\d+` | Jira URL | `mcp__atlassian__getJiraIssue` |
| `*/wiki/spaces/*/pages/\d+` | Confluence | `mcp__atlassian__getConfluencePage` |
| `github.com/*/issues/\d+` | GitHub issue | `gh issue view` |
| `github.com/*/pull/\d+` | GitHub PR | `gh pr view` |
| Plain text | User input | Parse & structure |

For all sources: detect contract specifications (code blocks with type definitions, interface signatures), preserve formatting, organize by layer.

### Stage 2: Format & Write

Write context file with sections: Summary, Description, Contract Specifications (Interface/Business Logic/Data Access), Tasks, Acceptance Criteria, Additional Info (status, assignee, labels, linked issues, TDD/ADR refs), Next Steps.

### Stage 3: Confirm

Report file created, content summary, and next steps (`/specify`, `/design`, `/plan`, `/build`).

## Error Handling

| Scenario | Action |
|----------|--------|
| Source not found | Report, suggest verifying ticket/page exists |
| Authentication failed | Report, link to MCP configuration docs |
| Multiple sources, one fails | Continue with successful sources, note partial results |

## Scope Limits

- Max sources per gather: 5
- Context file size: aim for <2000 lines
- Timeout: 5 minutes per external source
- Cache: 15 minutes (override with `--refresh`)
