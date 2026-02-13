# Agent Quality Checklist

Based on Anthropic's "Building Effective Agents" best practices.

## Core Quality

- [ ] **Description is specific** - includes what it does AND when to use it
- [ ] **Concise instructions** - only adds context Claude doesn't already have
- [ ] **Appropriate freedom level** - matches task fragility (high/medium/low)
- [ ] **Clear workflows** - steps are sequential and unambiguous
- [ ] **Feedback loops included** - validate → fix → repeat for quality-critical tasks

## Structure

- [ ] **Frontmatter present** - `---` block with `name`, `description`, `allowed-tools`
- [ ] **`name` is lowercase with hyphens** - e.g., `builder`, not `Builder`
- [ ] **Required sections present** - "When to Use", "When NOT to Use", "Workflow", "Tools Used"
- [ ] **Under 500 lines** - split into supporting files if longer
- [ ] **References one level deep** - no nested file chains
- [ ] **Cross-references resolve** - all `skills/`, `agents/`, `commands/` paths exist
- [ ] **Consistent terminology** - one term per concept throughout

## Content Guidelines

- [ ] **Third person descriptions** - "Analyzes code", not "I analyze"
- [ ] **No time-sensitive information** - or isolated in "old patterns" section
- [ ] **Concrete examples** - not abstract descriptions
- [ ] **Templates for outputs** - where format consistency matters

## Workflows and Patterns

- [ ] **Clear decision points** - what triggers different paths
- [ ] **Checklists for multi-step tasks** - trackable progress
- [ ] **Validation steps** - for quality-critical operations
- [ ] **Default with escape hatch** - one recommended path, alternatives available

## Scripts (if applicable)

- [ ] **Handle errors explicitly** - don't punt to Claude
- [ ] **Document all constants** - no magic numbers
- [ ] **Required packages listed** - and verified as available
- [ ] **No Windows paths** - use forward slashes only

## Testing

- [ ] **At least 3 test scenarios created**
- [ ] **Tested with intended model(s)** - Haiku/Sonnet/Opus have different needs
- [ ] **Tested with real usage** - not just hypothetical scenarios

## Final Check

```markdown
Agent: [name]

Core Quality:
- [ ] specific description (what + when)
- [ ] concise (only context Claude needs)
- [ ] appropriate freedom level
- [ ] feedback loops where needed

Structure:
- [ ] < 500 lines (or split)
- [ ] one level deep references
- [ ] consistent terminology

Testing:
- [ ] 3+ test scenarios
- [ ] tested with real usage

Status: [ ] READY / [ ] NEEDS WORK
```
