# ADR-[NNNN]: [Short Title in Title Case]

**Date:** [YYYY-MM-DD]
**Status:** Proposed | Accepted | Rejected | Deprecated | Superseded by ADR-XXXX
**Context:** [Link to ticket, epic, or TDD]

## Decision

[State the architecture decision in one clear sentence]

Example: "Use asynchronous job pattern (Celery + Redis) for user data export."

## Context

[Describe the problem and why this decision is needed. Include:]
- Business/user requirements
- Technical constraints
- Current system state
- What prompted this decision

## Alternatives Considered

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| **[Option 1]** | [List pros] | [List cons] | ❌ Rejected - [Reason] |
| **[Option 2]** | [List pros] | [List cons] | ✅ **Chosen** - [Reason] |
| **[Option 3]** | [List pros] | [List cons] | Future consideration - [Reason] |

## Decision Rationale

[Explain in detail why the chosen approach was selected. Include:]
- How it meets requirements
- Why rejected alternatives don't fit
- Trade-offs you're accepting
- Constraints that drove the decision

## Consequences

### Positive

- [List positive outcomes of this decision]
- [Include benefits, capabilities unlocked]

### Negative

- [List negative outcomes, costs, or limitations]
- [Be honest about downsides]

### Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| [Risk 1] | [High/Med/Low] | [High/Med/Low] | [How we mitigate] |
| [Risk 2] | [High/Med/Low] | [High/Med/Low] | [How we mitigate] |

## Implementation Notes

[Practical details for implementing this decision]

## Related

- **TDD:** [Link to technical design document]
- **Tickets:** [List related Jira tickets]
- **Code:** [Links to key files or PRs]
- **Supersedes:** [Link to ADR this replaces, if applicable]
- **Superseded by:** [Link to ADR that replaces this, if deprecated]

## Appendix

[Optional: Additional context, benchmarks, research notes, diagrams]

See `reference/adr-examples.md` for extended examples of each section (context, alternatives, rationale, consequences, risks, implementation notes, benchmarks, architecture diagrams).

---

## ADR Guidelines

### When to Create an ADR

Create an ADR for:
- **Significant technical decisions** that affect architecture, scalability, or maintainability
- **Trade-off decisions** where multiple valid approaches exist
- **Technology choices** (databases, frameworks, libraries, cloud services)
- **Architectural patterns** (sync/async, REST/GraphQL, monolith/microservices)
- **Security or compliance decisions** (auth methods, encryption, data handling)

Don't create an ADR for:
- Obvious or standard choices (e.g., "Use SQLAlchemy with FastAPI")
- Implementation details (e.g., variable naming, function structure)
- Decisions easily reversible without cost

### ADR Numbering

- Sequential: ADR-0001, ADR-0002, ADR-0003, ...
- Zero-padded to 4 digits
- Never reuse numbers (even if deprecated)

### ADR Status

- **Proposed**: Under discussion, not yet approved
- **Accepted**: Approved and ready to implement
- **Rejected**: Considered but not chosen (document why)
- **Deprecated**: No longer recommended (document replacement)
- **Superseded by ADR-XXXX**: Replaced by newer decision

### File Naming

Format: `NNNN-short-kebab-case-title.md`

Examples:
- `0001-use-postgresql-for-primary-database.md`
- `0023-async-job-pattern-for-exports.md`
- `0042-adopt-event-driven-architecture.md`

### Keep It Concise

- Aim for 1-2 pages
- Focus on **why**, not **how** (implementation goes in TDD)
- Use tables for comparisons
- Be specific about trade-offs

### Update When Deprecated

When an ADR is superseded:
1. Update status to "Superseded by ADR-XXXX"
2. Link to replacement ADR
3. Keep original content (historical record)
4. Create new ADR explaining why the change was needed
