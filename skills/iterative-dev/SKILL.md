---
name: iterative-dev
description: Loop prompt templates and configs for ralph-loop integration. Consumed by /build --loop, /fix --loop, /review --self --loop, and /author --loop.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(${profile.tools.test_runner.command}:*), Bash(${profile.tools.linter.command}:*), Bash(${profile.tools.type_checker.command}:*), Bash(git:*), Bash(gh:*), Bash(scripts/validate-toolkit.sh:*)
---

# Iterative Development Skill

Prompt templates and configuration for self-correcting development loops via ralph-loop. Consumed by `/build --loop`, `/fix --loop`, `/review --self --loop`, and `/author --loop`.

## When to Use

- Implementing a plan with automated TDD cycles (`/build --loop`)
- Fixing bugs with automated quality convergence (`/fix --loop`)
- Running automated self-review-fix before PR (`/review --self --loop`)
- Improving toolkit components with automated validation (`/author --loop`)

## When NOT to Use

- Manual, interactive development (no `--loop` flag)
- One-off commands that don't iterate (`/gather`, `/specify`, `/commit`)
- When ralph-loop is not installed — STOP and report, do not fall back

## Patterns

| Pattern | Consumed By | Prompt Template | Completion Promise |
|---------|-------------|-----------------|-------------------|
| `build` | `/build plan.md --loop` | `prompts/build.md` | `BUILD COMPLETE` |
| `review-fix` | `/build plan.md --loop` (review phase) | `prompts/review-fix.md` | `REVIEW COMPLETE` |
| `self-review` | `/review --self --loop` | `prompts/review-fix.md` | `REVIEW COMPLETE` |
| `quality` | `/fix --loop` | `prompts/quality.md` | `QUALITY COMPLETE` |
| `author` | `/author improve <path> --loop` | `prompts/author.md` | `AUTHOR COMPLETE` |

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
| ASSESS | Read current state: test results, lint output, type errors, review findings, or validation output |
| DECIDE | Classify highest-priority issue, choose fix strategy |
| ACT | Apply the fix |
| VERIFY | Re-run ALL gates to catch cross-gate regressions |
| COMPLETE | Commit, push, create PR (build/self-review) or output promise text |

## Progressive Disclosure

```
SKILL.md                        # Overview and entry point
configs/
  defaults.md                   # MAX_ITERATIONS (30), MAX_SELF_REVIEW_ITERATIONS (10), MAX_AUTHOR_ITERATIONS (10), completion promises, retry caps
  permissions.md                # Permission manifests per pattern (24/18/20/12/13 permissions)
prompts/
  build.md                      # Prompt template for TDD build loop
  review-fix.md                 # Prompt template for review-fix loop AND self-review loop
  quality.md                    # Prompt template for quality convergence loop
  author.md                     # Prompt template for toolkit component validation loop
```

Note: `prompts/review-fix.md` serves both the `review-fix` and `self-review` patterns. The self-review pattern hydrates additional context variables (`$SELF_REVIEW_MODE`, `$CREATE_PR_ON_COMPLETE`) to enable PR creation and external comment fetching.

## Profile Integration

Process-only skill. All stack-specific tools resolved from active profile at runtime via `${profile.tools.*}`. The author pattern is an exception — it uses `scripts/validate-toolkit.sh` instead of profile-specific tools since it validates markdown, not code.
