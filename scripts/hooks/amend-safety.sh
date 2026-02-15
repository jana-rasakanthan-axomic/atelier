#!/usr/bin/env bash
# Hook: PreToolUse (Bash)
# Purpose: Detect git commit --amend and warn or block.
#   - Block amend if the commit has already been pushed (exit 2).
#   - Allow amend for local-only commits with info message (exit 0).

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

[[ -z "$COMMAND" ]] && exit 0

# Only check git commit commands with --amend
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

if ! echo "$COMMAND" | grep -qE '\-\-amend'; then
  exit 0
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
HEAD_INFO=$(git log -1 --oneline HEAD 2>/dev/null || echo "unknown")

# Check if HEAD has been pushed by comparing with remote
LOCAL_HEAD=$(git rev-parse HEAD 2>/dev/null || echo "local")
REMOTE_HEAD=$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo "none")

if [[ "$LOCAL_HEAD" == "$REMOTE_HEAD" ]]; then
  echo "AMEND SAFETY: The commit to be amended has already been pushed."
  echo ""
  echo "Commit: $HEAD_INFO"
  echo "Branch: $BRANCH"
  echo ""
  echo "Amending a pushed commit requires a force push. Create a new commit instead:"
  echo "  git commit -m \"fix: ...\""
  exit 2
fi

# HEAD hasn't been pushed or no remote tracking -- allow with info
echo "AMEND INFO: Amending local commit: $HEAD_INFO"
exit 0
