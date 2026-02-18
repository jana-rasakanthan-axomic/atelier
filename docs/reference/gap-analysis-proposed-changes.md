# Gap Analysis: PDF Guides vs Atelier — Proposed Changes

Comprehensive gap analysis between [env-setup-addendum.pdf] and [mastering-claude-code-guide v4.pdf] and Atelier's current implementation, with proposed changes for review.

---

## Table of Contents

1. [Good, Bad, Ugly Summary](#1-good-bad-ugly-summary)
2. [tmux & Statusline Strategy](#2-tmux--statusline-strategy)
3. [Worktree Clarification](#3-worktree-clarification)
4. [PROGRESS.md / DECISIONS.md / SCRATCHPAD.md Pattern](#4-progressmd--decisionsmd--scratchpadmd-pattern)
5. [CLAUDE.md Size Auditing](#5-claudemd-size-auditing)
6. [Model & Thinking Strategy (Atomic Level)](#6-model--thinking-strategy-atomic-level)
7. [MCP Handling Strategy](#7-mcp-handling-strategy)
8. [Hooks & Security — Python/FastAPI](#8-hooks--security--pythonfastapi)
9. [Pricing, Cost & Subscription](#9-pricing-cost--subscription)
10. [Rate Limits, Token Usage & Session Budgets](#10-rate-limits-token-usage--session-budgets)
11. [Action Items Summary](#11-action-items-summary)

---

## 1. Good, Bad, Ugly Summary

### The Good (Atelier already does well)

| # | Area | Detail |
|---|------|--------|
| G1 | **TDD state machine** | Strict RED→GREEN→VERIFY enforced by hooks. Neither PDF achieves this level of enforcement. |
| G2 | **Profile system** | Process/stack separation is elegant. PDFs bundle everything together. |
| G3 | **Progressive disclosure** | Skills load on-demand via SKILL.md → detailed/*.md. PDFs recommend this; we do it. |
| G4 | **Hook enforcement** | 9 hooks covering TDD, phase guards, commit safety, secrets detection. Beyond what either PDF suggests. |
| G5 | **Session & workstream architecture** | 3-layer session state (transient/persistent/workflow), workstream engine with dependency management. More sophisticated than PROGRESS.md approach. |
| G6 | **Validation script** | `validate-toolkit.sh` checks CLAUDE.md size, frontmatter, cross-references, component structure. Neither PDF has automated validation. |
| G7 | **MCP strategy doc** | Already have `docs/reference/mcp-strategy.md` with gather-once-work-locally pattern. |
| G8 | **Model strategy docs** | Already have `model-thinking-strategy.md` and `model-rationale-report.md` with atomic-level analysis. |
| G9 | **Iterative dev loops** | `/build --loop`, `/review --self --loop`, `/author --loop` via ralph-loop plugin. |
| G10 | **Command lifecycle pipeline** | 15+ commands covering discovery → design → build → verify → ship. Structured, not ad-hoc. |

### The Bad (Gaps to address)

| # | Area | PDF Recommendation | Current State | Impact |
|---|------|-------------------|---------------|--------|
| B1 | **No tmux/terminal multiplexing guide** | env-setup: Run 5+ parallel sessions for throughput | No terminal session management scripts or docs | Users don't know how to maximize parallel throughput |
| B2 | **No statusline integration** | env-setup: statusline shows active model, tokens, thinking budget | No statusline config | Users lack real-time visibility into model/token usage |
| B3 | **Agent model_hint inconsistency** | mastering-guide: consistent frontmatter | Designer/Specifier use `model` field; 5 agents had no hint (now documented in strategy) | Inconsistent field names could break tooling |
| B4 | **No effort/thinking budget in frontmatter** | mastering-guide: thinking tokens are expensive, budget them | model_hint exists but no effort_hint or thinking_budget | Thinking tokens billed as output (most expensive) — uncontrolled |
| B5 | **No Python/FastAPI-specific hooks** | mastering-guide: stack-specific enforcement | All 9 hooks are language-agnostic | Missing: import ordering, async patterns, SQL injection checks |
| B6 | **No prompt caching strategy** | mastering-guide: 90% discount on cache reads | No caching guidance in toolkit | Missing significant cost savings opportunity |
| B7 | **Worktree only for /build** | env-setup: worktrees for all parallel work | Worktree management coupled to build command | /fix, /review, manual exploration don't create worktrees |
| B8 | **No daily rhythm guide** | env-setup: structured daily workflow pattern | /daily-brief exists but no broader rhythm doc | Users lack guidance on optimal session patterns |

### The Ugly (Fundamental mismatches or risks)

| # | Area | Issue | Risk |
|---|------|-------|------|
| U1 | **Thinking token spend is invisible** | No monitoring or budgeting of thinking tokens per session | Could burn through Max subscription window unknowingly — thinking tokens are 5x more expensive than input tokens on Opus |
| U2 | **MCP schema bloat untracked** | ~8,000 tokens per turn for Atlassian MCP (4% of context window) | Compounds over long sessions; no metric or warning |
| U3 | **No cost visibility per session** | PDFs emphasize tracking spend; we have no mechanism | Users can't correlate task complexity with resource consumption |
| U4 | **Multi-agent coordination undocumented** | env-setup describes specific patterns for parallel agents | Workstream creates worktrees but doesn't guide multi-agent coordination (e.g., session isolation, conflict prevention) |

---

## 2. tmux & Statusline Strategy

### Current State
No terminal multiplexing support. No statusline configuration.

### PDF Recommendation
- env-setup: Run 5+ parallel Claude Code sessions via tmux
- env-setup: Statusline showing model, tokens used, thinking budget, session time

### Proposed Changes

**Do NOT adopt tmux scripts.** Rationale:
- tmux is a personal workflow preference, not a toolkit concern
- Users who want tmux already know how to configure it
- Adding tmux scripts creates a maintenance burden for a niche use case

**DO adopt:** Add a `docs/manuals/parallel-sessions.md` guide covering:
- How to run multiple Claude Code sessions in parallel (tmux, separate terminals, IDE panes)
- Session isolation — each session should operate in its own worktree
- Model budget awareness — 5 parallel Opus sessions consume 5x the window budget
- When to parallelize (independent features) vs. when not to (shared state)

**Statusline:** Out of scope — Claude Code statusline is configured per-user, not per-toolkit.

| Item | Action | Priority |
|------|--------|----------|
| tmux scripts | Skip | — |
| Statusline config | Skip (user-level, not toolkit) | — |
| Parallel sessions guide | Create `docs/manuals/parallel-sessions.md` | P2 |

---

## 3. Worktree Clarification

### Current State
- `scripts/worktree-manager.sh` handles worktree creation/cleanup
- Used by `/build` (Stage 0) and `/workstream`
- Pattern: `project-TICKET-ID/` sibling directories
- `/fix`, `/review` do not create worktrees

### PDF Recommendation
- env-setup: Worktrees for ALL parallel work, not just builds
- mastering-guide: Separate worktrees prevent context leaks between sessions

### What worktrees solve
Worktrees are NOT just for parallel plans. They solve:
1. **Isolation** — each task gets a clean working directory
2. **Context separation** — no accidental file reads from another task's changes
3. **Parallel execution** — multiple sessions can work simultaneously without conflicts
4. **Quick switching** — `cd ../project-TICKET-102/` instead of `git stash && git checkout`

### Proposed Changes

| Item | Action | Priority |
|------|--------|----------|
| `/fix` worktree support | Add optional worktree creation to `/fix` (Stage 0) | P2 |
| `/review` worktree support | Not needed — review reads from target branch, doesn't modify | — |
| Worktree guide | Add section to `docs/manuals/parallel-sessions.md` | P2 |
| Worktree cleanup automation | Already handled by `worktree-manager.sh clean` — no change needed | — |

---

## 4. PROGRESS.md / DECISIONS.md / SCRATCHPAD.md Pattern

### PDF Recommendation (mastering-guide)
- `PROGRESS.md` — current state of implementation, checkpoints
- `DECISIONS.md` — architectural decisions made during session
- `SCRATCHPAD.md` — temporary thinking space for the agent

### Atelier's Current Approach

| PDF Pattern | Atelier Equivalent | Status |
|-------------|-------------------|--------|
| PROGRESS.md | `.atelier/sessions/*.json` + `/worklog` | **Covered.** Session state tracks per-layer progress. Worklog captures narrative. |
| DECISIONS.md | ADRs via `/design` skill + `templates/adr-template.md` | **Covered and better.** ADRs are formal, versioned, and linked to tickets. |
| SCRATCHPAD.md | `.claude/context/*.md` (gather output) + auto-memory | **Partially covered.** Context files serve as scratch, but no explicit agent scratchpad. |

### Assessment

**Do NOT adopt PROGRESS.md / DECISIONS.md / SCRATCHPAD.md** as separate files. Rationale:

1. **PROGRESS.md is worse than our session system.** Our `.atelier/sessions/*.json` tracks structured state (phase, layer, test results) that can be queried programmatically. A markdown file is just prose.

2. **DECISIONS.md is worse than ADRs.** ADRs have templates, are linked to tickets, and follow a formal format. A flat DECISIONS.md file becomes an unstructured dump.

3. **SCRATCHPAD.md has a case.** For long-running agent tasks, a scratchpad file could help the agent persist intermediate reasoning across context compaction. However, auto-memory (`~/.claude/projects/`) already serves this purpose.

### Proposed Changes

| Item | Action | Priority |
|------|--------|----------|
| PROGRESS.md | Skip — session state system is superior | — |
| DECISIONS.md | Skip — ADR system is superior | — |
| SCRATCHPAD.md | Consider adding `.claude/scratchpad.md` as a temporary thinking file for `/build --loop` long-running sessions | P3 |

---

## 5. CLAUDE.md Size Auditing

### Current State
`validate-toolkit.sh` already checks CLAUDE.md:

```
Hard limit: 500 lines
Soft limit: 350 lines (warning)
Token estimate: ~1.3 tokens/word, hard limit 4000 tokens
```

Current CLAUDE.md: **352 lines** (just above soft limit, below hard limit).

### What gets validated

| File/Type | Checked? | Limits |
|-----------|----------|--------|
| CLAUDE.md | Yes | Hard: 500 lines / 4000 tokens. Soft: 350 lines. |
| Commands | Yes | Soft: 200 lines. Hard: 500 lines. |
| Agents | Yes | Soft: 200 lines. Hard: 500 lines. |
| Skills (SKILL.md) | Yes | Soft: 300 lines. Hard: 500 lines. |
| Skill detailed/*.md | No | Not checked |
| Profiles | Partial | Checks key sections exist, no size check |
| docs/reference/*.md | No | Not checked |
| templates/*.md | No | Not checked |

### PDF Recommendation
- mastering-guide: Keep CLAUDE.md under 500 lines. Use WHAT/WHY/HOW structure. Link to detailed docs rather than inlining.

### Proposed Changes

| Item | Action | Priority |
|------|--------|----------|
| Skill detailed/*.md size check | Add to validate-toolkit.sh — soft 300 lines, hard 500 lines | P2 |
| Profile size check | Add line count check — soft 300 lines, hard 500 lines | P2 |
| docs/reference/*.md size check | Add — soft 300 lines, hard 500 lines | P3 |
| CLAUDE.md at 352 lines | Monitor — close to soft limit. Consider moving Quick Reference tables to a linked reference file if it grows further. | P3 |

---

## 6. Model & Thinking Strategy (Atomic Level)

### Current State

Already documented in:
- `docs/reference/model-thinking-strategy.md` — atomic operation → tier mapping
- `docs/reference/model-rationale-report.md` — rationale + pricing + effort levels

### Summary: Model Assignment by Component

#### Commands (18)

| Tier | Commands | Count |
|------|----------|-------|
| T1 (Opus) | `/design`, `/review`, `/specify`, `/plan` | 4 |
| T2 (Sonnet) | `/build`, `/fix`, `/braindump`, `/workstream` | 4 |
| T3 (Haiku) | `/commit`, `/test`, `/gather`, `/daily-brief`, `/deploy`, `/update`, `/worklog`, `/init`, `/author`, `/atelier-feedback` | 10 |

#### Agents (7)

| Tier | Agents | Count |
|------|--------|-------|
| T1 (Opus) | Designer, Specifier, Reviewer, Planner | 4 |
| T2 (Sonnet) | Builder | 1 |
| T3 (Haiku) | Author, Verifier | 2 |

#### Skills (11) — No model_hint (by design)

Skills are consumed by agents/commands; they don't run independently. Optimization is via progressive disclosure depth, not model hints.

### Effort Level Recommendations

| Effort | Commands | Rationale |
|--------|----------|-----------|
| **high** | `/design`, `/review`, `/specify`, `/plan` | Architecture/security decisions — wrong calls cascade |
| **medium** | `/build`, `/fix`, `/braindump`, `/workstream` | Iterative workflows self-correct; medium is sufficient |
| **low** | All haiku commands | Speed > depth; minimal reasoning tasks |

### Implementation Status

| Item | Status | Action Needed |
|------|--------|---------------|
| Command model_hints | Documented, some already updated | Verify all 18 commands match strategy |
| Agent model_hints | Documented; 5 agents missing in code | Add model_hint to 5 agent frontmatters |
| Agent field name consistency | Designer/Specifier use `model` not `model_hint` | Standardize to `model_hint` |
| Effort level hints | Documented in reference | Not yet in frontmatter — see proposal below |
| Thinking budget keywords | None used anywhere | Not yet actionable — Claude Code doesn't expose effort in frontmatter |

### Proposed Changes

| Item | Action | Priority |
|------|--------|----------|
| Standardize agent frontmatter | Change `model` → `model_hint` in Designer, Specifier | P1 |
| Add missing agent model_hints | Reviewer→opus, Planner→opus, Builder→sonnet, Author→haiku, Verifier→haiku | P1 |
| Verify command model_hints | Audit all 18 commands match strategy doc | P1 |
| Add `effort_hint` to frontmatter | Add `effort_hint: high|medium|low` to commands and agents | P2 |
| Document effort strategy in CLAUDE.md | Add effort-level table to Model Hints section | P2 |

---

## 7. MCP Handling Strategy

### Current State

Already documented in `docs/reference/mcp-strategy.md`. Key principles:
- Gather-once, work-locally
- Prefer `gh` CLI over GitHub MCP (zero context overhead)
- Keep only Atlassian MCP enabled
- Batch MCP operations at start of Stage 2

### MCP Context Cost

| Server | Tools | Est. Tokens/Turn | % of 200k Window |
|--------|-------|-------------------|-------------------|
| Atlassian | ~30 | ~8,000 | 4% |
| GitHub MCP | ~20 | ~5,000 | 2.5% |
| Total (all on) | ~50 | ~13,000 | 6.5% |
| Recommended (Atlassian only) | ~30 | ~8,000 | 4% |

### PDF Recommendations
- mastering-guide: MCP tools inject schemas into every turn. Minimize active servers.
- mastering-guide: Cache MCP results to avoid repeated calls.

### Assessment

Our MCP strategy doc is already comprehensive. Two gaps:

1. **No cache-manifest implementation** — the strategy describes it but it's not built
2. **No MCP schema size monitoring** — no warning when MCP bloat exceeds threshold

### Proposed Changes

| Item | Action | Priority |
|------|--------|----------|
| Cache-manifest for /gather | Implement `.claude/context/.cache-manifest.json` with TTL checking | P2 |
| MCP schema size warning | Add to validate-toolkit.sh or as a session startup check | P3 |
| Document MCP in CLAUDE.md | Already there implicitly — no change needed | — |

---

## 8. Hooks & Security — Python/FastAPI

### Current Hooks (All Language-Agnostic)

| Hook | Purpose |
|------|---------|
| `protect-main.sh` | Block commits to main/master |
| `enforce-tdd-order.sh` | Require test file edit before impl file |
| `phase-guard.sh` | Block impl writes during read-only phases |
| `commit-size-check.sh` | Warn on large commits (>500 lines, >30 files) |
| `amend-safety.sh` | Block amend if HEAD is pushed |
| `force-push-warning.sh` | Block force push to main/master |
| `detect-secrets.sh` | Scan for credentials/API keys |
| `post-edit-lint.sh` | Run linter after edits |
| `regression-reminder.sh` | Remind to run full regression |

### Python/FastAPI-Specific Gaps

| Gap | Risk | Proposed Hook |
|-----|------|---------------|
| **No async pattern enforcement** | Agent writes sync code in async FastAPI endpoints | `enforce-async-patterns.sh` — check that new route handlers use `async def` |
| **No SQL injection check** | Agent uses raw SQL or f-string queries | `check-sql-patterns.sh` — flag raw SQL strings, ensure SQLAlchemy parameterized queries |
| **No import ordering check** | Mixed import styles confuse readers | Covered by `post-edit-lint.sh` if ruff is configured with isort rules |
| **No Pydantic v2 enforcement** | Agent uses v1 patterns (`.dict()`, `Config` class) | `check-pydantic-v2.sh` — flag `.dict()`, `class Config`, `@validator` |
| **No alembic migration check** | Agent modifies models without creating migration | `check-alembic-migration.sh` — warn if model files change without new migration |
| **No dependency injection pattern** | Agent creates global state or bypasses `Depends()` | Harder to enforce via hooks — add to review checklist instead |

### Implementation Approach

These hooks should be **profile-activated**, not global. They live in:
```
profiles/hooks/python-fastapi/
├── enforce-async-patterns.sh
├── check-sql-patterns.sh
├── check-pydantic-v2.sh
└── check-alembic-migration.sh
```

The `post-edit-lint.sh` hook already checks the active profile. We extend this pattern: profile-specific hooks are loaded when the profile is active.

### Proposed Changes

| Item | Action | Priority |
|------|--------|----------|
| `enforce-async-patterns.sh` | Create — flag sync route handlers in FastAPI files | P2 |
| `check-sql-patterns.sh` | Create — flag raw SQL strings, f-string queries | P1 |
| `check-pydantic-v2.sh` | Create — flag deprecated v1 patterns | P2 |
| `check-alembic-migration.sh` | Create — warn on model changes without migration | P2 |
| Profile hook loading mechanism | Extend hook system to load profile-specific hooks | P1 |
| Review checklist update | Add FastAPI-specific items to review skill | P2 |

---

## 9. Pricing, Cost & Subscription

### API Pricing (Per Million Tokens — Feb 2026)

| Model | Input | Output | Cache Read | Cache Write (5m TTL) | Batch Input | Batch Output |
|-------|-------|--------|------------|---------------------|-------------|--------------|
| **Opus 4.6** | $5.00 | $25.00 | $0.50 | $6.25 | $2.50 | $12.50 |
| **Sonnet 4.5** | $3.00 | $15.00 | $0.30 | $3.75 | $1.50 | $7.50 |
| **Haiku 4.5** | $1.00 | $5.00 | $0.10 | $1.25 | $0.50 | $2.50 |

### Relative Cost (Haiku = 1x Baseline)

| Model | Input | Output | Effective Multiplier |
|-------|-------|--------|---------------------|
| Haiku 4.5 | 1x | 1x | **1x** |
| Sonnet 4.5 | 3x | 3x | **3x** |
| Opus 4.6 | 5x | 5x | **5x** |

### Subscription Plans (Claude Code)

| Plan | Price | Model Access | Approx. Prompts per 5-Hour Window |
|------|-------|-------------|-----------------------------------|
| **Pro** | $20/mo | Sonnet only | ~45 |
| **Max 5x** | $100/mo | Opus + Sonnet + Haiku | ~225 |
| **Max 20x** | $200/mo | Opus + Sonnet + Haiku | ~900 |

### Subscription vs. API Economics

On a subscription, the economics are fundamentally different from API billing:

| Factor | API Billing | Subscription |
|--------|-------------|--------------|
| Cost driver | Per-token cost | Monthly flat fee |
| Constraint | Dollar spend | Prompts per window |
| Optimization goal | Minimize total tokens | Maximize prompts per window |
| Model choice impact | Direct cost multiplier | Throughput multiplier |

**Key insight:** On a subscription, using Haiku for `/commit` instead of Opus doesn't save dollars — it saves **throughput budget**. One Opus prompt consumes ~12x the active time of a Haiku prompt. Model_hint selection directly controls how many operations you can perform per session.

### Prompt Caching Economics

| Metric | Value |
|--------|-------|
| Cache read discount | **90%** off standard input price |
| Cache write surcharge | 25% above standard input price |
| Cache TTL | 5 minutes (extended on re-hit) |
| Break-even | 2 cache hits pay for the write |

**How this applies to Atelier:**
- CLAUDE.md, skills, and agent definitions are sent every turn → prime caching candidates
- Long sessions (>5 min between turns) lose cache → keep sessions active
- Batch operations (read 5 files) in one turn → maximizes cache reuse

### Per-Call Cost Estimates (Model + Effort Combined)

Typical call: 10K input tokens, 5K output tokens.

| | Low Effort | Medium Effort | High Effort | Max Effort |
|---|-----------|---------------|-------------|------------|
| **Opus 4.6** | ~$0.18 | ~$0.35 | ~$0.60 | ~$1.25 |
| **Sonnet 4.5** | ~$0.06 | ~$0.12 | ~$0.20 | N/A |
| **Haiku 4.5** | ~$0.02 | ~$0.04 | ~$0.06 | N/A |

### Full Feature Lifecycle Cost

`/gather → /specify → /design → /plan → /build (3 layers) → /test → /review → /commit`

| Command | Model | Est. Tokens (in/out) | API Cost | Window Prompts |
|---------|-------|---------------------|----------|----------------|
| `/gather` | haiku | 5K / 2K | $0.015 | 1 |
| `/specify` | opus | 10K / 8K | $0.250 | 1 |
| `/design` | opus | 15K / 12K | $0.375 | 1 |
| `/plan` | opus | 12K / 10K | $0.310 | 1 |
| `/build` (3 layers) | sonnet | 30K / 25K | $0.465 | 6 |
| `/test` | haiku | 3K / 1K | $0.008 | 1 |
| `/review` | opus | 20K / 15K | $0.475 | 1 |
| `/commit` | haiku | 2K / 1K | $0.007 | 1 |
| **Total** | | **97K / 74K** | **~$1.91** | **13 prompts** |

On Max 5x ($100/mo): ~1/17th of the 5-hour window → **~17 full feature cycles per window**.

---

## 10. Rate Limits, Token Usage & Session Budgets

### API Rate Limits (Per-Minute, by Tier)

| Model | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|-------|--------|--------|--------|--------|
| **Opus 4.x** | 50 RPM / 30K ITPM / 8K OTPM | 1K / 450K / 90K | 2K / 800K / 160K | 4K / 2M / 400K |
| **Sonnet 4.x** | 50 RPM / 30K ITPM / 8K OTPM | 1K / 450K / 90K | 2K / 800K / 160K | 4K / 2M / 400K |
| **Haiku 4.5** | 50 / 50K / 10K | 1K / 450K / 90K | 2K / 1M / 200K | 4K / 4M / 800K |

RPM = Requests per minute. ITPM = Input tokens per minute. OTPM = Output tokens per minute.

**Key observations:**
- Haiku has **2x** the token throughput of Opus/Sonnet at Tier 3+
- Cached input tokens do NOT count toward ITPM limits
- Opus 4.x rate limit is **shared** across all Opus versions (4.6, 4.5, 4.1, 4)

### Claude Code Session Limits

| Constraint | Mechanism | Reset |
|-----------|-----------|-------|
| **Burst limit** | Rolling 5-hour window of prompts | Continuous (sliding window) |
| **Weekly cap** | Active processing hours per week | Weekly reset |
| **Unified** | Shared across browser, CLI, IDE | N/A |

### Weekly Budget by Plan

| Plan | Sonnet Hours/Week | Opus Hours/Week | Haiku Hours/Week |
|------|-------------------|-----------------|------------------|
| **Pro** | ~40-80 | N/A | N/A |
| **Max** | ~480 | ~40 | Effectively unlimited |

### Active Time Per Prompt (Average)

| Model | Time Per Prompt | Prompts Per Hour |
|-------|----------------|------------------|
| Opus | 0.5 - 2 min | ~30-120 |
| Sonnet | 0.2 - 0.5 min | ~120-300 |
| Haiku | 0.05 - 0.1 min | ~600-1200 |

### Thinking Token Economics

Thinking tokens are billed as **output tokens** — the most expensive token type.

| Model | Effort | Est. Thinking Tokens | Added Output Cost |
|-------|--------|---------------------|-------------------|
| Opus 4.6 | max | ~20K-50K | $0.50 - $1.25 |
| Opus 4.6 | high | ~8K-20K | $0.20 - $0.50 |
| Opus 4.6 | medium | ~3K-8K | $0.08 - $0.20 |
| Opus 4.6 | low | ~0-3K | $0.00 - $0.08 |
| Sonnet 4.5 | high | ~5K-15K | $0.08 - $0.23 |
| Sonnet 4.5 | low | ~0-2K | $0.00 - $0.03 |

### Subscription Impact of Effort

On a Max subscription, effort directly affects operations per window:

- **High effort** Opus: ~1-2 min active time per prompt
- **Low effort** Opus: ~0.2-0.5 min active time per prompt
- Reducing effort from high → low on non-critical commands can **3-5x** prompts per window

### Throughput Comparison: Before vs. After Optimization

| Scenario | Opus Prompts | Sonnet Prompts | Haiku Prompts | Total Ops/Window |
|----------|-------------|----------------|---------------|------------------|
| Before (all sonnet) | 0 | ~225 | 0 | **225** |
| After (tiered hints) | ~20 | ~80 | ~400 | **~500** |

**Estimated throughput gain: ~2.2x more operations per 5-hour window** by routing low-complexity commands to haiku.

### Practical Daily Budget (Max 5x Plan)

Assuming 8 working hours = ~1.6 rolling windows:

| Activity | Model | Prompts | % of Daily Budget |
|----------|-------|---------|-------------------|
| Morning `/daily-brief` | haiku | 3-5 | ~1% |
| 2x `/gather` | haiku | 4-6 | ~1% |
| 2x `/plan` | opus | 4-6 | ~2% |
| 4x `/build` (3 layers each) | sonnet | 24-48 | ~10% |
| 4x `/test` | haiku | 4-8 | ~1% |
| 2x `/review` | opus | 2-4 | ~1% |
| 8x `/commit` | haiku | 8-16 | ~2% |
| 2x `/worklog` | haiku | 2-4 | ~1% |
| Ad-hoc (exploration, fixes) | mixed | 30-60 | ~15% |
| **Total** | | **~81-157** | **~34%** |

**Conclusion:** On a Max 5x plan with proper model routing, a productive 8-hour day uses roughly **34% of the daily budget**, leaving ample headroom for complex tasks, retries, and exploration.

---

## 11. Action Items Summary

### Priority 1 (Do First)

| # | Item | Files Affected |
|---|------|---------------|
| A1 | Standardize agent `model` → `model_hint` | `agents/designer.md`, `agents/specifier.md` |
| A2 | Add missing agent model_hints | `agents/reviewer.md`, `agents/planner.md`, `agents/builder.md`, `agents/author.md`, `agents/verifier.md` |
| A3 | Verify all 18 command model_hints match strategy | All `commands/*.md` files |
| A4 | Profile hook loading mechanism | `scripts/hooks/`, `CLAUDE.md` hooks section |
| A5 | `check-sql-patterns.sh` hook | New: `profiles/hooks/python-fastapi/check-sql-patterns.sh` |

### Priority 2 (Next Sprint)

| # | Item | Files Affected |
|---|------|---------------|
| A6 | Add `effort_hint` to command/agent frontmatter | All commands and agents |
| A7 | Create parallel sessions guide | New: `docs/manuals/parallel-sessions.md` |
| A8 | Python/FastAPI hooks (async, pydantic, alembic) | New: `profiles/hooks/python-fastapi/` |
| A9 | `/fix` worktree support | `commands/fix.md` |
| A10 | Cache-manifest for /gather | `commands/gather.md`, new `.claude/context/.cache-manifest.json` |
| A11 | Validate skill detailed/*.md sizes | `scripts/validate-toolkit.sh` |
| A12 | Validate profile sizes | `scripts/validate-toolkit.sh` |
| A13 | Add FastAPI-specific items to review checklist | `skills/review/` |
| A14 | Document effort strategy in CLAUDE.md | `CLAUDE.md` |

### Priority 3 (Backlog)

| # | Item | Files Affected |
|---|------|---------------|
| A15 | Scratchpad file for long-running loop sessions | `/build --loop` docs |
| A16 | MCP schema size monitoring | `scripts/validate-toolkit.sh` or session startup |
| A17 | Reference doc size checks | `scripts/validate-toolkit.sh` |
| A18 | Monitor CLAUDE.md growth (currently 352/500 lines) | Ongoing |

### Not Adopting

| Item | Reason |
|------|--------|
| tmux scripts | Personal workflow, not toolkit concern |
| Statusline config | User-level Claude Code setting |
| PROGRESS.md | Session state system is superior |
| DECISIONS.md | ADR system is superior |
| Thinking budget in frontmatter | Not actionable — Claude Code doesn't expose effort parameter in skill/command frontmatter |

---

*Generated 2026-02-17. Based on gap analysis of env-setup-addendum.pdf and mastering-claude-code-guide v4.pdf against Atelier v0.1.2.*
*See also: `docs/reference/model-thinking-strategy.md`, `docs/reference/model-rationale-report.md`, `docs/reference/mcp-strategy.md`*
