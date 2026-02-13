---
name: review
description: Multi-persona code review with structured checklists for security, engineering, and product perspectives. Use for PR reviews, security audits, and architecture validation.
allowed-tools: Read, Grep, Glob
---

# Review Skill

Multi-persona code review with structured checklists.

## When to Use

- PR review before merge
- Security audit of new code
- Architecture validation
- Requirements coverage verification
- Code quality assessment

## When NOT to Use

**Only for code review and audits.** Do not use for implementation or test execution.

- Test execution → use Verifier agent
- Self-review of just-written code → use `/review --self`
- Generating fixes → use Builder agent
- Simple formatting issues → use linter

## Personas

Load the appropriate persona based on review scope:

| Persona | File | Focus |
|---------|------|-------|
| Security | `personas/security.md` | OWASP, STRIDE, auth, crypto |
| Engineering | `personas/engineering.md` | Architecture, quality, perf, merge readiness |
| Product | `personas/product.md` | Requirements, UX, edge cases |

## Checklists

Each persona has a corresponding checklist:

- `checklists/security-checklist.md`
- `checklists/engineering-checklist.md`
- `checklists/product-checklist.md`

## Workflow

1. **Select Persona(s)** based on review scope
2. **Load Persona** from `personas/`
3. **Apply Checklist** from `checklists/`
4. **Generate Findings** with file:line references
5. **Render Verdict** (approve/request changes/block)

## Output Format

```json
{
  "verdict": "approve | request_changes | block",
  "findings": [
    {
      "severity": "critical | high | medium | low",
      "file": "src/services/user_service.py",
      "line": 42,
      "issue": "SQL injection vulnerability",
      "fix": "Use parameterized query"
    }
  ],
  "summary": "Brief overall assessment"
}
```

## Severity Guidelines

| Severity | Description | Action |
|----------|-------------|--------|
| Critical | Security vulnerability, data loss risk | Block merge |
| High | Bug, performance issue, arch violation | Request changes |
| Medium | Code smell, missing tests, unclear code | Suggest fix |
| Low | Style, naming, minor improvement | Optional |

## Tools Used

| Tool | Purpose |
|------|---------|
| Read | Examine code under review |
| Grep | Search for patterns across files |
| Glob | Find related files |
