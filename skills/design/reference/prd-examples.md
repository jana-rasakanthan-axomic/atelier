# PRD Translation — Full Examples

> Referenced from [prd-translation.md](../prd-translation.md)

## Example 1: User Data Export

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

### API Endpoints
1. `POST /api/users/{user_id}/export`
   - **Trigger:** User clicks "Start Export"
   - **Request:** `{"format": "csv" | "json"}`
   - **Response:** `{"job_id": "...", "status": "pending"}`

2. `GET /api/users/{user_id}/export/{job_id}`
   - **Trigger:** Frontend polls while showing spinner
   - **Response:** `{"job_id": "...", "status": "pending|completed|failed", "download_url": "..."}`

### Architecture Needs
- **Async job pattern:** PRD shows loading spinner -> processing takes time
- **File storage:** PRD shows download -> need to store generated file
- **Status tracking:** PRD shows progress -> need job state

### Data Requirements
- User profile, posts, comments (inferred from "export my data")
- CSV format: Row per item
- JSON format: Nested structure

---

## Example 2: Asset Reordering

**PRD (UI-focused):**
```markdown
## User Flow
1. User sees list of assets in a content block
2. User drags asset to new position
3. Asset moves to new position in list
4. Order persists after page refresh
```

**Backend Translation:**

### API Endpoints
1. `PATCH /api/blocks/{block_id}/assets/{asset_id}/position`
   - **Trigger:** User drops asset in new position
   - **Request:** `{"insert_before_id": "..." | null}`
   - **Response:** `204 No Content`

2. `GET /api/blocks/{block_id}/assets`
   - **Trigger:** User opens block, page refresh
   - **Response:** Assets in position order

### Architecture Needs
- Position storage: Need `position` attribute
- Position calculation: Insert before another asset
- Order preservation: Database query ORDER BY position

### Data Requirements
- Asset position (numeric or fractional for easy reordering)
- Reference to block (assets belong to block)

---

## Example 3: Recipe Import

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

### API Endpoints
1. `POST /api/recipes/import`
   - **Trigger:** User clicks "Import"
   - **Request:** `{"url": "https://example.com/recipe"}`
   - **Response:** `{"recipe_id": "...", "status": "processing"}`

2. `GET /api/recipes/{recipe_id}`
   - **Trigger:** Frontend polls to check if recipe is ready
   - **Response:** Recipe data when `status: "ready"`

### Architecture Needs
- **Scraping:** Fetch HTML from URL
- **AI extraction:** Use Gemini to extract structured data
- **Async processing:** PRD shows 5-10 second wait
- **Error handling:** Return 400/422 with clear error message

### Data Requirements
- Recipe structure: title, ingredients, instructions
- Source URL (for attribution)
- Processing status (processing -> ready)
