# Improvements

Backlog of ideas, observations, and suggestions for atelier. Captured from any project, refined here.

Add new items under the appropriate category. When an item becomes real work, move it to a GitHub issue or `/plan` and mark it `[DONE]` here.

---

## Enforcement & Hooks

- [ ] **Phase guard hook** — `guard_phase.py` blocks writes during read-only phases (plan, specify, review). Reads `.atelier/state.json` to determine current phase.
- [ ] **TDD verification hook** — `verify_tdd.py` confirms test files were modified before implementation files during `/build`.
- [ ] **Post-edit auto-lint hook** — `post_edit_lint.py` runs `${profile.linter}` after file edits automatically.
- [ ] **State machine via `.atelier/state.json`** — simple JSON tracking current phase, feature, ticket, locked files. Hooks read this to enforce gates.

## Context & Performance

- [ ] **Context diet for `commands/design.md`** — currently 1,708 lines. Target <200 lines. Move splitting rules to `skills/design/reference/`, workflow prose to `docs/manuals/`, examples to reference docs.
- [ ] **Context diet for `commands/workstream.md`** — ~1,000 lines of prose algorithms. Move dependency resolution and status tracking to Python scripts.
- [ ] **Context diet for `commands/build.md`** — ~500 lines. TDD philosophy already in CLAUDE.md; layer details belong in profile patterns.
- [ ] **Progressive disclosure for skills** — lean SKILL.md loaded by default, `reference/` subfolder loaded on-demand (on retry or with less capable models).

## Scripts & Automation

- [ ] **`scripts/workstream_engine.py`** — replace prose algorithm with real dependency-aware Python code (create, status, next subcommands).
- [ ] **`scripts/validate_prd.py`** — check PRD has all required sections, flag ambiguous words ("fast", "easy") at end of `/specify`.
- [ ] **`scripts/validate_design.py`** — check tickets have acceptance criteria, point estimates, file targets at end of `/design`.
- [ ] **`scripts/bootstrap.py`** — verify Python, git, profile tools all available at session start.
- [ ] **`scripts/state_manager.py`** — init, transition, status, lock subcommands for the state machine.

## Integration

- [ ] **MCP server config for Jira/Confluence** — add `.claude/settings.json` MCP block, update `/gather` to detect MCP availability.
- [ ] **Session persistence** — `.atelier/sessions/` directory with session logs, resume capability.
- [ ] **Multi-model hints** — add `model_hint` to command frontmatter (e.g., `model_hint: opus` for `/design`, `model_hint: haiku` for `/build`).

## Profiles

- [ ] **Flesh out stub profiles** — Flutter, React, OpenTofu profiles exist but are incomplete. Fix core engine first, then expand.
- [ ] **Profile validation** — script or hook that checks all `${profile.tools.*}` references resolve to real commands when a profile is activated.

## Commands & Skills

- [ ] **`/review --self --loop` end-to-end test** — validate the full pre-PR self-review flow on a real branch with deliberate issues.
- [DONE] **`/author` command for IMPROVEMENTS.md** — teach `/author` to append structured entries here when improvement ideas surface during work. (Foundation: `validate-toolkit.sh` + `--loop` mode added)
- [ ] **Workstream pr-check integration test** — verify `/review --self --loop <PR#>` works correctly when invoked from `/workstream pr-check`.

## Documentation

- [ ] **Human-readable manuals** — `docs/manuals/` with getting-started, design, and workstream guides. Never loaded by agents, just for humans.
- [ ] **Remove fictional `plugins install`** — the `claude plugins install` command doesn't exist in standard Claude Code. Document git clone + symlink honestly.

---

*Last updated: 2026-02-13*
