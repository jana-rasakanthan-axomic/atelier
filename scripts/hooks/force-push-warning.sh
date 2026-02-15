#!/usr/bin/env bash
# Hook: PreToolUse (Bash)
# Purpose: Detect force push commands and warn or block.
#   - Block force push to main/master (exit 2).
#   - Warn on force push to other branches (exit 0 with message).

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

[[ -z "$COMMAND" ]] && exit 0

# Only check git push commands
if ! echo "$COMMAND" | grep -qE 'git\s+push'; then
  exit 0
fi

# Only check if force flags are present
if ! echo "$COMMAND" | grep -qE '(--force|--force-with-lease|\s-f\b)'; then
  exit 0
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Block force push to main/master
if [[ "$BRANCH" == "main" ]] || [[ "$BRANCH" == "master" ]]; then
  echo "FORCE PUSH BLOCKED: Cannot force-push to '$BRANCH'."
  echo ""
  echo "Force-pushing to main/master can destroy shared history."
  exit 2
fi

# Check if the origin branch exists and how HEAD relates to it
LOCAL_ONLY=$(git log "origin/$BRANCH..HEAD" --oneline 2>/dev/null) || {
  # No upstream branch exists -- warn but allow
  echo "FORCE PUSH WARNING: No upstream branch 'origin/$BRANCH' found."
  echo ""
  echo "This appears to be a local-only branch. Force push will set the remote."
  exit 0
}

# Count local-only commits
if [[ -n "$LOCAL_ONLY" ]]; then
  N=$(echo "$LOCAL_ONLY" | wc -l | tr -d ' ')
  echo "FORCE PUSH WARNING: You are force-pushing to '$BRANCH'."
  echo ""
  echo "This will rewrite $N commit(s) on the remote."
  echo "Make sure no one else is working on this branch."
  exit 0
fi

# HEAD matches origin -- force push is unnecessary
echo "FORCE PUSH WARNING: HEAD matches origin/$BRANCH."
echo ""
echo "Force push is unnecessary -- consider regular push instead."
exit 0
