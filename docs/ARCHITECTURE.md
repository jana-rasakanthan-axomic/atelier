# Atelier Architecture

## Core Concept: Process + Profile

Atelier separates **process** (how to develop) from **stack** (what tools to use).

```
Process (commands, agents, skills)    Stack (profiles)
────────────────────────────────     ──────────────────
TDD workflow: RED -> GREEN -> REFACTOR  Test runner: pytest / flutter test / jest
Quality gate: lint + type + test      Linter: ruff / dart analyze / eslint
Outside-in build order                Layers: Router->Service->Repo / Screen->Notifier->Repo
Code review: 4 personas               Patterns: FastAPI / Flutter / React
```

Commands never hardcode tools. They read the active profile to learn which linter, test runner, type checker, and build order to use.

---

## Directory Structure

```
atelier/
├── CLAUDE.md                    # Process-only entry point (~250 lines)
├── commands/                    # 15 slash commands (lifecycle pipeline)
│   ├── braindump.md            # Raw ideas -> PRD draft
│   ├── gather.md               # Fetch context from external tools
│   ├── specify.md              # Business rules + BDD for PM review
│   ├── design.md               # Technical design + tickets
│   ├── plan.md                 # Implementation planning
│   ├── build.md                # TDD feature implementation
│   ├── test.md                 # Standalone test command
│   ├── fix.md                  # Fix quality issues
│   ├── review.md               # Multi-persona code review
│   ├── commit.md               # Generate commit messages
│   ├── iterate.md              # Self-correcting loops
│   ├── workstream.md           # Batch orchestration
│   ├── deploy.md               # Deployment orchestration
│   ├── init.md                 # Project initialization
│   └── author.md               # Create/improve toolkit components
├── agents/                      # 7 core agents
│   ├── specifier.md            # Business rules + BDD extraction
│   ├── designer.md             # Technical design documents
│   ├── planner.md              # Implementation plans
│   ├── builder.md              # TDD code implementation
│   ├── reviewer.md             # Multi-persona review
│   ├── verifier.md             # Test execution + quality gates
│   └── author.md               # Toolkit component creation
├── skills/                      # 10 skill areas
│   ├── building/               # Process-only build patterns
│   ├── testing/                # Process-only test patterns (AAA)
│   ├── design/                 # Design ticket creation
│   ├── specify/                # Business rules + BDD
│   ├── review/                 # Review personas + checklists
│   ├── analysis/               # Coverage, gaps, risks
│   ├── security/               # STRIDE, OWASP
│   ├── git-workflow/           # Worktree, branch naming
│   ├── iterative-dev/          # Loop prompt templates
│   └── authoring/              # Agent/skill/command creation
├── profiles/                    # Stack-specific configurations
│   ├── _template.md            # Template for new profiles
│   ├── python-fastapi.md       # Python + FastAPI + SQLAlchemy
│   ├── python-fastapi/         # Patterns, tests, style
│   ├── flutter-dart.md         # Flutter + Dart + Riverpod
│   ├── flutter-dart/
│   ├── react-typescript.md     # React + TypeScript
│   ├── react-typescript/
│   └── opentofu-hcl.md        # OpenTofu infrastructure
│       └── opentofu-hcl/
├── scripts/                     # Shared bash scripts
│   ├── resolve-profile.sh     # Profile auto-detection
│   ├── worktree-manager.sh    # Git worktree lifecycle
│   ├── session-manager.sh     # Session tracking
│   ├── generate-branch-name.sh
│   └── quality-gate.sh        # Profile-aware quality checks
├── templates/                   # Document templates
│   ├── plan-template.md
│   ├── ticket-template.md
│   └── adr-template.md
└── docs/                        # Documentation
    ├── ARCHITECTURE.md          # This file
    ├── CONTRIBUTING.md
    └── PROFILES.md
```

---

## The Profile System

### What a Profile Contains

Each profile (e.g., `profiles/python-fastapi.md`) defines everything a command or agent needs to operate within a specific technology stack:

| Section | Purpose | Example (Python/FastAPI) |
|---------|---------|--------------------------|
| Detection | How to identify this stack | pyproject.toml + "fastapi" |
| Architecture Layers | Ordered layers for build | Router -> Service -> Repository -> External |
| Quality Tools | Linter, type checker, test runner | ruff, mypy, pytest |
| Allowed Bash Tools | Permissions for frontmatter | Bash(pytest:*), Bash(ruff:*) |
| Test Patterns | Where tests live, naming | tests/unit/test_*.py |
| Naming Conventions | File, class, function naming | snake_case.py, PascalCase |
| Code Patterns | Stack-specific patterns | Repository: select() not query() |
| Style Limits | Size and complexity rules | max 30 lines per function |
| Dependencies | Package manager commands | uv sync, uv add |
| Project Structure | Expected directory layout | src/, tests/ |

### Profile Resolution

Order of resolution (first match wins):

1. **Explicit config** -- `.atelier/config.yaml` contains `profile: python-fastapi`
2. **Auto-detect** -- `scripts/resolve-profile.sh` examines marker files in the working directory (e.g., `pyproject.toml` with `fastapi`, `pubspec.yaml` with `flutter`, `package.json` with `react`)
3. **User prompt** -- If detection is ambiguous (multiple stacks present, no clear winner), the command asks the user to choose

The resolve script exits with a single profile name on stdout. Commands consume this value and load the corresponding profile markdown.

### How Commands Use Profiles

```
/build .claude/plans/PROJ-123.md
  |
  +-- 1. Resolve profile -> python-fastapi
  |
  +-- 2. Read profile -> profiles/python-fastapi.md
  |     +-- layers: Router -> Service -> Repository
  |     +-- test_runner: pytest
  |     +-- linter: ruff check src/
  |     +-- type_checker: mypy src/
  |
  +-- 3. Execute TDD loop (process from command)
  |     +-- RED: Write test using profile's test patterns
  |     +-- RUN: ${profile.test_runner} (pytest -x --tb=short)
  |     +-- GREEN: Implement using profile's layer patterns
  |     +-- RUN: ${profile.test_runner} (pytest -v)
  |
  +-- 4. Quality gate (process from command)
        +-- Lint: ${profile.linter} (ruff check src/)
        +-- Type: ${profile.type_checker} (mypy src/)
        +-- Test: ${profile.test_runner} (pytest)
```

The process (TDD loop, quality gate) is defined by the command and agent. The specific tool invocations come from the profile. This means `/build` works identically for a FastAPI backend and a Flutter app -- only the tool commands differ.

### Multi-Stack Workspaces

For projects spanning multiple stacks (e.g., backend + mobile + infra):

```yaml
# .atelier/config.yaml
workspace:
  repos:
    mise-backend:
      path: ./mise-backend
      profile: python-fastapi
    mise-client:
      path: ./mise-client
      profile: flutter-dart
    mise-infra:
      path: ./mise-infra
      profile: opentofu-hcl
```

Commands auto-resolve the correct profile based on which subdirectory they operate in. A `/build` invoked within `mise-backend/` loads `python-fastapi`; the same `/build` invoked within `mise-client/` loads `flutter-dart`. No configuration changes needed.

---

## Command -> Agent -> Skill Flow

### How a Command Executes

```
User: /build .claude/plans/PROJ-123.md
  |
  +-- Command (commands/build.md)
  |   +-- Stage 0: Setup (worktree, session)
  |   +-- Stage 1: Parse plan
  |   +-- Stage 2: Resolve profile
  |   +-- Stage 3-5: Delegate to agents
  |
  +-- Agent (agents/builder.md)
  |   +-- Reads plan requirements
  |   +-- Uses profile for tool commands
  |   +-- Follows TDD state machine
  |
  +-- Skills (skills/building/, skills/testing/)
      +-- Process-only patterns (AAA, TDD)
      +-- Profile patterns (from profiles/{name}/patterns/)
```

### Separation of Concerns

| Layer | Contains | Does NOT Contain |
|-------|----------|------------------|
| **Commands** | Stages, workflow, gates, user interaction | Tool commands, layer names |
| **Agents** | Orchestration, state machines, decision logic | Hardcoded tools |
| **Skills** | Process patterns (TDD, AAA, review personas) | Framework-specific code |
| **Profiles** | Tools, layers, naming, code patterns | Process logic |

This separation is the central architectural invariant. When adding a new stack, you create a profile. When improving the development process, you modify commands, agents, or skills. Neither side touches the other.

---

## Lifecycle Pipeline

### Linear Variant (Single Feature)

```
/braindump -> /gather -> /specify -> /design -> /plan -> /build -> /review -> /commit
     |           |          |          |         |        |         |         |
  Raw ideas   Context   BDD rules   Tickets   Plans   Code    Review    Ship
              from       for PM     for eng           with     with
              external   review     teams             TDD      personas
```

Each command in the pipeline produces artifacts that the next command consumes:

| Command | Input | Output |
|---------|-------|--------|
| `/braindump` | Raw user ideas, notes | Structured PRD draft |
| `/gather` | URLs, docs, external tools | Context files in `.claude/context/` |
| `/specify` | PRD + context | Business rules + BDD scenarios |
| `/design` | Specifications | Design documents + tickets |
| `/plan` | Tickets | Implementation plans with layer breakdown |
| `/build` | Plans | Working code with tests |
| `/review` | Code changes | Review feedback from 4 personas |
| `/commit` | Staged changes | Conventional commit message |

### Batch Variant (Multiple Features)

```
/gather -> /specify -> /design -> /workstream create -> plan -> approve -> build -> pr-check
```

The `/workstream` command orchestrates multiple tickets in parallel, managing dependencies between workstreams and coordinating builder agents across isolated worktrees.

### Supporting Commands

| Command | Role in Pipeline |
|---------|-----------------|
| `/test` | Run tests outside the build loop |
| `/fix` | Fix lint, type, or test failures |
| `/build --loop` | Self-correcting TDD build via ralph-loop |
| `/deploy` | Push artifacts to environments |
| `/init` | Bootstrap a new project with profile detection |
| `/author` | Create or improve toolkit components |

---

## Agent Architecture

### The 7 Agents

| Agent | Role | Key Skills | Permission Level |
|-------|------|------------|-----------------|
| **Specifier** | Extract business rules and BDD scenarios | specify/ | Read-only |
| **Designer** | Create technical design documents and tickets | design/ | Read + Write tickets |
| **Planner** | Create implementation plans with layer breakdown | analysis/ | Read + Write plans |
| **Builder** | TDD code implementation, layer by layer | building/, testing/ | Full (profile tools) |
| **Reviewer** | Multi-persona code review | review/ | Read-only |
| **Verifier** | Execute quality gates (lint, type, test) | testing/ | Profile test/lint tools |
| **Author** | Create and improve toolkit components | authoring/ | Full |

### Agent Invocation

Agents are never invoked directly by users. Commands invoke agents internally:

```
/build  ->  Builder agent  (primary)
            Verifier agent (quality gates)

/review ->  Reviewer agent (all 4 personas)

/plan   ->  Planner agent  (plan creation)

/design ->  Designer agent (ticket creation)
```

### Builder Agent: TDD State Machine

The builder agent is the most complex agent. It operates as a strict state machine:

```
WRITE_TESTS -> CONFIRM_RED -> WRITE_IMPL -> CONFIRM_GREEN -> VERIFY
     |              |              |               |             |
  Write test    Run tests     Write code      Run tests     Lint +
  cases         (must FAIL)   (minimum)       (must PASS)   Type check
```

State transition rules:

| Current State | Condition | Next State |
|---------------|-----------|------------|
| WRITE_TESTS | Tests written | CONFIRM_RED |
| CONFIRM_RED | Tests FAIL | WRITE_IMPL |
| CONFIRM_RED | Tests PASS | WRITE_TESTS (delete and retry) |
| WRITE_IMPL | Code written | CONFIRM_GREEN |
| CONFIRM_GREEN | Tests PASS | VERIFY |
| CONFIRM_GREEN | Tests FAIL (attempt < 3) | WRITE_IMPL (fix) |
| CONFIRM_GREEN | Tests FAIL (attempt = 3) | ESCALATE |
| VERIFY | Lint/type pass | STOP |

The CONFIRM_RED state is the most important gate. If tests pass before implementation exists, they are testing the wrong thing. The builder deletes them and starts over.

### Reviewer Agent: 4 Personas

The reviewer agent evaluates code from four distinct perspectives:

1. **Correctness** -- Does the code do what the spec says?
2. **Security** -- OWASP, input validation, auth checks
3. **Maintainability** -- Readability, naming, complexity
4. **Performance** -- N+1 queries, unnecessary allocations, scaling concerns

Each persona produces independent findings. Conflicts between personas are surfaced for human resolution.

---

## Build Order: Outside-In

Atelier builds features from the outside in, starting with what the user sees:

```
Stage 3a: Router (API Layer)     <- Start here (user-facing contract)
Stage 3b: Service (Business)     <- Business logic, DTOs
Stage 3c: Repository (Data)      <- Database access
Stage 3d: External (Gateway)     <- Third-party integrations
Stage 3e: Models (ORM)           <- Database entities (if new)
```

Each stage is a separate TDD cycle. The builder completes one stage entirely (RED -> GREEN -> VERIFY) before moving to the next.

For a Flutter profile, the equivalent order would be:

```
Stage 3a: Screen (UI Layer)      <- Start here (user-facing)
Stage 3b: Notifier (State)       <- State management
Stage 3c: Repository (Data)      <- API client calls
Stage 3d: Models (Domain)        <- Data classes
```

The principle is the same regardless of stack: start at the boundary the user interacts with and work inward.

---

## Worktree Isolation

### Why Worktrees?

Each build operates in its own git worktree, a sibling directory to the main project:

```
/path/to/repos/
├── mise-backend/              # Main project (user's working directory)
├── mise-backend-PROJ-101/     # Builder worktree for ticket PROJ-101
├── mise-backend-PROJ-102/     # Builder worktree for ticket PROJ-102
└── mise-backend-PROJ-103/     # Builder worktree for ticket PROJ-103
```

Benefits:

- **True isolation** -- Each ticket has its own directory. No file conflicts between parallel builds.
- **Parallel execution** -- Multiple builder agents work simultaneously without interference.
- **Clear identification** -- Directory name shows which ticket it belongs to.
- **Safe rollback** -- Failed builds do not affect the main project or other worktrees.

### Worktree Lifecycle

```
/build (start)    ->  worktree-manager.sh create  ->  New worktree + branch
/build (complete) ->  git commit + push            ->  PR created
/build (cleanup)  ->  worktree-manager.sh remove   ->  Worktree deleted
```

The `WORKTREE_PATH` environment variable is set for every builder invocation. All file operations use this path, never the main project directory.

---

## Session Tracking

Each command invocation creates a session:

```
SESSION_ID: a1b2c3d4
BRANCH_NAME: JRA_add-assets_PROJ-101
WORKTREE_PATH: /path/to/project-PROJ-101
TICKET_ID: PROJ-101
```

Sessions track:

- Which layer is currently being built
- Retry attempt count (max 3 before escalation)
- Files created and modified
- Test results per stage

Session state enables resumption after interruption and provides debugging context when builds fail.

---

## Scripts

Scripts are the only components that execute directly on the host system. They handle operations that markdown-based commands and agents cannot:

| Script | Purpose |
|--------|---------|
| `resolve-profile.sh` | Detect stack from marker files, return profile name |
| `worktree-manager.sh` | Create, list, and remove git worktrees |
| `session-manager.sh` | Create and query session state |
| `generate-branch-name.sh` | Produce consistent branch names from ticket IDs |
| `quality-gate.sh` | Run lint + type + test using profile-specified tools |

Scripts read the active profile to determine which tools to invoke. `quality-gate.sh` does not hardcode `ruff` or `pytest` -- it reads the profile's quality tools section and executes whatever is specified there.

---

## Design Decisions

### Why Profiles, Not Plugins?

Profiles are simpler. They are markdown files that commands read. There is no plugin API, no hooks, no extension points, no runtime registration. Adding a new stack means writing one markdown file following `_template.md`. The barrier to entry is reading a template and filling in sections.

### Why Markdown, Not YAML/JSON?

LLMs read markdown natively. Profiles are consumed by Claude, not by compiled programs. Markdown with structured sections (headers, tables, code blocks) is the most natural format for LLM consumption while remaining human-readable and version-control-friendly.

YAML is used only for `.atelier/config.yaml` where machine parsing is required (profile resolution, workspace configuration).

### Why Process and Stack Separation?

Same workflow, any language. The TDD loop (RED -> GREEN -> REFACTOR) is universal. The quality gate (lint + type + test) is universal. Only the specific tool invocations change per stack. Maintaining ONE process and N profiles means:

- Process improvements benefit all stacks immediately
- New stacks require zero process changes
- Testing a process change requires testing it once, not once per stack

### Why Outside-In Build Order?

Contract-first development. Starting from what the user sees (API endpoint, UI screen) and working inward produces several advantages:

- Tests are written against the contract before implementation exists
- Implementation is driven by requirements, not by database schema
- Integration points are defined early, reducing late-stage surprises
- Each layer can be mocked at the boundary below it, enabling true unit tests

### Why 3-Attempt Escalation?

Diminishing returns. If the builder cannot make tests pass in 3 attempts, the problem is likely architectural (wrong approach, missing dependency, circular import) rather than a simple code bug. Continuing to retry wastes time. Escalating with full context (error messages, files affected, attempts made) gives a human the information needed to unblock quickly.

### Why Slash Commands, Not Chat?

Structured invocation. Slash commands provide:

- **Discoverability** -- Users can list available commands
- **Consistency** -- Same command name always triggers the same workflow
- **Composability** -- Commands can invoke other commands
- **Auditability** -- Session logs show exactly which commands were run

Free-form chat is still supported for questions, clarifications, and ad-hoc tasks. Commands handle the structured development workflow.
