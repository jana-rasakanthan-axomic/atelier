#!/usr/bin/env bash
# Hook: PreToolUse (Bash)
# Purpose: Warn when staged changes are too large for a single commit.
# Thresholds: 30 files or 500 lines changed.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

[[ -z "$COMMAND" ]] && exit 0

# Only check git commit commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

# Count staged files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

# If nothing staged, nothing to warn about
if [[ "$STAGED_FILES" -eq 0 ]]; then
  exit 0
fi

# Count staged lines changed (insertions + deletions)
STAT_LINE=$(git diff --cached --stat 2>/dev/null | tail -1)
INSERTIONS=$(echo "$STAT_LINE" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
DELETIONS=$(echo "$STAT_LINE" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo "0")
TOTAL_LINES=$(( INSERTIONS + DELETIONS ))

# Thresholds
MAX_FILES=30
MAX_LINES=500

if [[ "$TOTAL_LINES" -gt "$MAX_LINES" ]] || [[ "$STAGED_FILES" -gt "$MAX_FILES" ]]; then
  echo "COMMIT SIZE WARNING: Large commit detected."
  echo ""
  echo "Staged: ${STAGED_FILES} files, ${TOTAL_LINES} lines changed"
  echo "Thresholds: ${MAX_FILES} files, ${MAX_LINES} lines"
  echo ""
  echo "Consider splitting into smaller, focused commits."
fi

exit 0
