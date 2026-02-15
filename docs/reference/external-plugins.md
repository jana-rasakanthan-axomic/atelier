# External Plugins

Evaluation criteria, landscape assessment, and integration patterns for community tools alongside Atelier.

---

## Evaluation Criteria

Before adopting any external plugin, evaluate it against these five criteria. A plugin must pass ALL of them.

### 1. Active Maintenance

- Commits within the last 6 months
- Issues triaged (not necessarily all closed, but responded to)
- Compatible with the current Claude Code version
- Not archived or deprecated

### 2. Clean Scope

- Does one thing well
- Does not attempt to own the entire development workflow
- Clear documentation of inputs, outputs, and side effects
- Minimal configuration surface

### 3. Process Compatibility

- Does not impose a workflow that conflicts with Atelier's TDD state machine
- Does not bypass quality gates (lint, type check, test)
- Respects the profile system (does not hardcode stack-specific tools)
- Works with slash commands (does not require a competing invocation model)

### 4. No Conflicts

- Does not register hooks that conflict with Atelier's hooks (`enforce-tdd-order.sh`, `protect-main.sh`, `regression-reminder.sh`)
- Does not overwrite `.claude/settings.json` entries managed by Atelier
- Does not claim command names that collide with Atelier's 15 commands

### 5. Incremental Adoption

- Can be installed alongside Atelier without breaking existing workflows
- Can be removed without leaving orphaned configuration
- Does not require migrating existing project structure

---

## Plugin Landscape

Assessment of community tool categories relative to Atelier's built-in capabilities.

### PR Review Tools

**Atelier equivalent:** `/review`, `/review --self`, `/review --self --loop`

**Verdict: Build**

Atelier's review pipeline is tightly integrated with the profile system (stack-specific review checklists), the TDD enforcement model (verifying test coverage), and the iterative loop (self-review-fix cycle). External PR review tools operate on generic code quality heuristics and lack awareness of Atelier's contract-first design, layer boundaries, and mocking strategy. The value of `/review` is process enforcement, not just code scanning.

### Commit Message Generators

**Atelier equivalent:** `/commit`

**Verdict: Build**

Atelier's `/commit` follows specific conventions (imperative mood, ticket ID reference, why-not-what). External commit message generators produce generic descriptions from diffs. The overhead of configuring an external tool to match Atelier's conventions exceeds the cost of maintaining the built-in command.

### Code Analysis Tools

**Atelier equivalent:** `/audit`, `/analyze`

**Verdict: Evaluate**

Static analysis is a broad domain. Atelier's `/audit` and `/analyze` cover structural analysis (dependencies, complexity, layer violations) but do not replace dedicated tools for security scanning, license compliance, or performance profiling. Worth evaluating:

- **Security scanners** -- Tools that detect secrets, vulnerable dependencies, or injection patterns. These complement `/audit` rather than replace it.
- **Dependency analyzers** -- Tools that map transitive dependencies and detect version conflicts. Atelier's analysis skill covers architectural dependencies but not package-level supply chain analysis.
- **Performance profilers** -- Outside Atelier's scope entirely. Adopt if needed.

When evaluating, check that the tool produces output Atelier can consume (e.g., structured findings that `/fix` can act on).

### Git Workflow Tools

**Atelier equivalent:** Worktree management, branch naming, `/workstream`

**Verdict: Build**

Atelier's git workflow is deeply integrated with the workstream system (worktree-per-ticket, dependency-aware build ordering, PR lifecycle management). External git workflow tools (branch managers, worktree helpers) would need to understand Atelier's `status.json`, `build-queue.json`, and branch naming conventions. The integration cost outweighs the benefit.

### Documentation Generators

**Atelier equivalent:** `/author` (for toolkit docs), ADR templates

**Verdict: Evaluate**

API documentation generators (OpenAPI renderers, typedoc, pdoc) are complementary. Atelier generates design documents and ADRs but does not produce API reference documentation from code. These tools fill a genuine gap without conflicting with any Atelier command.

### Testing Utilities

**Atelier equivalent:** `/test`, TDD enforcement hooks

**Verdict: Evaluate**

Test coverage reporters, mutation testing frameworks, and snapshot testing tools operate below the layer where Atelier works. Atelier orchestrates the TDD cycle; these tools augment the test runner itself. They integrate via the profile system (add to `${profile.test_runner}` invocation) rather than as Atelier plugins.

---

## Integration Patterns

Three patterns for integrating external tools alongside Atelier.

### 1. Complementary (Different Scope)

The external tool covers functionality Atelier does not attempt. Both tools coexist without interaction.

```
Atelier: /review --self        (process + architecture review)
External: security-scanner     (CVE + secrets detection)
```

**Integration:** Run independently. No configuration overlap. Optionally reference external tool output in Atelier's `/audit` findings.

**When to use:** The external tool fills a gap (security, performance, license compliance) that is outside Atelier's process model.

### 2. Replacement (Disable Atelier Equivalent)

The external tool is strictly better at a specific task. Disable Atelier's equivalent to avoid duplication.

```
# .atelier/config.yaml
disabled_commands:
  - analyze    # Replaced by external-analyzer plugin
```

**Integration:** Disable the overlapping Atelier command. Document the replacement in the project's CLAUDE.md with usage instructions. Ensure the replacement tool's output format is compatible with downstream Atelier commands (e.g., if `/fix` reads `/audit` output, the replacement must produce equivalent structure).

**When to use:** Rare. Only when the external tool is demonstrably superior AND produces output compatible with Atelier's pipeline.

### 3. Wrapper (Atelier Orchestrates External Tool)

Atelier invokes the external tool as part of its workflow, wrapping it in process enforcement.

```
# In profile's test_runner configuration
test_runner: "pytest"
coverage_tool: "pytest-cov"      # External, invoked by /test
mutation_tool: "mutmut"          # External, invoked by /test --mutation
```

**Integration:** Add the external tool to the active profile's configuration. Atelier commands invoke it via profile variables. The external tool runs within Atelier's TDD cycle, not outside it.

**When to use:** The external tool enhances an existing Atelier stage (better test coverage reporting, richer linting) without replacing the stage itself.

---

## Decision Log

Track adoption decisions here as they are made.

| Date | Category | Tool | Decision | Rationale |
|------|----------|------|----------|-----------|
| *(template)* | *(category)* | *(tool name)* | Build / Evaluate / Adopt | *(one-line rationale)* |

Update this table when evaluating a specific tool. Reference the evaluation criteria above.
