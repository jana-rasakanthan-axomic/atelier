# Pattern Referencing

**Purpose:** Reference existing code patterns by feature name, not file path.

**Part of:** Design skill

---

## Overview

Design tickets should point implementers to similar features in the codebase WITHOUT copying code or specifying file paths. This allows the Planner agent to explore the codebase and discover the best implementation approach.

**Key Principle:** Name the pattern, don't prescribe the implementation.

---

## Pattern Reference Levels

| Level | When to Use | Example |
|-------|-------------|---------|
| **1. Feature Name** | Design phase (best) | "Follow the section/block reordering pattern" |
| **2. Behavioral Description** | Design phase (good) | "Like section reordering: accepts insert_before_id, null = move to end" |
| **3. File Hints** | Planning phase only | "See section/block reordering implementations for positioning logic" |
| **4. Specific Paths** | Implementation phase only | "Review: src/api/section/service.py update_section_position()" |

Levels 1-2 belong in design tickets. Levels 3-4 should never appear in design tickets.

---

## Good vs Bad References

> See [reference/pattern-referencing-examples.md](reference/pattern-referencing-examples.md) for full annotated examples.

**Good** (name the pattern, describe behavior):
```markdown
## Context
System already implements:
- Section reordering (users can reorder sections within a draft)
- Block reordering (users can reorder blocks within a section)

Assets should follow the same pattern, limited to within-block only.
```

**Bad** (prescribes implementation):
```markdown
## Context
Look at `src/api/section/routes.py` lines 364-427 for the section
reordering endpoint which uses a PATCH method...
```

### Common Mistakes Summary

| Mistake | Problem | Fix |
|---------|---------|-----|
| File paths and line numbers | Fragile, over-specified | Name the feature instead |
| Method names | Assumes specific API | Describe the behavior |
| Code snippets | Prevents discovery | Let Planner find the implementation |
| Prescribing class structure | Constrains architecture | Describe the pattern category |

---

## Search Terms for Common Patterns

When referencing patterns, use standard terms so Planner can search effectively:

| Category | Search Terms |
|----------|-------------|
| **API** | "user CRUD", "paginated listing", "cursor pagination", "full-text search", "file upload" |
| **Data** | "position-based ordering", "hierarchical data", "soft delete", "audit logging" |
| **Processing** | "async job", "background job", "Redis caching", "rate limiting", "retry logic" |
| **Integration** | "third-party API", "webhook handling", "S3 upload", "email notification", "Auth0 integration" |

---

## Context Section Template

```markdown
## Context

[1-2 sentences describing related functionality]

System already implements:
- [Feature 1]: [Brief user-level description]
- [Feature 2]: [Brief user-level description]

[Feature name] should follow the same pattern[, with these differences: ...].

**Pattern References:**
- Similar feature: [Feature name]
- Related API: [Endpoint/feature name]
- Existing pattern: [Pattern name]
```

---

## When Pattern Doesn't Exist

State it explicitly and suggest an approach:

```markdown
## Context

This is a new pattern not currently in the codebase.

**Suggested approach:** [High-level description]
**Why this approach:** [Rationale]
**References:** [External docs or standards]
```

---

## Benefits

- **Freedom:** Planner explores and discovers best practices instead of following prescriptive paths
- **Resilience:** References survive file renames and refactors
- **Consistency:** New code naturally matches existing patterns

---

## Checklist

- [ ] Pattern named by feature (not file path)
- [ ] User-level behavior described (not implementation)
- [ ] Level 1-2 references used (feature name or behavior)
- [ ] No file paths, line numbers, or method names
- [ ] No code snippets or implementation details
- [ ] Differences from existing pattern noted (if any)

---

## Related

- **Requirements Analysis:** [requirements-analysis.md](requirements-analysis.md)
- **Vertical Slicing:** [vertical-slicing.md](vertical-slicing.md)
- **Main Skill:** [SKILL.md](SKILL.md)
- **Design Guidelines:** [../../docs/design-ticket-optimization-guidelines.md](../../docs/design-ticket-optimization-guidelines.md)
