# Pattern Referencing

**Purpose:** Reference existing code patterns by feature name, not file path.

**Part of:** Design skill

---

## Overview

Design tickets should point implementers to similar features in the codebase WITHOUT copying code or specifying file paths. This allows the Planner agent to explore the codebase and discover the best implementation approach.

**Key Principle:** Name the pattern, don't prescribe the implementation.

---

## Pattern Reference Levels

### Level 1: Feature Name Only (Best for Design)
```markdown
Follow the section/block reordering pattern
```

**Why this works:**
- High signal, low context
- Planner will search for "section reordering" in codebase
- Discovers actual implementation patterns
- Not fragile (works even if files move)

### Level 2: Behavioral Description (Good for Design)
```markdown
Like section reordering: accepts insert_before_id to specify position,
null means "move to end"
```

**Why this works:**
- Describes behavior without prescribing implementation
- Gives Planner enough context to search
- Not tied to specific files or methods

### Level 3: File Hints (Planning Phase, NOT Design)
```markdown
See section/block reordering implementations for positioning logic
```

**When to use:** Only in `/plan` phase after exploring codebase

### Level 4: Specific Paths (Implementation Phase, NOT Design)
```markdown
Review: src/api/section/service.py update_section_position() method
```

**When to use:** Never in design tickets. Only during implementation if needed.

---

## How to Reference Patterns

### ✅ Good Pattern References

#### Example 1: Feature Name
```markdown
## Context
System already implements:
- Section reordering (users can reorder sections within a draft)
- Block reordering (users can reorder blocks within a section)

Assets should follow the same pattern, limited to within-block only.
```

**Why good:**
- Names features to search for
- Describes behavior at user level
- Notes key difference (limited to within-block)

#### Example 2: Similar Feature
```markdown
## Context
Similar to existing user data export feature.
Follow the same async job pattern.
```

**Why good:**
- Points to similar feature by name
- Identifies pattern type (async job)
- Planner will search for "user data export"

#### Example 3: Pattern Category
```markdown
## Context
Follow existing async job pattern (like report generation).
Use same status tracking and notification approach.
```

**Why good:**
- Identifies pattern category
- Gives example feature
- Describes high-level approach

### ❌ Bad Pattern References

#### Example 1: File Paths
```markdown
## Context
Look at `src/api/section/routes.py` lines 364-427 for the section
reordering endpoint which uses a PATCH method...
```

**Why bad:**
- Too implementation-specific
- Fragile (line numbers change)
- Prescriptive (tells HOW, not WHAT)

#### Example 2: Method Names
```markdown
## Context
Call `get_position_boundaries()` from the repository and
calculate midpoint like in `update_section_position()` method.
```

**Why bad:**
- Assumes specific method names
- Prescribes implementation before exploration
- LLM should discover actual method names

#### Example 3: Code Snippets
```markdown
## Context
Use this approach:
```python
position = (prev_position + next_position) / 2
```
```

**Why bad:**
- Shows implementation code
- Prevents LLM from discovering better approaches
- Assumes specific data types and logic

---

## Search Terms for Common Patterns

When referencing patterns, use these standard terms so Planner can search effectively:

### API Patterns
- **CRUD operations:** "user CRUD", "recipe CRUD"
- **Pagination:** "paginated listing", "cursor pagination"
- **Search/filtering:** "full-text search", "filtering by..."
- **File upload:** "file upload", "multipart upload"

### Data Patterns
- **Ordering:** "position-based ordering", "reordering"
- **Hierarchy:** "hierarchical data", "parent-child"
- **Soft delete:** "soft delete", "trash/restore"
- **Audit trail:** "audit logging", "change tracking"

### Processing Patterns
- **Async jobs:** "async job", "background job", "Celery task"
- **Caching:** "cached queries", "Redis caching"
- **Rate limiting:** "rate limiting", "request throttling"
- **Retries:** "retry logic", "exponential backoff"

### Integration Patterns
- **External APIs:** "third-party API", "webhook handling"
- **File storage:** "S3 upload", "file storage"
- **Email:** "email notification", "transactional email"
- **Authentication:** "JWT validation", "Auth0 integration"

---

## Context Section Template

Use this template for the Context section of design tickets:

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

### Example: Asset Reordering
```markdown
## Context

Users can already reorder sections and blocks within their drafts.
Assets should have the same reordering capability within their parent block.

System already implements:
- Section reordering: Users can reorder sections within a draft
- Block reordering: Users can reorder blocks within a section, or move between sections

Assets should follow the same pattern, limited to within-block reordering only (no cross-block movement).

**Pattern References:**
- Similar feature: Section reordering
- Similar feature: Block reordering
- Related API: Asset CRUD endpoints
```

---

## When Pattern Doesn't Exist

If there's no similar pattern in the codebase, state that explicitly:

```markdown
## Context

This is a new pattern not currently in the codebase.

**Suggested approach:**
[High-level description of recommended approach]

**Why this approach:**
[Rationale for recommendation]

**References:**
- External pattern: [Industry standard or library]
- Documentation: [Link to guide or best practice]
```

### Example: Adding WebSocket Support
```markdown
## Context

Real-time updates are a new requirement. The codebase currently uses
REST APIs with polling, but this feature needs push-based updates.

**Suggested approach:**
Server-Sent Events (SSE) for one-way push notifications from server to client.

**Why this approach:**
- Simpler than WebSocket (don't need bi-directional)
- Better browser support than WebSocket
- Works with existing REST API infrastructure

**References:**
- FastAPI SSE support: https://fastapi.tiangolo.com/advanced/custom-response/#streamingresponse
- Pattern: Long-lived HTTP connection with event stream
```

---

## Common Mistakes

### ❌ Mistake 1: Over-Specifying Location
**Wrong:**
```markdown
Look at src/api/section/routes.py, specifically the update_section_position
endpoint on line 427. It uses a PATCH method with insert_before_id parameter.
```

**Right:**
```markdown
Follow section reordering pattern (accepts insert_before_id parameter).
```

### ❌ Mistake 2: Copying Implementation Details
**Wrong:**
```markdown
The section reordering uses a fractional indexing system where positions
are stored as Decimal values and new positions are calculated as the
midpoint between adjacent items.
```

**Right:**
```markdown
Use same position storage approach as sections/blocks.
```

Let Planner discover the actual implementation (fractional indexing, midpoint calculation).

### ❌ Mistake 3: Prescribing Architecture
**Wrong:**
```markdown
Create a PositionService class with methods calculate_position() and
update_position() like the SectionPositionService.
```

**Right:**
```markdown
Position calculation should follow existing pattern from section/block reordering.
```

Let Planner discover the actual class structure and method names.

---

## Benefits of Pattern Referencing

### For Planner Agent:
1. **Freedom to explore:** Not constrained by prescriptive instructions
2. **Discovery of best practices:** Finds actual patterns in codebase
3. **Consistency:** Matches existing code style and conventions
4. **Flexibility:** Can adapt pattern to specific needs

### For Human Developers:
1. **Not hand-held:** Trusted to find and follow patterns
2. **Learn by example:** Explores similar features
3. **Make good decisions:** Can adapt pattern as needed
4. **Context-aware:** Understands why pattern is used

### For Code Quality:
1. **Consistency:** New code matches existing patterns
2. **Maintainability:** Similar features implemented similarly
3. **Evolvability:** Easier to refactor when patterns are consistent

---

## Checklist

Use this when adding pattern references to design tickets:

- [ ] Pattern named by feature (not file path)
- [ ] User-level behavior described (not implementation)
- [ ] Level 1-2 references used (feature name or behavior)
- [ ] No file paths, line numbers, or method names
- [ ] No code snippets or implementation details
- [ ] Clear why this pattern applies
- [ ] Differences from pattern noted (if any)
- [ ] Multiple similar features listed (if applicable)

---

## Related

- **Requirements Analysis:** [requirements-analysis.md](requirements-analysis.md)
- **Vertical Slicing:** [vertical-slicing.md](vertical-slicing.md)
- **Main Skill:** [SKILL.md](SKILL.md)
- **Design Guidelines:** [../../docs/design-ticket-optimization-guidelines.md](../../docs/design-ticket-optimization-guidelines.md)
