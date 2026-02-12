# PRD Translation

**Purpose:** Translate UI-focused PRD language into backend requirements.

**Part of:** Design skill

---

## Overview

PRDs naturally describe user experience, which includes UI elements (buttons, modals, forms). This skill helps extract backend requirements from UI-focused PRDs and translate them into API contracts and backend architecture needs.

**Key Principle:** UI actions imply backend needs. Our job is to identify those needs.

---

## Translation Table

| PRD Statement (UI-focused) | Backend Requirement | API Contract |
|----------------------------|---------------------|--------------|
| "User clicks Export button" | Create export job | `POST /api/users/{user_id}/export` |
| "User sees loading spinner" | Provide job status | `GET /api/users/{user_id}/export/{job_id}` |
| "User selects CSV or JSON" | Support multiple formats | Request param: `format: "csv" \| "json"` |
| "File downloads when ready" | Deliver export file | S3 signed URL or file stream |
| "User sees error message" | Return error details | HTTP status codes + error schema |
| "User can drag and drop to reorder" | Update item position | `PATCH /api/items/{id}/position` |
| "User can filter by date range" | Query with date filter | Query params: `?start_date=...&end_date=...` |
| "User sees real-time updates" | Push updates to client | WebSocket or SSE endpoint |
| "User can upload file" | Handle file upload | Multipart form data or presigned S3 URL |
| "User sees progress bar" | Track operation progress | Status endpoint with percentage |

---

## Extraction Process

### Step 1: Identify UI Actions

Scan PRD for user interactions: "User clicks...", "User selects...", "User sees...", "User receives...", "User uploads...", "User drags..."

### Step 2: Translate to API Endpoints

For each UI action, determine:
- **HTTP Method:** GET (read), POST (create), PATCH/PUT (update), DELETE (remove)
- **Endpoint Path:** `/api/resource` or `/api/resource/{id}/action`
- **Request Payload:** What data does the action need?
- **Response:** What does the client need back?

### Step 3: Identify Async Patterns

Look for indicators of long-running operations: "Loading spinner", "Progress bar", "When ready...", "Email notification", large data volumes. These likely need async job pattern (Celery, background worker).

### Step 4: Extract Data Requirements

From UI descriptions, infer data needs:
- "Display user profile" -> User data structure
- "Show last 10 items" -> Pagination/limiting
- "Export includes profile, posts, comments" -> Join queries
- "Filter by date range" -> Date query capability

### Step 5: Identify Non-Functional Requirements

UI clues reveal performance/scale needs:
- "Thousands of records" -> Pagination, caching needed
- "Real-time updates" -> WebSocket or SSE
- "Works on slow networks" -> Compression, minimal payloads

---

## Example: User Data Export

> See [reference/prd-examples.md](reference/prd-examples.md) for all three detailed examples (Data Export, Asset Reordering, Recipe Import).

**PRD:** User clicks "Export My Data", selects CSV/JSON, sees spinner, downloads file when ready.

**Backend Translation:**
1. `POST /api/users/{user_id}/export` -- Start async export job
2. `GET /api/users/{user_id}/export/{job_id}` -- Poll status, get download URL

**Architecture needs:** Async job pattern, file storage, status tracking.

---

## Common Patterns

| PRD Pattern | Backend Pattern | Key Indicator |
|-------------|----------------|---------------|
| Modal/Form with fields | Request schema (Pydantic model) | Named input fields |
| Loading spinner | Async job + status endpoint | Wait time implied |
| Real-time updates | WebSocket, SSE, or polling | "Without refreshing" |
| Drag-and-drop reorder | Position attribute + PATCH endpoint | "Reorder", "drag" |
| Infinite scroll | Cursor-based pagination | "More items load" |

---

## Backend-Only Concerns

These requirements are not visible in PRDs but must be added to design tickets:

- **Security:** JWT validation, rate limiting, data encryption, audit logging
- **Performance:** Caching, query optimization, connection pooling
- **Data integrity:** Transactions, foreign key constraints, validation
- **Operational:** Health checks, metrics, structured logging

---

## Tips

- **Action verbs -> HTTP verbs:** creates=POST, views=GET, updates=PATCH, deletes=DELETE
- **Timing clues -> architecture:** "Instantly"=cached, "Within seconds"=async OK, "Within minutes"=background job
- **Happy path only in PRD?** Always infer error scenarios (file too large, timeout, invalid input)
- **Exclude frontend details:** No React components, Redux, CSS, or client routing in backend design

---

## Checklist

- [ ] UI actions translated to API endpoints
- [ ] HTTP methods chosen appropriately
- [ ] Request/response schemas identified
- [ ] Async operations identified (loading spinners, progress bars)
- [ ] Data requirements extracted
- [ ] Non-functional requirements inferred (performance, security)
- [ ] Error scenarios identified
- [ ] Backend-only concerns added (auth, caching, logging)
- [ ] Frontend implementation details excluded

---

## Related

- **Requirements Analysis:** [requirements-analysis.md](requirements-analysis.md)
- **Constraint Definition:** [constraint-definition.md](constraint-definition.md)
- **Main Skill:** [SKILL.md](SKILL.md)
