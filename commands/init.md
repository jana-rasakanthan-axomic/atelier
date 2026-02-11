---
name: init
description: Initialize Atelier for a project — detect stack and create config
allowed-tools: Read, Write, Glob, Bash(cat:*), AskUserQuestion
---

# /init

Initialize Atelier for a project by detecting the tech stack and creating configuration.

## Input Formats

```bash
/init                              # Auto-detect in current directory
/init --profile python-fastapi     # Explicit profile
/init --workspace                  # Multi-repo workspace mode
```

## When to Use

- First time setting up Atelier for a project
- Setting up a multi-repo workspace

## When NOT to Use

- Project already has `.atelier/config.yaml` → edit manually
- Just want to run a command → commands auto-detect profiles

## Workflow (3 Stages)

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

## Scope Limits

- Single project or workspace initialization only
- Does NOT install dependencies, create scaffolding, or modify source code
