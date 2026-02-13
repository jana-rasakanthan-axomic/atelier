# Architecture Design Decisions

Rationale behind key architectural choices in Atelier.

---

## Why Profiles, Not Plugins?

Profiles are simpler. They are markdown files that commands read. There is no plugin API, no hooks, no extension points, no runtime registration. Adding a new stack means writing one markdown file following `_template.md`. The barrier to entry is reading a template and filling in sections.

## Why Markdown, Not YAML/JSON?

LLMs read markdown natively. Profiles are consumed by Claude, not by compiled programs. Markdown with structured sections (headers, tables, code blocks) is the most natural format for LLM consumption while remaining human-readable and version-control-friendly.

YAML is used only for `.atelier/config.yaml` where machine parsing is required (profile resolution, workspace configuration).

## Why Process and Stack Separation?

Same workflow, any language. The TDD loop (RED -> GREEN -> REFACTOR) is universal. The quality gate (lint + type + test) is universal. Only the specific tool invocations change per stack. Maintaining ONE process and N profiles means:

- Process improvements benefit all stacks immediately
- New stacks require zero process changes
- Testing a process change requires testing it once, not once per stack

## Why Outside-In Build Order?

Contract-first development. Starting from what the user sees (API endpoint, UI screen) and working inward produces several advantages:

- Tests are written against the contract before implementation exists
- Implementation is driven by requirements, not by database schema
- Integration points are defined early, reducing late-stage surprises
- Each layer can be mocked at the boundary below it, enabling true unit tests

## Why 3-Attempt Escalation?

Diminishing returns. If the builder cannot make tests pass in 3 attempts, the problem is likely architectural (wrong approach, missing dependency, circular import) rather than a simple code bug. Continuing to retry wastes time. Escalating with full context (error messages, files affected, attempts made) gives a human the information needed to unblock quickly.

## Why Slash Commands, Not Chat?

Structured invocation. Slash commands provide:

- **Discoverability** -- Users can list available commands
- **Consistency** -- Same command name always triggers the same workflow
- **Composability** -- Commands can invoke other commands
- **Auditability** -- Session logs show exactly which commands were run

Free-form chat is still supported for questions, clarifications, and ad-hoc tasks. Commands handle the structured development workflow.
