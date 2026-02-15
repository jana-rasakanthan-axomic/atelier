# User Manual: /braindump

## Overview

The `/braindump` command captures raw, unstructured ideas and transforms them into a structured PRD (Product Requirement Document) draft. It accepts input in any form -- typed text, files, voice transcripts, or images -- and outputs a prioritized, gap-analyzed draft ready for downstream commands.

## Target Audience

Anyone starting a new feature or product from scratch, before requirements are formalized.

## When to Use

- You have raw ideas and need structure before planning.
- Starting a new feature or product from scratch.
- Converting meeting notes or brainstorms into requirements.
- Before `/gather` -- when there is no ticket or external source yet.

## Input Formats

```bash
/braindump                          # Interactive mode (guided questions)
/braindump "I want an app that..."  # From inline text
/braindump path/to/notes.md        # From a file (markdown, text)
/braindump path/to/transcript.txt  # From a voice transcript
/braindump path/to/sketch.png      # From an image or sketch
/braindump --name my-feature       # Specify output filename
/braindump --interactive            # Force interactive mode even with input
```

## Interactive Questions

When no input is provided (or `--interactive` is used), the command asks these questions in a single batch:

1. **Problem** -- What problem are you trying to solve? (one sentence)
2. **Users** -- Who is this for? (target users/audience)
3. **Features** -- What are the key things it should do? (bullet points, rough is fine)
4. **Boundaries** -- What should it NOT do? (out of scope)
5. **Constraints** -- Any constraints? (tech, budget, timeline, platform)
6. **Context** -- Anything else I should know? (inspiration, existing solutions)

You do not need to answer every question. Unanswered items become "Open Questions" in the draft.

## How Extraction Works

The command scans your input for signals and maps them to PRD elements:

| PRD Element | Signals It Looks For |
|-------------|---------------------|
| Problem Statement | "the problem is...", "we need...", "currently..." |
| Target Users | "users", "customers", "admins", "developers" |
| Key Features | "should be able to...", "must have...", "I want..." |
| Constraints | "can't", "must not", "limited to", "only" |
| Out of Scope | "not now", "later", "won't", "skip" |
| Non-Functional | "fast", "secure", "scalable", "accessible" |

After extraction, the command identifies gaps (missing users, vague scope, conflicting needs) and asks up to 5 clarifying questions in a single batch. Anything unresolved becomes an "Open Question" in the output.

## Output

A PRD draft is written to `.claude/context/{feature-name}-prd-draft.md` containing:

1. Header (status, date, source)
2. Problem Statement
3. Target Users / Personas
4. User Stories (Given/When/Then)
5. Feature Requirements (P0 Must Have, P1 Should Have, P2 Nice to Have)
6. Non-Functional Requirements
7. Out of Scope (with rationale)
8. Open Questions
9. Assumptions
10. Next Steps

The command never invents requirements -- it only structures what you provided, marking uncertain items with `[?]`.

## What to Do Next

After braindump, the draft is ready for refinement:

| Next Command | Purpose |
|-------------|---------|
| `/gather {prd-file}` | Enrich with external context (APIs, docs) |
| `/specify {prd-file}` | Extract business rules and BDD scenarios |
| `/design {prd-file}` | Create technical design and tickets |
| Edit the draft directly | Add details, resolve open questions |

## Tips

- **Keep it rough.** The command is designed for messy input. Do not over-polish before running it.
- **One feature per braindump.** Split large ideas into separate runs.
- **Use `--name`** to keep output filenames predictable across sessions.
- **Images work.** Sketch a UI on paper, take a photo, and pass the path. The command will describe what it sees.
