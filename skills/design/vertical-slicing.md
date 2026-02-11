# Vertical Slicing

**Purpose:** Break features into user-value increments that cut through all technical layers.

**Part of:** Design skill

---

## Overview

Vertical slicing is the practice of breaking features into small, independently deliverable pieces that:
- Deliver complete end-to-end user value
- Cut through all technical layers (API → Service → Repository → DB)
- Are independently testable and deployable
- Focus on user outcomes, not technical tasks

---

## Vertical vs Horizontal Slicing

### ❌ Horizontal Slicing (Bad)

Breaking work by technical layer:

```
Story 1: Create database schema
Story 2: Create repository methods
Story 3: Create service layer
Story 4: Create API endpoints
Story 5: Write tests
```

**Problems:**
- No user value until ALL stories complete
- Cannot deploy incrementally
- Hard to test in isolation
- Technical focus, not user focus

### ✅ Vertical Slicing (Good)

Breaking work by user capability:

```
Story 1: User can create basic export (CSV only, no filters)
Story 2: User can select export format (add JSON support)
Story 3: User can filter export by date range
Story 4: User receives email when export completes
```

**Benefits:**
- Each story delivers user value
- Can deploy after each story
- Easy to test end-to-end
- User-focused, prioritizable

---

## Characteristics of Good Vertical Slices

### 1. Delivers Complete User Capability

**Good:** "User can reorder assets within a block"
- Complete flow: User action → API → Service → Repository → DB → Response
- User can actually do something new

**Bad:** "Create asset repository methods"
- Technical task, not user capability
- No user value until integrated with API

### 2. Independently Deployable

**Good:** "User can export data to CSV"
- Can deploy to production and users can use it
- Doesn't depend on future stories

**Bad:** "Create export infrastructure"
- Can't deploy without export feature
- No standalone value

### 3. Testable End-to-End

**Good:** "User can log in with email magic link"
- Can write integration test: Submit email → Receive link → Click link → Logged in
- Verifiable by user or QA

**Bad:** "Implement JWT validation middleware"
- Can't test without protected endpoints
- No end-to-end flow

### 4. Right-Sized (2-5 Story Points)

**Good:** 2-5 points (1-3 days)
- Small enough to complete quickly
- Large enough to deliver meaningful value
- **Never exceed 5 points** - split if larger

**Bad:** >5 points
- Too large, must be split further
- Risk of scope creep and delays

### 5. Endpoint-Level Granularity

**Rule:** One ticket = One primary endpoint (or tightly coupled pair)

**Good:** "User can log in with Google OAuth" → `GET /auth/callback`
- Single endpoint focus
- Clear API contract
- Testable in isolation

**Bad:** "User Authentication" → Multiple endpoints bundled
- Login, logout, token refresh all in one
- Too many moving parts
- Hard to estimate and test

---

## Slicing Strategies

### Strategy 1: Progressive Enhancement

Start with simplest version, add features incrementally.

**Example: User Data Export**

```
Slice 1: Basic export (CSV only, all fields, no filters) - 3 points
Slice 2: Add JSON format support - 2 points
Slice 3: Add date range filter - 3 points
Slice 4: Add email notification - 2 points
```

### Strategy 2: Happy Path First

Implement successful flow first, add error handling later.

**Example: User Authentication**

```
Slice 1: User can log in with valid credentials (happy path) - 5 points
Slice 2: Handle invalid credentials, expired tokens - 3 points
Slice 3: Add rate limiting for brute-force protection - 2 points
```

### Strategy 3: Core Then Extensions

Build essential functionality first, add nice-to-haves later.

**Example: Asset Reordering**

```
Slice 1: User can reorder assets within block - 5 points
Slice 2: Add drag-and-drop UI (extension) - 3 points
Slice 3: Add keyboard shortcuts (extension) - 2 points
```

### Strategy 4: By User Persona

Different personas may need different capabilities.

**Example: Recipe Management**

```
Slice 1: Home cook can import recipe from URL - 5 points
Slice 2: Chef can bulk import recipes - 5 points
Slice 3: Admin can moderate imported recipes - 3 points
```

---

## Endpoint-Level Slicing (Required)

**Rule:** One ticket = One primary endpoint (or tightly coupled pair)

This is the **required granularity** for `/design` output. Each ticket should map to a single API endpoint.

### Why Endpoint-Level?

| Granularity | Problem |
|-------------|---------|
| **Epic-level** | Too large (8+ points), multiple endpoints bundled, hard to estimate |
| **Feature-level** | Often bundles related endpoints, still too large |
| **Endpoint-level** ✅ | Right-sized (2-5 points), clear scope, testable in isolation |
| **Task-level** | Too small, horizontal slicing, no user value |

### Endpoint-Level Examples

#### ❌ Wrong: Feature-Level (Too Coarse)

```
MISE-002: User Authentication (8 points)
- Login (Google, Magic Link, Apple)
- Logout
- JWT validation
- User creation
```

**Problems:** Multiple endpoints, exceeds 5 points, hard to parallelize work.

#### ✅ Right: Endpoint-Level

```
MISE-002: User Can Log In with Google OAuth (3 points)
  Endpoint: GET /auth/callback
  - Handles OAuth callback from Google
  - Creates/updates user record
  - Returns JWT token

MISE-003: User Can Log In with Email Magic Link (3 points)
  Endpoint: POST /auth/magic-link
  - Validates magic link token
  - Creates session
  - Returns JWT token

MISE-004: Protect API Endpoints with JWT Validation (2 points)
  Middleware: JWT validation dependency injection
  - Validates JWT signature
  - Extracts user from token
  - Returns 401 for invalid tokens
```

**Benefits:** Clear scope, parallelizable, estimable, testable.

### Slicing by Endpoint Pattern

| Pattern | Points | Example |
|---------|--------|---------|
| GET list | 2 | `GET /api/recipes` - List user's recipes |
| GET detail | 2 | `GET /api/recipes/{id}` - Get single recipe |
| POST create | 3 | `POST /api/recipes` - Create recipe with validation |
| PUT/PATCH update | 3 | `PATCH /api/recipes/{id}` - Update recipe fields |
| DELETE | 2 | `DELETE /api/recipes/{id}` - Delete recipe |
| Complex flow | 5 | `POST /api/recipes/import` - Import with external API call |

### When to Bundle Endpoints (Exceptions)

Bundle **only** when endpoints are tightly coupled and meaningless alone:

```
MISE-005: User Can Export Data (5 points)
  Endpoints (tightly coupled):
  - POST /api/exports - Create export job
  - GET /api/exports/{id} - Poll job status

  Why bundled: Status endpoint is useless without create endpoint.
```

**Don't bundle** unrelated endpoints just because they're in the same domain:
- ❌ "Recipe CRUD" (4 endpoints) → Split into 4 tickets
- ❌ "User Management" (5 endpoints) → Split into 5 tickets

---

## Slicing Process

### Step 1: Identify User Capabilities

From PRD, list all user capabilities (not technical tasks):

**Example PRD: User Data Export**
- User can export their data
- User can choose format (CSV or JSON)
- User can filter by date range
- User receives notification when export completes

### Step 2: Order by Dependency

Identify dependencies between capabilities:

```
1. User can export their data (core)
   ↓
2. User can choose format (extends #1)
   ↓
3. User can filter by date (extends #2)
   ↓
4. User receives notification (independent, can be parallel)
```

### Step 3: Apply Slicing Strategy

Choose appropriate strategy (progressive enhancement, happy path, etc.):

```
Slice 1: User can export data to CSV (no filters)
Slice 2: User can choose CSV or JSON format
Slice 3: User can filter export by date range
Slice 4: User receives email notification
```

### Step 4: Validate Slices

For each slice, check:
- [ ] Delivers complete user value?
- [ ] Independently deployable?
- [ ] Testable end-to-end?
- [ ] Right-sized (1-8 points)?
- [ ] Cuts through all layers (API → DB)?

### Step 5: Create Design Tickets

For each slice, create a design ticket (see `SKILL.md` template).

---

## Examples

### Example 1: Asset Reordering

**Input PRD:**
```markdown
Users need to reorder assets within a content block.
Assets can be reordered by drag-and-drop or by clicking up/down arrows.
Changes should save automatically.
```

**Bad Horizontal Slicing:**
```
Story 1: Add position column to database
Story 2: Create repository methods for position queries
Story 3: Add service layer for reordering logic
Story 4: Create API endpoint
Story 5: Add frontend drag-and-drop UI
```

**Good Vertical Slicing:**
```
Slice 1: User can reorder assets within block via API (PATCH endpoint)
  - Includes: DB schema, repository, service, API
  - Value: Backend ready, can test with curl/Postman
  - Points: 5

Slice 2: User can reorder assets via drag-and-drop UI
  - Includes: Frontend component, API integration
  - Value: Full user experience
  - Points: 3
```

### Example 2: Recipe Import

**Input PRD:**
```markdown
Users can import recipes from:
- URL (website)
- Image (photo of recipe card)
- PDF (printed recipe)
- Raw text (copy-paste)

All imports should extract: title, ingredients, instructions.
```

**Bad Horizontal Slicing:**
```
Story 1: Set up Gemini AI integration
Story 2: Create scraping service
Story 3: Add image processing
Story 4: Create import API endpoints
Story 5: Add frontend import UI
```

**❌ Bad Feature-Level Slicing (Too Coarse):**
```
Slice 1: User can import recipe from URL (8 points)
  - Includes: URL scraping, Gemini extraction, API, DB
```

**Problems:** Exceeds 5 points, bundles multiple operations.

**✅ Good Endpoint-Level Slicing:**
```
MISE-010: User Can Import Recipe from URL (5 points)
  Endpoint: POST /api/recipes/import/url
  - Accepts URL in request body
  - Scrapes webpage content
  - Extracts recipe via Gemini
  - Saves recipe to database
  - Returns created recipe

  Infrastructure (embedded): Gemini API integration

MISE-011: User Can Import Recipe from Image (5 points)
  Endpoint: POST /api/recipes/import/image
  - Accepts image upload (multipart)
  - Sends to Gemini for OCR + extraction
  - Saves recipe to database
  - Returns created recipe

MISE-012: User Can Import Recipe from PDF (5 points)
  Endpoint: POST /api/recipes/import/pdf
  - Accepts PDF upload (multipart)
  - Extracts text from PDF
  - Sends to Gemini for extraction
  - Saves recipe to database

MISE-013: User Can Import Recipe from Text (3 points)
  Endpoint: POST /api/recipes/import/text
  - Accepts raw text in request body
  - Sends to Gemini for extraction
  - Saves recipe to database
```

**Benefits:** Each ticket is one endpoint, 5 points max, clear scope.

---

## Common Mistakes

### ❌ Mistake 1: Technical Layer Slicing

**Wrong:**
- "Create database schema"
- "Implement service layer"
- "Add API endpoints"

These are horizontal slices, not vertical.

**Right:**
- "User can export data to CSV"
- "User can reorder assets within block"
- "User can import recipe from URL"

### ❌ Mistake 2: Infrastructure as First Slice

**Wrong:**
```
Slice 1: Set up Celery workers
Slice 2: Configure Redis
Slice 3: Create job queue
Slice 4: Implement export feature
```

**Right:**
```
Slice 1: User can export data (sync, <1k records)
Slice 2: Upgrade to async export for large datasets
  - Now includes: Celery, Redis, job queue
```

Start with simplest solution that delivers value, add infrastructure when needed.

### ❌ Mistake 3: Too Many Features in One Slice

**Wrong:**
```
Slice 1: User can import recipes from URL, image, PDF, and text
```
Too large (20+ points), should be 4 separate slices.

**Right:**
```
Slice 1: User can import recipe from URL (8 points)
Slice 2: User can import recipe from image (5 points)
Slice 3: User can import recipe from PDF (5 points)
Slice 4: User can import recipe from text (3 points)
```

---

## Sizing Guidelines

| Points | Duration | Scope | Endpoint Complexity |
|--------|----------|-------|---------------------|
| 2 | Half day | Simple endpoint | GET list, GET detail, DELETE |
| 3 | 1 day | Endpoint with logic | POST create with validation |
| 5 | 2-3 days | Complex endpoint | Multi-step flow, external API, async |
| >5 | - | **Too large** | **Must split** |

**Target:** 2-5 points per slice (one endpoint)

**Never exceed 5 points.** If a slice is >5 points, split by:
- Separating endpoints (one ticket per endpoint)
- Extracting infrastructure setup into first feature that needs it
- Breaking multi-step flows into sequential tickets

---

## Validation Checklist

For each slice, verify:

- [ ] **Endpoint-Level:** One primary endpoint (or tightly coupled pair)
- [ ] **User Value:** Delivers complete user capability (not just technical task)
- [ ] **Vertical:** Cuts through all layers (API → Service → Repository → DB)
- [ ] **Deployable:** Can be deployed independently to production
- [ ] **Testable:** Can write end-to-end integration test
- [ ] **Right-Sized:** 2-5 story points (never exceed 5)
- [ ] **Clear:** Title describes user outcome, not implementation
- [ ] **Focused:** Does one thing well, not multiple things partially

---

## Related

- **Requirements Analysis:** [requirements-analysis.md](requirements-analysis.md)
- **Main Skill:** [SKILL.md](SKILL.md)
- **Designer Agent:** [../../agents/designer.md](../../agents/designer.md)
