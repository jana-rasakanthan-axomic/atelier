# Design Agent Workflow

## Stage 0: Clarification Gate

**Goal**: Determine if requirements are clear enough to proceed.

1.  **Analyze Input**: Read the provided PRD or context.
2.  **Evaluate Clarity**: check for:
    - **Scale**: Data volume (10s, 1000s, 100k+).
    - **Performance**: Latency targets.
    - **Format**: Input/output schemas.
    - **Security**: Auth requirements.
3.  **Action**:
    - If **CLEAR**: Proceed to Stage 1.
    - If **UNCLEAR**: Use `AskUserQuestion` to ask a _single batch_ of clarification questions.

## Stage 1: Assessment

**Goal**: Determine complexity level.

1.  **Research**: Check codebase for existing patterns using `grep_search` or `file_search`.
2.  **Classify**:
    - **Simple**: Single approach, clear path. Skip to Stage 3.
    - **Complex**: Multiple approaches, tradeoffs involved. Proceed to Stage 2.

## Stage 2: Alternatives (Complex Only)

**Goal**: Select the best architecture.

1.  **Generate**: Propose 2-3 viable architectures (Sync vs Async, storage options, etc.).
2.  **Present**: Show a table of Pros/Cons/Complexity/Cost.
3.  **Checkpoint**: Save analysis to `.claude/design/{feature}-analysis.md`.
4.  **Decide**: Ask user to choose the approach.

## Stage 3: Technical Design Document (TDD)

**Goal**: write the blueprint.

1.  **Draft**: Fill out `skills/design/templates/tdd.md`.
2.  **Validate**: Ensure it addresses all Business Rules from `/specify`.
3.  **Review**: Ask user for approval before generating tickets.

## Stage 4: Ticket Generation

**Goal**: Create implementation tasks.

1.  **Split**: Break TDD into tickets based on the mode (`monolith` or `services`).
2.  **Create**: Write tickets to `.claude/tickets/TICKET-*.md`.
    - Use `skills/design/templates/detailed-ticket.md`.
    - Ensure logical dependencies (Ticket A blocks Ticket B).
3.  **Summary**: Present a list of created tickets.
