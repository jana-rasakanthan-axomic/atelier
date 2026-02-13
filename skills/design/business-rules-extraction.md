# Business Rules Extraction Skill

Extract high-level business rules and constraints from Product Requirements Documents (PRDs) for user review and approval.

## Purpose

Support the **design phase** by:
1. Reading PRDs and extracting implicit business rules
2. Structuring rules in clear, reviewable format
3. Writing rules to file for user review/approval
4. Providing foundation for BDD scenarios and implementation

## When to Use

- **For PM-facing extraction:** Use `skills/specify/business-rules.md` via `/specify` command (mandatory before `/design`)
- **For engineer reference:** This skill documents the engineering-focused format (includes Enforcement field)

**Note:** Business rules extraction is now handled exclusively by `/specify` as a mandatory prerequisite for `/design`. This file serves as the engineering reference for rule format and categories.

**Specific use cases:**
- Reference for rule categories (the 8 rule types below)
- PRD contains implicit rules that need surfacing
- Need to convert informal requirements to formal rules
- Multi-stakeholder review (rules document as product/engineering contract)

## When NOT to Use

- Rules already explicit in PRD (just copy them)
- Implementation details (this is for business logic, not technical decisions)
- After design phase (extract rules during design, not during implementation)

## Rule Categories

| # | Category | What It Covers | Example |
|---|----------|----------------|---------|
| 1 | Authorization | Who can perform actions, access data | "Users can only export their own data" |
| 2 | Validation | Input constraints, formats, ranges | "File uploads limited to 10MB" |
| 3 | Rate Limiting | Frequency constraints, quotas | "Max 5 exports per day" |
| 4 | Performance | Latency, timeouts, scale | "API response <500ms" |
| 5 | Data Retention | Storage duration, deletion, archival | "Export files expire after 24 hours" |
| 6 | Data Privacy | PII handling, sensitive data exclusion | "Exports exclude password hashes" |
| 7 | Business Logic | Core domain constraints, process rules | "Orders cannot be cancelled after shipment" |
| 8 | Integration | External system constraints | "Payment processing via Stripe only" |

## Extraction Process

### Step 1: Read PRD Thoroughly
Identify sections containing requirements, user stories, acceptance criteria, constraints.

### Step 2: Identify Implicit Rules

Look for signal phrases:
- "Users can..." -> Authorization rule
- "Must be..." -> Validation rule
- "Limited to..." -> Rate limiting rule
- "Should complete within..." -> Performance rule
- "Available for..." -> Data retention rule
- "Exclude..." -> Data privacy rule

### Step 3: Structure Rules

Each rule must be explicit, include rationale, specify enforcement, and note exceptions.

**Template:**
```markdown
## Business Rules: [Feature Name]

### Rule: [Category] - [Short Name]

**Statement:** [Clear, concise rule statement]

**Rationale:** [Why this rule exists]

**Enforcement:** [Where/how rule is enforced]

**Exceptions:** [Any exceptions to the rule]

**Examples:**
- Valid case
- Invalid case
```

### Step 4: Write to File

**Output location:** `.claude/design/[feature-name]-rules.md`

### Step 5: Present for User Review

Prompt the user with a numbered summary of extracted rules and the file location. Offer options: proceed, add missing rule, modify rule, or start over.

### Step 6: Incorporate Feedback

Update rules file based on user feedback, then proceed to next stage.

## Output Format

The output file follows this structure:

```markdown
# Business Rules: [Feature Name]

**Feature:** [Feature description from PRD]
**Date:** [YYYY-MM-DD]
**Source:** [Link to PRD file]
**Status:** Draft | Under Review | Approved

---

## Rule 1: [Category] - [Short Name]

**Statement:** [Clear rule statement]

**Rationale:** [Why this rule exists - security, compliance, cost, etc.]

**Enforcement:**
- [Layer]: [How enforced]

**Exceptions:**
- [Exception and conditions]

**Examples:**
- [Valid case]
- [Invalid case]
- [Edge case]

---

## Summary

**Total Rules:** [N]
**By Category:** [breakdown]
**Critical (Must Have for MVP):** [list]
**Nice-to-Have (Can Defer):** [list]

## Open Questions

1. **Q:** [Ambiguity found during extraction]
   **A:** [Resolution or "pending user input"]

## Approval

**Status:** Draft | Under Review | Approved
**Approved by:** [Name]
```

## Integration with Workflow

Business rules extraction is handled by `/specify` (mandatory before `/design`):

```
/gather -> /specify (extracts rules + BDD) -> /design (uses approved rules) -> /plan -> /build
```

`/design` consumes approved rules from `.claude/design/[feature]-rules.md` -- it does NOT extract rules itself.

## Output Location

**Primary output:** `.claude/design/[feature-name]-rules.md`

**Referenced by:** BDD scenarios (validates rules), Tickets (specifies constraints), Contracts (enforces rules), Tests (verifies compliance)

## Related

- **Workflow:** [docs/contract-first-design-workflow.md](../../docs/contract-first-design-workflow.md)
- **Design Skill:** [skills/design/SKILL.md](SKILL.md)
- **BDD Skill:** [skills/testing/bdd-scenario-generation.md](../testing/bdd-scenario-generation.md)
