# Pre-Analysis Report Template

## When to Generate

- Generated at Stage 1.5 of `/build`, AFTER loading the plan but BEFORE requesting permissions
- Output to: `.claude/builds/<BRANCH_NAME>/pre-analysis.md`

## Template Structure

### Header

- Ticket ID(s), workstream, plan source file path
- Branch name, worktree path, base branch, timestamp

### Scope Assessment

- Files to create (list with paths)
- Files to modify (list with paths)
- Total file count, within scope limits? (max 30)

### Layer-by-Layer Build Plan

For EACH layer (outside-in order per profile):
1. Layer name (e.g., "API Layer -- Router")
2. Test file to create (path)
3. Estimated test cases (count + list of test names from contract)
4. Production file(s) to create/modify (paths)
5. Estimated lines of code

### Contract Alignment Check

For each endpoint/function in the plan:
- Method + path + status code
- Request schema fields
- Response schema fields
- Matches contract? YES/NO + discrepancy note if NO

### Dependency Check

- Prerequisites (which layers/tickets must be done first)
- Shared resources (models, schemas, utilities being modified)
- Risk: could this conflict with parallel work?

### Permissions Required

- Bash commands to be run (test runner, linter, type checker, git)
- Files to create (paths)
- Files to modify (paths)

### Risk Flags

- Model changes requiring migrations
- Deferred integrations (SQS, Redis, etc.)
- Shared file modifications
- Scope close to limits

## After Generating

- Present the report to the user
- WAIT for explicit approval before proceeding to Stage 2
- If user requests changes, regenerate the affected sections
