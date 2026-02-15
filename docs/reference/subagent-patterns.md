# Subagent Patterns

When and how to delegate heavy processing to subagents via the Task tool.

---

## When to Use Subagents

Use a subagent (Task tool) when processing is **compute-heavy, context-isolated, and non-interactive**. Keep the main context for user interaction, decision-making, and orchestration.

### Use Subagent (Task Tool)

| Signal | Example |
|--------|---------|
| Processing >3 items in a batch | Generating 8 tickets from a PRD |
| Graph computation (sort, cycle detection) | Dependency resolution across 20 tickets |
| Repetitive transformation per item | Applying a template to each ticket |
| Output is structured data, not a conversation | JSON status file, markdown batch |

### Stay Inline

| Signal | Example |
|--------|---------|
| User clarification needed mid-process | Ambiguous requirement during design |
| Single-item processing | Planning one ticket |
| Result requires immediate user review | Presenting architecture alternatives |
| Process is interactive by nature | `/gather` conversation |

---

## Core Pattern

```
Main Context (orchestrator)        Subagent (worker)
─────────────────────────          ─────────────────
1. Collect inputs
2. Validate prerequisites
3. Delegate via Task tool -------> 4. Receive scoped instructions
                                   5. Process (no user interaction)
                                   6. Return structured result
7. Receive result <---------------
8. Present to user for review
9. Iterate based on feedback
```

The main context never loses conversational state. The subagent receives only what it needs and returns only the result.

### Task Tool Invocation Template

When delegating, provide the subagent with:

1. **Role** -- Which agent persona to adopt (Designer, Builder, etc.)
2. **Skill references** -- Which skill files to read for procedures
3. **Input data** -- The specific items to process (file paths, ticket IDs)
4. **Output format** -- Exact structure expected in the response
5. **Constraints** -- What NOT to do (no user interaction, no file writes beyond scope)

---

## Pattern: Design -- Ticket Splitting

When `/design` Stage 4 needs to generate more than 3 tickets, delegate to a Designer subagent.

**Main context responsibilities:**
- Run Stages 0-3 (clarification, analysis, design, contracts)
- Determine ticket count from the contract definitions
- If >3 tickets: delegate Stage 4 to subagent
- Review returned tickets, present to user in Stage 5

**Subagent responsibilities:**
- Read the contracts from Stage 3
- Read `skills/design/vertical-slicing.md` and `skills/design/templates/detailed-ticket.md`
- Generate ticket files following the template
- Return list of generated ticket paths and summaries

**Why this split works:** Ticket generation is mechanical (apply template to each endpoint). The main context preserves the design conversation for user iteration in Stage 5.

---

## Pattern: Workstream -- Dependency Resolution

When `/workstream create` processes more than 10 tickets, delegate Stage 3 (dependency analysis) to a subagent or the workstream engine script.

**Main context responsibilities:**
- Run Pre-Stage (ticket discovery) and Stage 1-2 if `--from-sources`
- Collect parsed ticket metadata
- If >10 tickets: delegate dependency resolution
- Run Stages 4-5 with the resolved graph

**Subagent/script responsibilities:**
- Parse `blocked_by`/`blocks` from ticket frontmatter
- Apply implicit dependency rules (auth blocks, CRUD chains)
- Run topological sort and cycle detection
- Calculate depth levels and critical path
- Return the dependency graph as structured data

**Why this split works:** Graph computation is pure data transformation with no user interaction. The main context stays responsive for error reporting and output presentation.

---

## Anti-Patterns

| Anti-Pattern | Why It Fails |
|--------------|-------------|
| Delegating user-facing decisions | Subagent cannot call `AskUserQuestion` effectively in nested context |
| Passing entire conversation history | Bloats subagent context, slows processing, risks confusion |
| Delegating single-item work | Overhead of Task tool exceeds inline processing cost |
| Fire-and-forget without validation | Main context must validate subagent output before proceeding |
| Chaining subagents (subagent spawns subagent) | Creates opaque processing chains; keep orchestration flat |

---

## Sizing Guidelines

| Batch Size | Strategy |
|------------|----------|
| 1-3 items | Inline processing |
| 4-10 items | Subagent recommended |
| 11-20 items | Subagent required |
| 20+ items | Split into multiple subagent calls (10 items each) |

These thresholds balance context window usage against Task tool overhead. Adjust based on item complexity -- a batch of 4 complex schema definitions may warrant a subagent, while 8 simple CRUD tickets may not.
