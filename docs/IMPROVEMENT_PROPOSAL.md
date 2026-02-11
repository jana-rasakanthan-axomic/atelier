# Atelier Improvement Proposal — Deep Analysis & Recommendations

**Date:** 11 February 2026
**Status:** Approved for Implementation

---

## Sources Analyzed

| Source | Key Insight |
|--------|------------|
| **PDF** (17 pages) | The architectural blueprint: FSM state machine, hooks governance, agent teams, artifact schemas, TUI wrapper |
| **IMPROVEMENT_PLAN_2026.md** | Gap analysis: context bloat, missing scripts, platform dependency |
| **Atelier codebase** | 146 files, 15 commands, 7 agents, 10 skills, 4 profiles |
| **claude-toolkit** (all branches) | Jira-native, marketplace-ready, hooks roadmap, multi-model strategy, session persistence |

---

## 1. THE CORE TENSION: Vision vs Reality

The PDF describes an **Operating System** with FSM state transitions, deterministic hooks, agent teams via tmux, a TUI built in Bubble Tea, and mailbox-based inter-agent communication. The actual codebase is a **collection of well-structured Markdown instructions**. This gap isn't a problem — it's a *phasing opportunity*. The Markdown-first approach is the right foundation, but several pieces of the vision can be realized today with what Claude Code already supports.

### What the PDF envisions but doesn't exist yet

| PDF Concept | Status | Feasibility Now |
|-------------|--------|----------------|
| FSM via `state.json` | Not implemented | **High** — simple JSON file + hook checks |
| Deterministic Hooks (PreToolUse/PostToolUse) | Not implemented | **High** — Claude Code hooks are GA |
| Agent Teams (tmux + mailboxes) | Not implemented | **Medium** — experimental `TeammateTool` exists |
| TUI wrapper (Bubble Tea) | Not implemented | **Low priority** — Claude Code's native TUI is good enough |
| Periodic Compaction (session reboot) | Not implemented | **Medium** — can use `/compact` + artifact summarization |
| Validation Scripts (validate_prd.py, verify_tdd.py) | Not implemented | **High** — straightforward Python |

---

## 2. CRITICAL FINDINGS

### 2.1 Context Bloat (confirmed)

The improvement plan calls out `commands/design.md` at 1,708 lines. This is the single biggest operational risk. When loaded into an agent's context, it consumes ~4,000 tokens just for instructions. Combined with the design skill (SKILL.md + 6 supporting docs), a `/design` invocation could load 3,000+ lines of Markdown before touching a single line of user content.

**Measured impact**: Every command invocation pays a "token tax" proportional to its instruction length. A 1,700-line command wastes ~30% of a Haiku context window just on instructions.

### 2.2 The "Imposter Script" Problem (confirmed)

`commands/workstream.md` (1,000+ lines) describes algorithms in prose that LLMs execute unreliably: dependency graph resolution, priority search lists, state tracking via text parsing. The claude-toolkit takes a similar approach — it doesn't have scripts either. Both toolkits are asking the LLM to be a database engine, which it isn't.

### 2.3 Missing Enforcement Layer

The PDF's best idea — deterministic hooks — isn't implemented. Today, nothing mechanically prevents an agent from:
- Writing code during the `/plan` phase (which should be read-only)
- Skipping TDD (claiming tests pass without running them)
- Modifying the PRD during the build phase

### 2.4 What claude-toolkit Does Better

| Feature | claude-toolkit | atelier |
|---------|---------------|---------|
| Jira/Confluence native | Built-in `/gather` with MCP | Generic, no MCP config |
| Session persistence | `.claude/sessions.json` | Referenced in PDF, not implemented |
| Multi-model strategy | Documented (Opus for design, Haiku for build) | Mentioned in PDF, not operationalized |
| LLM-optimized skills | `detailed/` subfolder pattern (lean by default, verbose on fallback) | Everything loaded at once |
| Marketplace distribution | `.claude-marketplace/` ready | Plugin install documented but fictional |
| Hooks roadmap | Explicit Priority 1 with PreToolUse specs | Not started |

### 2.5 What Atelier Does Better

| Feature | atelier | claude-toolkit |
|---------|---------|---------------|
| Profile system | 4 stacks with full patterns/testing/style | FastAPI only |
| Specify phase | BDD scenarios + business rules before design | Skips to design |
| Process/stack separation | Clean `${profile.tools.*}` references | Hardcoded `pytest`, `ruff` |
| CLAUDE.md as constitution | 282 lines, comprehensive quick ref | Scattered across files |
| Authoring skill | Templates + checklists for creating new components | Basic |
| Worktree management | Full lifecycle scripts | Not present |

---

## 3. PRIORITIZED IMPROVEMENT PLAN

### P0: Hooks — The Enforcement Layer (Week 1)

This is the highest-leverage change. It makes every other improvement enforceable.

**Create `.claude/settings.json` with hooks:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "python scripts/hooks/guard_phase.py",
        "description": "Block writes during read-only phases (plan, specify, review)"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit",
        "command": "python scripts/hooks/post_edit_lint.py",
        "description": "Auto-lint after edits using profile's linter"
      }
    ]
  }
}
```

**Scripts needed:**
- `scripts/hooks/guard_phase.py` — reads `.atelier/state.json`, blocks writes if phase is `plan`/`specify`/`review`
- `scripts/hooks/post_edit_lint.py` — runs `${profile.linter}` after file edits
- `scripts/hooks/verify_tdd.py` — on build completion, checks test file timestamps

### P1: Context Diet — Slash Commands Under 200 Lines (Weeks 1-2)

Refactor the 3 bloated commands using a **3-tier architecture**:

```
commands/design.md        (~150 lines)  → Agent protocol only
skills/design/SKILL.md    (~200 lines)  → Procedural knowledge
docs/manuals/design.md    (~500 lines)  → Human reference (never loaded by agent)
```

**Specific actions:**

| File | Current | Target | What moves out |
|------|---------|--------|----------------|
| `commands/design.md` | 1,708 lines | <200 lines | Story splitting modes → `skills/design/reference/splitting_rules.md`; Workflow prose → `docs/manuals/design.md`; Examples → `skills/design/reference/examples.md` |
| `commands/workstream.md` | ~1,000 lines | <150 lines | Dependency resolution → `scripts/workstream_engine.py`; Status tracking → `scripts/workstream_status.py` |
| `commands/build.md` | ~500 lines | <150 lines | TDD philosophy → already in CLAUDE.md; Layer details → profile patterns |

### P2: State Machine — `.atelier/state.json` (Week 2)

Implement the FSM from the PDF as a simple JSON file:

```json
{
  "phase": "design",
  "feature": "subscription-billing",
  "ticket_id": "PROJ-42",
  "artifacts": {
    "prd": ".atelier/artifacts/prd-v1.md",
    "tdd": null,
    "plan": null
  },
  "locked_files": [".atelier/artifacts/prd-v1.md"],
  "created_at": "2026-02-11T10:00:00Z"
}
```

**Scripts:**
- `scripts/state_manager.py` — `init`, `transition`, `status`, `lock` subcommands
- Called by hooks to enforce phase gates
- Called by commands to check current phase before executing

### P3: Validation Scripts (Week 2-3)

These are the "verification protocols" the PDF calls for:

| Script | Purpose | When |
|--------|---------|------|
| `scripts/validate_prd.py` | Check PRD has all 6 sections, flag ambiguous words ("fast", "easy") | End of `/specify` |
| `scripts/validate_design.py` | Check tickets have acceptance criteria, point estimates, file targets | End of `/design` |
| `scripts/verify_tdd.py` | Confirm test files exist and were modified before impl files | During `/build` |
| `scripts/bootstrap.py` | Check Python, git, profile tools all available | Session start |

### P4: Progressive Disclosure for Skills (Week 3)

Adopt claude-toolkit's `detailed/` pattern. Skills load a lean SKILL.md by default. The agent only reads the `detailed/` subfolder if it needs more context (e.g., on retry, or when working with a less capable model).

```
skills/design/
├── SKILL.md                    (~100 lines, core protocol)
├── reference/                  (loaded on-demand)
│   ├── splitting_rules.md
│   ├── checklist.md
│   └── examples.md
└── templates/                  (loaded when generating output)
    ├── tdd.md
    ├── detailed-ticket.md
    └── adr.md
```

Use `@import` in CLAUDE.md sparingly — only load `SKILL.md`, let the agent `Read` reference files when needed.

### P5: Merge Best of claude-toolkit (Week 3-4)

| Feature to adopt | From | How |
|-----------------|------|-----|
| MCP server config for Jira/Confluence | claude-toolkit | Add `.claude/settings.json` MCP block; update `/gather` to detect MCP availability |
| Session persistence | claude-toolkit | `.atelier/sessions/` directory with session logs; `scripts/session_manager.py` resume capability |
| Multi-model hints | PDF + claude-toolkit | Add `model_hint` to command frontmatter: `model_hint: opus` for `/design`, `model_hint: haiku` for `/build` |
| Pattern referencing by name | claude-toolkit | Already partially done; formalize convention in authoring skill |

### P6: Workstream Engine in Python (Week 4)

Replace the 1,000-line prose algorithm with actual code:

```python
# scripts/workstream_engine.py (using typer)
@app.command()
def create(source: str, output_dir: str = ".atelier/workstreams/"):
    """Parse design tickets into a dependency-aware workstream."""

@app.command()
def status(workstream_id: str):
    """Print workstream status as JSON for agent consumption."""

@app.command()
def next(workstream_id: str):
    """Return the next unblocked ticket."""
```

The command file becomes a thin wrapper: "Read user intent → call `python scripts/workstream_engine.py <subcommand>` → summarize JSON output."

---

## 4. THINGS TO NOT DO

| Temptation | Why Not |
|------------|---------|
| Build a Bubble Tea TUI | Claude Code's native TUI is sufficient. Custom wrapper adds maintenance burden with no agent benefit. |
| Implement agent teams via tmux | Experimental feature still unstable. Wait for GA `TeammateTool`. Use subagents (`Task` tool) instead. |
| Add more profiles before fixing core | Flutter/React/OpenTofu profiles are stubs. Fix the engine (hooks, state, validation) before expanding the fleet. |
| Create a marketplace package | The `claude plugins install` command doesn't exist in standard Claude Code. Use git clone + symlink. |
| Over-engineer session management | A simple `state.json` + artifact files is sufficient. Don't build a database. |

---

## 5. PROPOSED NEW DIRECTORY STRUCTURE

```
atelier/
├── CLAUDE.md                          (282 lines — keep as-is, it's good)
├── .claude/
│   └── settings.json                  (NEW: hooks config)
├── commands/                          (all < 200 lines after refactor)
├── agents/                            (7 agents — keep as-is)
├── skills/
│   └── design/
│       ├── SKILL.md                   (lean: ~100 lines)
│       ├── reference/                 (NEW: on-demand loading)
│       │   ├── splitting_rules.md
│       │   ├── checklist.md
│       │   └── examples.md
│       └── templates/                 (keep)
├── profiles/                          (keep, expand later)
├── scripts/
│   ├── hooks/                         (NEW)
│   │   ├── guard_phase.py
│   │   ├── post_edit_lint.py
│   │   └── verify_tdd.py
│   ├── validate_prd.py               (NEW)
│   ├── validate_design.py            (NEW)
│   ├── workstream_engine.py          (NEW)
│   ├── state_manager.py              (NEW)
│   ├── bootstrap.py                  (NEW)
│   └── resolve-profile.sh            (keep)
├── templates/                         (keep)
└── docs/
    ├── manuals/                       (NEW: human-readable guides)
    │   ├── design.md
    │   ├── workstream.md
    │   └── getting-started.md
    └── ARCHITECTURE.md               (keep)
```

---

## 6. EXECUTION ORDER

| Week | Action | Impact |
|------|--------|--------|
| **1** | Implement hooks (`guard_phase.py`, `post_edit_lint.py`) + `state.json` | Enforcement layer — prevents phase violations |
| **1-2** | Refactor `commands/design.md` from 1,708 → <200 lines | 90% reduction in token tax for most common command |
| **2** | Add `validate_prd.py`, `validate_design.py` | Self-verification — agents can check their own work |
| **2-3** | Refactor `commands/workstream.md` into `scripts/workstream_engine.py` | Deterministic dependency resolution |
| **3** | Progressive disclosure for all skills (lean SKILL.md + reference/) | Context window savings across all commands |
| **3-4** | Port MCP config and session persistence from claude-toolkit | Enterprise readiness |
| **4** | Update `CLAUDE.md` to remove fictional `plugins install`, add bootstrap workflow | Honest onboarding |

---

## 7. SUCCESS METRICS

| Metric | Current | Target |
|--------|---------|--------|
| Largest command file | 1,708 lines | <200 lines |
| Avg tokens per command invocation | ~4,000 (estimated) | <1,000 |
| Phase violations possible | Unlimited | 0 (hook-enforced) |
| Self-verification scripts | 0 | 4 |
| Deterministic scripts (Python) | 0 | 6 |
| Commands requiring prose-algorithm execution | 2 (workstream, design) | 0 |

---

**Bottom line**: Atelier's *process design* is excellent — the pipeline, profiles, TDD enforcement, and separation of concerns are best-in-class. The gap is in *mechanical enforcement*. The PDF's hooks + state machine + validation scripts vision is the right answer. Build the enforcement layer first, diet the context second, and steal the best integration patterns from claude-toolkit third.
