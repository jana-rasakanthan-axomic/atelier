---
name: iterative-dev
description: Loop prompt templates and configs for ralph-loop integration. Consumed by /build --loop and /fix --loop.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(${profile.tools.test_runner.command}:*), Bash(${profile.tools.linter.command}:*), Bash(${profile.tools.type_checker.command}:*), Bash(git:*), Bash(gh:*)
---

# Iterative Development Skill

Prompt templates and configuration for self-correcting development loops via ralph-loop. Consumed by `/build --loop` and `/fix --loop`.

## Patterns

| Pattern | Consumed By | Prompt Template | Completion Promise |
|---------|-------------|-----------------|-------------------|
| `build` | `/build plan.md --loop` | `prompts/build.md` | `BUILD COMPLETE` |
| `review-fix` | `/build plan.md --loop` (review phase) | `prompts/review-fix.md` | `REVIEW COMPLETE` |
| `quality` | `/fix --loop` | `prompts/quality.md` | `QUALITY COMPLETE` |

## Architecture: Unified State Machine

All patterns share a single state machine:

```
ASSESS --> DECIDE --> ACT --> VERIFY --fail--> DECIDE
                                |
                              pass
                                v
                            COMPLETE
```

| State | Action |
|-------|--------|
| ASSESS | Read current state: test results, lint output, type errors, review findings |
| DECIDE | Classify highest-priority issue, choose fix strategy |
| ACT | Apply the fix |
| VERIFY | Re-run ALL gates to catch cross-gate regressions |
| COMPLETE | Commit, push, create PR (build) or output promise text |

## Progressive Disclosure

```
SKILL.md                        # Overview and entry point
configs/
  defaults.md                   # MAX_ITERATIONS (30), completion promises, retry caps
  permissions.md                # Permission manifests per pattern (24/18/12 permissions)
prompts/
  build.md                      # Prompt template for TDD build loop
  review-fix.md                 # Prompt template for review-fix loop
  quality.md                    # Prompt template for quality convergence loop
```

## Profile Integration

Process-only skill. All stack-specific tools resolved from active profile at runtime via `${profile.tools.*}`. No tool names hardcoded.
