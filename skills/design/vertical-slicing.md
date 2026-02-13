# Vertical Slicing

**Purpose:** Break features into user-value increments that cut through all technical layers.

**Part of:** Design skill

---

## Overview

Vertical slicing breaks features into small, independently deliverable pieces that:
- Deliver complete end-to-end user value
- Cut through all technical layers (API -> Service -> Repository -> DB)
- Are independently testable and deployable
- Focus on user outcomes, not technical tasks

---

## Vertical vs Horizontal Slicing

| | Horizontal (Bad) | Vertical (Good) |
|---|---|---|
| **Slices by** | Technical layer | User capability |
| **Example** | "Create database schema", "Create service layer" | "User can export to CSV", "User can filter by date" |
| **User value** | None until ALL slices complete | Each slice delivers value |
| **Deployability** | Cannot deploy incrementally | Deploy after each slice |
| **Testability** | Hard to test in isolation | Easy end-to-end tests |

---

## Characteristics of Good Vertical Slices

### 1. Delivers Complete User Capability

**Good:** "User can reorder assets within a block" (complete flow: action -> API -> DB -> response)

**Bad:** "Create asset repository methods" (technical task, no user value until integrated)

### 2. Independently Deployable

**Good:** "User can export data to CSV" (standalone value)

**Bad:** "Create export infrastructure" (no value without the export feature)

### 3. Testable End-to-End

**Good:** "User can log in with email magic link" (verifiable flow: submit email -> receive link -> click -> logged in)

**Bad:** "Implement JWT validation middleware" (can't test without protected endpoints)

### 4. Right-Sized (2-5 Story Points)

2-5 points (1-3 days). **Never exceed 5 points** -- split if larger.

### 5. Endpoint-Level Granularity

**Rule:** One ticket = One primary endpoint (or tightly coupled pair).

| Granularity | Problem |
|-------------|---------|
| Epic-level | Too large (8+ points), multiple endpoints bundled |
| Feature-level | Often bundles related endpoints, still too large |
| **Endpoint-level** | Right-sized (2-5 points), clear scope, testable |
| Task-level | Too small, horizontal slicing, no user value |

---

## Slicing Strategies

| Strategy | Approach | Example |
|----------|----------|---------|
| **Progressive Enhancement** | Start simplest, add features incrementally | CSV only -> add JSON -> add date filter -> add email notification |
| **Happy Path First** | Success flow first, error handling later | Valid login -> invalid credentials -> rate limiting |
| **Core Then Extensions** | Essential first, nice-to-haves later | Reorder assets -> drag-and-drop UI -> keyboard shortcuts |
| **By User Persona** | Different personas, different capabilities | Home cook imports URL -> Chef bulk imports -> Admin moderates |

---

## Endpoint-Level Slicing (Required)

This is the **required granularity** for `/design` output. Each ticket maps to a single API endpoint.

### Wrong: Feature-Level (Too Coarse)

```
MISE-002: User Authentication (8 points)
- Login, Logout, JWT validation, User creation
```

Problems: Multiple endpoints, exceeds 5 points, hard to parallelize.

### Right: Endpoint-Level

```
MISE-002: User Can Log In with Google OAuth (3 pts) -> GET /auth/callback
MISE-003: User Can Log In with Email Magic Link (3 pts) -> POST /auth/magic-link
MISE-004: Protect API Endpoints with JWT (2 pts) -> JWT validation middleware
```

### Sizing by Endpoint Pattern

| Pattern | Points | Example |
|---------|--------|---------|
| GET list / GET detail / DELETE | 2 | `GET /api/recipes`, `DELETE /api/recipes/{id}` |
| POST create / PUT update | 3 | `POST /api/recipes` with validation |
| Complex flow (external API, async) | 5 | `POST /api/recipes/import` |
| >5 points | **Must split** | Separate endpoints, extract infrastructure |

### When to Bundle Endpoints

Bundle **only** when endpoints are tightly coupled and meaningless alone:
- POST /api/exports (create job) + GET /api/exports/{id} (poll status) -- status endpoint useless without create

**Don't bundle** unrelated endpoints just because they're in the same domain.

---

## Slicing Process

### Step 1: Identify User Capabilities
From PRD, list all user capabilities (not technical tasks).

### Step 2: Order by Dependency
Identify which capabilities depend on others.

### Step 3: Apply Slicing Strategy
Choose appropriate strategy (progressive enhancement, happy path, etc.).

### Step 4: Validate Slices
For each slice, verify against the checklist below.

### Step 5: Create Design Tickets
For each slice, create a design ticket (see `SKILL.md` template).

---

## Example: Recipe Import (Endpoint-Level Slicing)

**Input PRD:** Users can import recipes from URL, image, PDF, and raw text.

| Ticket | Endpoint | Points | Scope |
|--------|----------|--------|-------|
| MISE-010 | `POST /api/recipes/import/url` | 5 | Scrape URL, extract via Gemini, save |
| MISE-011 | `POST /api/recipes/import/image` | 5 | Upload image, OCR + extract via Gemini, save |
| MISE-012 | `POST /api/recipes/import/pdf` | 5 | Upload PDF, extract text, Gemini extract, save |
| MISE-013 | `POST /api/recipes/import/text` | 3 | Accept raw text, Gemini extract, save |

Each ticket is one endpoint, max 5 points, clear scope.

---

## Common Mistakes

| Mistake | Why It's Wrong | Fix |
|---------|---------------|-----|
| Technical layer slicing | "Create database schema" is horizontal, no user value | Slice by user capability: "User can export data to CSV" |
| Infrastructure as first slice | "Set up Celery workers" delays user value | Start with simplest solution that delivers value, add infra when needed |
| Too many features in one slice | "Import from URL, image, PDF, and text" is 20+ points | Split into one slice per input type |

---

## Validation Checklist

For each slice, verify:

- [ ] **Endpoint-Level:** One primary endpoint (or tightly coupled pair)
- [ ] **User Value:** Delivers complete user capability (not just technical task)
- [ ] **Vertical:** Cuts through all layers (API -> Service -> Repository -> DB)
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
