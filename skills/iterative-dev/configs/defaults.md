# Iterative Development Defaults

Default configuration values for `--loop` mode (`/build --loop`, `/fix --loop`, `/review --self --loop`, `/author --loop`). These are loaded during loop initialization. User-provided flags (e.g., `--max`) override these values.

## Configuration Table

| Setting | Default | Description |
|---------|---------|-------------|
| MAX_ITERATIONS | 30 | Maximum loop iterations before stopping |
| MAX_SELF_REVIEW_ITERATIONS | 10 | Maximum iterations for self-review-fix loop |
| MAX_AUTHOR_ITERATIONS | 10 | Maximum iterations for author loop |
| COMPLETION_PROMISE_BUILD | BUILD COMPLETE | Promise text for build pattern |
| COMPLETION_PROMISE_REVIEW | REVIEW COMPLETE | Promise text for review-fix pattern |
| COMPLETION_PROMISE_SELF_REVIEW | REVIEW COMPLETE | Promise text for self-review pattern |
| COMPLETION_PROMISE_QUALITY | QUALITY COMPLETE | Promise text for quality pattern |
| COMPLETION_PROMISE_AUTHOR | AUTHOR COMPLETE | Promise text for author pattern |
| MAX_GREEN_RETRIES | 3 | Max attempts to make tests pass per layer |
| MAX_FINDING_RETRIES | 3 | Max fix attempts per individual finding before skipping |
| ESCALATION_ON_FAILURE | true | Escalate to user after max retries exhausted |

## Hard Limits

| Limit | Value | Rationale |
|-------|-------|-----------|
| MAX_ITERATIONS cap | 50 | Prevents runaway loops regardless of user input |
| MAX_SELF_REVIEW_ITERATIONS cap | 15 | Prevents runaway self-review loops |
| MAX_AUTHOR_ITERATIONS cap | 15 | Prevents runaway author loops |
| MAX_GREEN_RETRIES cap | 5 | Prevents infinite fix cycles on a single layer |
| MAX_FINDING_RETRIES cap | 5 | Prevents infinite fix cycles on a single finding |

## Promise Resolution

The loop terminates when the agent outputs the exact promise text for its pattern. The promise text must appear as a standalone line in the agent's output -- partial matches or substrings do not count.

```
Pattern       -> Completion Promise
build         -> BUILD COMPLETE
review-fix    -> REVIEW COMPLETE
self-review   -> REVIEW COMPLETE
quality       -> QUALITY COMPLETE
author        -> AUTHOR COMPLETE
```
