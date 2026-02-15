# Smart Context Loading

On-demand reference loading pattern for commands and skills.

---

## Problem

Loading all reference material upfront wastes context window tokens and dilutes focus. Most tasks only need one or two specific reference files. Eager loading of everything under `docs/`, `skills/`, and `profiles/` is wasteful and reduces output quality.

## Pattern

**Load nothing by default. Load precisely what you need, when you need it.**

### Step 1: Identify the Topic

Before loading any reference file, determine what the user actually needs help with:

- What command or workflow are they running?
- What error or question did they raise?
- What phase of the lifecycle are they in?

### Step 2: Consult the Topic Index

Check `docs/reference/topic-index.md` to find the file that covers the identified topic. The index maps common questions, errors, and workflow stages to specific files.

### Step 3: Load On-Demand

Use `Read` to load only the matched file(s). Typical cases require one file; complex cases may require two or three.

### Step 4: Act on the Content

Use the loaded material to answer the question, resolve the error, or guide the workflow. Do not summarize the reference back to the user unless they asked for an explanation.

---

## Rules

1. **Never preload** -- Do not read `docs/`, `skills/`, or `profiles/` directories at session start
2. **One file at a time** -- Load the most specific file first; only load additional files if the first does not resolve the question
3. **Prefer leaf files** -- Load `skills/git-workflow/worktree-setup.md` rather than `skills/git-workflow/SKILL.md` when the question is about worktrees
4. **Reference files are read-only** -- Commands should read reference material, never modify it
5. **Profile files are context-loaded too** -- When a command needs stack-specific details, load the active profile file on-demand rather than embedding profile content in the command

---

## Examples

| Scenario | Action |
|----------|--------|
| User asks "how do worktrees work?" | Load `skills/git-workflow/worktree-setup.md` |
| `/build` encounters a TDD hook error | Load `docs/manuals/getting-started.md` (Troubleshooting section) |
| User runs `/design` for a new endpoint | Load active profile file for layer conventions |
| Workstream dependency cycle detected | Load `skills/workstream/reference/build-json-examples.md` |
| User asks about MCP setup | Load `docs/manuals/mcp-setup.md` (if it exists) |

---

## Anti-Patterns

- **Preloading all skills** at the start of `/build` -- only load the skill for the current TDD stage
- **Reading the entire CLAUDE.md** to answer a narrow question -- use Grep to find the relevant section first
- **Loading profile + reference + examples** all at once -- start with the profile, add references only if needed
