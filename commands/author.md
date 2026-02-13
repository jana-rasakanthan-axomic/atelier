---
name: author
description: Create agents, skills, and commands following Anthropic best practices
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(scripts/validate-toolkit.sh:*)
---

# /author

Create or improve agents, skills, or commands.

## Input Formats

- `/author agent "name" "description"` - Create agent
- `/author skill "name" "description"` - Create skill
- `/author command "name" "description"` - Create command
- `/author improve <path>` - Improve existing
- `/author improve <path> --loop` - Improve with automated validation loop
- `/author validate <path>` - Validate only
- `/author create ... --loop` - Create then validate-fix loop

## When to Use

- Creating new agents, skills, or commands
- Improving existing agents, skills, or commands
- Validating agents, skills, or commands

## When NOT to Use

**Only for agents, skills, or commands.** Do not use for any other purpose.

## Workflow

### Create Mode

1. **Gather** - Parse type, name, description
2. **Research** - Read similar existing agents, skills, or commands
3. **Generate** - Agent creates using templates
4. **Validate** - Run `scripts/validate-toolkit.sh` on created files, then apply checklist. Present results.

### Improve Mode

1. **Analyze** - Run `scripts/validate-toolkit.sh` on target files, then assess against checklist
2. **Propose** - Present changes for approval
3. **Apply** - Make approved changes
4. **Verify** - Re-run `scripts/validate-toolkit.sh` and re-validate against checklist

### Validate Mode

1. **Analyze** - Run `scripts/validate-toolkit.sh` on target files, then run through checklist
2. **Report** - Present results, no modifications

### Loop Mode (`--loop`)

Automated validation-fix loop using ralph-loop. Available on both create and improve modes.

1. **Resolve profile** - For consistent tooling context
2. **Hydrate prompt** - Load `skills/iterative-dev/prompts/author.md` with context variables:
   - `$TARGET_FILES` — file(s) being authored/improved
   - `$COMPONENT_TYPE` — command | agent | skill
   - `$TOOLKIT_DIR` — toolkit root
   - `$BASE_BRANCH` — for commit context
3. **Launch loop** - `/ralph-loop` with `--completion-promise "AUTHOR COMPLETE"` and `--max-iterations 10`
4. **Strict enforcement** - ralph-loop is required. If unavailable, STOP and report. Do NOT silently fall back to manual mode.

## Agent Used

| Agent | Purpose |
|-------|---------|
| Author | Generate and validate agents, skills, commands |

## Skill Used

| Skill | Purpose |
|-------|---------|
| `skills/authoring/` | Templates, checklists, best practices |
| `skills/iterative-dev/` | Loop prompt template for `--loop` mode |
