# Workstream Create Pipeline

Reference documentation for the `/workstream create` pipeline. Describes how tickets are discovered or generated, analyzed for dependencies, grouped into workstreams, and output as actionable artifacts.

---

## Entry Points

The create pipeline supports two distinct entry points that determine which stages execute.

### Default: From Existing Tickets (Stages 3-4-5)

```
/workstream create
```

Assumes tickets already exist in `.claude/tickets/`. Skips source analysis and ticket decomposition. Runs:

- **Stage 3** -- Dependency Analysis
- **Stage 4** -- Workstream Grouping
- **Stage 5** -- Output Generation

Use this when `/specify` and `/design` have already produced ticket files.

### From Sources: Full Pipeline (Stages 1-2-3-4-5)

```
/workstream create --from-sources <path1> [path2] ...
```

Starts from raw source documents (PRDs, user stories, API contracts) and generates tickets before organizing them. Runs all five stages:

- **Stage 1** -- Source Analysis
- **Stage 2** -- Ticket Decomposition
- **Stage 3** -- Dependency Analysis
- **Stage 4** -- Workstream Grouping
- **Stage 5** -- Output Generation

Use this for greenfield projects or when converting external specs into an actionable workstream.

---

## Pre-Stage: Ticket Discovery (Default Entry Point)

When no `--from-sources` flag is provided, the pipeline begins by discovering existing tickets.

### Discovery Process

1. Glob `.claude/tickets/*.md` for all ticket files
2. Parse each ticket's YAML frontmatter for metadata:
   - `id` -- Ticket identifier (e.g., MISE-101)
   - `status` -- Current status (draft, ready, planned, in-progress, done)
   - `blocked_by` -- List of ticket IDs this ticket depends on
   - `blocks` -- List of ticket IDs this ticket unblocks
   - `area` -- Functional area (auth, import, export, etc.)
   - `priority` -- Priority level (critical, high, medium, low)
3. Filter to tickets with status `ready` or `draft`
4. Validate that each ticket has required fields: `id`, `summary`, `area`

### Validation Errors

| Error | Action |
|-------|--------|
| Missing `id` field | Skip ticket, warn user |
| Missing `area` field | Prompt user to assign area |
| Circular dependency detected | Error, list the cycle, abort |
| Duplicate ticket IDs | Error, list duplicates, abort |

---

## Stage 1: Source Analysis (--from-sources only)

Reads and parses raw source documents to extract implementable features.

### 1.1 Locate Source Files

```bash
# Sources can be:
# - PRD documents (.md, .txt)
# - User story files (.md)
# - API contracts (openapi.yaml, openapi.json)
# - Design documents (.md)
# - Confluence page IDs (fetched via MCP)
```

For each source path provided:
- If file exists locally, read it directly
- If it looks like a URL or page ID, fetch via appropriate tool
- If it is a directory, glob for `.md`, `.yaml`, `.json` files within it

### 1.2 Read and Parse Content

Each source is parsed to extract structured information:

| Source Type | Parser | Extracts |
|-------------|--------|----------|
| PRD (.md) | Heading + bullet extraction | Features, requirements, constraints |
| User Stories (.md) | Story format parser | Actors, actions, outcomes, acceptance criteria |
| API Contract (.yaml/.json) | OpenAPI parser | Endpoints, methods, request/response schemas |
| Design Doc (.md) | Section extraction | Components, data models, integration points |

### 1.3 Extract Features, Epics, and Endpoints

The parsed content is organized into a feature map:

```
Feature Map:
├── Epic: User Authentication
│   ├── Feature: Email/password login
│   ├── Feature: Token refresh
│   └── Feature: Password reset
├── Epic: Data Import
│   ├── Feature: CSV upload
│   ├── Feature: Validation pipeline
│   └── Feature: Import status tracking
└── Epic: API Endpoints
    ├── POST /api/auth/login
    ├── POST /api/auth/refresh
    ├── POST /api/import/upload
    └── GET  /api/import/{id}/status
```

Each feature is tagged with:
- Source document it came from
- Confidence level (explicit requirement vs inferred)
- Related features (cross-references)

---

## Stage 2: Ticket Decomposition (--from-sources only)

Transforms the feature map into individual ticket files following a numbering convention.

### 2.1 Numbering Convention

Tickets are numbered by functional area using hundred-blocks:

| Range | Area | Examples |
|-------|------|----------|
| 1XX | Authentication & Authorization | PROJ-101 Login, PROJ-102 Token Refresh |
| 2XX | Data Import | PROJ-201 CSV Upload, PROJ-202 Validation |
| 3XX | Data Export | PROJ-301 PDF Generation, PROJ-302 CSV Export |
| 4XX | Core Domain / CRUD | PROJ-401 Create Asset, PROJ-402 List Assets |
| 5XX | Search & Filtering | PROJ-501 Full-text Search, PROJ-502 Faceted Filters |
| 6XX | Notifications | PROJ-601 Email Notifications, PROJ-602 Webhooks |
| 7XX | Admin & Configuration | PROJ-701 User Management, PROJ-702 Settings |
| 8XX | Integration / External | PROJ-801 S3 Integration, PROJ-802 Auth0 Setup |
| 9XX | Infrastructure & DevOps | PROJ-901 CI Pipeline, PROJ-902 Monitoring |

The project prefix (e.g., `PROJ`) is read from `.atelier/config.yaml` or inferred from the repository name.

### 2.2 Decomposition Logic

Each feature is decomposed into one or more tickets:

1. **Single-endpoint features** become a single ticket
   - Example: `POST /api/auth/login` -> PROJ-101

2. **CRUD features** are split into individual operations
   - Example: Asset CRUD -> PROJ-401 (Create), PROJ-402 (Read), PROJ-403 (Update), PROJ-404 (Delete), PROJ-405 (List)

3. **Multi-layer features** are kept as one ticket but the plan will address layers
   - Example: CSV Import (upload + validate + store) -> PROJ-201 (single ticket, multi-layer plan)

4. **Cross-cutting concerns** get their own tickets
   - Example: Auth middleware -> PROJ-100, Error handling -> PROJ-900

### 2.3 Ticket File Generation

Each ticket is written to `.claude/tickets/<TICKET-ID>.md` using the ticket template (see Ticket Template Structure below).

---

## Stage 3: Dependency Analysis

Parses and validates the dependency graph across all tickets.

### 3.1 Parse Dependencies

For each ticket, read the `blocked_by` and `blocks` fields from frontmatter:

```yaml
---
id: PROJ-201
blocked_by:
  - PROJ-101   # Needs auth before import
  - PROJ-401   # Needs asset model before import
blocks:
  - PROJ-301   # Export depends on import data
---
```

### 3.2 Dependency Rules

The following rules are applied automatically when dependencies are not explicitly declared:

**Auth blocks all authenticated endpoints:**
- Any ticket in the 2XX-8XX range that requires authentication is implicitly blocked by the auth ticket (typically X00 or X01 in the 1XX range)
- Exception: Tickets explicitly marked `auth: none` in frontmatter

**CRUD chain ordering:**
- Create blocks Read (need data to read)
- Create blocks Update (need entity to update)
- Create blocks Delete (need entity to delete)
- Create blocks List (need data to list)
- These are inferred within the same functional area

**Cross-functional dependencies:**
- Import depends on the target entity's Create operation
- Export depends on the target entity's Read/List operation
- Search depends on the target entity existing (Create)
- Notifications depend on the triggering operation

### 3.3 Graph Validation

After building the full dependency graph:

1. **Cycle detection** -- Run topological sort. If a cycle is detected, report the exact cycle path and abort.
   ```
   ERROR: Dependency cycle detected:
   PROJ-201 -> PROJ-301 -> PROJ-201
   ```

2. **Orphan detection** -- Warn about tickets with no dependencies and no dependents (isolated nodes). These may be missing connections.

3. **Depth calculation** -- Calculate the dependency depth for each ticket (longest path from a root node). This determines execution phase.

### 3.4 Dependency Graph Output

The graph is stored as an adjacency list in `status.json` and visualized in `WORKSTREAMS.md`:

```
PROJ-101 (depth 0) ─┬─> PROJ-201 (depth 1) ──> PROJ-301 (depth 2)
                     ├─> PROJ-401 (depth 1) ──> PROJ-402 (depth 2)
                     └─> PROJ-801 (depth 1)
```

---

## Stage 4: Workstream Grouping

Groups tickets into named workstreams and organizes them into execution phases.

### 4.1 Group by Functional Area

Tickets are grouped by their `area` field into workstreams:

```
WS-1: Authentication     [PROJ-101, PROJ-102, PROJ-103]
WS-2: Data Import         [PROJ-201, PROJ-202, PROJ-203]
WS-3: Core Domain         [PROJ-401, PROJ-402, PROJ-403, PROJ-404, PROJ-405]
WS-4: Data Export          [PROJ-301, PROJ-302]
WS-5: Infrastructure      [PROJ-901, PROJ-902]
```

Each workstream gets:
- A sequential ID (`WS-1`, `WS-2`, ...)
- A human-readable name (from the area)
- A list of ticket IDs in dependency order

### 4.2 Organize into Phases by Dependency Depth

Tickets are assigned to phases based on their dependency depth:

| Phase | Dependency Depth | Description |
|-------|-----------------|-------------|
| Phase 1 | depth = 0 | No dependencies. Can start immediately. |
| Phase 2 | depth = 1 | Blocked by Phase 1 tickets only. |
| Phase 3 | depth = 2 | Blocked by Phase 2 tickets. |
| Phase N | depth = N-1 | Blocked by Phase N-1 tickets. |

Within each phase, tickets from different workstreams can execute in parallel.

### 4.3 Critical Path

The critical path is the longest chain of dependent tickets. It determines the minimum total build time.

```
Critical Path: PROJ-101 -> PROJ-201 -> PROJ-301 -> PROJ-501
Total depth: 4 phases
Estimated duration: 4 x avg_build_time
```

The critical path is highlighted in `WORKSTREAMS.md` output.

### 4.4 Parallel Execution Slots

For each phase, calculate how many tickets can run in parallel:

```
Phase 1: 3 tickets (PROJ-101, PROJ-901, PROJ-100)  -- 3 parallel slots
Phase 2: 4 tickets (PROJ-201, PROJ-401, PROJ-801, PROJ-601) -- 4 parallel slots
Phase 3: 3 tickets (PROJ-301, PROJ-402, PROJ-501) -- 3 parallel slots
```

---

## Stage 5: Output Generation

Produces the final artifacts consumed by subsequent commands.

### 5.1 WORKSTREAMS.md Format

Written to `.claude/WORKSTREAMS.md`:

```markdown
# Workstreams

Generated: <timestamp>
Total tickets: <count>
Total phases: <count>
Critical path: <ticket chain>

## Phase 1 — Foundation

| Ticket | Summary | Workstream | Status | Blocked By |
|--------|---------|------------|--------|------------|
| PROJ-101 | User login | WS-1: Auth | ready | -- |
| PROJ-901 | CI pipeline | WS-5: Infra | ready | -- |

## Phase 2 — Core Features

| Ticket | Summary | Workstream | Status | Blocked By |
|--------|---------|------------|--------|------------|
| PROJ-201 | CSV import | WS-2: Import | ready | PROJ-101 |
| PROJ-401 | Create asset | WS-3: Domain | ready | PROJ-101 |

## Workstream Summary

| ID | Name | Tickets | Phase Span |
|----|------|---------|------------|
| WS-1 | Authentication | 3 | 1-2 |
| WS-2 | Data Import | 3 | 2-3 |
| WS-3 | Core Domain | 5 | 2-4 |
```

### 5.2 status.json Format

Written to `.claude/status.json`:

```json
{
  "version": "1.0",
  "created": "<ISO timestamp>",
  "project": "<project key>",
  "workstreams": {
    "WS-1": {
      "name": "Authentication",
      "tickets": ["PROJ-101", "PROJ-102", "PROJ-103"]
    }
  },
  "tickets": {
    "PROJ-101": {
      "summary": "User login",
      "area": "auth",
      "workstream": "WS-1",
      "phase": 1,
      "depth": 0,
      "status": "ready",
      "blocked_by": [],
      "blocks": ["PROJ-201", "PROJ-401"],
      "plan_status": "none",
      "build_status": "none",
      "pr_number": null,
      "pr_status": null,
      "retry_count": 0
    }
  },
  "phases": {
    "1": ["PROJ-101", "PROJ-901"],
    "2": ["PROJ-201", "PROJ-401", "PROJ-801"]
  },
  "critical_path": ["PROJ-101", "PROJ-201", "PROJ-301"],
  "dependency_graph": {
    "PROJ-101": [],
    "PROJ-201": ["PROJ-101"],
    "PROJ-301": ["PROJ-201"]
  }
}
```

### 5.3 Ticket Enrichment

Each ticket file in `.claude/tickets/` is updated with computed fields:

```yaml
---
# ... existing frontmatter ...
workstream: WS-1
phase: 1
depth: 0
# ... rest of frontmatter ...
---
```

---

## Ticket Template Structure

Tickets generated by Stage 2 (or expected by Stage 3 for the default entry point) follow this structure:

```markdown
---
id: PROJ-101
summary: User login with email and password
area: auth
priority: critical
status: ready
blocked_by: []
blocks:
  - PROJ-201
  - PROJ-401
  - PROJ-801
acceptance_criteria:
  - User can log in with valid email and password
  - Invalid credentials return 401 with error message
  - Successful login returns access token and refresh token
  - Tokens have appropriate expiry times
---

# PROJ-101: User Login

## Description

Implement email/password authentication using Auth0. The login endpoint
accepts credentials, validates them against Auth0, and returns JWT tokens.

## Technical Notes

- Auth0 tenant configuration required (see PROJ-800)
- Token format: JWT with RS256 signing
- Access token TTL: 15 minutes
- Refresh token TTL: 7 days

## Acceptance Criteria

- [ ] User can log in with valid email and password
- [ ] Invalid credentials return 401 with error message
- [ ] Successful login returns access token and refresh token
- [ ] Tokens have appropriate expiry times

## API Contract

POST /api/auth/login
Request: { email: string, password: string }
Response 200: { access_token: string, refresh_token: string }
Response 401: { error: string, message: string }
```

---

## Error Handling

### No Sources Provided (--from-sources with empty list)

```
ERROR: --from-sources requires at least one source path.
Usage: /workstream create --from-sources <path1> [path2] ...
```

### Partial Sources (some files missing)

```
WARNING: Could not read source: docs/missing-prd.md (file not found)
Continuing with 3 of 4 sources...
```

Processing continues with available sources. Missing sources are logged but do not abort the pipeline.

### No Tickets Found (default entry point)

```
ERROR: No ticket files found in .claude/tickets/
Run /specify and /design first, or use --from-sources to generate tickets.
```

### Existing Workstreams

When `.claude/WORKSTREAMS.md` or `.claude/status.json` already exist:

```
WARNING: Existing workstream artifacts found.
  - .claude/WORKSTREAMS.md (last modified: <date>)
  - .claude/status.json (last modified: <date>)

Options:
  1. Overwrite (regenerate from current tickets)
  2. Merge (add new tickets, keep existing status)
  3. Abort

Choose [1/2/3]:
```

- **Overwrite**: Regenerates everything. Loses status tracking for in-progress tickets.
- **Merge**: Adds new tickets, preserves status of existing tickets. New tickets get `status: ready`. Dependency graph is recalculated.
- **Abort**: No changes made.

### Dependency Cycle

```
ERROR: Dependency cycle detected. Cannot proceed.

Cycle: PROJ-201 -> PROJ-301 -> PROJ-501 -> PROJ-201

Fix the blocked_by/blocks fields in the affected ticket files and re-run.
```

This is a hard error. The pipeline aborts and no output is generated.
