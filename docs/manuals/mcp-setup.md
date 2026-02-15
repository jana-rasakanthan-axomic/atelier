# MCP Server Setup

## Overview

MCP (Model Context Protocol) servers let Claude Code connect to external services like Jira and Confluence. The `/gather` command uses MCP to fetch tickets, wiki pages, and linked issues directly into your workflow -- no copy-pasting required.

Without MCP servers configured, `/gather` can only process GitHub sources (via the `gh` CLI) and plain-text input. To unlock Jira and Confluence support, you need to configure the Atlassian MCP server.

## Prerequisites

- Node.js 18+ installed (for `npx`)
- An Atlassian account with API access
- An Atlassian API token

## Step 1: Generate an Atlassian API Token

1. Go to [Atlassian API token management](https://id.atlassian.com/manage-profile/security/api-tokens).
2. Click **Create API token**.
3. Give it a label (e.g., "Claude Code MCP").
4. Copy the token. You will not be able to see it again.

Store the token securely. Do not commit it to version control.

## Step 2: Add the Atlassian MCP Server

Copy the `mcpServers` block from `templates/mcp-settings.json` into your Claude Code settings file.

**Project-level** (recommended -- keeps config per-project):
```
.claude/settings.json
```

**Global** (applies to all projects):
```
~/.claude/settings.json
```

The minimum configuration:

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "@anthropic/atlassian-mcp-server"],
      "env": {
        "JIRA_API_URL": "https://yourcompany.atlassian.net",
        "CONFLUENCE_API_URL": "https://yourcompany.atlassian.net/wiki",
        "ATLASSIAN_EMAIL": "you@yourcompany.com",
        "ATLASSIAN_API_TOKEN": "your-api-token"
      }
    }
  }
}
```

Replace all placeholder values with your actual credentials.

## Step 3: Restart Claude Code

MCP server configuration is loaded at startup. After editing settings, restart Claude Code for the changes to take effect.

## Step 4: Verify the Connection

Run a simple gather to confirm everything works:

```bash
/gather PROJ-123    # Replace with a real ticket ID from your Jira
```

If the connection is working, you will see the ticket content fetched and saved to `.claude/context/PROJ-123.md`.

## GitHub MCP Server (Optional)

The `gh` CLI handles most GitHub operations (issues, PRs, API calls). A dedicated GitHub MCP server is only needed if you want richer integration. See `templates/mcp-settings.json` for the optional GitHub server block.

## Troubleshooting

**"Authentication failed" error**

- Verify your API token has not expired at [Atlassian token management](https://id.atlassian.com/manage-profile/security/api-tokens).
- Confirm `ATLASSIAN_EMAIL` matches the account that owns the token.
- Check that `JIRA_API_URL` uses `https://` and has no trailing slash.

**"Source not found" error**

- Confirm the ticket ID exists and you have permission to view it.
- Check that the project key in the ticket ID matches your Jira instance.

**MCP server fails to start**

- Run `npx -y @anthropic/atlassian-mcp-server` manually in your terminal to see error output.
- Ensure Node.js 18+ is installed: `node --version`.
- If behind a corporate proxy, ensure `HTTPS_PROXY` is set in your environment.

**Tools not detected by `/gather`**

- Restart Claude Code after editing settings.
- Confirm the server name is `atlassian` (not `jira` or `confluence`). The tool names derive from the server name: `mcp__atlassian__getJiraIssue`.
- Check that the `mcpServers` block is valid JSON (no trailing commas, no comments).

**Confluence URL differs from Jira URL**

If your Confluence is hosted separately from Jira, set `CONFLUENCE_API_URL` to your Confluence base URL (e.g., `https://confluence.yourcompany.com/wiki`).
