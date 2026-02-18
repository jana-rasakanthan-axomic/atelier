# MCP Strategy

How to manage Model Context Protocol servers to minimize context bloat while maintaining access to external systems.

---

## Problem

MCP tools inject their schemas into every conversation turn. Each MCP server adds tool definitions to the system prompt, consuming context window budget even when those tools aren't needed. With multiple servers (Atlassian, GitHub, Slack, etc.), this overhead compounds.

---

## Principles

1. **Minimal active servers.** Only enable MCP servers needed for the current workflow phase.
2. **Prefer CLI over MCP when equivalent.** `gh pr view` costs zero context vs. GitHub MCP tool schemas in every turn.
3. **Batch MCP operations.** Fetch all needed data in one burst, save to context files, then work from local files.
4. **Gate MCP behind commands.** Only `/gather` and `/daily-brief` should trigger MCP calls. Build/review/plan work from local files.

---

## Current MCP Usage Map

| Command | MCP Server | Operation | Alternative |
|---------|-----------|-----------|-------------|
| `/gather` | Atlassian | Fetch Jira issues, Confluence pages | None (MCP required) |
| `/gather` | GitHub | Fetch issues, PRs | `gh issue view`, `gh pr view` |
| `/daily-brief` | Atlassian | Fetch assigned Jira tickets | None (MCP required) |
| `/daily-brief` | GitHub | Fetch PR reviews, checks | `gh pr list`, `gh pr checks` |
| `/review --push` | GitHub | Post PR comments | `gh pr comment`, `gh api` |
| `/workstream pr-check` | GitHub | Check PR status | `gh pr view`, `gh pr checks` |

---

## Strategy: Gather-Once, Work-Locally

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│  /gather    │────▶│ .claude/     │────▶│ /plan, /build,  │
│  (MCP calls)│     │ context/*.md │     │ /review (local) │
└─────────────┘     └──────────────┘     └─────────────────┘
      ▲                                          │
      │                                          │
      └── Only re-fetch if context is stale ─────┘
```

**Rule:** After `/gather` writes a context file, all downstream commands (`/plan`, `/build`, `/fix`, `/review`) read from local `.claude/context/*.md` files. They never call MCP directly.

---

## Server Configuration Tiers

### Tier 1 — Always Enabled
Servers with low schema overhead and high-frequency use:

| Server | Schema Cost | Usage Frequency | Verdict |
|--------|------------|-----------------|---------|
| Atlassian (Jira + Confluence) | Medium (~30 tools) | High (gather, daily-brief) | **Enable** — core workflow |

### Tier 2 — Prefer CLI
Servers where a CLI equivalent exists with zero context cost:

| Server | Schema Cost | CLI Alternative | Verdict |
|--------|------------|-----------------|---------|
| GitHub | Medium | `gh` CLI (already in permissions) | **Prefer CLI** — use `gh` commands |

### Tier 3 — On-Demand Only
Servers for specialized workflows, disabled by default:

| Server | Schema Cost | Use Case | Verdict |
|--------|------------|----------|---------|
| Slack | High | Notifications | **Disable** — use webhooks instead |
| Database | High | Direct queries | **Disable** — use scripts |
| Browser | High | Web scraping | **Disable** — use `WebFetch` tool |

---

## Implementation Patterns

### Pattern 1: CLI-First for GitHub

Replace MCP GitHub calls with `gh` CLI in commands that interact with GitHub:

```bash
# Instead of MCP tool call:
gh pr view 123 --json title,body,reviews,comments
gh issue view 456 --json title,body,labels,assignees
gh pr checks 123
gh pr comment 123 --body "Review feedback..."
```

This is already supported — `Bash(gh pr:*)` and `Bash(gh issue:*)` are in permissions.

### Pattern 2: Context File Caching

When `/gather` fetches from MCP, it writes to `.claude/context/`. Add cache awareness:

```
.claude/context/
├── PROJ-123.md              # Jira ticket (fetched via MCP)
├── gh-repo-pr-456.md        # GitHub PR (fetched via gh CLI)
├── confluence-789.md        # Confluence page (fetched via MCP)
└── .cache-manifest.json     # Timestamps for staleness checks
```

Commands check `.cache-manifest.json` before re-fetching. Default TTL: 15 minutes.

### Pattern 3: MCP Call Batching

When `/daily-brief` needs data from multiple sources, batch all MCP calls at the start of Stage 2 (Gather), then process locally:

```
Stage 2a: Batch fetch (all MCP calls)
  → Jira: assigned tickets
  → Confluence: recent updates
  → GitHub (CLI): PR statuses

Stage 2b: Process locally (no MCP)
  → Synthesize from fetched data
  → Cross-reference with worklogs
  → Generate brief
```

### Pattern 4: Selective MCP Loading

For future Claude Code versions that support dynamic MCP server loading, the toolkit templates prepare for this:

```yaml
# templates/mcp-settings.json — per-command MCP needs
gather:
  required: [atlassian]
  optional: [github]  # prefer gh CLI
daily-brief:
  required: [atlassian]
  optional: []
build:
  required: []
  optional: []
review:
  required: []
  optional: [github]  # only for --push mode
```

---

## Context Window Budget

Rough estimates of MCP schema overhead per server:

| Server | Tool Count | Est. Tokens | % of 200k Window |
|--------|-----------|-------------|-------------------|
| Atlassian | ~30 tools | ~8,000 | 4% |
| GitHub MCP | ~20 tools | ~5,000 | 2.5% |
| Slack MCP | ~15 tools | ~4,000 | 2% |
| **Total (all on)** | **~65** | **~17,000** | **8.5%** |
| **Recommended (Atlassian only)** | **~30** | **~8,000** | **4%** |

Keeping only Atlassian MCP active and using `gh` CLI for GitHub saves ~5,000 tokens per turn — roughly 2.5% of context window, which compounds across long sessions.

---

## Action Items

1. **Keep Atlassian MCP enabled** — no CLI alternative for Jira/Confluence
2. **Use `gh` CLI for all GitHub operations** — already permitted, zero context overhead
3. **Disable any future MCP servers by default** — only enable when a command explicitly needs them
4. **Add cache-manifest to `/gather`** — prevent redundant MCP calls in the same session
5. **Document MCP needs per command** — update `templates/mcp-settings.json`

---

*See also: `templates/mcp-settings.json` for per-command MCP requirements.*
