# Atelier Improvement Plan 2026

**Date:** 11 February 2026
**Status:** Living Document

---

## 1. Vision: The Architect's Operating System

### The Paradigm Shift

The role of the software engineer is fundamentally shifting. We are moving from **Code Authoring** to **System Architecture & Product Management**.

- **Coding is delegated**: LLMs can generate implementation code at incredible speed.
- **Verification is critical**: Humans cannot manually review every line of generated code at scale.
- **New Artifacts**: The source of truth is no longer the code—it is the **PRD**, the **TDD**, and the **Execution Plan**. Validating these high-level artifacts is higher leverage than linting syntax.

### The Toolkit's Purpose

Atelier is designed to be the "Operating System" for this new workflow. It enforces a strict pipeline:
`Idea -> Gather -> Specify -> Design -> Plan -> Build -> Review -> Deploy`

It uses **Progressive Disclosure** to manage context and **Agents** to execute work, allowing the human to focus on constraints, acceptance criteria, and architectural decisions.

---

## 2. Gap Analysis (Feb 2026)

### Context Bloat

- **Issue**: Core files (`commands/design.md`, `skills/design/SKILL.md`) are massive (1700+ lines), mixing user manuals with agent instructions.
- **Impact**: LLMs struggle with context limits, leading to instruction drift and higher "token tax".
- **Fix**: Separate "Agent Cards" (logic) from "User Manuals" (usage). See Section 3.1.

### Missing Execution Logic

- **Issue**: Critical components like `ralph-loop` (referenced in `/iterate`) are missing implementation.
- **Impact**: The "Self-Correcting Loop" (Build -> Test -> Fix -> Verify) cannot run autonomously.
- **Fix**: Implement `scripts/ralph_loop.py` using `typer`.

### Platform Dependency

- **Issue**: Documentation instructs `claude plugins install`, which is a hypothetical feature not present in standard CLIs.
- **Impact**: Friction in onboarding and session startup.
- **Fix**: Create `scripts/bootstrap.py` to auto-configure the environment.

---

## 3. Strategic Roadmap

### 3.1 Separation of Concerns (Refactor)

Splitting "Instructions for Agents" from "Instructions for Humans".

- **Commands Refactor**: Reduce all `commands/*.md` files to < 100 lines of strict executable logic.
- **Manual Creation**: Move detailed "How To", "Examples", and "Philosophy" to `docs/manuals/`.
- **Expected Result**: Faster tool routing, lower cost, higher success rate.

### 3.2 The "Architect's Console" (Scripting)

Empower the Architect with scripts that enforce the "PM Spec" constraints _before_ the LLM starts coding.

- **Adopt `typer`**: Build robust CLI tools for:
  - `scripts/validate_design.py`: Automated check of output schema.
  - `scripts/gather_interview.py`: Structured interview process for requirements.
  - `scripts/bootstrap.py`: One-command session setup.

### 3.3 Automated Verification (Evaluation)

If humans aren't reading the code, the Agent must verify itself.

- **Evaluation Framework**: Add `evals/*.json` to test Agent decision making.
- **Validation Steps**: All `commands/` must include a self-check step: "Run validation script X before returning summary."

---

## 4. Immediate Action Items

1.  **Refactor `/design`**:
    - Create `docs/manuals/design.md` (Human info).
    - Create `skills/design/reference/` (Static patterns).
    - Rewrite `commands/design.md` (Agent protocol).

2.  **Bootstrap**:
    - Create `scripts/bootstrap.py` to check for Python, Git, and active Profile.

3.  **Docs**:
    - Update `CLAUDE.md` to reference the new Bootstrap workflow instead of "plugins".

---

## 5. Detailed Feature Review & Remediation

This section breaks down the status of each major Atelier feature and the specific actions required to modernize it.

### 5.1 Author & Braindump (The Idea Phase)

#### Current State

- `commands/author.md` (Low complexity): Defines how to create new skills.
- `commands/braindump.md` (Medium complexity): 426 lines. Contains "Philosophy", "Input Formats", "When to Use".

#### Issues

- **Braindump**: Mixes user manual ("How to use the CLI") with agent instructions ("How to parse inputs").
- **Author**: Lacks a validation script to ensure new skills follow the schema (e.g. < 500 lines).

#### Remediation

- **Refactor**: Extract `docs/manuals/braindump.md` (User Guide).
- **Script**: `scripts/validate_skill.py` (for Author) to lint new agent files against best practices.

### 5.2 Gather & Specify (The PM Phase)

#### Current State

- `commands/gather.md` (271 lines): Hardcoded regex for Jira/GitHub URL detection.
- `commands/specify.md` (444 lines): Good focus, but mixes "Target User" info with "Stage 0" logic.

#### Issues

- **Gather**: URL detection logic in Markdown is brittle and costly.
- **Specify**: Relies on the LLM to guide the user through clarification questions ("Stage 0").

#### Remediation

- **Script**: `scripts/detect_source.py` (for Gather). Takes a string, returns `{"type": "jira", "id": "PROJ-123"}`.
- **Interactive CLI**: `scripts/gather_interview.py` (using `typer`). A structured questionnaire that ensures all PM requirements (Persona, Problem, KPI) are captured _before_ the LLM sees it.

### 5.3 Design (The Architect Phase)

#### Current State

- `commands/design.md` (1708 lines!!): CRITICAL VIOLATION.
- `skills/design/SKILL.md` (647 lines): CRITICAL VIOLATION.

#### Issues

- **Command**: Contains entire chapters on "Story Splitting Modes" and "Workflow".
- **skill**: Contains generic definitions of "What is a REST API?" which is redundant for advanced models.

#### Remediation

- **Modularization**:
  - `skills/design/reference/splitting_rules.md` (Static logic).
  - `skills/design/reference/checklist.md` (Validation rules).
- **Script**: `scripts/validate_design.py`. Automated schema check for generated tickets.

### 5.4 Workstream (The Project Manager Phase)

#### Current State

- `commands/workstream.md` (1471 lines): Defines complex dependency graph resolution in prose.

#### Issues

- **The "Imposter Script"**: This file describes an algorithm ("Search Priority: 1. Context, 2. Docs..."). LLMs are poor at executing priority search lists reliably.
- **State Management**: Tries to manage "Blocked By" logic via text parsing.

#### Remediation

- **Total Replacement**: Move logic to `scripts/workstream_engine.py` (Python).
- **Agent Role**: The Agent becomes a simple interface: "User asked for status -> Run `python scripts/workstream_engine.py status` -> Read JSON output -> Summarize."

### 5.5 Build (The Engineering Phase)

#### Current State

- `commands/build.md` (1061 lines): "Iron Rule of TDD" explicitly written out.

#### Issues

- **Trust**: Relies on Agent self-reporting "I ran the test".
- **Context**: Loads generic TDD philosophy even for simple tasks.

#### Remediation

- **Tooling**: `scripts/verify_tdd.py`. Checks timestamps of files: "Did `test_*.py` exist before `impl.py` was modified?"
- **Validation**: Agent cannot report "Done" until `verify_tdd.py` returns True.

---

## 6. External Plugin Integration

We will move away from custom implementations where standard tools exist.

- **Jira/GitHub**: Continue using MCP (Model Context Protocol) servers.
- **Documentation**: Explicitly link to `awesome-claude-plugins` in `docs/references.md` to encourage extending the toolkit.
- **Validation**: Ensure `scripts/bootstrap.py` checks for required MCP servers (e.g., `sqlite`, `filesystem`, `jira`) during startup.

---

## 7. Research & Ecosystem Review (Feb 2026)

**Source**: Official Claude Code Docs & Awesome Claude Plugins Registry.

### 7.1 Best Practice Validation

Our strategic roadmap aligns with official recommendations, but specific refinements are needed:

1.  **Context isolation is King**:
    - **Finding**: Subagents are explicitly recommended for "tasks that read many files" to avoid polluting the main context.
    - **Action**: Refactor `/workstream` and `/design` not just into scripts, but potentially into **Subagents** (`.claude/agents/`) that run in isolated windows rather than just CLI tools.

2.  **"Plan Mode" Adoption**:
    - **Finding**: Claude Code has a native `Plan Mode` (`--permission-mode plan`) designed for exploration and planning without execution.
    - **Action**: The `/plan` and `/design` commands should explicitly enforce or request `Plan Mode` to prevent accidental code writing.

3.  **Verification Pattern**:
    - **Finding**: "Give Claude a way to verify its work" is the #1 tip. Suggests including "verification criteria" in prompts.
    - **Action**: Our "Validation Scripts" (`scripts/validate_design.py`) are exactly this. We should double down on this pattern.

### 7.2 Plugin Ecosystem Opportunities

Instead of building everything from scratch, we should evaluate adopting:

- **Official Plugins**:
  - `pr-review-toolkit` (Anthropic): Likely superior to our custom `/review`.
  - `commit-commands`: Standardizes git operations.
- **Community Plugins**:
  - `code-architect` (for scaffolding).
  - `doc-cleaner` / `update-claudemd` (for maintenance).

### 7.3 "Smart" Context Management

- **Finding**: `CLAUDE.md` supports `@import` syntax for modularity.
- **Action**: Use `@docs/manuals/design.md` in prompts to load user manuals _only_ when the user is confused, rather than keeping them in the main context.
