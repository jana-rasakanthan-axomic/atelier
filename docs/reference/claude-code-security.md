# Claude Code Security & Data Privacy

Tech note covering Claude Code built-in commands that transmit data externally, passive telemetry, and how to lock things down.

---

## Commands That Send Data Externally

### `/bug` — Highest Risk

- Sends your **entire conversation history** (all prompts, responses, code, file contents) to Anthropic
- Retained for **5 years**
- Easy to trigger accidentally
- Disable: `export DISABLE_BUG_COMMAND=1`

### `/feedback` (Session Quality Survey) — Low Risk

- Only sends a numeric rating (1, 2, or 3) — no conversation content
- Appears as "How is Claude doing this session?" prompt
- Disable: `export CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1`

---

## Passive Data Collection (Always Running)

These run in the background without explicit user action.

| Service | What It Sends | What It Does NOT Send | Disable |
|---------|--------------|----------------------|---------|
| **Statsig Telemetry** | Latency, reliability, usage metrics | Code, file paths, conversation content | `DISABLE_TELEMETRY=1` |
| **Sentry Error Reporting** | Error stack traces, system diagnostics | Code, conversation content | `DISABLE_ERROR_REPORTING=1` |

Both use TLS in transit and 256-bit AES at rest.

---

## Local Commands Worth Knowing

These don't transmit data but can expose information locally:

| Command | What It Does | Watch Out For |
|---------|-------------|---------------|
| `/export` | Dumps full conversation to a file | Don't commit exported files to repos |
| `/copy` | Copies last response to clipboard | Other apps can read clipboard |

---

## Kill Switch: Disable All Non-Essential Traffic

```bash
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

This single variable disables **all four** external services at once:
- Statsig telemetry
- Sentry error reporting
- `/bug` command
- Feedback surveys

### Does It Affect Normal Functionality?

**No.** Core functionality is completely unaffected:
- All conversations with Claude (LLM API calls work normally)
- All tool use (file editing, bash, search, etc.)
- Every slash command except `/bug`
- MCP servers, hooks, everything else

The only user-visible changes are `/bug` stops working and the feedback survey disappears.

---

## Provider Defaults

| Provider | Non-Essential Traffic |
|----------|----------------------|
| Claude API (direct) | **Enabled** by default |
| AWS Bedrock | Disabled by default |
| Google Vertex AI | Disabled by default |
| Microsoft Foundry | Disabled by default |

If you're on Bedrock, Vertex, or Foundry, you're already locked down.

---

## Recommended Setup

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, or equivalent):

```bash
# Option A: Kill everything at once
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# Option B: Selective (if you want telemetry but not /bug)
export DISABLE_BUG_COMMAND=1
export CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1
# export DISABLE_TELEMETRY=1           # uncomment if desired
# export DISABLE_ERROR_REPORTING=1     # uncomment if desired
```

---

## Data Retention Summary

| User Type | Retention |
|-----------|-----------|
| Consumer (Free/Pro/Max) with training opt-in | 5 years |
| Consumer without training opt-in | 30 days |
| Commercial (Team/Enterprise/API) | 30 days (or zero if configured) |

---

*Last updated: 2026-02-18*
