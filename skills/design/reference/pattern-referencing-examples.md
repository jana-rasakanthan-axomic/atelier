# Pattern Referencing — Detailed Examples

> Referenced from [pattern-referencing.md](../pattern-referencing.md)

## Good Pattern References

### Example 1: Feature Name
```markdown
## Context
System already implements:
- Section reordering (users can reorder sections within a draft)
- Block reordering (users can reorder blocks within a section)

Assets should follow the same pattern, limited to within-block only.
```

### Example 2: Similar Feature
```markdown
## Context
Similar to existing user data export feature.
Follow the same async job pattern.
```

### Example 3: Pattern Category
```markdown
## Context
Follow existing async job pattern (like report generation).
Use same status tracking and notification approach.
```

---

## Bad Pattern References

### Example 1: File Paths (too implementation-specific, fragile)
```markdown
## Context
Look at `src/api/section/routes.py` lines 364-427 for the section
reordering endpoint which uses a PATCH method...
```

### Example 2: Method Names (assumes specifics, prescriptive)
```markdown
## Context
Call `get_position_boundaries()` from the repository and
calculate midpoint like in `update_section_position()` method.
```

### Example 3: Code Snippets (prevents discovery of better approaches)
```markdown
## Context
Use this approach:
```python
position = (prev_position + next_position) / 2
```
```

---

## Context Section — Filled Example

### Asset Reordering
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

## When Pattern Doesn't Exist — Filled Example

### Adding WebSocket Support
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
