# Topic Index

Maps common user questions, errors, and workflow topics to the reference files that should be loaded on-demand.

---

## How to Use

When a user's question or error matches a topic below, load the listed file(s) using `Read`. Load only what is needed -- do not preload.

---

## Index

| Topic | File to Load |
|-------|-------------|
| How do I set up a new project? | `docs/manuals/getting-started.md` |
| How do worktrees work? | `skills/git-workflow/worktree-setup.md` |
| How do I create a branch? | `skills/git-workflow/branch-creation.md` |
| What is the TDD process? | `CLAUDE.md` (TDD section) |
| TDD hook blocking writes | `docs/manuals/getting-started.md` (Troubleshooting) |
| Profile not detected | `docs/manuals/getting-started.md` (First Run) |
| How do I add a new profile? | `docs/PROFILES.md` |
| Workstream dependency error | `skills/workstream/reference/build-json-examples.md` |
| How do workstreams work? | `docs/manuals/workstream.md` |
| Workstream status format | `skills/workstream/schemas/status-json-and-templates.md` |
| How do I write a design doc? | `docs/manuals/design.md` |
| Design examples / patterns | `docs/examples/design-examples.md` |
| Architecture decisions / ADRs | `docs/reference/design-decisions.md` |
| How do I write a braindump? | `docs/manuals/braindump.md` |
| Contributing to the toolkit | `docs/CONTRIBUTING.md` |
| Session management / cleanup | `skills/git-workflow/session-management.md` |
| Git cleanup after PR merge | `skills/git-workflow/cleanup.md` |
| Authoring best practices | `skills/authoring/best-practices.md` |
| Command template / structure | `skills/authoring/templates/command.md` |
| Agent template / structure | `skills/authoring/templates/agent.md` |
| Skill template / structure | `skills/authoring/templates/skill.md` |
| Model optimization tips | `skills/authoring/model-optimization.md` |
| Model/thinking strategy | `docs/reference/model-thinking-strategy.md` |
| MCP strategy / context bloat | `docs/reference/mcp-strategy.md` |
| Toolkit architecture overview | `docs/ARCHITECTURE.md` |

---

## Adding New Entries

When you create a new reference file or manual, add a row to this table mapping the topic to its path. Keep entries sorted by workflow phase (setup, discovery, design, build, review, ship) when possible.
