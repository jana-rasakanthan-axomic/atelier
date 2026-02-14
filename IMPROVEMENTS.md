# Improvements

Single source of truth for all atelier improvement ideas. Items originate from brainstorms, session observations, and gap analysis. When an item becomes real work, update its status here.

---

## Status Tracker

| ID | Category | Improvement | Priority | Status | Notes |
|----|----------|-------------|----------|--------|-------|
| 1 | Hooks | Phase guard hook — block writes during read-only phases | P0 | backlog | Reads `.atelier/state.json`; needs state machine (ID 4) first |
| 2 | Hooks | TDD verification hook — confirm test files modified before impl | P0 | backlog | `scripts/hooks/verify_tdd.py` |
| 3 | Hooks | Post-edit auto-lint hook — run `${profile.linter}` after edits | P0 | backlog | `scripts/hooks/post_edit_lint.py` |
| 4 | State | State machine via `.atelier/state.json` — track phase, feature, locked files | P2 | backlog | Simple JSON FSM; hooks depend on this |
| 5 | Context | Context diet for `commands/design.md` — 1,708→<200 lines | P1 | backlog | Move splitting rules to `skills/design/reference/`, prose to `docs/manuals/` |
| 6 | Context | Context diet for `commands/workstream.md` — ~1,000→<150 lines | P1 | backlog | Move dependency resolution to `scripts/workstream_engine.py` |
| 7 | Context | Context diet for `commands/build.md` — ~500→<150 lines | P1 | backlog | TDD philosophy already in CLAUDE.md; layer details to profiles |
| 8 | Context | Progressive disclosure for skills — lean SKILL.md + `reference/` on-demand | P4 | backlog | Adopt claude-toolkit's `detailed/` pattern |
| 9 | Scripts | `scripts/workstream_engine.py` — dependency-aware Python (create, status, next) | P6 | backlog | Replace prose algorithm with real code |
| 10 | Scripts | `scripts/validate_prd.py` — check PRD sections, flag ambiguous words | P3 | backlog | Run at end of `/specify` |
| 11 | Scripts | `scripts/validate_design.py` — check tickets have AC, estimates, file targets | P3 | backlog | Run at end of `/design` |
| 12 | Scripts | `scripts/bootstrap.py` — verify Python, git, profile tools at session start | P3 | backlog | One-command environment check |
| 13 | State | `scripts/state_manager.py` — init, transition, status, lock subcommands | P2 | backlog | Companion to state machine (ID 4) |
| 14 | Integration | MCP server config for Jira/Confluence — `.claude/settings.json` MCP block | P5 | backlog | Update `/gather` to detect MCP availability |
| 15 | Integration | Session persistence — `.atelier/sessions/` with logs and resume | P5 | backlog | Port pattern from claude-toolkit |
| 16 | Integration | Multi-model hints — `model_hint` in command frontmatter | P5 | backlog | e.g. `opus` for `/design`, `haiku` for `/build` |
| 17 | Profiles | Flesh out stub profiles — Flutter, React, OpenTofu incomplete | — | backlog | Fix core engine first |
| 18 | Profiles | Profile validation — check `${profile.tools.*}` references resolve | — | backlog | Script or hook on profile activation |
| 19 | Testing | `/review --self --loop` end-to-end test on real branch | — | backlog | Validate full pre-PR self-review flow |
| 20 | Commands | `/author` validate-toolkit.sh + `--loop` mode | — | implemented | Foundation for author quality loop |
| 21 | Testing | Workstream pr-check integration test | — | backlog | Verify `/review --self --loop <PR#>` from `/workstream pr-check` |
| 22 | Config | User-level config at `~/.config/atelier/` (XDG standard) | — | backlog | Resolution: project > user > auto-detect; needs `/init --global` |
| 23 | Docs | Human-readable manuals in `docs/manuals/` | P1 | backlog | Getting-started, design, workstream guides; never loaded by agents |
| 24 | Docs | Remove fictional `plugins install` — document git clone + symlink | P5 | backlog | Plugin install command doesn't exist in standard Claude Code |
| 25 | Scripts | Evaluation framework — `evals/*.json` to test agent decisions | P3 | backlog | All commands must include self-check step |
| 26 | Context | Refactor `commands/braindump.md` — extract user guide to `docs/manuals/` | P1 | backlog | 426 lines; mixes user manual with agent instructions |
| 27 | Scripts | `scripts/validate_skill.py` — lint new agent files against best practices | P3 | backlog | For `/author` to validate created components |
| 28 | Scripts | `scripts/detect_source.py` — parse input string, return source type + ID | P3 | backlog | Replace brittle regex URL detection in `/gather` |
| 29 | Scripts | `scripts/gather_interview.py` — structured requirements questionnaire | P3 | backlog | Capture Persona, Problem, KPI before LLM sees input |
| 30 | Architecture | Subagent refactoring for `/workstream` and `/design` | — | backlog | Run in isolated context via `Task` tool instead of main window |
| 31 | Integration | Adopt external plugins — evaluate pr-review-toolkit, commit-commands, etc. | — | backlog | Use community tools instead of building from scratch |

---

## Vision & Strategy

Atelier is the "Operating System" for a workflow where coding is delegated to LLMs but verification remains critical. The source of truth shifts from code to **PRDs, TDDs, and Execution Plans**. The toolkit enforces a strict pipeline (`Gather → Specify → Design → Plan → Build → Review → Deploy`) using progressive disclosure and specialized agents.

**Core thesis**: The process design is excellent — the pipeline, profiles, TDD enforcement, and separation of concerns are best-in-class. The gap is in *mechanical enforcement*. Build the enforcement layer first, diet the context second, steal integration patterns third.

---

## Gap Analysis

**Context bloat** — Core commands (`design.md` at 1,708 lines, `workstream.md` at ~1,000 lines) mix user manuals with agent instructions. A single `/design` invocation can load 3,000+ lines before touching user content, consuming ~30% of a Haiku context window in "token tax" alone.

**Missing enforcement** — Nothing mechanically prevents writing code during `/plan`, skipping TDD, or modifying the PRD during build. The hooks + state machine vision from the architecture PDF is the right answer but isn't implemented yet.

**"Imposter script" problem** — `workstream.md` describes algorithms in prose (dependency graphs, priority search, state tracking) that LLMs execute unreliably. These should be deterministic Python scripts with the command as a thin wrapper.

**Platform dependency** — Documentation references `claude plugins install` which doesn't exist. `scripts/bootstrap.py` should handle environment setup honestly.

---

## Priority Tiers

| Tier | Focus | Rationale |
|------|-------|-----------|
| **P0** | Hooks (enforcement layer) | Highest leverage — makes every other improvement enforceable |
| **P1** | Context diet (commands <200 lines) | 90% reduction in token tax for common commands |
| **P2** | State machine (`.atelier/state.json`) | Enables phase-aware hooks and artifact locking |
| **P3** | Validation scripts | Self-verification — agents check their own work |
| **P4** | Progressive disclosure for skills | Context savings across all commands |
| **P5** | Integration (MCP, sessions, multi-model) | Enterprise readiness; port best of claude-toolkit |
| **P6** | Workstream engine in Python | Deterministic dependency resolution |

---

## Things NOT To Do

| Temptation | Why Not |
|------------|---------|
| Build a Bubble Tea TUI | Claude Code's native TUI is sufficient; custom wrapper adds maintenance with no agent benefit |
| Implement agent teams via tmux | Experimental `TeammateTool` still unstable; use subagents (`Task` tool) instead |
| Add more profiles before fixing core | Flutter/React/OpenTofu are stubs; fix hooks, state, and validation first |
| Create a marketplace package | `claude plugins install` doesn't exist; use git clone + symlink |
| Over-engineer session management | Simple `state.json` + artifact files is sufficient; don't build a database |

---

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Largest command file | 1,708 lines | <200 lines |
| Avg tokens per command invocation | ~4,000 (estimated) | <1,000 |
| Phase violations possible | Unlimited | 0 (hook-enforced) |
| Self-verification scripts | 0 | 4+ |
| Deterministic scripts (Python) | 0 | 6+ |
| Commands requiring prose-algorithm execution | 2 (workstream, design) | 0 |

---

*Last updated: 2026-02-14*
