# Implementation Plan: [TICKET-ID]

**Ticket:** [link to ticket]
**Profile:** [auto-detected or specified]
**Author:** [name]
**Date:** [YYYY-MM-DD]

---

## Overview

[1-2 sentence summary of what this plan implements and the user-facing value it delivers]

## Prerequisites

- [ ] [Dependency 1 — e.g., blocked-by ticket completed]
- [ ] [Dependency 2 — e.g., required infrastructure provisioned]
- [ ] [Dependency 3 — e.g., external API access confirmed]

---

## Layer Breakdown

### Layer 1: [Entry Point Layer — from profile]

**Source:** `${profile.layers[0].src_dir}/...`
**Tests:** `${profile.layers[0].test_dir}/...`

#### Contracts

[Define the public interface for this layer — request/response types, method signatures,
input validation rules. This is what consumers of this layer depend on.]

- Input: [key fields, types, constraints]
- Output: [key fields, types, status codes or return values]
- Errors: [error types and when they occur]

#### Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `[src_dir]/[file]` | New | [purpose] |
| `[src_dir]/[file]` | Modify | [what changes and why] |

#### Test Cases

- Happy path: [description of expected behavior with valid input]
- Error case: [description of behavior with invalid or missing input]
- Edge case: [description of boundary condition behavior]
- Auth/access: [description of unauthorized or forbidden scenarios, if applicable]

---

### Layer 2: [Business Logic Layer — from profile]

**Source:** `${profile.layers[1].src_dir}/...`
**Tests:** `${profile.layers[1].test_dir}/...`

#### Contracts

[Internal interface — method signatures, DTOs, business rules enforced at this layer]

- Input: [key fields from layer above]
- Output: [transformed data, domain objects]
- Side effects: [events emitted, state changes]

#### Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `[src_dir]/[file]` | New | [purpose] |
| `[src_dir]/[file]` | Modify | [what changes and why] |

#### Test Cases

- Happy path: [core business logic with valid data]
- Validation: [business rule enforcement]
- Error propagation: [how errors from dependencies are handled]

---

### Layer 3: [Data Access Layer — from profile]

**Source:** `${profile.layers[2].src_dir}/...`
**Tests:** `${profile.layers[2].test_dir}/...`

#### Contracts

[Data access interface — query methods, persistence operations, data mapping]

- Operations: [CRUD operations needed]
- Queries: [lookup patterns — by ID, by filter, paginated]
- Mapping: [how domain objects map to/from storage format]

#### Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `[src_dir]/[file]` | New | [purpose] |
| `[src_dir]/[file]` | Modify | [what changes and why] |

#### Test Cases

- CRUD: [create, read, update, delete operations]
- Not found: [behavior when entity does not exist]
- Constraint: [unique constraint violations, referential integrity]

---

### Layer N: [Additional Layers as Needed — from profile]

[Repeat the same structure: Contracts, Files, Test Cases.
Examples: external gateway, event publisher, migration, seed data.]

---

## Patterns to Follow

- [Pattern name]: [Brief description — reference by feature name, not file path]
- [Pattern name]: [Brief description]
- [Pattern name]: [Brief description]

## Schema Changes (if applicable)

- [ ] [Table/collection/resource to add or alter]
- [ ] [Migration or schema evolution strategy]
- [ ] [Data backfill needed: yes/no]

## Out of Scope

- [Item 1 — explicitly excluded to keep scope tight]
- [Item 2]

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk 1] | H / M / L | [Strategy] |
| [Risk 2] | H / M / L | [Strategy] |

## Open Questions

- [ ] [Question 1 — who needs to answer, by when]
- [ ] [Question 2]
