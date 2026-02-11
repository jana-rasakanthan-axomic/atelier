---
name: authoring
description: Create agents, skills, and commands following Anthropic best practices. Use when creating or improving agents, skills, or commands.
allowed-tools: Read, Write, Edit, Grep, Glob
---

# Authoring Skill

Create and validate agents, skills, and commands.

## When to Use

- Creating new agents, skills, or commands
- Improving existing agents, skills, or commands
- Validating agents, skills, or commands

## When NOT to Use

**Only for agents, skills, or commands.** Do not use for any other purpose.

## Progressive Disclosure

### Templates

| Type | File |
|------|------|
| Skill | `templates/skill.md` |
| Agent | `templates/agent.md` |
| Command | `templates/command.md` |

### Checklists

| Type | File |
|------|------|
| Skill | `checklists/skill-checklist.md` |
| Agent | `checklists/agent-checklist.md` |
| Command | `checklists/command-checklist.md` |

### Reference

| Topic | File |
|-------|------|
| Core Principles | `best-practices.md` |
| Multi-Model | `model-optimization.md` |
| Structures & Examples | `detailed/structures.md` |

## YAML Frontmatter Rules

### Name
- Max 64 chars, lowercase + hyphens only
- No "anthropic" or "claude", no XML tags

### Description
- Max 1024 chars, non-empty, third person
- Include WHAT it does AND WHEN to use it
