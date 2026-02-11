---
name: review
description: Review pull request with multiple perspectives
allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(${profile.tools.test_runner.command}:*), Bash(gh api:*), Bash(gh pr view:*), Bash(gh repo view:*)
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

## When to Use

- PR ready for review, pre-merge validation
- Security-sensitive changes, major feature implementations

## When NOT to Use

- Draft PR not ready -> finish implementation first
- Simple typo/doc fixes -> quick self-review sufficient
- Generating a PR -> use `/commit` then `gh pr create`

## Context File Integration

If argument is a path to `.claude/context/*.md`, read context file for requirements/acceptance criteria and review the PR against documented requirements.

## Workflow (5 Stages)

### Stage 1: Scope

Collect changed files, diff stats, and commit list via `git diff` / `git log` against base branch. Report file count, line changes, and which personas will be applied. If `--dry-run`, stop here.

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

## Agents Used

| Agent | Stage | Purpose |
|-------|-------|---------|
| Reviewer | 2-3 | Multi-persona review and synthesis |

## Skills Used

| Skill | Purpose |
|-------|---------|
| `skills/review/personas/security.md` | Security review perspective |
| `skills/review/personas/engineering.md` | Engineering review perspective |
| `skills/review/personas/product.md` | Product review perspective |
| `skills/review/personas/pr.md` | PR checklist (always applied) |

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
