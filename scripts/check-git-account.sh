#!/usr/bin/env bash
# Git Account Mismatch Detection
# Validates that the local gh CLI account matches the repo's remote ownership,
# catching mismatches before push failures.
#
# Usage:
#   check-git-account.sh
#
# Exit codes:
#   0 - All checks pass
#   1 - Warnings (email mismatch)
#   2 - Errors (account mismatch or missing tools)

set -euo pipefail

# Track highest severity: 0=ok, 1=warning, 2=error
EXIT_CODE=0

# Helper: update exit code to the higher severity
raise_severity() {
  local level="$1"
  if [[ "$level" -gt "$EXIT_CODE" ]]; then
    EXIT_CODE="$level"
  fi
}

# Check required tools
for cmd in gh git; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "Error: $cmd not found. Install it first." >&2
    exit 2
  fi
done

# Check gh authentication
if ! gh auth status &> /dev/null; then
  echo "Error: gh CLI is not authenticated. Run 'gh auth login' first." >&2
  exit 2
fi

# Check we're inside a git repo
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
  echo "Error: Not inside a git repository." >&2
  exit 2
fi

echo "Git Account Check"
echo "-----------------"

# --- Step 1: Get current gh authenticated user ---
gh_user=$(gh api user --jq '.login' 2>/dev/null || echo "")
if [[ -z "$gh_user" ]]; then
  echo "x GitHub CLI: could not determine authenticated user"
  raise_severity 2
else
  echo "ok GitHub CLI: authenticated as $gh_user"
fi

# --- Step 2: Get remote URL and extract owner ---
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ -z "$remote_url" ]]; then
  echo "x Remote: no 'origin' remote configured"
  raise_severity 2
else
  # Extract owner from HTTPS or SSH URL formats
  # https://github.com/OWNER/repo.git -> OWNER
  # git@github.com:OWNER/repo.git -> OWNER
  if [[ "$remote_url" =~ github\.com[:/]([^/]+)/ ]]; then
    remote_owner="${BASH_REMATCH[1]}"
  else
    echo "x Remote: could not parse owner from URL: $remote_url"
    raise_severity 2
    remote_owner=""
  fi

  if [[ -n "$remote_owner" && -n "$gh_user" ]]; then
    if [[ "$remote_owner" == "$gh_user" ]]; then
      echo "ok Remote owner: $remote_owner (match)"
    else
      # Check if the user is a member of the org (owner might be an org)
      is_member=false
      if gh api "orgs/${remote_owner}/members/${gh_user}" &> /dev/null; then
        is_member=true
      fi

      if [[ "$is_member" == "true" ]]; then
        echo "ok Remote owner: $remote_owner (org member)"
      else
        echo "!! Account mismatch: gh user=$gh_user, remote owner=$remote_owner"
        echo "   You may not have push access. Check your gh account."
        raise_severity 2
      fi
    fi
  fi
fi

# --- Step 3: Compare git email with GitHub email ---
local_email=$(git config user.email 2>/dev/null || echo "")
gh_email=$(gh api user --jq '.email // empty' 2>/dev/null || echo "")

if [[ -z "$local_email" ]]; then
  echo "!! Git email: not configured locally (run 'git config user.email')"
  raise_severity 1
elif [[ -z "$gh_email" ]]; then
  echo "-- Git email: local=$local_email, GitHub=<private/not set>"
  echo "   Cannot verify (GitHub email may be set to private)."
elif [[ "$local_email" == "$gh_email" ]]; then
  echo "ok Git email: $local_email (match)"
else
  echo "!! Git email: local=$local_email, GitHub=$gh_email"
  raise_severity 1
fi

exit "$EXIT_CODE"
