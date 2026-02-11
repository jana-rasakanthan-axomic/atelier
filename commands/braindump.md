---
name: braindump
description: Capture raw ideas and transform them into a structured PRD draft
allowed-tools: Read, Write, Edit, Grep, Glob, AskUserQuestion
---

# /braindump

Capture raw ideas and transform them into a structured PRD draft.

## Input Formats

- `/braindump` - Interactive mode (ask structured questions)
- `/braindump "I want an app that..."` - From inline text
- `/braindump path/to/notes.md` - From a file (markdown, text, etc.)
- `/braindump path/to/transcript.txt` - From a voice transcript
- `/braindump path/to/sketch.png` - From an image/sketch
- `/braindump --name my-feature` - Specify output filename
- `/braindump --interactive` - Force interactive mode even with input

## When to Use

- You have raw ideas and need structure before planning
- Starting a new feature or product from scratch
- Converting meeting notes or brainstorms into requirements
- Before `/gather` -- when there is no ticket or external source yet

## When NOT to Use

- Requirements already structured -> use `/gather` or `/plan` directly
- Ticket already exists in Jira/GitHub -> use `/gather`
- Refining an existing PRD -> edit directly
- Implementation ready -> use `/build`

## Output Location

Default: `.claude/context/{feature-name}-prd-draft.md`

| Input Type | Filename Pattern |
|------------|------------------|
| Inline text | `{derived-from-content}-prd-draft.md` |
| File input | `{input-filename}-prd-draft.md` |
| Interactive | `{user-provided-name}-prd-draft.md` |
| `--name` flag | `{specified-name}-prd-draft.md` |

---

## Workflow (4 Stages)

### Stage 0: Capture

Accept raw input in whatever form it arrives.

**Input Detection:**

| Pattern | Type | Action |
|---------|------|--------|
| No arguments | Interactive | Enter interactive questioning mode |
| Quoted string | Inline text | Parse directly |
| Path to `.md` / `.txt` | Document | Read file contents |
| Path to `.png` / `.jpg` | Image/Sketch | Read and describe visual content |
| `--interactive` flag | Interactive | Force interactive mode regardless of other input |

**Interactive Mode (no input provided):**

Ask the following in a single batch using `AskUserQuestion`. One pass only -- no follow-ups.

1. What problem are you trying to solve? (one sentence)
2. Who is this for? (target users/audience)
3. What are the key things it should do? (bullet points, rough is fine)
4. What should it NOT do? (boundaries, out of scope)
5. Any constraints? (tech, budget, timeline, platform)
6. Anything else I should know? (context, inspiration, existing solutions)

**File/Text Mode:** Read content, extract key themes and requirements, note existing structure, identify input format.

---

### Stage 1: Structure

Extract structured elements from raw input and identify gaps.

**Extraction Targets:**

| Element | Source Signals |
|---------|---------------|
| Problem Statement | "the problem is...", "we need...", "currently..." |
| Target Users | "users", "customers", "admins", "developers" |
| Key Features | "should be able to...", "must have...", "I want..." |
| Constraints | "can't", "must not", "limited to", "only" |
| Out of Scope | "not now", "later", "won't", "skip" |
| Non-Functional | "fast", "secure", "scalable", "accessible" |

**Gap Analysis:** After extraction, identify missing users, vague scope, missing constraints, conflicting needs, or missing priority signals.

**Clarifying Questions (ONE TIME ONLY):** If gaps are found, ask a single batch of max 5 clarifying questions via `AskUserQuestion`. Anything unanswered becomes "Open Questions" in the draft. If no significant gaps, skip and proceed.

---

### Stage 2: Draft PRD

Write a structured PRD draft to `.claude/context/{feature-name}-prd-draft.md`.

**PRD Sections:**

1. **Header** -- Status (DRAFT), created date, source
2. **Problem Statement** -- Why this needs to exist
3. **Target Users / Personas** -- Table of persona, description, primary need
4. **User Stories** -- Given/When/Then format per persona
5. **Feature Requirements** -- Prioritized: Must Have (P0), Should Have (P1), Nice to Have (P2)
6. **Non-Functional Requirements** -- Performance, security, scalability, accessibility
7. **Out of Scope** -- Items excluded with rationale
8. **Open Questions** -- Unresolved items needing answers before implementation
9. **Assumptions** -- Stated assumptions
10. **Next Steps** -- Recommended follow-on commands

**Writing Rules:**
- Fill sections with extracted content; leave clear placeholders for unknowns
- Mark uncertain items with `[?]` prefix
- Prioritize features based on input signals; default to "Must Have" if no signals
- Do NOT invent requirements -- only structure what was provided

---

### Stage 3: Review

Present the draft summary and offer next actions.

1. Summarize the PRD draft (do not repeat the full document)
2. Highlight open questions that need resolution
3. Offer next steps:
   - `/gather {prd-file}` -- Enrich with external context
   - `/specify {prd-file}` -- Extract business rules and BDD scenarios
   - `/design {prd-file}` -- Create technical design
   - Edit the draft directly
   - Re-run `/braindump --interactive` with different input

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Input file not found | Report path, suggest checking it, offer interactive mode |
| Input empty or unreadable | Report issue, fall back to interactive mode |
| Image cannot be interpreted | Report failure, ask user to describe in text |
| User skips all interactive questions | Report insufficient input, explain minimum needed (problem statement or feature description), offer single open-ended prompt |

## Integration

| Command | Usage |
|---------|-------|
| `/gather` | Enrich PRD draft with external context |
| `/specify` | Extract business rules and BDD scenarios from PRD draft |
| `/design` | Create technical design from PRD draft |
| `/plan` | Create implementation plan from PRD draft |

## Scope Limits

- Single feature or product area per braindump
- Max input size: 5000 lines (suggest splitting larger documents)
- Max clarifying questions: 5 (one batch, no follow-ups)
- Output is a DRAFT -- not a final PRD
