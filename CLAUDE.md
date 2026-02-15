# Atelier — Process-Agnostic Development Toolkit

The master's workshop — battle-tested development workflows that work with any language or framework via the profile system.

Atelier encodes **how** you build software (TDD, outside-in, PR review) while profiles encode **what** tools you use. The process never changes; only the instruments do.

---

## Installation

| Method | Command |
|--------|---------|
| **Global** (~/.claude, recommended) | `git clone https://github.com/jana-rasakanthan-axomic/atelier.git ~/.claude/plugins/atelier` |
| **Project-specific** | `git clone https://github.com/jana-rasakanthan-axomic/atelier.git .atelier` |

For project-specific installs, add to `.claude/settings.json`: `{ "plugins": [".atelier"] }`

---

## Architecture Overview

```
CLAUDE.md (this file)
├── commands/     -> 15 slash commands (lifecycle pipeline)
├── agents/       -> 7 core agents (orchestration)
├── skills/       -> 10 skills with progressive disclosure
├── profiles/     -> Stack-specific configurations
├── scripts/      -> Shared bash scripts
├── templates/    -> Plan, ticket, ADR templates
└── docs/         -> Architecture & standards
```

- **Commands** define process (what steps to follow)
- **Agents** define roles (who does the work)
- **Skills** define knowledge (how to do each step well)
- **Profiles** define tools (which stack-specific tools to invoke)

---

## Profile System

Commands contain process logic. Stack specifics live in profile files. This separation is the core design principle.

```
/build command (process)      |    profile (stack)
─────────────────────────     |    ────────────────
1. RED: Write failing test    |    Test runner: ${profile.test_runner}
2. GREEN: Implement           |    Linter: ${profile.linter}
3. REFACTOR: Clean up         |    Type checker: ${profile.type_checker}
```

### Profile Resolution Order
1. **Explicit** — `.atelier/config.yaml` setting
2. **Auto-detect** — Marker files in project root (e.g., `pubspec.yaml`, `package.json`, `pyproject.toml`)
3. **Fallback** — Prompt the user to select a profile

### Built-in Profiles

| Profile | Marker File | Domain |
|---------|------------|--------|
| `python-fastapi` | `pyproject.toml` | Backend API |
| `flutter-dart` | `pubspec.yaml` | Mobile app |
| `react-typescript` | `tsconfig.json` | Web frontend |
| `opentofu-hcl` | `main.tf` | Infrastructure |

### Multi-Stack Workspace
```yaml
# .atelier/config.yaml
workspace:
  repos:
    backend:
      profile: python-fastapi
    client:
      profile: flutter-dart
    infra:
      profile: opentofu-hcl
```

Each repo resolves its own profile. Commands automatically use the correct tools based on which repo you are operating in.

---

## Quick Reference — Agents

| Agent | Role | Trigger |
|-------|------|---------|
| **Specifier** | Elicit requirements, write user stories | `/specify` |
| **Designer** | Produce API contracts, schemas, ADRs | `/design` |
| **Planner** | Break features into layered implementation plans | `/plan` |
| **Builder** | Implement code layer-by-layer with TDD | `/build`, `/fix` |
| **Reviewer** | Review PRs against standards and contracts | `/review` |
| **Verifier** | Run test suites, lint, type checks end-to-end | `/test` |
| **Author** | Write documentation, ADRs, changelogs | `/author` |

## Quick Reference — Commands

| Command | Purpose | Phase |
|---------|---------|-------|
| `/gather` | Collect context from user (braindump, URLs, docs) | Discovery |
| `/specify` | Generate user stories and acceptance criteria | Discovery |
| `/design` | Produce API contracts, ADRs, schemas | Design |
| `/plan` | Create layered implementation plan for a ticket | Planning |
| `/build` | Implement a plan layer-by-layer (TDD). `--loop` for automated ralph-loop | Build |
| `/fix` | Fix a bug or failing test. `--loop` for quality convergence | Build |
| `/test` | Run full verification suite | Verify |
| `/review` | Review a PR or code change. `--self` for self-review, `--self --loop` for automated self-review-fix | Review |
| `/commit` | Stage, commit, and optionally push | Ship |
| `/worklog` | Capture session summary and append to work log | Ship |
| `/workstream` | Manage parallel workstreams (create/status/next) | Orchestration |
| `/audit` | Audit codebase for issues | Analysis |
| `/analyze` | Analyze code structure, dependencies, complexity | Analysis |
| `/braindump` | Capture unstructured ideas into structured output | Discovery |
| `/init` | Initialize atelier in a new project | Setup |
| `/author` | Create or improve toolkit components. `--loop` for automated validation | Documentation |
| `/atelier-feedback` | Capture toolkit improvement ideas into IMPROVEMENTS.md | Feedback |

## Quick Reference — Skills

| Skill | Domain | Used By |
|-------|--------|---------|
| `building/` | Code generation patterns, layer templates | Builder |
| `testing/` | Test-first workflow, mocking strategies | Builder, Verifier |
| `design/` | Contract design, schema patterns, ADRs | Designer |
| `specify/` | User story format, acceptance criteria | Specifier |
| `review/` | PR review checklists, feedback categories | Reviewer |
| `analysis/` | Code metrics, dependency analysis | Audit, Analyze |
| `security/` | Auth patterns, input validation, secrets | Reviewer, Builder |
| `git-workflow/` | Branching, worktrees, PR conventions | All |
| `iterative-dev/` | Loop prompt templates for ralph-loop (`--loop` mode), including self-review and author | Builder, Reviewer, Author |
| `workstream/` | Workstream subcommand procedures | Workstream |
| `authoring/` | Documentation templates, ADR format | Author |

---

## Test-Driven Development (MANDATORY)

Every code change follows strict TDD. No exceptions.

### The TDD State Machine

```
WRITE_TESTS --> CONFIRM_RED --> WRITE_IMPL --> CONFIRM_GREEN --> VERIFY
     ^              |                               |
     |              v                               v
     +--- Tests pass (delete, retry)    Fail 3x --> ESCALATE
```

### State Transitions

| State | Action | Gate |
|-------|--------|------|
| **WRITE_TESTS** | Write test cases from the contract/spec | Tests written |
| **CONFIRM_RED** | Run `${profile.test_runner}` | Tests MUST fail. If they pass, delete and rewrite. |
| **WRITE_IMPL** | Write minimum code to make tests pass | Code written |
| **CONFIRM_GREEN** | Run `${profile.test_runner}` | Tests MUST pass. Max 3 fix attempts, then escalate. |
| **VERIFY** | Run `${profile.linter}` and `${profile.type_checker}` | Zero errors |

### STOP Signs

- **STOP** after CONFIRM_RED if tests pass. You wrote tests that do not test new behavior.
- **STOP** after 3 failed CONFIRM_GREEN attempts. Escalate to the user.
- **STOP** after completing one layer. Do not proceed to the next until instructed.

### What Gets Tested

| Layer | What to Test | Mocking Strategy |
|-------|-------------|-----------------|
| API layer | Request validation, response shape, status codes | Mock the service layer |
| Service layer | Business logic, edge cases, error handling | Mock the data access layer |
| Data access layer | Queries, filters, ordering, pagination | Mock the database or use test fixtures |
| External integrations | Request formation, response parsing, error mapping | Mock HTTP calls |

Layer names are defined by your active profile. The table above shows the general pattern.

### Mocking Strategy

- Mock **one layer down** only. Never mock the layer under test.
- Use the mocking library appropriate for your stack (specified in the active profile's test patterns section).
- Tests must be deterministic. No real network calls, no real databases, no real clocks.

---

## Design Principles

1. **YAGNI** -- Do not build features, abstractions, or infrastructure "just in case." Build exactly what the current ticket requires.
2. **KISS** -- Prefer the simplest solution. Between two approaches, pick the one with fewer moving parts.
3. **DRY** -- Extract duplication only after you see it three times. Premature abstraction is worse than duplication.
4. **Simplicity Over Cleverness** -- Write code a junior developer can read. Avoid metaprogramming, deep inheritance, and magic.
5. **Transparency** -- Every agent action should be visible: what it read, what it decided, what it changed, and why.
6. **Tool Design (ACI)** -- Commands and skills follow Anthropic's Agent-Computer Interface principles: clear scope, obvious inputs, predictable outputs, actionable errors.

---

## Strict Compliance (MANDATORY)

The agent MUST follow all command, agent, and skill procedures EXACTLY as defined.

### Rules

1. **No deviation** -- Execute every stage in the defined order. Do not skip, merge, reorder, or improvise stages unless the user explicitly permits it.
2. **No silent fallback** -- If a required tool or mode is unavailable (e.g., ralph-loop not installed when `--loop` is requested), STOP and report. Do NOT silently fall back to an alternative mode.
3. **No batch TDD** -- Each layer completes its full RED -> GREEN -> VERIFY cycle before the next layer begins. Writing tests for multiple layers before implementing any is PROHIBITED.
4. **Mandatory artifacts** -- When a procedure specifies output artifacts (pre-analysis report, build log), they MUST be generated. Omitting them is a process violation.
5. **Ask, don't guess** -- If a procedure is ambiguous or a prerequisite is missing, STOP and ask the user. Do not interpret or improvise.

---

## Tool Permissions

Commands declare their required tool permissions in frontmatter:

```yaml
---
allowed-tools:
  - Read
  - Glob
  - Grep
  - Edit
  - Write
  - Bash
---
```

Follow the principle of minimum permissions. A `/review` command should not need `Write`. A `/gather` command should not need `Bash`. Only request what the command actually uses.

---

## Getting Started -- Workflows

### Quick Fix
```
/gather -> /fix -> /review -> /commit
```

### Pre-PR Self-Review
```
/build -> /review --self --loop -> (PR created automatically when clean)
```

### Single Feature
```
/gather -> /specify -> /design -> /plan -> /build -> /review --self --loop -> /commit
```

### Feature Batch
```
/gather -> /specify -> /design -> /workstream create -> /plan -> approve -> /build
```

### Batch / Overnight
```
/workstream create -> /plan (all tickets) -> approve all -> /build --loop (all tickets)
```
Review each PR in the morning, then `/fix --loop` to address remaining quality issues.

### Session End
```
/worklog -> (compact / clear / exit)
```

---

## Git Workflow

Each ticket gets its own git worktree. Worktrees share git history but provide completely isolated working directories.

```
project/                    # Main worktree (your working directory)
project-TICKET-101/         # Builder worktree for ticket 101
project-TICKET-102/         # Builder worktree for ticket 102
```

**Branch naming:** `<initials>_<description>_<TICKET-ID>`

**Rules:**
- **Never** commit directly to `main` or `master`
- **Always** create a feature branch first
- **Always** submit changes via pull request
- **Always** use `git worktree` for parallel work to avoid conflicts

---

## Standards & Conventions

Process standards (TDD, PR review, commit messages) are defined in this file and in `skills/`.

Stack-specific conventions -- naming, file structure, import ordering, architectural layers -- are defined in your active profile. Run `/init` to see which profile is active and what conventions apply.

### Commit Messages
- Focus on **why**, not what
- One sentence, imperative mood
- Reference the ticket ID

### PR Descriptions
- Summary (1-3 bullet points)
- Test plan (checklist)
- Link to the ticket

---

## Hooks

Atelier registers Claude Code hooks in `.claude/settings.json` for deterministic enforcement:

| Hook | Type | Trigger | Purpose |
|------|------|---------|---------|
| `enforce-tdd-order.sh` | PreToolUse | Write/Edit | Blocks implementation writes if no test file modified first |
| `protect-main.sh` | PreToolUse | Bash | Blocks `git commit` on main/master |
| `regression-reminder.sh` | PostToolUse | Bash | Reminds to run full regression after targeted tests |

Hooks live in `scripts/hooks/`. To temporarily bypass TDD enforcement: `touch .claude/skip-tdd` (remove after).

---

## Session Logging

Before responding to any of the following, run `/worklog --auto` first:
- **compact** (manual or automatic)
- **clear** (or `/clear`)
- **exit** / **quit** / session end

This captures session context before it is lost. `--auto` skips user approval.

**Exception:** Skip if no meaningful work was done (only read-only commands or simple questions).

---

## Sources

This toolkit's process design is informed by:

- [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) -- Anthropic's research on agent orchestration patterns
- [Giving Claude Code the right skills](https://www.anthropic.com/engineering/claude-code-agent-skills) -- Anthropic's guide to skill design and progressive disclosure
