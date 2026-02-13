---
name: design
description: Contract design, schema patterns, and ADRs. Use when converting PRDs into design tickets or defining technical boundaries.
allowed-tools: Read, Grep, Glob, Write
---

# Design Skill

Convert product requirements into LLM-optimized design tickets that define WHAT to build and WHY, not HOW.

## Purpose

Support the requirements design phase by:
1. Extracting backend requirements from UI-focused PRDs
2. Analyzing requirements and identifying user value
3. Researching existing codebase patterns (by name, not path)
4. Creating vertical slices that deliver end-to-end user value
5. Generating LLM-optimized design tickets (200-400 words, 600 max)

## When to Use

- **PRD → Tickets**: Turn requirements into design tickets
- **Requirements analysis**: Extract functional and non-functional requirements
- **Vertical slicing**: Break features into endpoint-level increments
- **Pattern identification**: Reference existing patterns for consistency

## When NOT to Use

- Implementation planning → `/plan` (Planner agent)
- Code exploration → Explore agent
- Bug fixes → `/fix`

## Key Concepts

### Design Ticket
Requirements document (NOT implementation plan) with: Problem/Goal, Context (pattern references), Requirements, Constraints, Success Criteria, Out of Scope. Output: `.claude/tickets/TICKET-ID.md`

**Excludes:** File paths, method signatures, database schema details, code examples, layer-by-layer breakdowns.

### Vertical Slice
One ticket = one endpoint, 2-5 story points. Cuts through all layers (API → Service → Repository → DB). Independently deployable and testable.

### Pattern Reference Levels
- **Level 1 (Best):** "Follow section/block reordering pattern"
- **Level 2 (Good):** "Like section reordering: accepts insert_before_id"
- **Level 3 (Avoid):** File paths, line numbers, method names

### Story Splitting Modes
- **`monolith`** (default): Single story per endpoint. Personal/small team projects.
- **`services`**: Split by service boundary. Multi-team microservices.

## Sub-Skills

| Skill File | Purpose |
|------------|---------|
| `requirements-analysis.md` | Extract and classify requirements from PRDs |
| `vertical-slicing.md` | Break features into user-value increments |
| `prd-translation.md` | Translate UI-focused PRD to backend requirements |
| `pattern-referencing.md` | Reference existing patterns by name |
| `constraint-definition.md` | Define technical boundaries |

## Templates

| Template | Location |
|----------|----------|
| Detailed ticket | `templates/detailed-ticket.md` |
| TDD document | `templates/tdd.md` |
| ADR document | `templates/adr.md` |

## Error Handling

When defining service contracts, follow the active profile's exception patterns: `${profile.patterns_dir}/exceptions.md`. All exceptions need `message`, `detail` (API response), and `context` (structured logging).

## Integration

- **Used by:** Designer agent, `/design` command
- **Hands off to:** Planner agent (`/plan`), Builder agent (`/build`)
- **Checkpointing:** See `CHECKPOINTING.md` for session persistence
- **Examples:** See `docs/examples/design-examples.md`
