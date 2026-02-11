---
name: deploy
description: Build, deploy, and verify application using profile-configured tools
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(${profile.tools.test_runner.command}:*), Bash(${profile.tools.linter.command}:*), Bash(git:*), Bash(docker:*), AskUserQuestion
---

# /deploy

Build, deploy, and verify application using profile-configured tools.

## Input Formats

```bash
/deploy                    # Deploy current branch to staging (default)
/deploy staging            # Deploy to staging
/deploy production         # Deploy to production (extra confirmation)
/deploy --dry-run          # Preview deployment steps
/deploy --rollback         # Rollback to previous deployment
```

## When to Use

- Feature is built, tested, and ready to ship
- Need to push a release to staging or production

## When NOT to Use

- Code has failing tests → `/fix` first
- Feature not yet built → `/build` first
- Infrastructure changes needed → `/plan` first

## Environment Safety

| Environment | Confirmation | Branch Restriction |
|-------------|-------------|-------------------|
| dev/staging | No | Any branch |
| production | YES (explicit) | main/master only |

**Safety rules:** Never auto-deploy to production without explicit confirmation. Never auto-rollback. Always run preflight checks. Always record deployment metadata.

## Profile Resolution

```bash
TOOLKIT_DIR="${CLAUDE_TOOLKIT:-$HOME/.claude}"
PROFILE=$("$TOOLKIT_DIR/scripts/resolve-profile.sh")
```

Profile determines: test runner, linter, type checker, build tool (`${profile.tools.build.command}`), deploy tool (`${profile.tools.deploy.command}`).

## Workflow (5 Stages)

### Stage 0: Preflight Checks

Verify clean git state, run all quality gates (tests, lint, types), verify branch is up-to-date with remote. For production: enforce branch restriction (main/master only), require explicit confirmation via `AskUserQuestion`.

If `--dry-run`: annotate output with `[DRY RUN]`, continue through stages without executing side effects.

### Stage 1: Build

Execute `${profile.tools.build.command}`. Capture build artifacts path, git SHA, timestamp. On failure: report error and exit (do not attempt deploy).

### Stage 2: Deploy

Execute `${profile.tools.deploy.command} --environment "$TARGET_ENV"`. Save deployment metadata to `.claude/deployments/latest.json` (environment, git_sha, branch, timestamp, deployer, status). Keep history copy.

### Stage 3: Smoke Test

Run profile-defined smoke tests (`${profile.tools.smoke_test.command}`), check health endpoint (`${profile.deploy.health_endpoint}`), check deployment logs. On failure: report and offer rollback (do NOT auto-rollback).

### Stage 4: Completion

Update deployment metadata with final status (verified/failed). Present summary with environment, SHA, branch, status, timestamp.

## Rollback Flow (`--rollback`)

1. Read previous deployment from `.claude/deployments/latest.json`
2. Confirm with user via `AskUserQuestion` (MANDATORY)
3. Execute `${profile.tools.deploy.rollback_command}`
4. Run smoke tests to verify rollback
5. Report result

## Error Handling

| Scenario | Action |
|----------|--------|
| Preflight fails | Report which check failed, suggest remediation |
| Build fails | Report error, do not proceed to deploy |
| Deploy fails | Save failed status, do not auto-retry |
| Smoke tests fail | Offer rollback, do NOT auto-rollback |
| Rollback fails | Flag critical, require manual intervention |

## Scope Limits

- One environment per deploy invocation
- One application/service per deploy
- Rollback only to immediately previous deployment
- Escalate if: credentials missing, infrastructure state unknown, repeated failures
