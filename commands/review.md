---
name: review
description: Review pull request with multiple perspectives
model_hint: opus
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(${profile.tools.test_runner.command}:*), Bash(gh api:*), Bash(gh pr view:*), Bash(gh repo view:*), Bash(gh pr create:*)
---

# /review

Review pull request with multiple perspectives.

## Input Formats

- `/review` - Review current branch against main
- `/review 123` - Review PR #123 from GitHub
- `/review --base develop` - Review against specific base branch
- `/review --security` - Security-focused review only
- `/review --quick` - Fast review (PR checklist only)
- `/review --personas all` - All personas (security, engineering, product)
- `/review --dry-run` - Preview scope without reviewing
- `/review .claude/context/PR-123.md` - Review with additional context
- `/review --push` - Review and post findings to GitHub PR
- `/review 123 --push` - Review PR #123 and post findings
- `/review --self` - One-shot self-review report (no fixes)
- `/review --self --loop` - Self-review-fix loop, create PR when clean
- `/review --self --loop --no-pr` - Self-review-fix loop without PR creation
- `/review --self --loop 123` - Self-review-fix loop on existing PR #123 (includes external comments)

## When to Use

- PR ready for review, pre-merge validation
- Security-sensitive changes, major feature implementations
- Pre-PR self-review to catch issues before creating a PR

## When NOT to Use

- Draft PR not ready -> finish implementation first
- Simple typo/doc fixes -> quick self-review sufficient
- Generating a PR -> use `/commit` then `gh pr create`

## Modes

### External Review (default)

Review others' code. All 5 stages below apply. Findings are reported or posted to GitHub (with `--push`).

### Self-Review One-Shot (`--self`)

Runs Stages 1-4 against the branch diff (`git diff $BASE_BRANCH...HEAD`). Produces a local report only. No fixes, no push, no GitHub interaction.

### Self-Review Loop (`--self --loop`)

Automated self-review-fix loop. This mode:

1. Resolves the active profile
2. Hydrates the `skills/iterative-dev/prompts/review-fix.md` prompt with:
   - `$SELF_REVIEW_MODE=true`
   - `$CREATE_PR_ON_COMPLETE=true` (unless `--no-pr` flag is set)
   - `$PR_NUMBER=<number>` (if a PR number is provided)
   - `$BASE_BRANCH` from git or `--base` flag
   - `$TOOLKIT_DIR` resolved to the toolkit installation path
3. Launches `/ralph-loop` with:
   - `--completion-promise "REVIEW COMPLETE"`
   - `--max-iterations 10`
4. The loop runs ASSESS -> DECIDE -> ACT -> VERIFY until clean, then COMPLETE

**Strict enforcement:** If ralph-loop is not available, STOP and report. Do NOT silently fall back to manual iteration.

**Permission manifest:** Self-Review pattern from `skills/iterative-dev/configs/permissions.md` (20 permissions).

## Context File Integration

If argument is a path to `.claude/context/*.md`, read context file for requirements/acceptance criteria and review the PR against documented requirements.

## Workflow (5 Stages)

### Stage 1: Scope

Collect changed files, diff stats, and commit list. Report file count, line changes, and which personas will be applied. If `--dry-run`, stop here.

**Source detection:**
- Default: `git diff` / `git log` against base branch, or fetch PR diff from GitHub
- `--self`: Always uses `git diff $BASE_BRANCH...HEAD` on the local branch

### Stage 2: Review

**Agent:** Reviewer

Auto-select personas based on changed file patterns:

| File Pattern | Personas |
|--------------|----------|
| `*auth*`, `*security*`, `*crypto*`, `*config*`, `*.env*` | Security |
| `*service*`, `*repository*`, `*test*` | Engineering |
| `*route*`, `*api*`, `*endpoint*` | Engineering + Product |
| All PRs | PR Checklist (always) |

For each persona, load the checklist from `skills/review/personas/{persona}.md`, read each changed file, apply persona-specific analysis, and record findings with severity.

### Stage 3: Synthesize

Consolidate findings from all personas. Deduplicate overlapping issues. Assign a unique key to each finding (`key = "{file_path}:{line_number}"`) for re-review matching. Determine verdict:

| Condition | Verdict |
|-----------|---------|
| Any Critical findings | BLOCK |
| Any High findings | REQUEST CHANGES |
| Only Medium/Low findings | APPROVE with comments |
| No findings | APPROVE |

### Stage 4: Report

Present findings grouped by severity (Critical, High, Medium, Low), each with file:line, issue description, suggested fix, and originating persona. Include PR checklist results and recommended next steps.

### Stage 5: Push (Conditional)

**Trigger:** `--push` flag present. Requires a GitHub PR number and authenticated `gh` CLI.

**Guard:** This stage is skipped entirely in `--self` mode. Self-review mode fixes findings directly instead of posting them as comments.

**Step 5.0: Duplicate check.** Use `scripts/check-existing-review.sh` to skip if same commit already reviewed.

**Step 5.1: Get PR metadata.** Fetch repo, commit SHA, PR author. Detect own-PR (forces COMMENT event).

**Step 5.2: Re-review detection.** Fetch previous review comments by this user. For each previous comment, check if its `file:line` key is still in current findings:
- Issue resolved -> reply "Resolved in commit `$SHA`" and resolve the thread
- Issue still present -> skip (do not duplicate)
- Filter new findings to only those not previously commented

If all previous issues resolved and no new issues found, post a "Ready for Approval" comment and exit.

**Step 5.3: Build inline comments.** For each new finding with a file:line reference, create a comment object with path, line, and formatted body.

**Step 5.4: Post review.** Use `gh api repos/$REPO/pulls/$PR_NUMBER/reviews` with inline comments array. Event type: `COMMENT` for own PR, `APPROVE` or `REQUEST_CHANGES` for others based on verdict.

**Step 5.5: Handle errors.** If line not in diff, include finding in review body instead. If own-PR gets 422 on APPROVE/REQUEST_CHANGES, fall back to COMMENT event.

## Error Handling

| Scenario | Action |
|----------|--------|
| Git commands fail | Report error, suggest `git fetch origin` |
| PR too large (>50 files or >2000 lines) | Warn about quality degradation, suggest splitting |
| No changes detected | Report branch matches base, suggest `--base` flag |
| GitHub PR not found | Report, suggest checking PR number and repo access |
| ralph-loop not available (`--self --loop`) | STOP and report, do not silently fall back |

## Agents Used

| Agent | Stage | Purpose |
|-------|-------|---------|
| Reviewer | 2-3 | Multi-persona review and synthesis |

## Skills Used

| Skill | Purpose |
|-------|---------|
| `skills/review/personas/security.md` | Security review perspective |
| `skills/review/personas/engineering.md` | Engineering review perspective (includes PR readiness) |
| `skills/review/personas/product.md` | Product review perspective |
| `skills/iterative-dev/prompts/review-fix.md` | Self-review-fix loop prompt (for `--self --loop`) |

## Output Verdicts

| Verdict | Meaning | Action |
|---------|---------|--------|
| APPROVE | Ready to merge | Merge when ready |
| REQUEST CHANGES | Issues found | Address findings before merge |
| BLOCK | Critical issues | Must not merge until resolved |

## Scope Limits

- Max files per review: 50
- Max lines per review: 2000
- For larger PRs: suggest splitting or use `--scope src/specific/`
