#!/usr/bin/env bash
# Atelier Daily Brief Data Gatherer
# Collects structured data for /daily-brief to synthesize.
#
# Usage:
#   daily-brief-gather.sh github     # PRs awaiting review, authored PRs, failed CI
#   daily-brief-gather.sh worktrees  # Uncommitted work across git worktrees
#   daily-brief-gather.sh worklog    # "Next steps" from most recent worklog entry
#   daily-brief-gather.sh repos      # Recent merge activity in configured repos
#   daily-brief-gather.sh -h         # Show help
#
# Output format: Tab-separated values (TSV), one record per line.
# Each subcommand outputs a header comment, then data lines.
#
# Exit codes:
#   0 - Success (data found or gracefully empty)
#   1 - Error (missing tool, invalid arguments)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: daily-brief-gather.sh <subcommand>

Subcommands:
  github      PRs awaiting review, authored PRs, failed CI runs
  worktrees   Uncommitted changes across git worktrees
  worklog     "Next steps" from the most recent worklog entry
  repos       Recent merge activity in configured repos

Options:
  -h, --help  Show this help

Output: TSV format, parseable by /daily-brief command.
EOF
}

# --- Helpers ---

require_tool() {
  if ! command -v "$1" &>/dev/null; then
    echo "# ERROR: $1 not found. Install it or check your PATH." >&2
    exit 1
  fi
}

# --- Subcommands ---

gather_github() {
  require_tool gh

  # Check auth
  if ! gh auth status &>/dev/null 2>&1; then
    echo "# github: not authenticated (run 'gh auth login')"
    return 0
  fi

  echo "# github:review_requested"
  echo "# REPO	NUMBER	TITLE	UPDATED	URL"
  gh search prs --review-requested=@me --state=open --json repository,number,title,updatedAt,url \
    --jq '.[] | [.repository.nameWithOwner, (.number|tostring), .title, .updatedAt, .url] | @tsv' \
    2>/dev/null || true

  echo ""
  echo "# github:authored"
  echo "# REPO	NUMBER	TITLE	STATE	URL"
  gh search prs --author=@me --state=open --json repository,number,title,state,url \
    --jq '.[] | [.repository.nameWithOwner, (.number|tostring), .title, .state, .url] | @tsv' \
    2>/dev/null || true

  echo ""
  echo "# github:failed_ci"
  echo "# REPO	RUN_ID	NAME	BRANCH	URL"
  # Get failed runs from the current repo only (cross-repo requires explicit repos config)
  if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    gh run list --status=failure --limit=5 --json databaseId,name,headBranch,url \
      --jq '.[] | [(.databaseId|tostring), .name, .headBranch, .url] | @tsv' \
      2>/dev/null || true
  fi
}

gather_worktrees() {
  require_tool git

  if ! git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    echo "# worktrees: not in a git repository"
    return 0
  fi

  echo "# worktrees:uncommitted"
  echo "# PATH	BRANCH	MODIFIED	UNTRACKED"

  # List all worktrees and check for uncommitted changes
  while IFS= read -r worktree_line; do
    local wt_path
    wt_path=$(echo "$worktree_line" | awk '{print $1}')

    if [[ -z "$wt_path" || ! -d "$wt_path" ]]; then
      continue
    fi

    local branch modified untracked
    branch=$(git -C "$wt_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")
    modified=$(git -C "$wt_path" diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git -C "$wt_path" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$modified" -gt 0 || "$untracked" -gt 0 ]]; then
      printf '%s\t%s\t%s\t%s\n' "$wt_path" "$branch" "$modified" "$untracked"
    fi
  done < <(git worktree list --porcelain 2>/dev/null | grep "^worktree " | sed 's/^worktree //')
}

gather_worklog() {
  local worklog_path="${WORKLOG_PATH:-$HOME/.config/atelier/worklog.md}"

  if [[ ! -f "$worklog_path" ]]; then
    echo "# worklog: no worklog found at $worklog_path"
    return 0
  fi

  echo "# worklog:next_steps"

  # Extract the "Next steps" section from the most recent entry
  # The most recent entry is the first ## heading after the file header
  local in_next_steps=false
  local found_entry=false

  while IFS= read -r line; do
    # First ## heading = most recent entry
    if [[ "$line" =~ ^## && "$found_entry" == false ]]; then
      found_entry=true
      continue
    fi

    # Second ## heading = end of most recent entry
    if [[ "$line" =~ ^## && "$found_entry" == true ]]; then
      break
    fi

    # Detect "Next steps" section
    if [[ "$found_entry" == true && "$line" =~ ^\*\*Next\ steps:\*\* ]]; then
      in_next_steps=true
      continue
    fi

    # End of "Next steps" on empty line or new bold section
    if [[ "$in_next_steps" == true ]]; then
      if [[ -z "$line" || "$line" =~ ^\*\* ]]; then
        break
      fi
      # Output the line (strip leading "- ")
      echo "${line#- }"
    fi
  done < "$worklog_path"
}

gather_repos() {
  require_tool git

  if ! git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    echo "# repos: not in a git repository"
    return 0
  fi

  echo "# repos:recent_merges"
  echo "# HASH	DATE	AUTHOR	MESSAGE"

  # Show merges in the last 24 hours on the default branch
  local default_branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

  git log "origin/$default_branch" --merges --since="24 hours ago" \
    --format="%h	%ci	%an	%s" 2>/dev/null || true
}

# --- Main ---

cmd="${1:-}"

case "$cmd" in
  github)    gather_github ;;
  worktrees) gather_worktrees ;;
  worklog)   gather_worklog ;;
  repos)     gather_repos ;;
  -h|--help) usage; exit 0 ;;
  *)
    echo "Error: Unknown subcommand: ${cmd:-<none>}" >&2
    usage >&2
    exit 1
    ;;
esac
