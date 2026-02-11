#!/usr/bin/env bash
# Hook: PostToolUse (Bash)
# Purpose: Remind to run full regression suite after targeted test runs.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

[[ -z "$COMMAND" ]] && exit 0

# Detect targeted test runs (file-specific, not full suite)
if echo "$COMMAND" | grep -qE '(pytest|jest|flutter test|dart test|vitest|mocha)\s+\S+'; then
  # Check if it looks like a targeted run (has a specific path argument)
  if echo "$COMMAND" | grep -qE '\.(py|ts|js|dart|tsx|jsx)\b|tests/|test/|spec/'; then
    echo ""
    echo "REMINDER: You ran targeted tests. Before marking the feature complete,"
    echo "run the full regression suite to catch cross-cutting breakage:"
    echo "  make test  (or the full test runner command from your profile)"
  fi
fi

exit 0
