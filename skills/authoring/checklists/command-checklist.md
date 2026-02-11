# Command Quality Checklist

Based on Anthropic's "Building Effective Agents" best practices.

## Core Quality

- [ ] **Description is specific** - includes what it does AND when to use it
- [ ] **Concise instructions** - only adds context Claude doesn't already have
- [ ] **Clear input formats** - examples for each supported format
- [ ] **Structured output** - consistent format for results

## Structure

- [ ] **Under 500 lines** - split into supporting files if longer
- [ ] **References one level deep** - no nested file chains
- [ ] **Consistent terminology** - one term per concept throughout

## Content Guidelines

- [ ] **Third person descriptions** - "Generates reports", not "I generate"
- [ ] **No time-sensitive information** - or isolated in "old patterns" section
- [ ] **Concrete examples** - not abstract descriptions
- [ ] **Templates for outputs** - where format consistency matters

## Workflow Design

- [ ] **Appropriate stage count** - complex enough to be useful, simple enough to follow
- [ ] **Clear decision points** - what triggers different paths
- [ ] **Approval gates** - where user confirmation matters
- [ ] **Default with escape hatch** - one recommended path, alternatives available

## User Experience

- [ ] **Multiple input formats** - description, file path, options
- [ ] **Preview/dry-run option** - where applicable
- [ ] **Clear next steps** - what user should do after command completes
- [ ] **Error messages are actionable** - tell user how to fix, not just what failed

## Testing

- [ ] **At least 3 test scenarios created**
- [ ] **Tested with intended model(s)** - Haiku/Sonnet/Opus have different needs
- [ ] **Tested with real usage** - not just hypothetical scenarios

## Final Check

```markdown
Command: /[name]

Core Quality:
- [ ] specific description (what + when)
- [ ] concise (only context Claude needs)
- [ ] clear input formats
- [ ] structured output

User Experience:
- [ ] multiple input formats
- [ ] approval gates where needed
- [ ] clear next steps

Testing:
- [ ] 3+ test scenarios
- [ ] tested with real usage

Status: [ ] READY / [ ] NEEDS WORK
```
