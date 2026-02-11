# Specify Skill

PM-facing behavioral specification before engineering design. Extracts business rules and generates BDD scenarios in business language for Product Manager review and approval.

## Purpose

Support the **specification phase** by:
1. Extracting business rules from PRDs in PM-readable language
2. Generating BDD scenarios using user-action language (no technical jargon)
3. Generating flow diagrams (Mermaid flowcharts + sequence diagrams) for visual PM review
4. Creating PM-approved artifacts that feed into `/design`

## Scope

**Business behavior only** — no engineering artifacts.

**Focus areas:**
- Business rules (authorization, validation, rate limits, retention, privacy, logic, integration)
- BDD scenarios in Gherkin format (user flows, authorization)
- Flow diagrams in Mermaid (flowcharts for user decisions, sequence diagrams for multi-party interactions)
- PM-readable language throughout

**Out of scope:**
- API paths, HTTP methods, status codes
- Database schemas, SQL, migrations
- Service/repository architecture
- Code examples, method signatures
- Technical error formats (JSON error bodies)
- Codebase research (no Grep, Glob, Bash)

## When to Use

- **Before `/design`** — PM validates behavior before engineering starts
- **PRD contains implicit rules** — Extract and make explicit for PM review
- **PM review gate needed** — Business stakeholders must approve behavior before technical design
- **Complex features** — Multiple user roles, edge cases, business constraints

## When NOT to Use

- **Engineering-facing extraction** — Use `skills/design/business-rules-extraction.md` via `/design` (includes Enforcement field)
- **Technical BDD scenarios** — Use `skills/testing/bdd-scenario-generation.md` via `/design` (all patterns, technical language)
- **Implementation planning** — Use `/plan`
- **Simple, obvious features** — Skip straight to `/design` or `/plan`

## Language Constraint

All outputs must use **business language only**.

**Allowed:**
- "Users can request a data export"
- "The system should notify the user when complete"
- "Administrators can view all accounts"
- "Export files are available for 24 hours"

**Not allowed:**
- "POST /api/users/export" — use "request a data export"
- "Returns 403 Forbidden" — use "the user should see an access denied message"
- "JWT token validation" — use "the user must be logged in"
- "SELECT with pagination" — use "results are shown in pages"
- "Celery background job" — use "processed in the background"

## Sub-Skills

| Skill File | Purpose |
|------------|---------|
| `business-rules.md` | Extract business rules from PRDs in PM-readable format |
| `bdd-scenarios.md` | Generate BDD scenarios using user-action language |
| `flow-diagrams.md` | Generate Mermaid flowcharts and sequence diagrams |

### Progressive Disclosure

**Quick Start:**
- Read SKILL.md (this file) to understand the approach
- Understand the PM-facing language constraint

**When Needed:**
- `business-rules.md` — When extracting rules from complex PRDs
- `bdd-scenarios.md` — When generating Gherkin acceptance scenarios
- `flow-diagrams.md` — When generating visual flow diagrams (on by default, `--no-diagrams` to skip)

## Output Locations

```
.claude/design/[feature]-rules.md        # Business rules (PM-approved)
.claude/design/[feature]-bdd.feature     # BDD scenarios (PM-approved)
.claude/design/[feature]-flows.md        # Flow diagrams (default on, --no-diagrams to skip)
```

## Integration with `/design`

When `/design` detects pre-approved artifacts from `/specify`:
1. `.claude/design/[feature]-rules.md` with `Status: Approved` → `/design` skips its Stage 1 (business rules extraction)
2. `.claude/design/[feature]-bdd.feature` → `/design` skips its Stage 9 (BDD generation)

This creates a clean handoff:
```
/specify (PM approves behavior) → /design (engineer designs solution)
```

## Tools Used

- **Read**: Parse PRD and context files
- **Write**: Create rules and BDD files
- **Edit**: Update files based on PM feedback
- **AskUserQuestion**: Clarify business requirements, present for approval

**Not used (by design):**
- Grep, Glob, Bash — no codebase research needed
- This skill works entirely from PRD content

## Related Documentation

- **Agent:** [agents/specifier.md](../../agents/specifier.md)
- **Command:** [commands/specify.md](../../commands/specify.md)
- **Engineering rules:** [skills/design/business-rules-extraction.md](../design/business-rules-extraction.md) (includes Enforcement field)
- **Engineering BDD:** [skills/testing/bdd-scenario-generation.md](../testing/bdd-scenario-generation.md) (all patterns, technical language)
