# Command Template

Use this template when creating a new user-facing command.

## Command File Template

```markdown
---
name: command-name
description: Brief description of what this command does
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(specific:*)
---

# /command-name

One-line description of what this command does.

## Input Formats

- `/command-name "description"` - From description
- `/command-name .claude/context/FILE.md` - From context file
- `/command-name --option` - With options

## When to Use

- Use case 1
- Use case 2
- Use case 3

## When NOT to Use

**Only for [specific purpose].** Do not use for any other purpose.

## Options

```
/command-name "description"           # Default behavior
/command-name --option1               # Behavior with option1
/command-name --option2 value         # Behavior with option2
/command-name --dry-run               # Preview without executing
```

## Context File Integration

If first argument is a path to `.claude/context/*.md`:
1. Read context file
2. Extract requirements/tasks
3. Use as basis for execution

**Recommended workflow:**
```bash
/gather TICKET-123                       # Create context file
/command-name .claude/context/TICKET-123.md  # Execute from context
```

## Workflow (max 4-5 stages)

### Stage 1: [Name]

**Purpose:** What this stage accomplishes

**Actions:**
1. Action 1
2. Action 2
3. Action 3

**Output:**
```markdown
## Stage 1 Output

[Example output format]
```

### Stage 2: Approve (Required)

**Purpose:** Get user approval before modifications

Present:
- What will be done
- Files to create/modify
- Identified risks

**User confirms or requests changes.**

### Stage 3: [Name]

**Agent:** [Agent name if applicable]

**Actions:**
1. Action 1
2. Action 2
3. Action 3

**Success Criteria:**
- Criterion 1
- Criterion 2

**STOP HERE.** Present results before proceeding.

### Stage 4: [Name]

**Agent:** [Agent name if applicable]

**Actions:**
1. Final validation
2. Generate report

**Output:**
```markdown
## Command Complete

### Summary
[What was done]

### Files Created
- path/to/file1.py
- path/to/file2.py

### Files Modified
- path/to/existing.py

### Next Steps
[What user should do next]
```

## Tools Used

| Tool | Purpose |
|------|---------|
| Read | Examine existing code |
| Write | Create new files |
| Edit | Modify existing files |
| Bash | Run tests, linter |

## Agents Used

| Agent | Stage | Purpose |
|-------|-------|---------|
| Planner | 1 | Create plan |
| Builder | 3 | Implement |
| Verifier | 4 | Validate |

## Skills Used

| Skill | Purpose |
|-------|---------|
| `skills/skill-name/` | Description |

## Scope Limits

- Limit 1
- Limit 2
- For larger scope: split into multiple invocations
```

## Key Principles

### 1. Max 4-5 Stages

Commands should be digestible. If more stages needed, consider:
- Splitting into multiple commands
- Using sub-commands (e.g., `/command sub-action`)

### 2. Approval Gate Before Modifications

**Always** present plan before making changes:
- What will be created/modified
- Risks identified
- User confirms or adjusts

### 3. Clear Input/Output Contracts

**Inputs:**
- Support multiple input formats (description, context file, options)
- Document each format with examples

**Outputs:**
- Structured summary of what was done
- List of files created/modified
- Clear next steps

### 4. Context File Integration

Commands should work with `/gather` output:
```bash
/gather TICKET-123
/command-name .claude/context/TICKET-123.md
```

### 5. Stage Isolation

Each stage should:
- Have a clear purpose
- Produce visible output
- Allow user to intervene before next stage

### 6. Agent Delegation

Commands orchestrate agents:
- Commands = user interface (input parsing, output formatting)
- Agents = execution logic (actual work)
- Skills = domain knowledge (patterns, templates)

```
User → Command → Agent → Skill
             ↓
         Results
```
