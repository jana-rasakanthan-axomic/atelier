# Getting Started with Atelier

## What is Atelier?

Atelier is a development toolkit for Claude Code that encodes battle-tested workflows -- TDD, outside-in design, PR review -- into reusable commands. It separates **process** (how you build) from **stack** (what tools you use), so the same workflows work with Python, Flutter, React, or any other framework.

## Installation

| Method | Command |
|--------|---------|
| **Global** (~/.claude, recommended) | `git clone https://github.com/jana-rasakanthan-axomic/atelier.git ~/.claude/plugins/atelier` |
| **Project-specific** | `git clone https://github.com/jana-rasakanthan-axomic/atelier.git .atelier` |

For project-specific installs, add to `.claude/settings.json`:
```json
{ "plugins": [".atelier"] }
```

## First Run

Run `/init` in your project directory. Atelier will:

1. Detect your stack from marker files (`package.json`, `pubspec.yaml`, `pyproject.toml`, `main.tf`)
2. Activate the matching profile (test runner, linter, type checker)
3. Set up hooks for TDD enforcement and branch protection

### Built-in Profiles

| Profile | Marker File | Stack |
|---------|------------|-------|
| `python-fastapi` | `pyproject.toml` | Python backend |
| `flutter-dart` | `pubspec.yaml` | Flutter mobile |
| `react-typescript` | `tsconfig.json` | React web |
| `opentofu-hcl` | `main.tf` | Infrastructure |

If no marker file is found, Atelier will prompt you to select a profile.

## Quick Start Workflows

| Workflow | Commands |
|----------|----------|
| **Quick Fix** | `/gather` -- `/fix` -- `/review` -- `/commit` |
| **Single Feature** | `/gather` -- `/specify` -- `/design` -- `/plan` -- `/build` -- `/review --self` -- `/commit` |
| **Pre-PR Review** | `/build` -- `/review --self --loop` |
| **Batch / Overnight** | `/workstream create` -- `/plan` (all) -- approve -- `/build --loop` (all) |

## Key Concepts

### Commands vs Profiles vs Skills

- **Commands** define process: what steps to follow (`/build`, `/review`, `/plan`)
- **Profiles** define stack: which tools to invoke (pytest, flutter test, eslint)
- **Skills** define knowledge: how to do each step well (TDD patterns, review checklists)

Commands are stack-agnostic. The same `/build` command works in Python, Dart, or TypeScript because it delegates tool choices to the active profile.

### TDD is Mandatory

Every code change follows strict test-driven development:

1. **RED** -- Write failing tests first
2. **GREEN** -- Write minimum code to pass
3. **VERIFY** -- Run linter and type checker

Tests must fail before implementation begins. If they pass immediately, something is wrong with the tests.

### Git Worktrees

Each ticket gets its own git worktree -- an isolated working directory that shares git history. This enables parallel work without branch-switching conflicts.

```
project/                  # Main worktree
project-TICKET-101/       # Isolated worktree for ticket 101
project-TICKET-102/       # Isolated worktree for ticket 102
```

## Troubleshooting

**No profile detected**
Run `/init` manually. If no marker file exists, create a `.atelier/config.yaml` with an explicit profile setting.

**TDD hook blocking my write**
The hook requires a test file to be modified before implementation files. Write your test first. To temporarily bypass: `touch .claude/skip-tdd` (remove after).

**Branch protection blocking commit**
You are on `main` or `master`. Create a feature branch first: `git checkout -b <initials>_<description>`.

**`--loop` mode not working**
Loop mode requires the ralph-loop tool. If it is not installed, Atelier will report the error rather than silently falling back.
