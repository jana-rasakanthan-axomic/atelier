#!/usr/bin/env bash
# Hook: PreToolUse (Write, Edit)
# Purpose: Dispatch to profile-specific hooks based on the active profile.
# Resolves the profile, then runs all hooks in profiles/hooks/<profile>/.
# If any profile hook blocks (exit 2), this hook also blocks.
# If no profile or no profile hooks directory, exits 0 silently.

set -euo pipefail

# Read tool input from stdin (JSON with file_path and content)
INPUT=$(cat)

# --- Resolve plugin root ---
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [[ -z "$PLUGIN_ROOT" ]]; then
  PLUGIN_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fi

# --- Resolve active profile ---
RESOLVE_SCRIPT="$PLUGIN_ROOT/scripts/resolve-profile.sh"
if [[ ! -x "$RESOLVE_SCRIPT" ]]; then
  exit 0
fi

PROFILE=$("$RESOLVE_SCRIPT" 2>/dev/null) || exit 0
[[ -z "$PROFILE" ]] && exit 0

# --- Find profile hooks directory ---
HOOKS_DIR="$PLUGIN_ROOT/profiles/hooks/$PROFILE"
if [[ ! -d "$HOOKS_DIR" ]]; then
  exit 0
fi

# --- Run each hook in the profile hooks directory ---
BLOCKED=false
BLOCK_OUTPUT=""

for hook in "$HOOKS_DIR"/*.sh; do
  [[ -f "$hook" ]] || continue
  [[ -x "$hook" ]] || continue

  # Pass the original input to each profile hook via stdin
  HOOK_OUTPUT=$(echo "$INPUT" | "$hook" 2>&1) || {
    EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 2 ]]; then
      BLOCKED=true
      BLOCK_OUTPUT="$HOOK_OUTPUT"
    fi
  }
done

if [[ "$BLOCKED" == true ]]; then
  echo "$BLOCK_OUTPUT"
  exit 2
fi

exit 0
