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
| "Modal shows export options" | Define export parameters | Request schema with options |
| "User receives email notification" | Send notification when complete | Background job triggers email service |
| "User can drag and drop to reorder" | Update item position | `PATCH /api/items/{id}/position` |
| "User sees confirmation dialog" | Validate before action | Request validation rules |
| "User can filter by date range" | Query with date filter | Query params: `?start_date=...&end_date=...` |
| "User can search by keyword" | Full-text search | Query param: `?q={query}` |
| "User sees real-time updates" | Push updates to client | WebSocket or SSE endpoint |
| "User can upload file" | Handle file upload | Multipart form data or presigned S3 URL |
| "User sees progress bar" | Track operation progress | Status endpoint with percentage |
| "User can undo action" | Reversible operation | Soft delete or transaction rollback |

---

## Extraction Process

### Step 1: Identify UI Actions

Scan PRD for user interactions:
- User clicks...
- User selects...
- User sees...
- User receives...
- User uploads...
- User drags...

### Step 2: Translate to API Endpoints

For each UI action, determine:
- **HTTP Method:** GET (read), POST (create), PATCH/PUT (update), DELETE (remove)
- **Endpoint Path:** `/api/resource` or `/api/resource/{id}/action`
- **Request Payload:** What data does the action need?
- **Response:** What does the client need back?

### Step 3: Identify Async Patterns

Look for indicators of long-running operations:
- "Loading spinner"
- "Progress bar"
- "When ready..."
- "Email notification"
- Large data volumes mentioned

→ Likely needs async job pattern (Celery, background worker)

### Step 4: Extract Data Requirements

From UI descriptions, infer data needs:
- "Display user profile" → Need: User data structure
- "Show last 10 items" → Need: Pagination/limiting
- "Export includes profile, posts, comments" → Need: Join queries
- "Filter by date range" → Need: Date query capability

### Step 5: Identify Non-Functional Requirements

UI clues reveal performance/scale needs:
- "Thousands of records" → Pagination, caching needed
- "Real-time updates" → WebSocket or SSE
- "Works on slow networks" → Compression, minimal payloads
- "Instant search" → Caching, indexed queries

---

## Examples

### Example 1: User Data Export

**PRD (UI-focused):**
```markdown
## User Flow
1. User navigates to Settings > Privacy
2. User clicks "Export My Data" button
3. User sees modal: "Select format: CSV or JSON"
4. User selects CSV and clicks "Start Export"
5. User sees loading spinner: "Preparing your export..."
6. When ready, user sees "Download" button
7. User clicks Download and receives file
```

**Backend Translation:**

#### API Endpoints
1. `POST /api/users/{user_id}/export`
   - **Trigger:** User clicks "Start Export"
   - **Request:** `{"format": "csv" | "json"}`
   - **Response:** `{"job_id": "...", "status": "pending"}`

2. `GET /api/users/{user_id}/export/{job_id}`
   - **Trigger:** Frontend polls while showing spinner
   - **Response:** `{"job_id": "...", "status": "pending|completed|failed", "download_url": "..."}`

#### Architecture Needs
- **Async job pattern:** PRD shows loading spinner → processing takes time
- **File storage:** PRD shows download → need to store generated file
- **Status tracking:** PRD shows progress → need job state

#### Data Requirements
- User profile, posts, comments (inferred from "export my data")
- CSV format: Row per item
- JSON format: Nested structure

### Example 2: Asset Reordering

**PRD (UI-focused):**
```markdown
## User Flow
1. User sees list of assets in a content block
2. User drags asset to new position
3. Asset moves to new position in list
4. Order persists after page refresh
```

**Backend Translation:**

#### API Endpoints
1. `PATCH /api/blocks/{block_id}/assets/{asset_id}/position`
   - **Trigger:** User drops asset in new position
   - **Request:** `{"insert_before_id": "..." | null}`
   - **Response:** `204 No Content`

2. `GET /api/blocks/{block_id}/assets`
   - **Trigger:** User opens block, page refresh
   - **Response:** Assets in position order

#### Architecture Needs
- Position storage: Need `position` attribute
- Position calculation: Insert before another asset
- Order preservation: Database query ORDER BY position

#### Data Requirements
- Asset position (numeric or fractional for easy reordering)
- Reference to block (assets belong to block)

### Example 3: Recipe Import

**PRD (UI-focused):**
```markdown
## User Flow
1. User pastes recipe URL into input field
2. User clicks "Import" button
3. User sees "Importing recipe..." with spinning icon
4. After 5-10 seconds, recipe appears in library
5. If import fails, user sees error: "Could not import from this URL"
```

**Backend Translation:**

#### API Endpoints
1. `POST /api/recipes/import`
   - **Trigger:** User clicks "Import"
   - **Request:** `{"url": "https://example.com/recipe"}`
   - **Response:** `{"recipe_id": "...", "status": "processing"}`

2. `GET /api/recipes/{recipe_id}`
   - **Trigger:** Frontend polls to check if recipe is ready
   - **Response:** Recipe data when `status: "ready"`

#### Architecture Needs
- **Scraping:** Fetch HTML from URL
- **AI extraction:** Use Gemini to extract structured data
- **Async processing:** PRD shows 5-10 second wait
- **Error handling:** Return 400/422 with clear error message

#### Data Requirements
- Recipe structure: title, ingredients, instructions
- Source URL (for attribution)
- Processing status (processing → ready)

---

## Common Patterns

### Pattern 1: Modal/Form → Request Schema

**PRD:** "User sees modal with fields: Name, Email, Role"

**Backend:**
```python
class CreateUserRequest(BaseModel):
    name: str
    email: EmailStr
    role: Literal["admin", "user"]
```

### Pattern 2: Loading State → Async Operation

**PRD:** "User sees loading spinner"

**Backend:**
- Async job pattern (Celery + Redis)
- Status endpoint for polling
- Notification when complete

### Pattern 3: Real-Time Update → Push Mechanism

**PRD:** "User sees updates without refreshing"

**Backend:**
- WebSocket connection OR
- Server-Sent Events (SSE) OR
- Polling (simple but less efficient)

### Pattern 4: Drag-and-Drop → Position Update

**PRD:** "User can drag items to reorder"

**Backend:**
- Position attribute (numeric or fractional)
- Update endpoint: `PATCH /items/{id}/position`
- `insert_before_id` parameter

### Pattern 5: Infinite Scroll → Pagination

**PRD:** "More items load as user scrolls"

**Backend:**
- Cursor-based pagination OR
- Offset/limit pagination
- `next_page_token` in response

---

## Backend-Only Features

Sometimes backend requirements aren't visible in PRD because they're implementation details:

### Security Requirements
- JWT validation (not shown in UI flow)
- Rate limiting (prevents abuse)
- Data encryption (at rest, in transit)
- Audit logging (who did what when)

### Performance Requirements
- Caching (reduce database load)
- Query optimization (indexes, efficient queries)
- Connection pooling (handle concurrent requests)

### Data Integrity
- Transactions (atomic operations)
- Foreign key constraints (referential integrity)
- Validation (prevent invalid data)

### Operational Requirements
- Health checks (for load balancers)
- Metrics (Prometheus, CloudWatch)
- Logging (structured, searchable)

**These should be added to design tickets even if not in PRD.**

---

## Ignore Frontend Implementation

Design tickets are backend-only. Do NOT include:

### ❌ Don't Include:
- React component names
- Redux actions or state structure
- CSS classes or styling
- Frontend routing
- Client-side validation (backend should validate too)
- UI library details (Material-UI, etc.)

### ✅ Do Include:
- API contracts that frontend will consume
- Data structures frontend will receive
- Error responses frontend should handle
- Performance characteristics (latency, throughput)

---

## Tips for Success

### 1. Look for Action Verbs

User actions translate to HTTP verbs:
- "User creates..." → `POST`
- "User views..." → `GET`
- "User updates..." → `PATCH` or `PUT`
- "User deletes..." → `DELETE`

### 2. Infer from Timing

PRD timing clues reveal architecture needs:
- "Instantly" → Fast query, likely cached
- "Within seconds" → Async processing OK
- "Within minutes" → Definitely async (background job)

### 3. Think About Failure Cases

PRD often focuses on happy path. Infer error scenarios:
- "User uploads file" → What if file too large? Wrong format?
- "User exports data" → What if too much data? Timeout?
- "User imports recipe" → What if URL invalid? Site blocks scraping?

Add these to design ticket constraints/error handling.

---

## Checklist

Use this when translating PRD to backend requirements:

- [ ] UI actions translated to API endpoints
- [ ] HTTP methods chosen appropriately (GET/POST/PATCH/DELETE)
- [ ] Request/response schemas identified
- [ ] Async operations identified (loading spinners, progress bars)
- [ ] Data requirements extracted (what data is shown/modified)
- [ ] Non-functional requirements inferred (performance, security)
- [ ] Error scenarios identified (what can go wrong)
- [ ] Backend-only concerns added (auth, caching, logging)
- [ ] Frontend implementation details excluded (React, CSS, etc.)

---

## Related

- **Requirements Analysis:** [requirements-analysis.md](requirements-analysis.md)
- **Constraint Definition:** [constraint-definition.md](constraint-definition.md)
- **Main Skill:** [SKILL.md](SKILL.md)
