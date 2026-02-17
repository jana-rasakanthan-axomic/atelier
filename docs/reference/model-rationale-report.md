# Model Hint Rationale Report

Why each Atelier component uses the model it does, with cost and rate limit context.

---

## Pricing Context (Feb 2026)

### API Pricing (per million tokens)

| Model | Input | Output | Cache Read | Cache Write (5m) | Batch Input | Batch Output |
|-------|-------|--------|------------|------------------|-------------|--------------|
| **Opus 4.6** | $5.00 | $25.00 | $0.50 | $6.25 | $2.50 | $12.50 |
| **Sonnet 4.5** | $3.00 | $15.00 | $0.30 | $3.75 | $1.50 | $7.50 |
| **Haiku 4.5** | $1.00 | $5.00 | $0.10 | $1.25 | $0.50 | $2.50 |

**Relative cost (output-weighted, Haiku = 1x):**

| Model | Input | Output | Effective Multiplier |
|-------|-------|--------|---------------------|
| Haiku 4.5 | 1x | 1x | **1x** (baseline) |
| Sonnet 4.5 | 3x | 3x | **3x** |
| Opus 4.6 | 5x | 5x | **5x** |

### Subscription Plans (Claude Code)

We use Claude Code via subscription, not direct API billing. This changes the economics:

| Plan | Price | Effective Model Access | Notes |
|------|-------|----------------------|-------|
| **Pro** | $20/mo | Sonnet only | ~45 prompts per 5-hour window |
| **Max 5x** | $100/mo | Opus + Sonnet + Haiku | ~225 prompts per 5-hour window |
| **Max 20x** | $200/mo | Opus + Sonnet + Haiku | ~900 prompts per 5-hour window |

**Subscription implications for model_hint selection:**

- On a subscription, per-token cost is **amortized** — you pay a flat monthly fee regardless of which model runs
- The real constraint is **throughput** (prompts per window), not per-token cost
- Opus prompts consume more tokens → fewer prompts fit in the window
- **Optimization goal shifts from cost to throughput:** use the cheapest-adequate model to maximize the number of prompts per window, not to save dollars

### API Rate Limits (per-minute, by tier)

| Model | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|-------|--------|--------|--------|--------|
| **Opus 4.x** (RPM / ITPM / OTPM) | 50 / 30K / 8K | 1K / 450K / 90K | 2K / 800K / 160K | 4K / 2M / 400K |
| **Sonnet 4.x** (RPM / ITPM / OTPM) | 50 / 30K / 8K | 1K / 450K / 90K | 2K / 800K / 160K | 4K / 2M / 400K |
| **Haiku 4.5** (RPM / ITPM / OTPM) | 50 / 50K / 10K | 1K / 450K / 90K | 2K / 1M / 200K | 4K / 4M / 800K |

**Key observations:**
- Haiku has 2x the token throughput of Opus/Sonnet at Tier 3+
- Cached input tokens do NOT count toward ITPM limits (huge for prompt-heavy workflows)
- Opus 4.x rate limit is **shared** across Opus 4.6, 4.5, 4.1, and 4 — heavy Opus use can exhaust the pool

### Claude Code Session Limits

| Constraint | Mechanism | Reset |
|-----------|-----------|-------|
| **Burst limit** | Rolling 5-hour window of prompts | Continuous (sliding window) |
| **Weekly cap** | Active processing hours per week | Weekly reset |
| **Unified** | Shared across browser, CLI, IDE | N/A |

**Pro:** ~40-80 active Sonnet hours/week
**Max:** Up to ~480 Sonnet hours OR ~40 Opus hours/week

**Critical insight:** An Opus prompt consumes roughly **12x** the active time of a Haiku prompt. On a Max subscription, using Haiku for `/commit` instead of Opus means you can run ~12x more commits before hitting the weekly cap. Model_hint selection directly impacts how many operations you can perform per session.

---

## Model Tier Principles

| Tier | Model | Thinking Budget | Use When |
|------|-------|----------------|----------|
| **T1 — Max** | Opus | Extended (high) | Architecture decisions, multi-factor synthesis, contract design |
| **T2 — Balanced** | Sonnet | Standard | Code generation, TDD orchestration, plan drafting |
| **T3 — Fast** | Haiku | Minimal/None | File operations, git operations, template filling, validation |
| **T0 — Script** | None | None | Deterministic: linting, testing, formatting, git status |

---

## Effort Level Strategy

The `effort` parameter (available on Opus 4.6, Sonnet 4.6, Opus 4.5) controls how many tokens Claude spends on reasoning. It replaces manual `budget_tokens` on Opus 4.6 via adaptive thinking (`thinking: {type: "adaptive"}`).

### Effort Levels

| Level | Thinking Behavior | Token Impact | Use Case |
|-------|------------------|-------------|----------|
| **max** | Deepest reasoning, no token constraints | Highest token spend (~2-3x high) | Tasks requiring absolute thoroughness. Opus 4.6 only. |
| **high** | Full reasoning (default) | Baseline | Complex reasoning, difficult coding, agentic tasks |
| **medium** | Moderate reasoning, some savings | ~40-60% of high | Balanced speed/cost/quality for agentic workflows |
| **low** | Minimal reasoning, may skip thinking | ~20-30% of high | Simple tasks, subagents, classification, high-volume |

### Cost Impact of Effort (Thinking Tokens Are Output Tokens)

Thinking tokens are billed as **output tokens** — the most expensive token type. This makes effort level a major cost lever:

| Model | Effort | Est. Thinking Tokens | Est. Output Cost (per call) | Relative |
|-------|--------|---------------------|---------------------------|----------|
| Opus 4.6 | max | ~20K-50K | $0.50 - $1.25 | **2-3x** |
| Opus 4.6 | high | ~8K-20K | $0.20 - $0.50 | **1x** (baseline) |
| Opus 4.6 | medium | ~3K-8K | $0.08 - $0.20 | **0.4x** |
| Opus 4.6 | low | ~0-3K | $0.00 - $0.08 | **0.15x** |
| Sonnet 4.5 | high | ~5K-15K | $0.08 - $0.23 | **1x** |
| Sonnet 4.5 | medium | ~2K-5K | $0.03 - $0.08 | **0.4x** |
| Sonnet 4.5 | low | ~0-2K | $0.00 - $0.03 | **0.15x** |

### Subscription Impact of Effort

On a Max subscription, effort directly affects how many operations fit in the 5-hour window:

- **High effort** Opus prompt: consumes ~1-2 minutes of active time
- **Low effort** Opus prompt: consumes ~0.2-0.5 minutes
- Reducing effort from high → low on non-critical commands can **3-5x** the number of prompts per window

### Recommended Effort by Command

| Command | Model | Recommended Effort | Rationale |
|---------|-------|-------------------|-----------|
| `/design` | opus | **high** | Architecture decisions need full reasoning depth |
| `/review` | opus | **high** | Security analysis cannot afford shallow thinking |
| `/specify` | opus | **high** | Business rules require nuanced interpretation |
| `/plan` | opus | **high** | Gap/risk analysis needs thoroughness |
| `/build` | sonnet | **medium** | TDD is iterative — each step is bounded, doesn't need max depth |
| `/fix` | sonnet | **medium** | Diagnostic + targeted fix; iterative correction handles gaps |
| `/braindump` | sonnet | **medium** | Structuring ideas, not deep analysis |
| `/workstream` | sonnet | **medium** | Orchestration, not deep reasoning per se |
| `/commit` | haiku | **low** | Git ops + message drafting. Speed > depth. |
| `/test` | haiku | **low** | Script execution + output parsing |
| `/gather` | haiku | **low** | MCP fetch + template. Zero reasoning. |
| `/daily-brief` | haiku | **low** | Data aggregation |
| `/deploy` | haiku | **low** | Script execution |
| `/update` | haiku | **low** | Script execution |
| `/worklog` | haiku | **low** | Summary synthesis |
| `/init` | haiku | **low** | Template filling |
| `/author` | haiku | **low** | Template application |
| `/atelier-feedback` | haiku | **low** | Read + append |

### Recommended Effort by Agent

| Agent | Model | Recommended Effort | Rationale |
|-------|-------|-------------------|-----------|
| **Designer** | opus | **high** | Architecture decisions, ADRs — wrong designs cascade |
| **Specifier** | opus | **high** | Business rules go to PM — quality bar is high |
| **Reviewer** | opus | **high** | Multi-persona security analysis needs depth |
| **Planner** | opus | **high** | Plan quality gates build quality |
| **Builder** | sonnet | **medium** | TDD is self-correcting; iterations compensate for lighter thinking |
| **Author** | haiku | **low** | Template-driven, validation is scripted |
| **Verifier** | haiku | **low** | Runs scripts, parses output |

### Combined Model + Effort Cost Matrix

Estimated per-call cost combining model selection and effort level (typical 10K input, 5K output call):

| | Low Effort | Medium Effort | High Effort | Max Effort |
|---|-----------|---------------|-------------|------------|
| **Opus 4.6** | ~$0.18 | ~$0.35 | ~$0.60 | ~$1.25 |
| **Sonnet 4.5** | ~$0.06 | ~$0.12 | ~$0.20 | N/A |
| **Haiku 4.5** | ~$0.02 | ~$0.04 | ~$0.06 | N/A |

**Key takeaway:** An Opus call at low effort costs less than a Sonnet call at high effort. The effort lever is as powerful as the model lever for cost optimization. However, on subscription the throughput (prompts per window) impact matters more than dollar cost.

---

## Command Rationale (18 commands)

### Opus Commands (4)

| Command | model_hint | Key Operations | Rationale |
|---------|-----------|----------------|-----------|
| `/design` | **opus** | Architecture decisions, contract definition, ADR creation, vertical slicing | Multi-stage trade-off analysis across API, service, and data layers. Wrong design decisions cascade through the entire build. Extended thinking budget justified. |
| `/review` | **opus** | Multi-persona analysis (security + engineering + product), finding subtle bugs, architecture validation | Synthesis across three review perspectives requires thoroughness. Security analysis cannot afford false negatives. Cheapest model that catches the most issues. |
| `/specify` | **opus** | Business rule extraction, user story generation, acceptance criteria, BDD scenarios | Nuanced PM-language interpretation. Missing a business rule means building the wrong thing. Quality bar must match PM expectations. |
| `/plan` | **opus** | Gap analysis, risk assessment, layer decomposition, dependency ordering | Plan quality directly gates build quality. A flawed plan means rework across all downstream layers. Deep reasoning catches missing dependencies and architectural risks that cheaper models miss. Previously sonnet — upgraded because gap/risk analysis is architecture-level reasoning. |

### Sonnet Commands (4)

| Command | model_hint | Key Operations | Rationale |
|---------|-----------|----------------|-----------|
| `/build` | **sonnet** | TDD loop execution, layer-by-layer code generation, pre-analysis, verification | Core code generation loop. Needs enough reasoning for correct implementations but runs frequently — opus would exhaust the session budget. Stage 0 (worktree) is T3, Stage 1.5 (pre-analysis) is T1, Stage 3 (TDD) is T2, Stage 4 (verify) is T0. |
| `/fix` | **sonnet** | Diagnostic analysis, targeted bug fixing, TDD workflow | Similar to build but scoped to a single defect. Stage 1 (analyze) is T0 script, Stage 2 (plan fix) is T2, Stage 4 (execute) is T2. |
| `/braindump` | **sonnet** | Content capture, PRD structuring, idea organization | Transforms raw unstructured input into structured PRDs. Needs language organization ability but not deep architectural reasoning. |
| `/workstream` | **sonnet** | Batch orchestration, dependency reasoning, status aggregation | Orchestrates multiple parallel plans/builds with dependency awareness. Some stages are T0 (engine scripts), but orchestration decisions need T2 reasoning. |

### Haiku Commands (10)

| Command | model_hint | Previous | Key Operations | Rationale |
|---------|-----------|----------|----------------|-----------|
| `/commit` | **haiku** | haiku | Git staging, conventional commit message drafting, push | Deterministic git operations + short message generation. Speed is the priority — commits should feel instant. |
| `/test` | **haiku** | haiku | Run test suites via profile runner, parse output, report results | Almost entirely T0 script execution. Model involvement is limited to parsing and formatting test output. |
| `/gather` | **haiku** | sonnet | MCP fetch (Jira/Confluence/GitHub), template formatting, context document creation | All stages are fetch + format. Zero reasoning required. Previously over-modeled at sonnet. Downgraded to save ~60% throughput per invocation. |
| `/daily-brief` | **haiku** | sonnet | MCP aggregation (PRs, worklogs, workstreams), lightweight synthesis | Data aggregation with minimal synthesis. The "synthesis" is summarization, not analysis. Previously over-modeled at sonnet. |
| `/deploy` | **haiku** | sonnet | Profile-configured bash script execution | Runs deployment scripts defined by the active profile. No code generation, no reasoning — just script execution. Previously over-modeled at sonnet. |
| `/update` | **haiku** | none | Git operations, script execution | Runs update scripts. No reasoning needed. Previously had no model_hint at all. |
| `/worklog` | **haiku** | haiku | Session delta summary, append to work log | Lightweight synthesis of session activity. Speed matters more than depth. |
| `/init` | **haiku** | haiku | Marker file detection, config writing, profile selection | Template-based setup. Detects project stack and writes config — no reasoning. |
| `/author` | **haiku** | haiku | Template application, structural validation via scripts | Generates/improves components from templates. Validation is handled by `validate-toolkit.sh` (T0), not the model. |
| `/atelier-feedback` | **haiku** | haiku | Read file, append improvement idea | Read + append operation. Minimal model involvement. |

---

## Agent Rationale (7 agents)

| Agent | model_hint | Previous | Thinking Budget | Key Operations | Rationale |
|-------|-----------|----------|----------------|----------------|-----------|
| **Designer** | **opus** | opus | Extended | Architecture decisions, vertical slicing, ADR creation, contract definition | Produces the architectural blueprint. Wrong decisions here cascade through every downstream layer. Extended thinking catches trade-offs that standard thinking misses. |
| **Specifier** | **opus** | opus | Extended | Business rule extraction, BDD scenario generation, PM-facing deliverables | Quality bar must match PM expectations. Nuanced language interpretation requires deep reasoning. Approval-driven workflow — output goes directly to stakeholders. |
| **Reviewer** | **opus** | none | Extended | Multi-persona security analysis, engineering review, product alignment | Three review perspectives (security, engineering, product) require synthesis across different concern domains. Security analysis needs thoroughness — false negatives are costly. Previously had no model_hint. |
| **Planner** | **opus** | none | Extended | Gap analysis, risk assessment, implementation planning, dependency ordering | Plans gate build quality. A planner that misses a dependency creates rework across all build stages. Deep reasoning catches architectural risks. Previously had no model_hint — strategy recommended opus. |
| **Builder** | **sonnet** | none | Standard | TDD loop, layer-by-layer code generation, refactoring | Core code generation agent. Runs most frequently of all agents. Opus would be more thorough but would exhaust the session budget. Sonnet provides the right quality/throughput balance. Previously had no model_hint. |
| **Author** | **haiku** | none | Minimal | Template-driven component generation, documentation | Generates agents, commands, and skills from templates. Structural validation is handled by `validate-toolkit.sh` (T0 script), not the model. Haiku is sufficient for template filling. Previously had no model_hint. |
| **Verifier** | **haiku** | none | Minimal | Run test/lint/typecheck scripts, parse output, report results | Almost entirely script execution (T0). Model involvement is limited to parsing structured output and formatting reports. Previously had no model_hint. |

---

## Cost & Throughput Impact

### Per-Invocation Savings (API pricing)

| Change | Before | After | Savings |
|--------|--------|-------|---------|
| `/gather` sonnet → haiku | ~$0.045/call | ~$0.015/call | **~67%** |
| `/daily-brief` sonnet → haiku | ~$0.045/call | ~$0.015/call | **~67%** |
| `/deploy` sonnet → haiku | ~$0.045/call | ~$0.015/call | **~67%** |
| Agent model_hints (proper routing) | Variable | Routed correctly | **~30%** across builder/verifier |
| Script extraction | Model cost | Zero | **~15%** on verify stages |

### Subscription Throughput Impact

On a Max subscription, the real metric is **operations per window**, not dollars:

| Scenario | Opus Prompts | Sonnet Prompts | Haiku Prompts | Total Ops |
|----------|-------------|----------------|---------------|-----------|
| **Before** (everything on sonnet) | 0 | ~225 | 0 | 225 |
| **After** (tiered model_hints) | ~20 (design/review/specify/plan) | ~80 (build/fix) | ~400 (commit/test/gather/etc.) | **~500** |

**Estimated throughput gain: ~2.2x more operations per 5-hour window** by routing low-complexity commands to haiku.

### Weekly Active Hours Impact

| Model | Active Hours per Prompt (avg) | Weekly Budget (Max) |
|-------|------------------------------|---------------------|
| Opus | ~0.5-2 min | ~40 hours |
| Sonnet | ~0.2-0.5 min | ~480 hours |
| Haiku | ~0.05-0.1 min | Effectively unlimited |

Moving 10 commands from sonnet to haiku frees ~60% of weekly active hours for build/design work that actually needs model power.

### Full Feature Lifecycle Estimate

A typical feature lifecycle (`/gather → /specify → /design → /plan → /build → /review → /commit`):

| Command | Model | Est. Tokens (in/out) | API Cost | Window Cost |
|---------|-------|---------------------|----------|-------------|
| `/gather` | haiku | 5K / 2K | $0.015 | 1 prompt |
| `/specify` | opus | 10K / 8K | $0.250 | 1 prompt |
| `/design` | opus | 15K / 12K | $0.375 | 1 prompt |
| `/plan` | opus | 12K / 10K | $0.310 | 1 prompt |
| `/build` (3 layers) | sonnet | 30K / 25K | $0.465 | 6 prompts |
| `/test` | haiku | 3K / 1K | $0.008 | 1 prompt |
| `/review` | opus | 20K / 15K | $0.475 | 1 prompt |
| `/commit` | haiku | 2K / 1K | $0.007 | 1 prompt |
| **Total** | | **97K / 74K** | **~$1.91** | **13 prompts** |

On a Max 5x subscription ($100/mo), this is approximately **1/17th** of the 5-hour window budget — allowing roughly 17 full feature cycles per window.

---

## Decision Log

| Date | Component | Change | Rationale |
|------|-----------|--------|-----------|
| 2026-02-17 | `/plan` | sonnet → opus | Gap/risk analysis is architecture-level reasoning |
| 2026-02-17 | `/gather` | sonnet → haiku | MCP fetch + template formatting, no reasoning |
| 2026-02-17 | `/daily-brief` | sonnet → haiku | Data aggregation, not synthesis |
| 2026-02-17 | `/deploy` | sonnet → haiku | Runs profile bash scripts, no code generation |
| 2026-02-17 | `/update` | none → haiku | Script execution, add missing hint |
| 2026-02-17 | Planner agent | none → opus | Plans gate build quality; deep reasoning needed |
| 2026-02-17 | Reviewer agent | none → opus | Multi-persona security analysis needs thoroughness |
| 2026-02-17 | Builder agent | none → sonnet | TDD code generation, balanced quality/speed |
| 2026-02-17 | Author agent | none → haiku | Template-driven, validation is scripted |
| 2026-02-17 | Verifier agent | none → haiku | Runs test/lint scripts, parses output |

---

*Sources: [Anthropic Pricing](https://platform.claude.com/docs/en/about-claude/pricing), [Rate Limits](https://platform.claude.com/docs/en/api/rate-limits), [Effort Parameter](https://platform.claude.com/docs/en/build-with-claude/effort), [Extended Thinking](https://platform.claude.com/docs/en/build-with-claude/extended-thinking), [Claude Plans](https://claude.com/pricing). See also: `model-thinking-strategy.md` for the atomic operation analysis that informed these decisions.*
