# [TICKET-ID]: [Title]

**Type:** Story | Task | Bug | Spike
**Priority:** P0 | P1 | P2
**Points:** [1-8]

---

## Problem / Goal

[1-2 sentences: what user need or technical gap this addresses.
Frame from the user's perspective when possible.]

## Context

[Brief background — pattern references by name, related features, relevant BDD scenarios.
Keep to 2-3 sentences. Link to docs rather than repeating content.]

---

## Requirements

### Functional

- [Capability 1 — what the system must do]
- [Capability 2]
- [Capability 3]

### Non-Functional

- [Performance requirement — e.g., response time, throughput]
- [Follow existing [pattern name] pattern]
- [Test coverage target — e.g., all public methods covered]
- [Security requirement, if applicable]

---

## Constraints

- [Technical boundary 1 — e.g., must use existing [component]]
- [Technical boundary 2 — e.g., backward compatible with [version]]
- [No breaking changes to existing [feature]]

---

## Success Criteria

- [ ] [Measurable, testable criterion 1]
- [ ] [Measurable, testable criterion 2]
- [ ] [Measurable, testable criterion 3]
- [ ] [All tests pass, lint clean, type check clean]

---

## Out of Scope

- [Explicit exclusion 1 — prevents scope creep]
- [Explicit exclusion 2]

---

## Frontend Contract (if applicable)

**Endpoint:** `[METHOD /path]`
**Auth:** [Required / None]

**Request:**
```
[Key fields with types and constraints]
```

**Success Response:** `[status code]`
```
[Key fields in response body]
```

**Error Responses:**
| Status | Meaning |
|--------|---------|
| [4xx] | [description] |
| [4xx] | [description] |

---

## Dependencies

**Blocked by:** [TICKET-IDs that must complete first]
**Blocks:** [TICKET-IDs that depend on this]

## References

- PRD: [link or section reference]
- API contract: [link or section reference]
- Similar feature: [name — for pattern reference]
