#!/usr/bin/env bash
# Hook: PreToolUse (Bash)
# Purpose: Block commits directly to main/master branches.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

[[ -z "$COMMAND" ]] && exit 0

# Only check git commit commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

if [[ "$BRANCH" == "main" ]] || [[ "$BRANCH" == "master" ]]; then
  echo "BRANCH PROTECTION: Cannot commit directly to '$BRANCH'."
  echo ""
  echo "Create a feature branch first:"
  echo "  git checkout -b feat/your-feature-name"
  exit 2
fi

exit 0
