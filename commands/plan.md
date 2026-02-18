---
name: plan
description: Create implementation plan and save to file
model_hint: opus
allowed-tools: Read, Grep, Glob, Write
---

# /plan

Create implementation plan and save to `.claude/plans/` for use with `/build`.

## Structural Determinism

Plans MUST follow the exact template at `.claude/templates/plan-template.md`.

**Rules:** Exact section order, exact headers (case-sensitive), tables over prose, constrained values only (P0/P1/P2, S/M/L, High/Medium/Low), no filler prose, omit empty sections, inline all schemas (never "See contract from PROJ-XXX").

**Points:** S=1, M=2, L=5 (Large has non-linear complexity). Never hours/days.

## Specification-Only Plans

Plans contain **specifications, not code**. Include: method signatures, schema field names/types, test case names (`test_{action}_{condition}_returns_{code}`), file paths, acceptance criteria. Exclude: full implementations, complete models, test bodies, queries.

## Input Formats

```bash
/plan .claude/context/PROJ-123.md              # From context file (recommended)
/plan "Add real-time notifications"            # From description
/plan --dry-run .claude/context/PROJ-123.md    # Preview scope only
/plan --output custom/plan.md [input]          # Custom output path
```

## Output Location

| Input | Output |
|-------|--------|
| `.claude/context/PROJ-123.md` | `.claude/plans/PROJ-123.md` |
| `"Add notifications"` | `.claude/plans/add-notifications.md` |

## When to Use

- Complex feature requiring design
- Unclear implementation path
- Architecture decisions needed

## When NOT to Use

- Simple, well-defined task → implement directly
- Bug fix with clear solution → `/fix`
- Already have plan → `/build` directly

## Workflow (4 Stages)

### Stage 1: Scope

Parse input (context file or description). Extract requirements, contract specs, references to TDD/ADR docs. Identify related code, estimate complexity.

If `--dry-run`: stop and report scope only.

### Stage 2: Analyze

**Agent:** Planner

Search codebase for related implementations, detect architectural patterns, run gap analysis (`skills/analysis/gap-analysis.md`) and risk analysis (`skills/analysis/risk-analysis.md`).

### Stage 3: Design

Generate plan following the template's EXACT section order:

1. Header Block → 2. Summary → 3. Key Constraints → 4. Contract Specifications → 5. Files (Create/Modify) → 6. Implementation Phases → 7. Test Matrix (REQUIRED) → 8. Acceptance Criteria → 9. Dependencies → 10. Risks → 11. Effort (with Points) → 12. Notes (optional)

### Stage 4: Save & Review

Save plan to file. Present summary with key decisions, open questions, and next step: `/build .claude/plans/PROJ-123.md`.

## Error Handling

| Scenario | Action |
|----------|--------|
| Invalid context file | Report error, suggest `/gather` |
| Scope >30 files | Suggest splitting |
| No related code | Report greenfield, proceed |
| Requirements unclear | Add to Open Questions |

## Scope Limits

- Single feature/domain per plan
- Max files affected: 30
- Escalate if: security-critical, cross-service dependencies
