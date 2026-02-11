---
name: design
description: Create technical design and detailed implementation tickets from PRD
allowed-tools: Read, Grep, Glob, AskUserQuestion, Write, Edit
---

# /design

Create technical designs and endpoint-level tickets from PRD or requirements.

## Input Formats

```bash
/design .claude/context/user-export-prd.md   # From PRD file
/design PROJ-42                               # From epic ID
/design "Add real-time notifications"         # From description
/design --split=monolith [input]              # Single-repo stories (default)
/design --split=services [input]              # Multi-repo service-boundary stories
/design user-export                           # Resume existing session
/design user-export --status                  # View session progress
/design user-export --restart                 # Discard progress, start fresh
```

## When to Use

- Have a PRD or epic-level requirements
- Need to turn requirements into implementation tickets
- Need to document architecture decisions

## When NOT to Use

- Ticket already has detailed plan → `/plan`
- Just need to implement → `/build`
- Simple, obvious implementation → `/plan` directly

## Prerequisites

**`/specify` must be run first.** Requires:
1. `.claude/design/[feature]-rules.md` with `Status: Approved`
2. `.claude/design/[feature]-bdd.feature`

## Output Locations

- Business Rules: `.claude/design/[feature]-rules.md`
- Technical Design: `.claude/design/[feature]-tdd.md`
- Contracts: `.claude/design/[feature]-contracts.md`
- BDD Scenarios: `.claude/design/[feature]-bdd.feature`
- Tickets: `.claude/tickets/TICKET-*.md`
- ADRs: `docs/adr/NNNN-decision.md`

## Story Splitting Modes

- **`--split=monolith`** (default): One ticket per endpoint. For personal/small team projects.
- **`--split=services`**: Split by service boundary. For multi-team microservices.

## Workflow (6 Stages)

### Pre-Stage: Session Management

Enable resumption across context windows. Session file: `.claude/design/sessions/{feature}.session.json`

Follow `skills/design/CHECKPOINTING.md` for session persistence.

### Pre-Stage: Specify Prerequisite Check

Verify `/specify` artifacts exist with `Status: Approved`. **STOP** if missing.

### Stage 0: Clarification Gate

**Agent:** Designer | **Skill:** `skills/design/requirements-analysis.md`

Analyze requirements against clarity criteria (scale, performance, format, security, scope). If CLEAR → Stage 1. If UNCLEAR → ask batch questions via `AskUserQuestion` (ONE TIME), then proceed.

### Stage 1: Analyze Requirements

**Agent:** Designer | **Skills:** `skills/design/requirements-analysis.md`, `skills/design/prd-translation.md`

1. Parse PRD (may include UI references — extract technical requirements)
2. Translate PRD language to profile-appropriate technical requirements
3. Research existing codebase patterns
4. Identify complexity: **Simple** (skip to Stage 3) or **Complex** (continue to Stage 2)

### Stage 2: Design Phase (Complex Only)

**Agent:** Designer | **Skills:** `skills/design/requirements-analysis.md`, `skills/design/vertical-slicing.md`

1. Clarify requirements via `AskUserQuestion`
2. Research codebase for similar patterns
3. Generate 2-4 architecture alternatives with trade-offs
4. **CHECKPOINT 2a:** Save alternatives to `.claude/design/{feature}-analysis.md`
5. User chooses approach
6. Document design using TDD template: `skills/design/templates/tdd.md`
7. Create ADRs using template: `skills/design/templates/adr.md`
8. **CHECKPOINT 2b:** Save design approval
9. Save TDD to `docs/design/{feature}.md`, ADRs to `docs/adr/NNNN-*.md`

### Stage 3: Define Contracts

**Agent:** Designer | **Skill:** `skills/design/constraint-definition.md`

Define contracts for each layer (API, Service, Repository). Reference active profile's error handling patterns from `${profile.patterns_dir}/exceptions.md`.

### Stage 4: Break Into Endpoint-Level Tickets

**Agent:** Designer | **Skills:** `skills/design/vertical-slicing.md`, `skills/design/pattern-referencing.md`

**Rule:** One ticket = one primary endpoint. Points: 2 (simple CRUD), 3 (with business logic), 5 (complex/async). Never exceed 5.

**Embed infrastructure** in the first feature that needs it (no separate infra tickets).

Write tickets using template: `skills/design/templates/detailed-ticket.md`

Save to `.claude/tickets/TICKET-ID.md`. Validate: 200-400 words, no file paths/code, testable criteria.

**CHECKPOINT 4:** Save after each ticket for resumption.

### Stage 5: Present for Review

Present summary: outputs created, ticket distribution, architecture summary, next steps.

## Error Handling

| Scenario | Action |
|----------|--------|
| Invalid context file | Report error, suggest `/gather` |
| Requirements too vague | Ask clarifying questions |
| Scope too large (>30 files) | Suggest splitting into epics |
| No related code found | Report greenfield, suggest options |
| Ticket >5 points | Flag for splitting |

## Agents Used

| Agent | Stage | Purpose |
|-------|-------|---------|
| Designer | 0-5 | Converts PRD to design tickets |

## Skills Used

| Skill | Purpose |
|-------|---------|
| `skills/design/requirements-analysis.md` | Extract requirements |
| `skills/design/vertical-slicing.md` | Endpoint-level slicing |
| `skills/design/prd-translation.md` | PRD → technical requirements |
| `skills/design/pattern-referencing.md` | Reference patterns by name |
| `skills/design/constraint-definition.md` | Define technical boundaries |
| `skills/design/templates/tdd.md` | TDD document template |
| `skills/design/templates/adr.md` | ADR template |
| `skills/design/templates/detailed-ticket.md` | Ticket template |

## Examples

See `docs/examples/design-examples.md` for detailed usage examples.

## Scope Limits

- Single feature/epic per design
- Max tickets per batch: 20
- Max complexity per ticket: 5 points
- Only generates stories for the active profile's layers
