# Model & Thinking Token Optimization Strategy

Atomic-level analysis of model selection and thinking budget across all Atelier components.

---

## Principles

1. **Match model power to operation complexity.** Architecture decisions need Opus. File reads need Haiku.
2. **Thinking tokens are expensive.** Only allocate extended thinking where reasoning depth improves output quality.
3. **Subagents inherit the subagent model by default.** Use `CLAUDE_CODE_SUBAGENT_MODEL` for cost control.
4. **Progressive disclosure is the primary cost lever.** Lean SKILL.md for Opus, detailed/*.md for Haiku/Sonnet.
5. **Scripts are free.** Move deterministic logic to bash/python scripts — zero model cost.

---

## Model Tier Definitions

| Tier | Model | Thinking | Use When |
|------|-------|----------|----------|
| **T1 — Max** | Opus | Extended (high budget) | Architecture decisions, multi-factor synthesis, contract design |
| **T2 — Balanced** | Sonnet | Standard | Code generation, TDD orchestration, plan drafting |
| **T3 — Fast** | Haiku | Minimal/None | File operations, git operations, template filling, validation parsing |
| **T0 — Script** | None | None | Deterministic: linting, testing, formatting, git status |

---

## Command-Level Optimization

### Tier 1 — Opus Commands (3)

| Command | Current | Recommended | Reasoning |
|---------|---------|-------------|-----------|
| `/design` | opus | **opus** ✓ | Multi-stage architecture; contract definition requires deep reasoning |
| `/review` | opus | **opus** ✓ | Multi-persona synthesis; security analysis needs thoroughness |
| `/specify` | opus | **opus** ✓ | Business rule extraction with nuance; PM-facing quality bar |

**Thinking budget:** Extended (high). These commands make the highest-leverage decisions.

### Tier 2 — Sonnet Commands (8)

| Command | Current | Recommended | Stage-Level Notes |
|---------|---------|-------------|-------------------|
| `/build` | sonnet | **sonnet** ✓ | Stage 0 (worktree): T3. Stage 1.5 (pre-analysis): T1. Stage 3 (TDD): T2. Stage 4 (verify): T0 script. |
| `/plan` | sonnet | **sonnet** ✓ | Stage 1 (scope): T3. Stage 2-3 (analyze/design): T2. Stage 4 (save): T3. |
| `/fix` | sonnet | **sonnet** ✓ | Stage 1 (analyze): T0 script. Stage 2 (plan fix): T2. Stage 4 (execute): T2. |
| `/braindump` | sonnet | **sonnet** ✓ | Stage 0 (capture): T3. Stage 1 (structure): T2. Stage 2 (draft PRD): T2. |
| `/gather` | sonnet | **haiku** ↓ | All stages are MCP fetch + template formatting. No reasoning needed. |
| `/daily-brief` | sonnet | **haiku** ↓ | MCP fetch + synthesis. Synthesis is lightweight (aggregation, not analysis). |
| `/deploy` | sonnet | **haiku** ↓ | All stages run profile-configured bash commands. No code generation. |
| `/workstream` | sonnet | **sonnet** ✓ | Deterministic subcommands (T0 script). Orchestration subcommands (T2). |

**Key insight:** `/gather`, `/daily-brief`, and `/deploy` are over-modeled. They perform fetching, formatting, and script execution — not reasoning. Downgrade to haiku.

**Thinking budget:** Standard for code generation stages. Minimal for orchestration stages.

### Tier 3 — Haiku Commands (7)

| Command | Current | Recommended | Notes |
|---------|---------|-------------|-------|
| `/commit` | haiku | **haiku** ✓ | Git operations + message drafting. Keep fast. |
| `/test` | haiku | **haiku** ✓ | Run tests + parse output. Mostly T0 script. |
| `/init` | haiku | **haiku** ✓ | Marker file detection + config write. |
| `/worklog` | haiku | **haiku** ✓ | Session summary synthesis. Fast is correct. |
| `/author` | haiku | **haiku** ✓ | Template application + validation. |
| `/atelier-feedback` | haiku | **haiku** ✓ | Read file + append. Minimal reasoning. |
| `/update` | none | **haiku** | Script execution. Add model_hint. |

**Thinking budget:** Minimal or none. Speed matters more than depth.

---

## Agent-Level Optimization

| Agent | Current Hint | Recommended | Thinking Budget | Rationale |
|-------|-------------|-------------|-----------------|-----------|
| **Designer** | opus | **opus** ✓ | Extended | Architecture decisions, ADR creation |
| **Specifier** | opus | **opus** ✓ | Extended | Business rule extraction, PM quality bar |
| **Reviewer** | none | **opus** | Extended | Multi-persona synthesis requires deep analysis |
| **Planner** | none | **opus** ↑ | Extended | Gap/risk analysis benefits from deeper reasoning |
| **Builder** | none | **sonnet** | Standard | TDD loop execution, code generation |
| **Author** | none | **haiku** | Minimal | Template application, validation scripting |
| **Verifier** | none | **haiku** | Minimal | Runs scripts, parses output, reports results |

**Key changes:**
- **Planner → opus.** The user specifically noted planning benefits from deeper reasoning. Plan quality directly gates build quality.
- **Reviewer → opus.** Security analysis and multi-perspective synthesis require thoroughness.
- **Builder → sonnet.** Code generation needs balance between quality and speed.
- **Author → haiku.** Template-driven; validation is scripted.
- **Verifier → haiku.** Runs test/lint/typecheck scripts and parses output.

---

## Skill-Level Optimization

Skills don't run independently — they're consumed by agents/commands. Optimization is about **progressive disclosure depth**.

| Skill | Complexity | Primary Consumer | Disclosure Strategy |
|-------|-----------|-----------------|---------------------|
| `design/` | High | Designer (opus) | Lean SKILL.md sufficient; opus understands concepts |
| `specify/` | Medium-High | Specifier (opus) | Lean SKILL.md sufficient |
| `review/` | Medium-High | Reviewer (opus) | Lean checklists; detailed examples for edge cases |
| `security/` | Medium-High | Reviewer (opus) | Lean SKILL.md; OWASP/STRIDE references on-demand |
| `building/` | Medium-High | Builder (sonnet) | Needs explicit layer templates in detailed/ |
| `iterative-dev/` | High | Builder (sonnet) | Config-driven; prompts are templates, not reasoning |
| `workstream/` | High | Workstream (sonnet) | Schema-driven; deterministic engine handles logic |
| `analysis/` | Medium | Analysis commands | Script-heavy; minimal model involvement |
| `authoring/` | Medium | Author (haiku) | Detailed templates needed for haiku |
| `git-workflow/` | Medium | All builders | Script-heavy; worktree-manager.sh handles logic |
| `testing/` | Medium | Verifier (haiku) | Profile-configured; haiku just runs commands |

---

## Atomic Operation Cost Map

Every operation in the toolkit maps to one of these cost tiers:

### T0 — Zero Model Cost (Scripts)
```
Run tests             → ${profile.test_runner}
Run linter            → ${profile.linter}
Run type checker      → ${profile.type_checker}
Git status/diff/log   → git commands
Git worktree setup    → worktree-manager.sh
Branch creation       → generate-branch-name.sh
Session management    → session-manager.sh
Workstream engine     → workstream_engine.py
Validation            → validate-toolkit.sh
Coverage analysis     → analyze-coverage.py
Format code           → gofmt, goimports, ruff (via hooks)
```

### T3 — Haiku Operations
```
Read file contents            → simple file reads
Parse test output             → structured output parsing
Generate commit message       → conventional commit format
Detect project stack          → marker file matching
Write config file             → template filling
Append to worklog             → session delta summary
Fetch MCP data                → Jira/Confluence/GitHub fetch
Format context document       → template-based structuring
```

### T2 — Sonnet Operations
```
Generate code (TDD)           → layer-by-layer implementation
Draft implementation plan     → gap analysis + risk assessment
Structure PRD from braindump  → content organization
Fix bugs with TDD             → diagnostic + targeted fix
Orchestrate workstream        → dependency-aware sequencing
Pre-analysis report           → codebase pattern matching
Build log drafting            → technical narrative
```

### T1 — Opus Operations
```
Architecture design           → multi-factor trade-off analysis
Contract definition           → API/service/data layer contracts
Business rule extraction      → nuanced PM-language rules
Multi-persona review          → security + engineering + product
ADR creation                  → decision documentation with rationale
Vertical slicing              → endpoint-level ticket decomposition
BDD scenario generation       → behavioral completeness validation
Implementation planning       → deep gap/risk reasoning
```

---

## Implementation Recommendations

### 1. Add model_hint to all agents (currently only 2 of 7 have hints)

Update frontmatter in:
- `agents/planner.md` → `model_hint: opus`
- `agents/reviewer.md` → `model_hint: opus`
- `agents/builder.md` → `model_hint: sonnet`
- `agents/author.md` → `model_hint: haiku`
- `agents/verifier.md` → `model_hint: haiku`

### 2. Downgrade over-modeled commands

Update frontmatter in:
- `commands/gather.md` → `model_hint: haiku`
- `commands/daily-brief.md` → `model_hint: haiku`
- `commands/deploy.md` → `model_hint: haiku`
- `commands/update.md` → `model_hint: haiku` (add missing hint)

### 3. Move more logic to scripts

Candidates for script extraction:
- Build pre-analysis: Extract codebase pattern detection to a script
- Workstream status formatting: Already uses workstream_engine.py — ensure all deterministic ops go through it
- Test result parsing: Create a script to parse test output into structured JSON

### 4. Thinking token budget by command phase

| Phase | Budget | Example |
|-------|--------|---------|
| Discovery (gather, braindump) | Minimal | Formatting, not reasoning |
| Specification (specify) | Extended | Nuanced business rules |
| Design (design) | Extended | Architecture trade-offs |
| Planning (plan) | Extended | Gap/risk analysis |
| Build (build, fix) | Standard | Code generation, TDD |
| Verify (test) | None | Script execution |
| Review (review) | Extended | Multi-factor synthesis |
| Ship (commit, worklog) | Minimal | Message drafting |
| Orchestration (workstream) | Standard | Dependency reasoning |

### 5. Environment variables

```bash
# .bashrc — already configured
export CLAUDE_CODE_SUBAGENT_MODEL="claude-sonnet-4-5-20250929"

# For cost-sensitive exploration, consider:
# export CLAUDE_CODE_SUBAGENT_MODEL="claude-haiku-4-5-20251001"
```

---

## Cost Impact Estimate

Based on typical token usage patterns:

| Change | Estimated Savings |
|--------|-------------------|
| `/gather` haiku → haiku | ~60% per invocation (model + thinking) |
| `/daily-brief` haiku → haiku | ~60% per invocation |
| `/deploy` haiku → haiku | ~60% per invocation |
| Agent model_hints (proper routing) | ~30% across builder/verifier invocations |
| Script extraction (test parsing etc.) | ~15% on verify stages |
| Thinking budget tuning | ~20% on discovery/ship phases |

**Total estimated reduction:** 25-40% of token spend across a full feature lifecycle, with no quality degradation on high-stakes decisions.

---

*See also: `skills/authoring/model-optimization.md` for progressive disclosure patterns.*
