# Skill Quality Checklist

Use this checklist to validate a skill before finalizing.

## YAML Frontmatter

- [ ] `name` is lowercase with hyphens only
- [ ] `name` is max 64 characters
- [ ] `name` doesn't contain "anthropic" or "claude"
- [ ] `description` is non-empty
- [ ] `description` is max 1024 characters
- [ ] `description` is in third person ("Processes files", not "I process")
- [ ] `description` includes WHAT it does AND WHEN to use it
- [ ] `allowed-tools` lists only tools actually needed

## Structure

- [ ] SKILL.md body is under 500 lines
- [ ] File references are one level deep (not nested)
- [ ] Longer reference files have table of contents
- [ ] Directory structure is logical (patterns/, templates/, scripts/)

## Content Quality

- [ ] Has "When to Use" section with clear triggers
- [ ] Has "When NOT to Use" section with alternatives
- [ ] No time-sensitive information (or in "old patterns" section)
- [ ] Consistent terminology throughout
- [ ] Examples are concrete, not abstract
- [ ] No unnecessary explanations (Claude is smart)

## Progressive Disclosure

- [ ] SKILL.md serves as overview/navigation
- [ ] Details are in separate files
- [ ] Clear links to supporting files
- [ ] Supporting files are self-contained

## Code and Scripts (if applicable)

- [ ] Scripts handle errors explicitly (don't punt to Claude)
- [ ] No "voodoo constants" (all values documented)
- [ ] Required packages listed
- [ ] Scripts have clear documentation
- [ ] No Windows-style paths (use forward slashes)
- [ ] Validation/verification steps included

## Testing Considerations

- [ ] Can be tested with Haiku (enough guidance?)
- [ ] Can be tested with Sonnet (clear and efficient?)
- [ ] Can be tested with Opus (not over-explaining?)
- [ ] At least 3 test scenarios identified

## Final Check

Copy and check off as you validate:

```markdown
Skill Validation: [skill-name]

Frontmatter:
- [ ] name valid
- [ ] description complete (what + when)
- [ ] tools appropriate

Structure:
- [ ] < 500 lines
- [ ] one level deep references
- [ ] logical organization

Content:
- [ ] When to Use
- [ ] When NOT to Use
- [ ] concise (no over-explaining)
- [ ] consistent terminology

Status: [ ] READY / [ ] NEEDS WORK
```
