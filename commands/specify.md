---
name: specify
description: Extract business rules and generate BDD scenarios from PRD for PM review
allowed-tools: Read, Write, Edit, AskUserQuestion
---

# /specify

Extract business rules and generate BDD scenarios from a PRD in business language, for Product Manager review and approval before engineering design.

## Scope

**Includes:** Business rules extraction, BDD scenarios (Gherkin), flow diagrams (Mermaid), PM-readable language throughout, approval gates for PM sign-off.

**Excludes:** API contracts, database schemas, service architecture, code examples, codebase research, implementation plans.

## Input Formats

```bash
/specify .claude/context/user-export-prd.md            # From context file (recommended)
/specify "Add real-time notifications"                  # From description
/specify .claude/context/feature.md --no-diagrams      # Skip diagrams
```

## Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--diagrams` | On | Generate Mermaid flowcharts and sequence diagrams |
| `--no-diagrams` | -- | Skip diagram generation |

## When to Use

- PRD needs behavioral validation before engineering design
- PM must approve business rules and acceptance criteria
- Complex features with multiple user roles and edge cases

## When NOT to Use

- Engineering can derive rules directly -> use `/design`
- Simple, obvious implementation -> use `/plan` directly
- Technical-only changes -> use `/plan` or `/fix`
- PM has already documented explicit rules -> use `/design`

## Output Files

```
.claude/design/[feature]-rules.md        # Business rules (PM-approved)
.claude/design/[feature]-bdd.feature     # BDD scenarios (PM-approved)
.claude/design/[feature]-flows.md        # Flow diagrams (unless --no-diagrams)
```

## Context File Integration

If first argument is a path to `.claude/context/*.md`, read context file and extract requirements, user stories, and acceptance criteria as the basis for specification.

## Workflow (5 Stages)

### Stage 0: Load & Clarify

**Agent:** Specifier

Read PRD/context. If requirements are clear (roles defined, success criteria identifiable, constraints stated, failure behavior described), proceed. If unclear, ask ONE batch of business-only clarification questions, then proceed.

Questions must be business-focused ("Which roles have access?", "What happens at the limit?") -- never technical ("Which HTTP status?", "Use Celery or cron?").

### Stage 1: Extract Business Rules (Interactive)

**Agent:** Specifier | **Skill:** `skills/specify/business-rules.md`

Read PRD and extract rules by category (authorization, validation, rate limiting, retention, privacy, business logic, integration). Structure each rule with statement, rationale, affected roles, exceptions, and examples. Write to `.claude/design/[feature]-rules.md`.

Present rules summary for PM approval. Incorporate feedback and re-present if needed. Set status to Approved after PM sign-off.

### Stage 2: Generate BDD Scenarios (Interactive)

**Agent:** Specifier | **Skill:** `skills/specify/bdd-scenarios.md`

Generate Gherkin scenarios from approved rules. Use business language throughout ("When I request a data export" not "When I POST to /api/export"). Cover happy paths, access control, and edge cases. Write to `.claude/design/[feature]-bdd.feature`.

Present scenarios summary for PM approval. Incorporate feedback if needed.

### Stage 3: Generate Flow Diagrams (Conditional)

**Agent:** Specifier | **Skill:** `skills/specify/flow-diagrams.md`

Skip if `--no-diagrams`. Scan approved BDD scenarios. Generate flowcharts for single-user decision paths (max 4, 5-10 nodes each) and sequence diagrams for multi-party interactions (max 3). Use business language for all labels. Write to `.claude/design/[feature]-flows.md` with a Diagram Index mapping each diagram to its BDD scenarios.

Present for PM review. Incorporate feedback if needed.

### Stage 4: Finalize & Handoff

**Agent:** Specifier

Verify all approved artifacts exist. Present summary with file paths, rule/scenario counts, and handoff instructions. The `/design` command auto-detects these pre-approved artifacts and skips redundant stages.

## Error Handling

| Scenario | Action |
|----------|--------|
| Input too vague | List ambiguities, ask clarifying questions, suggest `/gather` |
| Scope too large | Warn, suggest splitting, offer to specify critical subset first |
| PM requests technical details | Redirect to business behavior, note concern for engineering |

## Agents Used

| Agent | Stage | Purpose |
|-------|-------|---------|
| Specifier | 0-4 | Extracts rules, BDD scenarios, and flow diagrams in PM-readable language |

## Skills Used

| Skill | Purpose |
|-------|---------|
| `skills/specify/business-rules.md` | Business rules extraction in PM-readable format |
| `skills/specify/bdd-scenarios.md` | BDD scenario generation in user-action language |
| `skills/specify/flow-diagrams.md` | Mermaid flowcharts and sequence diagrams |

## Scope Limits

- Single feature per invocation
- Business language only -- no technical jargon
- Maximum 15 rules, 30 BDD scenarios per feature
- Does NOT: research codebase, create API contracts, create tickets, make architecture decisions
