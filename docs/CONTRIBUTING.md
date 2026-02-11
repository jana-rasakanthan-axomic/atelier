# Contributing to Atelier

How to extend Atelier with new profiles, commands, agents, and skills.

Before you begin, read `docs/ARCHITECTURE.md` for the overall design and `CLAUDE.md` for quick-reference tables of all components.

---

## Core Rule: Process vs Stack Separation

| Contains PROCESS (never hardcode tools) | Contains STACK (never contain process logic) |
|----------------------------------------|---------------------------------------------|
| Commands (`commands/*.md`) | Profiles (`profiles/*.md`) |
| Agents (`agents/*.md`) | Profile patterns (`profiles/*/patterns/`) |
| Skills (`skills/*/`) | Profile style/testing dirs |

Commands, agents, and skills use `${profile.tools.*}` references. Profiles define the concrete tool commands. If you find yourself writing `pytest`, `ruff`, `eslint`, or any tool name inside a command or agent, stop and move it to the profile.

---

## Adding a New Profile

Profiles answer "which tools do I use?" for a given technology stack. See `docs/PROFILES.md` for the full specification.

### Steps

| # | Action | Details |
|---|--------|---------|
| 1 | Copy the template | `cp profiles/_template.md profiles/{name}.md` |
| 2 | Fill in all sections | Replace every `[...]` placeholder and `# TODO:` comment. See `profiles/_template.md` for required sections: Detection, Architecture Layers, Build Order, Quality Tools, Allowed Bash Tools, Test Patterns, Naming Conventions, Code Patterns, Style Limits, Dependencies, Project Structure. |
| 3 | Create patterns directory | `mkdir -p profiles/{name}/patterns/` and add one `.md` file per architecture layer (e.g., `router.md`, `service.md`, `repository.md`). |
| 4 | Add detection markers | Edit `scripts/resolve-profile.sh` to add a new detection block following the existing pattern (check marker files, run content match, echo profile name). |
| 5 | Register in CLAUDE.md | Add a row to the "Built-in Profiles" table with the profile name, marker file, and domain. |
| 6 | Validate | Run `/init` in a project that matches the new profile. Confirm auto-detection selects it correctly. |

### Profile Completeness Check

```
profiles/{name}.md          # Main profile file (all sections filled)
profiles/{name}/patterns/   # At least one pattern file per layer
scripts/resolve-profile.sh  # Detection block added
CLAUDE.md                   # Profile registered in table
```

### Example: Existing Profile Reference

Study `profiles/python-fastapi.md` and `profiles/python-fastapi/patterns/` as the most complete example.

---

## Adding a New Command

Commands define process workflows (stages, gates, user interaction). They invoke agents and read the active profile for tool commands.

### Steps

| # | Action | Details |
|---|--------|---------|
| 1 | Create the file | `commands/{name}.md` |
| 2 | Add YAML frontmatter | Required fields: `name`, `description`, `allowed-tools`. See example below. |
| 3 | Define stages | Break the workflow into numbered stages with clear inputs, actions, and outputs. |
| 4 | Declare agent invocations | Specify which agents the command delegates to and when. |
| 5 | Add input formats | Document all supported invocation patterns (file path, description, flags). |
| 6 | Register in CLAUDE.md | Add a row to the "Quick Reference -- Commands" table. |
| 7 | Run the checklist | Use `skills/authoring/checklists/command-checklist.md` to validate. |

### Frontmatter Template

```yaml
---
name: {name}
description: {One-line description of what this command does}
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(git:*), Bash(${profile.test_runner}), Bash(${profile.linter})
---
```

Tool permissions use `${profile.*}` references, never hardcoded tool names. Only request permissions the command actually needs (principle of minimum permissions).

### Key Rules

- Commands must be **process-only**. No `pytest`, `ruff`, `flutter test`, etc.
- Use `${profile.tools.test_runner}`, `${profile.tools.linter}`, `${profile.tools.type_checker}`.
- Include "When to Use" and "When NOT to Use" sections.
- Define approval gates where user confirmation matters.
- Keep under 500 lines; split into supporting files if longer.

### Example: Existing Command Reference

Study `commands/build.md` for a full-featured command with stages, agent delegation, and profile-aware tool references.

---

## Adding a New Agent

Agents define roles (who does the work) and orchestration logic (state machines, decision points). Commands invoke agents; users do not invoke agents directly.

### Steps

| # | Action | Details |
|---|--------|---------|
| 1 | Create the file | `agents/{name}.md` |
| 2 | Define the role | What this agent does, when it is invoked, what skills it uses. |
| 3 | List tools and skills | Which tools the agent needs and which skill directories it reads. |
| 4 | Make it profile-aware | The agent must read the active profile for tool commands. Never hardcode tools. |
| 5 | Define workflows | State machines, decision trees, or stage sequences with clear transitions. |
| 6 | Add escalation rules | When does the agent stop and ask the user for help? |
| 7 | Register in CLAUDE.md | Add a row to the "Quick Reference -- Agents" table. |
| 8 | Run the checklist | Use `skills/authoring/checklists/agent-checklist.md` to validate. |

### Key Rules

- Agents read `${profile.*}` for every tool invocation.
- Agents reference skills by directory path (e.g., `skills/building/`, `skills/testing/`).
- Include a "Permission Level" (Read-only, Read + Write, Full).
- Keep under 500 lines.
- Use third-person descriptions ("Analyzes code", not "I analyze code").

### Example: Existing Agent Reference

Study `agents/builder.md` for TDD state machine and profile-aware tool usage, or `agents/reviewer.md` for multi-persona review logic.

---

## Adding a New Skill

Skills define knowledge (how to do a step well). They provide patterns, templates, and checklists that agents consume.

### Steps

| # | Action | Details |
|---|--------|---------|
| 1 | Create the directory | `skills/{name}/` |
| 2 | Write SKILL.md | The entry point. Serves as overview and navigation to sub-files. |
| 3 | Add progressive disclosure files | Break detailed content into separate files (e.g., `patterns/`, `templates/`, `checklists/`). |
| 4 | Keep it process-only | Patterns come from profiles. Skills describe the process pattern (e.g., AAA test structure), not the stack-specific implementation. |
| 5 | Register in CLAUDE.md | Add a row to the "Quick Reference -- Skills" table. |
| 6 | Run the checklist | Use `skills/authoring/checklists/skill-checklist.md` to validate. |

### SKILL.md Structure

```markdown
# Skill: {Name}

{One paragraph: what this skill provides and when agents use it.}

## When to Use
- {Trigger 1}
- {Trigger 2}

## When NOT to Use
- {Alternative 1}

## Contents
| File | Purpose |
|------|---------|
| `patterns/foo.md` | {description} |
| `templates/bar.md` | {description} |
```

### Key Rules

- SKILL.md is the **overview only** (under 500 lines). Details go in sub-files.
- Sub-files are referenced one level deep. No nested file chains.
- Skills never contain framework-specific code. That belongs in `profiles/{name}/patterns/`.
- Include "When to Use" and "When NOT to Use" sections.

### Example: Existing Skill Reference

Study `skills/review/SKILL.md` for persona-based structure, or `skills/authoring/SKILL.md` for progressive disclosure with templates and checklists.

---

## Authoring Checklists

Before finalizing any component, run the appropriate checklist:

| Component | Checklist |
|-----------|-----------|
| Command | `skills/authoring/checklists/command-checklist.md` |
| Agent | `skills/authoring/checklists/agent-checklist.md` |
| Skill | `skills/authoring/checklists/skill-checklist.md` |

These checklists verify structure, content quality, permissions, and testing readiness.

---

## Style Guidelines

- **Markdown format** for all component files (commands, agents, skills, profiles).
- **YAML frontmatter** for commands (name, description, allowed-tools).
- **Tables** for structured data (layers, tools, conventions).
- **Code blocks** for examples, templates, and tool commands.
- **Third person** for descriptions ("Generates reports", not "I generate").
- **Under 500 lines** per file. Split if longer.
- **One level deep** for file references. No chains of includes.

---

## Testing Your Changes

1. **Profile detection** -- Run `/init` in a matching project directory. Verify the correct profile is selected.
2. **Command execution** -- Run the command with at least 3 different input formats.
3. **Agent behavior** -- Verify the agent reads the active profile and uses `${profile.*}` tool references.
4. **Skill consumption** -- Verify agents can find and read the skill's SKILL.md and sub-files.

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Hardcoding `pytest` in a command | Use `${profile.tools.test_runner}` |
| Putting process logic in a profile | Move to the command or agent |
| Nesting file references 3+ levels deep | Flatten to one level from the entry point |
| Creating a skill with only SKILL.md | Add sub-files for progressive disclosure |
| Forgetting to register in CLAUDE.md | Always add a row to the relevant table |
| Skipping the authoring checklist | Run it before marking the component ready |
