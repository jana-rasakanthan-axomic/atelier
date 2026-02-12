# Workstream Create Pipeline

Reference documentation for the `/workstream create` pipeline. Describes how tickets are discovered or generated, analyzed for dependencies, grouped into workstreams, and output as actionable artifacts.

---

## Entry Points

### Default: From Existing Tickets (Stages 3-4-5)

```
/workstream create
```

Assumes tickets already exist in `.claude/tickets/`. Runs Stage 3 (Dependency Analysis), Stage 4 (Workstream Grouping), Stage 5 (Output Generation).

Use this when `/specify` and `/design` have already produced ticket files.

### From Sources: Full Pipeline (Stages 1-2-3-4-5)

```
/workstream create --from-sources <path1> [path2] ...
```

Starts from raw source documents (PRDs, user stories, API contracts) and generates tickets before organizing them. Runs all five stages.

---

## Pre-Stage: Ticket Discovery (Default Entry Point)

When no `--from-sources` flag is provided:

1. Glob `.claude/tickets/*.md` for all ticket files
2. Parse each ticket's YAML frontmatter: `id`, `status`, `blocked_by`, `blocks`, `area`, `priority`
3. Filter to tickets with status `ready` or `draft`
4. Validate required fields: `id`, `summary`, `area`

| Validation Error | Action |
|------------------|--------|
| Missing `id` | Skip ticket, warn user |
| Missing `area` | Prompt user to assign area |
| Circular dependency | Error with cycle path, abort |
| Duplicate ticket IDs | Error with list, abort |

---

## Stage 1: Source Analysis (--from-sources only)

### 1.1 Locate Source Files

Sources can be PRDs (.md, .txt), user story files, API contracts (openapi.yaml/json), design docs, or Confluence page IDs (fetched via MCP). For directories, glob for `.md`, `.yaml`, `.json` files within.

### 1.2 Parse Content

| Source Type | Extracts |
|-------------|----------|
| PRD (.md) | Features, requirements, constraints |
| User Stories (.md) | Actors, actions, outcomes, acceptance criteria |
| API Contract (.yaml/.json) | Endpoints, methods, request/response schemas |
| Design Doc (.md) | Components, data models, integration points |

### 1.3 Build Feature Map

Organize parsed content into epics and features. Each feature is tagged with source document, confidence level (explicit vs inferred), and related features.

---

## Stage 2: Ticket Decomposition (--from-sources only)

### 2.1 Numbering Convention

Tickets are numbered by functional area using hundred-blocks:

| Range | Area | Range | Area |
|-------|------|-------|------|
| 1XX | Authentication & Authorization | 5XX | Search & Filtering |
| 2XX | Data Import | 6XX | Notifications |
| 3XX | Data Export | 7XX | Admin & Configuration |
| 4XX | Core Domain / CRUD | 8XX | Integration / External |
| 9XX | Infrastructure & DevOps | | |

Project prefix read from `.atelier/config.yaml` or inferred from repository name.

### 2.2 Decomposition Logic

- **Single-endpoint features** -- one ticket
- **CRUD features** -- split into individual operations (Create, Read, Update, Delete, List)
- **Multi-layer features** -- one ticket, multi-layer plan
- **Cross-cutting concerns** -- own ticket (e.g., auth middleware, error handling)

### 2.3 Output

Each ticket written to `.claude/tickets/<TICKET-ID>.md`.

> See [schemas/status-json-and-templates.md](schemas/status-json-and-templates.md) for ticket template structure.

---

## Stage 3: Dependency Analysis

### 3.1 Parse Dependencies

Read `blocked_by` and `blocks` fields from each ticket's frontmatter.

### 3.2 Dependency Rules

Auto-applied when not explicitly declared:

- **Auth blocks authenticated endpoints** -- tickets in 2XX-8XX requiring auth are implicitly blocked by the auth ticket (exception: `auth: none` in frontmatter)
- **CRUD chain** -- Create blocks Read, Update, Delete, List (inferred within same area)
- **Cross-functional** -- Import depends on target Create; Export depends on target Read/List; Search depends on target Create; Notifications depend on triggering operation

### 3.3 Graph Validation

1. **Cycle detection** -- Topological sort. If cycle detected, report exact path and abort.
2. **Orphan detection** -- Warn about isolated tickets (no dependencies or dependents).
3. **Depth calculation** -- Longest path from a root node. Determines execution phase.

---

## Stage 4: Workstream Grouping

### 4.1 Group by Functional Area

Tickets grouped by `area` field. Each workstream gets a sequential ID (`WS-1`, `WS-2`, ...), a name, and tickets listed in dependency order.

### 4.2 Phases by Dependency Depth

| Phase | Depth | Description |
|-------|-------|-------------|
| Phase 1 | 0 | No dependencies. Start immediately. |
| Phase 2 | 1 | Blocked by Phase 1 only. |
| Phase N | N-1 | Blocked by Phase N-1. |

Within each phase, tickets from different workstreams execute in parallel.

### 4.3 Critical Path

The longest chain of dependent tickets. Determines minimum total build time. Highlighted in `WORKSTREAMS.md` output.

---

## Stage 5: Output Generation

Produces final artifacts consumed by subsequent commands.

> See [schemas/status-json-and-templates.md](schemas/status-json-and-templates.md) for WORKSTREAMS.md format, status.json schema, and ticket enrichment details.

---

## Error Handling

| Error | Behavior |
|-------|----------|
| `--from-sources` with empty list | Hard error: requires at least one source path |
| Some source files missing | Warning, continue with available sources |
| No tickets found (default entry) | Hard error: run `/specify` + `/design` first, or use `--from-sources` |
| Existing workstream artifacts | Prompt: Overwrite (regenerate), Merge (add new, keep status), or Abort |
| Dependency cycle detected | Hard error: report cycle path, abort, no output generated |
