---
name: init
description: Initialize Atelier for a project or user — detect stack and create config
model_hint: haiku
allowed-tools: Read, Write, Glob, Bash(cat:*), Bash(scripts/resolve-config.sh:*), AskUserQuestion
---

# /init

Initialize Atelier for a project by detecting the tech stack and creating configuration.

## Input Formats

```bash
/init                              # Auto-detect in current directory
/init --profile python-fastapi     # Explicit profile
/init --workspace                  # Multi-repo workspace mode
/init --global                     # Initialize user-level config (~/.config/atelier/)
```

## When to Use

- First time setting up Atelier for a project
- Setting up a multi-repo workspace
- First time setting up Atelier on a new machine (`--global`)

## When NOT to Use

- Project already has `.atelier/config.yaml` → edit manually
- Just want to run a command → commands auto-detect profiles
- User config already exists → use `scripts/resolve-config.sh set <key> <value>`

## Workflow (3 Stages)

### Early Exit: --global Flag

If `--global` is passed, skip the project workflow entirely and initialize user-level config.

**Actions:**
1. Run `scripts/resolve-config.sh init-global`
2. If config already exists, report and suggest `resolve-config.sh set` for updates
3. Ask the user for their git initials and preferred profile via `AskUserQuestion`
4. Apply answers with `scripts/resolve-config.sh set git.initials <value>` and `scripts/resolve-config.sh set profile <value>`
5. Run `scripts/resolve-config.sh show` and display the resolved config
6. **STOP.** Do not continue to Stage 1.

**Output:**
```
User config initialized: ~/.config/atelier/config.yaml

Resolved config:
  profile:          python-fastapi   (user)
  git.initials:     jr               (user)
  default_model:    sonnet           (user)
  ...

Next steps:
  - Run /init in a project directory for project-level config
  - Edit ~/.config/atelier/config.yaml directly for advanced options
```

### Stage 1: Detect Stack

Check for existing `.atelier/config.yaml` (warn/ask before overwriting). If `--profile` given, skip detection.

Search for marker files in order:

| Marker File | Content Check | Profile |
|-------------|---------------|---------|
| `pyproject.toml` | Contains "fastapi" | python-fastapi |
| `pyproject.toml` | Contains "django" | python-django |
| `pyproject.toml` | (no framework) | python-generic |
| `pubspec.yaml` | (any) | flutter-dart |
| `package.json` | Contains "react" | react-typescript |
| `package.json` | Contains "next" | next-typescript |
| `*.tf` | (any) | opentofu-hcl |
| `Cargo.toml` | (any) | rust |
| `go.mod` | (any) | go |

If no match or ambiguous, ask user via `AskUserQuestion`. Validate profile file exists at `profiles/{name}.md`.

### Stage 2: Configure

Write `.atelier/config.yaml` with detected profile. For `--workspace` mode, scan subdirectories and create multi-repo config with per-directory profile detection.

### Stage 3: Report

Show summary: detected profile, config path, detection method, available commands, how to customize.

## Error Handling

| Scenario | Action |
|----------|--------|
| Config already exists | Warn, ask to overwrite via AskUserQuestion |
| No marker files found | Ask user to select profile |
| Profile file missing | List available profiles, ask user to confirm |
| `--workspace` with no sub-repos | Fall back to single-repo mode |
| `--global` and user config exists | Report existing config, suggest `resolve-config.sh set` |
| `--global` and `resolve-config.sh` missing | Error with path to expected script location |

## Scope Limits

- Single project or workspace initialization only
- Does NOT install dependencies, create scaffolding, or modify source code
