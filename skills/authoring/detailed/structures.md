# Agent, Skill, and Command Structures

Detailed reference for agent, skill, and command structures. Read if SKILL.md overview isn't sufficient.

## Skill Structure

```
skill-name/
├── SKILL.md              # < 500 lines, metadata + overview
├── detailed/             # Expanded guidance for Haiku fallback
├── patterns/             # Detailed patterns (optional)
├── templates/            # Code templates (optional)
├── checklists/           # Validation checklists (optional)
└── scripts/              # Executable scripts (optional)
```

### SKILL.md Template

```markdown
---
name: skill-name
description: What it does. When to use it.
allowed-tools: Read, Write, Edit, Grep, Glob
---

# Skill Name

Brief description.

## When to Use
- Trigger 1
- Trigger 2

## When NOT to Use
**Only for [specific purpose].** Do not use for any other purpose.

## Progressive Disclosure

| Topic | File |
|-------|------|
| Detail A | `file-a.md` |
| Detail B | `file-b.md` |

## Quick Reference
[Key rules as bullet points]
```

## Agent Structure

```markdown
---
name: agent-name
description: What this agent does
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(specific:*)
---

# Agent Name

## When to Use
## When NOT to Use
## Workflow
## Skills Used
## Output Format
## Tools Used
## Scope Limits
```

## Command Structure

```markdown
---
name: command-name
description: What this command does
allowed-tools: [inherited from agents]
---

# /command-name

## Input Formats
## When to Use
## When NOT to Use
## Workflow (max 4-5 stages)
## Agents Used
## Skills Used
```

## Naming Conventions

**Skills** - gerund form (verb + -ing):
- `processing-pdfs`
- `analyzing-spreadsheets`

**Agents** - noun/verb:
- `builder`, `planner`, `reviewer`

**Commands** - imperative verb:
- `build`, `review`, `analyze`

## Core Principles Summary

1. **Concise is key** - Only add context Claude doesn't have
2. **Degrees of freedom** - Match specificity to task fragility
3. **Progressive disclosure** - SKILL.md < 500 lines, details in linked files
4. **Third person** - "Processes files", not "I process"
5. **One level deep** - No nested file chains
