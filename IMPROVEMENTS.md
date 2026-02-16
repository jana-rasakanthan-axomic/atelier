# Improvements

Improvement ideas collected while using atelier. Both the table and the details section are **append-only** — new items get added at the end, existing items are never removed or reordered.

## Summary

**By Priority:**

| Priority | Total | Backlog | Partial | Done |
|----------|-------|---------|---------|------|
| P0 | 3 | 0 | 0 | 3 |
| P1 | 5 | 0 | 0 | 5 |
| P2 | 2 | 0 | 0 | 2 |
| P3 | 7 | 0 | 0 | 7 |
| P4 | 1 | 0 | 0 | 1 |
| P5 | 4 | 0 | 0 | 4 |
| P6 | 1 | 0 | 0 | 1 |
| — | 21 | 1 | 0 | 20 |
| **Total** | **44** | **1** | **0** | **43** |

**By Category:**

| Category | Total | Backlog | Partial | Done |
|----------|-------|---------|---------|------|
| Hooks | 7 | 0 | 0 | 7 |
| State | 2 | 0 | 0 | 2 |
| Context | 6 | 0 | 0 | 6 |
| Scripts | 12 | 0 | 0 | 12 |
| Integration | 5 | 0 | 0 | 5 |
| Profiles | 2 | 0 | 0 | 2 |
| Testing | 2 | 0 | 0 | 2 |
| Commands | 4 | 1 | 0 | 3 |
| Config | 1 | 0 | 0 | 1 |
| Docs | 2 | 0 | 0 | 2 |
| Architecture | 1 | 0 | 0 | 1 |
| **Total** | **44** | **1** | **0** | **43** |

---

## Status Tracker

| ID | Title | Category | Description | Priority | Status |
|----|-------|----------|-------------|----------|--------|
| 1 | Phase guard hook | Hooks | Block writes to impl files during read-only phases | P0 | implemented |
| 2 | TDD verification hook | Hooks | Confirm test files modified before impl writes | P0 | implemented |
| 3 | Post-edit auto-lint | Hooks | Run profile linter automatically after edits | P0 | implemented |
| 4 | State machine | State | Track phase, feature, and locked files via JSON FSM | P2 | implemented |
| 5 | Design command diet | Context | Reduce `commands/design.md` to <200 lines | P1 | implemented |
| 6 | Workstream command diet | Context | Reduce `commands/workstream.md` to <150 lines | P1 | implemented |
| 7 | Build command diet | Context | Reduce `commands/build.md` to <150 lines | P1 | implemented |
| 8 | Skill progressive disclosure | Context | Lean SKILL.md with `reference/` dirs for details | P4 | implemented |
| 9 | Workstream engine | Scripts | Dependency-aware Python script for workstream ops | P6 | implemented |
| 10 | PRD validator | Scripts | Check PRD sections and flag ambiguous language | P3 | implemented |
| 11 | Design validator | Scripts | Check design tickets for AC, estimates, file targets | P3 | implemented |
| 12 | Bootstrap script | Scripts | Verify environment tools at session start | P3 | implemented |
| 13 | State manager | State | CLI script for state init, transition, status, lock | P2 | implemented |
| 14 | MCP server config | Integration | Settings template for Jira/Confluence MCP tools | P5 | implemented |
| 15 | Session persistence | Integration | Save/resume session state across conversations | P5 | implemented |
| 16 | Multi-model hints | Integration | Model preference in command frontmatter | P5 | implemented |
| 17 | Flesh out profiles | Profiles | Complete stub profiles for all four stacks | — | implemented |
| 18 | Profile validation | Profiles | Verify profile tool references resolve correctly | — | implemented |
| 19 | Self-review loop test | Testing | E2E test of `/review --self --loop` on real branch | — | implemented |
| 20 | Author quality loop | Commands | validate-toolkit.sh + `--loop` mode for `/author` | — | implemented |
| 21 | Workstream pr-check test | Testing | Integration test for workstream pr-check flow | — | implemented |
| 22 | User-level config | Config | XDG config at `~/.config/atelier/` | — | implemented |
| 23 | Human-readable manuals | Docs | User guides in `docs/manuals/` | P1 | implemented |
| 24 | Fix install docs | Docs | Replace fictional `plugins install` with git clone | P5 | implemented |
| 25 | Evaluation framework | Scripts | `evals/*.json` to test agent decisions | P3 | implemented |
| 26 | Braindump command diet | Context | Reduce and extract user guide from braindump.md | P1 | implemented |
| 27 | Skill validator | Scripts | Lint agent files against best practices | P3 | implemented |
| 28 | Source detector | Scripts | Parse input strings into structured source types | P3 | implemented |
| 29 | Gather interview | Scripts | Structured requirements questionnaire | P3 | implemented |
| 30 | Subagent refactoring | Architecture | Isolate heavy commands in subagent context | — | implemented |
| 31 | Adopt external plugins | Integration | Evaluate community tools vs building from scratch | — | implemented |
| 32 | Commit size warning | Hooks | Warn when staged changes exceed size thresholds | — | implemented |
| 33 | Secrets detection | Hooks | Scan for credentials and API keys before commit | — | implemented |
| 34 | Stacked PR dependencies | Integration | Track PR merge order for dependent features | — | implemented |
| 35 | Smart context loading | Context | On-demand doc loading triggered by user need | — | implemented |
| 36 | Plugin update command | Commands | Self-update mechanism for atelier installations | — | implemented |
| 37 | Git account mismatch detection | Scripts | Validate gh account matches repo owner before push | — | implemented |
| 38 | Force push protection | Hooks | Warn before force-pushing amended commits | — | implemented |
| 39 | Cross-platform path library | Scripts | Shared path resolution for macOS/Linux differences | — | implemented |
| 40 | Plugin registry verification | Scripts | Check plugin symlink and settings.json are in sync | — | implemented |
| 41 | Amend safety check | Hooks | Verify HEAD matches expected commit before amend | — | implemented |
| 42 | /atelier-feedback command | Commands | Capture toolkit improvement ideas into IMPROVEMENTS.md | — | implemented |
| 43 | Auto-increment toolkit version on merge | Scripts | Bump version automatically when changes merge to main/master | — | implemented |
| 44 | Daily brief command | Commands | /daily-brief command to start the day — pull worklog next steps, PR reviews, workstream status, configurable by engineer level | — | backlog |

---

## Details

### 1. Phase guard hook

**Problem:** Nothing mechanically prevents writing implementation code during read-only phases like `/plan` or `/review`. The process relies entirely on the LLM following instructions, which is unreliable.

**Solution:** A PreToolUse hook that reads `.atelier/state.json` to determine the active phase and blocks Write/Edit calls to implementation files during phases that should be read-only. Depends on the state machine (ID 4).

### 2. TDD verification hook

**Problem:** Without enforcement, the RED step in TDD can be skipped — implementation code gets written before any test file is modified.

**Solution:** A PreToolUse hook that checks `git diff` for test file modifications before allowing writes to implementation files. Implemented as `scripts/hooks/enforce-tdd-order.sh` (68 lines) with an allowlist for toolkit files and a bypass flag (`.claude/skip-tdd`).

### 3. Post-edit auto-lint

**Problem:** Lint and type errors accumulate during a build cycle and are only caught at the VERIFY step, requiring backtracking to fix them.

**Solution:** A PostToolUse hook that runs the active profile's linter (`${profile.linter}`) automatically after file edits, catching issues immediately.

### 4. State machine

**Problem:** There is no shared state tracking what phase the session is in, what feature is being worked on, or which files are locked. Hooks and commands have no way to coordinate.

**Solution:** A simple JSON file (`.atelier/state.json`) acting as a finite state machine with fields like `phase`, `feature`, `locked_files`. Transitions follow the pipeline: gather → specify → design → plan → build → review → deploy.

### 5. Design command diet

**Problem:** `commands/design.md` was 1,708 lines mixing splitting rules, examples, and prose. Every `/design` invocation loaded all of it, wasting ~30% of a Haiku context window in token tax.

**Solution:** Extract reference material to `skills/design/reference/` and keep the command lean. Now 159 lines with 5 reference files loaded on-demand.

### 6. Workstream command diet

**Problem:** `commands/workstream.md` was ~1,000 lines describing dependency resolution algorithms in prose that LLMs execute unreliably.

**Solution:** Reduce the command to <150 lines and extract dependency logic to a deterministic Python script (`workstream_engine.py`). Currently 137 lines (line target met) but the Python extraction hasn't happened yet.

### 7. Build command diet

**Problem:** `commands/build.md` was ~500 lines. TDD philosophy was duplicated between this file and CLAUDE.md, and layer-specific details belonged in profiles.

**Solution:** Reduce to <150 lines by removing duplication and moving layer details to profiles. Currently 161 lines — 11 lines over target.

### 8. Skill progressive disclosure

**Problem:** Skills loaded their full content on every invocation regardless of whether the detail was needed, adding unnecessary token overhead.

**Solution:** Keep SKILL.md lean (55–98 lines) with detailed examples and reference material in `reference/` or `detailed/` subdirectories, loaded only when needed. 6 of 11 skills now follow this pattern.

### 9. Workstream engine

**Problem:** The workstream command describes dependency resolution, priority search, and state tracking in prose. LLMs interpret these algorithms inconsistently, leading to wrong ordering and missed dependencies.

**Solution:** A Python script (`scripts/workstream_engine.py`) that handles create/status/next subcommands deterministically, with the command as a thin wrapper.

### 10. PRD validator

**Problem:** PRDs produced by `/specify` can be missing required sections or contain ambiguous language that causes downstream issues in design and planning.

**Solution:** A Python script (`scripts/validate_prd.py`) that checks PRDs have required sections (persona, problem, acceptance criteria) and flags ambiguous words like "should", "might", "easy". Runs at the end of `/specify`.

### 11. Design validator

**Problem:** Design tickets from `/design` sometimes lack acceptance criteria, effort estimates, or target file paths, making them incomplete for `/plan` and `/build`.

**Solution:** A Python script (`scripts/validate_design.py`) that validates ticket completeness. Runs at the end of `/design`.

### 12. Bootstrap script

**Problem:** Missing tools (wrong Python version, missing linter, unavailable test runner) are only discovered mid-build, wasting a session.

**Solution:** A Python script (`scripts/bootstrap.py`) that verifies the environment at session start — Python version, git, and all tools referenced by the active profile. One command instead of discovering problems mid-build.

### 13. State manager

**Problem:** Commands and hooks that need to read or update session state would have to hand-parse JSON, leading to inconsistent state manipulation.

**Solution:** A CLI companion script (`scripts/state_manager.py`) with subcommands — init, transition, status, lock — providing a clean interface to `.atelier/state.json` (ID 4).

### 14. MCP server config

**Problem:** `/gather` declares MCP tools for Jira and Confluence in its frontmatter, but there's no config template showing users how to set up the MCP connection in `.claude/settings.json`.

**Solution:** Provide a `.claude/settings.json` template with MCP blocks for Jira/Confluence, and update `/gather` to detect MCP availability and guide users through setup.

### 15. Session persistence

**Problem:** Session context is lost when a conversation ends. Resuming work requires manually re-establishing what was done, what phase was active, and what decisions were made.

**Solution:** Save session state to `.atelier/sessions/` with logs and resume capability. `/worklog` is a first step (captures summaries), but broader session state (phase, feature, artifacts) isn't persisted yet.

### 16. Multi-model hints

**Problem:** All commands use whatever model the user has selected, but some phases benefit from different models — `/design` needs deep reasoning (opus), `/build` needs speed (haiku).

**Solution:** Allow commands to declare a `model_hint` in their frontmatter, enabling cost/quality optimization per phase.

### 17. Flesh out profiles

**Problem:** The four built-in profiles (python-fastapi, flutter-dart, react-typescript, opentofu-hcl) were stubs with placeholder content, making them unusable for real projects.

**Solution:** Complete each profile with architecture layers, quality tools, test patterns, naming conventions, and patterns directories. All four are now comprehensive at 227–237 lines each.

### 18. Profile validation

**Problem:** Commands reference profile values like `${profile.test_runner}` and `${profile.linter}`, but nothing checks whether these references actually resolve to tools defined in the active profile. Broken references fail silently.

**Solution:** A script or hook that validates all `${profile.tools.*}` references resolve correctly when a profile is activated.

### 19. Self-review loop test

**Problem:** `/review --self --loop` is implemented but has never been tested end-to-end on a real branch. It's unknown whether the full flow (find issues → fix → re-review → converge) actually works reliably.

**Solution:** Run the flow on a real branch with known issues and document the results. Validate that it converges and produces a clean PR.

### 20. Author quality loop

**Problem:** Creating toolkit components (agents, skills, commands) by hand is error-prone — easy to miss required frontmatter, sections, or cross-references.

**Solution:** `scripts/validate-toolkit.sh` (364 lines) validates components against best practices. `/author --loop` runs automated validation-fix cycles until the component passes all checks.

### 21. Workstream pr-check test

**Problem:** The workstream `pr-check` subcommand triggers `/review --self --loop` for a PR, but this integration path has never been tested.

**Solution:** Run an integration test verifying that `/review --self --loop <PR#>` works correctly when triggered from workstream orchestration.

### 22. User-level config

**Problem:** There's no way to set atelier preferences (default profile, preferred model, output paths) that persist across projects.

**Solution:** XDG-compliant config at `~/.config/atelier/` with resolution order: project > user > auto-detect. `/worklog` already writes to this path, but `/init --global` and the full resolution chain aren't implemented.

### 23. Human-readable manuals

**Problem:** All documentation is agent-facing (commands, skills, CLAUDE.md). There are no user-facing guides explaining how to use atelier workflows as a human.

**Solution:** Guides in `docs/manuals/` for getting-started, design, and workstream workflows. These are never loaded by agents. Only `design.md` (68 lines) exists so far.

### 24. Fix install docs

**Problem:** CLAUDE.md references `claude plugins install jana-rasakanthan-axomic/atelier` as the recommended install method, but this command doesn't exist in Claude Code.

**Solution:** Replace with the actual install method: git clone + symlink (or project-specific clone to `.atelier`).

### 25. Evaluation framework

**Problem:** There's no way to test whether agent commands produce correct artifacts or make correct decisions. Regressions can go unnoticed.

**Solution:** An `evals/*.json` framework that defines expected inputs, agent actions, and expected outputs for each command. Run as part of CI or manual validation.

### 26. Braindump command diet

**Problem:** `commands/braindump.md` was 426 lines mixing a user-facing guide (how to braindump effectively) with agent instructions (how to process the braindump).

**Solution:** Extract the user guide to `docs/manuals/braindump.md` and keep only agent instructions in the command. Currently 163 lines — reduced but not yet extracted.

### 27. Skill validator

**Problem:** `/author` creates new toolkit components but has no automated way to lint them against best practices (required frontmatter, section structure, file size limits).

**Solution:** A Python script (`scripts/validate_skill.py`) that checks new agent, skill, and command files. Complements `validate-toolkit.sh` (ID 20) with deeper structural checks.

### 28. Source detector

**Problem:** `/gather` uses brittle regex patterns to detect whether input is a URL, file path, Jira ticket ID, or Confluence page. Edge cases break silently.

**Solution:** A Python script (`scripts/detect_source.py`) that parses an input string and returns a structured source type + ID, handling edge cases deterministically.

### 29. Gather interview

**Problem:** `/gather` accepts raw unstructured input, which means the LLM has to infer persona, problem statement, and success criteria from freeform text. Important context often gets missed.

**Solution:** A structured questionnaire (`scripts/gather_interview.py`) that captures Persona, Problem, and KPIs before the LLM processes the input, ensuring critical context is always present.

### 30. Subagent refactoring

**Problem:** `/workstream` and `/design` run heavy logic (dependency graphs, ticket splitting, schema generation) in the main context window, consuming tokens and risking context overflow for subsequent commands.

**Solution:** Delegate heavy processing to subagents via the `Task` tool, running in isolated context. The main window stays lean for user interaction.

### 31. Adopt external plugins

**Problem:** Atelier builds everything from scratch (PR review, commit messages, code analysis) when community plugins may already solve these problems well.

**Solution:** Evaluate external plugins (pr-review-toolkit, commit-commands, etc.) and adopt where they're better than building in-house. Reduce maintenance burden by leveraging community tools.

### 32. Commit size warning

**Problem:** Large commits (>500 lines or >30 files) are hard to review and increase merge risk. The toolkit doesn't warn or suggest splitting when staged changes are too large.

**Solution:** Add detection in `/commit` that warns when staged changes exceed thresholds. Suggest splitting into logical commits and require explicit confirmation before proceeding with oversized commits.

### 33. Secrets detection

**Problem:** Sensitive files (`.env`, `credentials.json`, API keys) can accidentally be committed, exposing secrets. There's no automated pre-commit scan to catch these.

**Solution:** Add pre-commit detection in `/commit` to scan for suspicious patterns — files matching `.env`, `*credentials*`, `*secret*`, `*key*`, and common secret patterns in file contents. STOP and warn before committing.

### 34. Stacked PR dependencies

**Problem:** When building dependent features in parallel, workstream doesn't track which PRs must merge before others. There's no `depends_on` field or merge-order enforcement.

**Solution:** Add a `depends_on` field to workstream ticket metadata tracking parent PR dependencies. Enforce merge order validation in `/workstream` to prevent merging child PRs before parents.

### 35. Smart context loading

**Problem:** Documentation is either always loaded (wasting tokens) or never loaded (missing when needed). There's no way to load reference material on-demand when the user is confused or a command fails.

**Solution:** An `@import` directive or similar mechanism that loads manuals or detailed reference docs based on user questions or command failures. Triggered by need signals rather than always-on.

### 36. Plugin update command

**Problem:** After installing atelier, there's no easy way to update to the latest version without manually running `git pull` in the plugin directory.

**Solution:** A `/update` command or script that automatically pulls the latest version from the configured source, handling both global (`~/.claude/plugins/`) and project-specific (`.atelier/`) installations.

### 37. Git account mismatch detection

**Problem:** Push failures due to account mismatches (local git config uses a different account than repo ownership) only surface during push, after all work is complete.

**Solution:** Add validation in `/init` or at the start of build/commit phases that checks the git remote URL against the active `gh` CLI account and warns about mismatches before work begins.

### 38. Force push protection

**Problem:** While CLAUDE.md prohibits force push to main/master, there's no protection against force-pushing to feature branches after amending already-pushed commits. This can overwrite shared work.

**Solution:** Detect in `/commit --amend` whether the commit has been pushed (`git log origin/branch..HEAD`) and warn about the force push requirement. Require explicit `--force` flag confirmation.

### 39. Cross-platform path library

**Problem:** macOS `realpath` doesn't support `--relative-to`, requiring Python workarounds. Scripts have platform-specific path handling inconsistencies that break on different OSes.

**Solution:** A shared `scripts/lib/paths.sh` library with platform-agnostic path resolution functions, or standardize on Python-based path handling across all scripts.

### 40. Plugin registry verification

**Problem:** Plugin symlinks alone don't register plugins — `settings.json` entries and marketplace registration can get out of sync. Manual edits to `installed_plugins.json` are ignored by Claude Code.

**Solution:** A `scripts/verify-plugin.sh` that checks plugin registration state (symlink exists, `settings.json` entry, marketplace registration) and provides repair commands when state is inconsistent.

### 41. Amend safety check

**Problem:** `git commit --amend` after a pre-commit hook failure targets the wrong commit — the failed commit never happened, so amend modifies the previous (unrelated) commit, destroying work.

**Solution:** Before allowing `--amend`, verify that HEAD matches the expected state. Show which commit will be modified and require explicit confirmation.

### 42. /atelier-feedback command

**Problem:** There's no structured way to capture toolkit improvement ideas during a session. Ideas get lost in conversation history or require manually editing IMPROVEMENTS.md.

**Solution:** A `/atelier-feedback` command that takes the user's raw suggestion, reformats it into the Title/Problem/Solution structure, shows it for confirmation, then appends to both the Status Tracker table and Details section in IMPROVEMENTS.md.

### 43. Auto-increment toolkit version on merge

**Problem:** The toolkit version (`0.1.0` in `installed_plugins.json`) is static and never updates when changes merge to main. Users and the plugin cache have no way to know if their cached version is current, and there's no version history tracking releases.

**Solution:** Add a version bump mechanism that increments the toolkit version each time a PR merges to main. This could be a GitHub Action, a git hook, or a script run by `/commit`. Store the version in a canonical location (e.g., `VERSION` file or `package.json`) and update the marketplace metadata accordingly.

### 44. Daily brief command

**Problem:** There's no structured way to start an engineering day. Context from previous sessions, pending PR reviews, and workstream status are scattered across tools. Engineers waste time manually piecing together what needs attention.

**Solution:** A `/daily-brief` command that aggregates: (1) "next steps" from the last worklog entry, (2) workstream ticket status, (3) pending PR reviews via `gh`, (4) uncommitted work across worktrees. Support a `--level` flag (default: senior) that adjusts focus — IC level emphasizes code tasks, staff level adds cross-team dependencies and blockers. Configuration (repos, boards, level default) lives in `~/.config/atelier/config.yaml`.

---

*Last updated: 2026-02-16*
