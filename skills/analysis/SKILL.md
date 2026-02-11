---
name: analysis
description: Code analysis for coverage gaps, requirements tracing, risks, and quality metrics. Use when assessing coverage, identifying gaps, or auditing code quality.
allowed-tools: Read, Grep, Glob, Bash(pytest:*), Bash(coverage:*)
---

# Analysis Skill

Code analysis for coverage, gaps, risks, and quality metrics.

## When to Use

- Analyzing test coverage gaps
- Identifying requirements gaps
- Assessing technical risks
- Auditing code complexity
- Tracing requirements to implementation

## When NOT to Use

**Only for analysis and measurement.** Do not use for implementation or execution.

- Implementing fixes → use Builder agent
- Running tests → use Verifier agent
- Code review → use Reviewer agent
- Security assessment → use security skill

## Guides

| Guide | Purpose |
|-------|---------|
| `coverage-analysis.md` | Test coverage gaps |
| `gap-analysis.md` | Requirements vs implementation |
| `risk-analysis.md` | Technical risks |
| `requirements-trace.md` | Requirements traceability |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/analyze-coverage.py` | Parse pytest coverage, identify gaps |
| `scripts/code-audit.py` | Complexity, tech debt analysis |

## Workflow

1. **Scope** - Define what to analyze
2. **Collect** - Gather data via scripts
3. **Analyze** - Identify patterns and gaps
4. **Prioritize** - Rank findings by impact
5. **Report** - Generate actionable output

## Output Format

```json
{
  "analysis_type": "coverage | gap | risk | audit",
  "scope": "module or feature name",
  "findings": [
    {
      "id": "FIND-001",
      "category": "coverage | gap | risk | complexity",
      "severity": "critical | high | medium | low",
      "location": "file:line or feature name",
      "description": "What was found",
      "recommendation": "Suggested action",
      "effort": "small | medium | large"
    }
  ],
  "metrics": {
    "total_items": 100,
    "issues_found": 10,
    "by_severity": {"critical": 1, "high": 3, "medium": 4, "low": 2}
  },
  "summary": "Overall assessment"
}
```

## Tools Used

| Tool | Purpose |
|------|---------|
| Bash | Run analysis scripts |
| Read | Examine code and reports |
| Grep | Search for patterns |
| Glob | Find files to analyze |
