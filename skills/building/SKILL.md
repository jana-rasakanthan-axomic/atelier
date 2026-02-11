---
name: building
description: Process-only code generation patterns. Stack-specific patterns live in the active profile.
allowed-tools: Read, Write, Edit, Grep, Glob
---

# Building Skill

Generate production-ready code following established patterns for the active profile's stack.

## When to Use

- New domain entities (following profile's layer order)
- CRUD operations for existing domains
- External service integrations
- Database migrations

## When NOT to Use

**Only for generating new code following patterns.** Do not use for refactoring or infrastructure changes.

- Refactoring existing code → analyze first
- No clear requirements → use Planner
- Modifying shared infrastructure → manual review required
- One-off scripts → write directly

## Profile Integration

This skill is **process-only**. All stack-specific patterns, layer definitions, and code templates live in the active profile.

### Loading Patterns

```bash
TOOLKIT_DIR="${CLAUDE_TOOLKIT:-$HOME/.claude}"
PROFILE=$("$TOOLKIT_DIR/scripts/resolve-profile.sh")
```

Read patterns from `$TOOLKIT_DIR/profiles/{profile}/patterns/{layer}.md`.

### Pattern Files (Profile-Specific)

Patterns are defined per-profile. Common pattern types:

| Pattern | Purpose |
|---------|---------|
| Config | Application configuration |
| Models | Data models / entities |
| Repository / Data Access | Data layer |
| Service | Business logic |
| Router / Controller | API endpoints / entry points |
| Exceptions | Error handling |
| External Integration | Third-party services |

The exact patterns available depend on the active profile.

## Architecture Layers

Layers and their order come from the active profile. The universal principle is **outside-in** (contract-first):

1. **Entry Point** — API endpoint, screen, or CLI handler (user-facing contract)
2. **Business Logic** — Core logic, DTOs, validation
3. **Data Access** — Database, file system, or external data
4. **External** — Third-party service integrations (if needed)
5. **Models/Schema** — Data models or schema definitions (if new entities needed)

> **Rationale:** Start with what the user interacts with and drive implementation from requirements, not from the data layer.

Read `$TOOLKIT_DIR/profiles/{active_profile}.md` for the specific layer names, patterns, and conventions.

## Build Order (Outside-In)

When implementing a feature, build **outside-in** (contract-first):

```
Entry Point --> Business Logic --> Data Access --> External --> Models
```

The profile maps these generic layers to concrete stack concepts.

## Key Rules Summary

Stack-specific rules (coding conventions, import patterns, config access) live in:
- `$TOOLKIT_DIR/profiles/{profile}/patterns/_shared.md` — Common concepts
- `$TOOLKIT_DIR/profiles/{profile}/style/` — Style limits and naming conventions

## Templates

Code boilerplate in `$TOOLKIT_DIR/profiles/{profile}/patterns/templates/` (if the profile provides them).
