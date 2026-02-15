# Design: Widget Dashboard

## Overview

Technical design for the widget dashboard feature.

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

### API Endpoints

- `GET /api/widgets` - List widgets with filtering
- `GET /api/widgets/:id` - Get single widget

## Dependencies

Depends on the existing auth middleware for user context.
