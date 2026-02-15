# Design: Widget Dashboard

## Acceptance Criteria

- [ ] Dashboard loads in under 2 seconds with 100 widgets
- [ ] Filtering by category returns correct results and updates URL params
- [ ] Pagination displays 25 widgets per page with next/previous controls
- [ ] Empty state shown when no widgets match the active filter
- [ ] Widget cards display title, description (truncated to 120 chars), and relative timestamp

## Implementation

### Data Model

```
Widget {
  id: UUID
  title: string
  description: string
  category: string
  status: enum(active, archived)
  updated_at: timestamp
}
```

### Layers

1. **Data access** — `src/repositories/widget_repository.py` — query with filter/sort/paginate
2. **Service** — `src/services/widget_service.py` — business rules, authorization
3. **API** — `src/api/widgets.py` — request validation, response serialization

## API Contract / Interface

### GET /api/widgets

**Query params:**
- `category` (optional, string) — filter by category
- `status` (optional, enum: active|archived) — filter by status
- `sort` (optional, enum: updated_at|title, default: updated_at) — sort field
- `page` (optional, int, default: 1) — pagination page
- `per_page` (optional, int, default: 25, max: 100) — items per page

**Response (200):**
```json
{
  "widgets": [...],
  "total": 142,
  "page": 1,
  "per_page": 25
}
```

## Schema

```sql
CREATE TABLE widgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100),
  status VARCHAR(20) DEFAULT 'active',
  updated_at TIMESTAMP DEFAULT now()
);
CREATE INDEX idx_widgets_category ON widgets(category);
CREATE INDEX idx_widgets_status ON widgets(status);
```

## Effort Estimate

Medium (3-5 hours)

## Dependencies

Depends on the existing auth middleware for user context.
