---
name: author
description: Create agents, skills, and commands following Anthropic best practices
allowed-tools: Read, Write, Edit, Grep, Glob
---

# /author

Create or improve agents, skills, or commands.

## Input Formats

- `/author agent "name" "description"` - Create agent
- `/author skill "name" "description"` - Create skill
- `/author command "name" "description"` - Create command
- `/author improve <path>` - Improve existing
- `/author validate <path>` - Validate only

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
4. **Validate** - Apply checklist, present results

### Improve Mode

1. **Analyze** - Assess against checklist
2. **Propose** - Present changes for approval
3. **Apply** - Make approved changes
4. **Verify** - Re-validate

### Validate Mode

1. **Analyze** - Run through checklist
2. **Report** - Present results, no modifications

## Agent Used

| Agent | Purpose |
|-------|---------|
| Author | Generate and validate agents, skills, commands |

## Skill Used

| Skill | Purpose |
|-------|---------|
| `skills/authoring/` | Templates, checklists, best practices |
