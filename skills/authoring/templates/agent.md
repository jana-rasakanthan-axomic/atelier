# Agent Template

Use this template when creating a new agent.

## Agent File Template

```markdown
---
name: agent-name
description: Brief description of what this agent does
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(specific:*)
---

# Agent Name

One-line description: You [verb] [object] by [method].

## When to Use

- Trigger condition 1
- Trigger condition 2
- Trigger condition 3
- Trigger condition 4

## When NOT to Use

**Only for [specific purpose].** Do not use for any other purpose.

## Workflow

### Execution Pattern

[Describe how the agent executes tasks step by step]

1. **Phase 1**: Description
   - Sub-step a
   - Sub-step b

2. **Phase 2**: Description
   - Sub-step a
   - Sub-step b

3. **Phase 3**: Description
   - Sub-step a
   - Sub-step b

## Skills Used

| Skill | Purpose |
|-------|---------|
| `skills/skill-name/` | Description |
| `skills/other-skill/` | Description |

## Scripts Used

| Script | Purpose |
|--------|---------|
| `scripts/script-name.sh` | Description |
| `skills/skill/scripts/other.sh` | Description |

## Output Format

```json
{
  "result_field": "description",
  "files_created": ["path/to/file.py"],
  "files_modified": ["path/to/other.py"],
  "status": "success | failed | escalated"
}
```

## Tools Used

| Tool | Purpose |
|------|---------|
| Read | Examine existing code, patterns |
| Edit | Modify existing files |
| Write | Create new files |
| Bash | Run tests, linter, typecheck |

## Iteration Strategy

When [operation] fails:

1. Read output to understand failure
2. Identify root cause
3. Fix the issue
4. Re-run [operation]
5. If still failing after 3 attempts → escalate to user

## Error Recovery & Escalation

### When to Escalate Immediately (skip retries)

- Condition 1 (e.g., circular import detected)
- Condition 2 (e.g., missing required dependency)
- Condition 3 (e.g., environment configuration missing)

### Escalation Report Format

```markdown
## Escalation Required

### What Was Attempted
- Phase: {phase_name}
- Action: {action description}
- Attempts: 3/3

### Error Details
{exact error message}

### Suggested Next Steps
1. Specific suggestion
2. Alternative approach
3. Whether to rollback changes
```

## Scope Limits

- Limit 1 (e.g., single domain per execution)
- Limit 2 (e.g., max files: 20 new + 10 modified)
- Limit 3 (e.g., request review for security-sensitive code)
- If limits exceeded: split into multiple executions or escalate
```

## Key Principles

### 1. Clear Boundaries

Define exactly what the agent does and doesn't do:
- "When to Use" = clear triggers
- "When NOT to Use" = explicit redirects to alternatives
- "Scope Limits" = hard boundaries

### 2. Explicit Tool Contracts

List every tool used and its purpose. Use specific Bash patterns:
- `Bash(pytest:*)` - can run any pytest command
- `Bash(ruff:*)` - can run any ruff command
- Not just `Bash` (too permissive)

### 3. Structured Output

Always define output format (JSON preferred) for:
- Consistency across invocations
- Machine-parseable results
- Clear success/failure signals

### 4. Retry with Limits

- Max 3 attempts for recoverable errors
- Immediate escalation for unrecoverable errors
- Clear escalation report format
