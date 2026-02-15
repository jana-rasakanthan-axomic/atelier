#!/usr/bin/env bash
# Hook: PostToolUse (Write, Edit)
# Purpose: Auto-lint files after Write/Edit tool calls using the active profile's linter.
# This is informational only — lint failures produce warnings but never block.

set -euo pipefail

# Read tool input from stdin (JSON with file_path)
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // empty' 2>/dev/null)

[[ -z "$FILE_PATH" ]] && exit 0

# --- Skip: file no longer exists (deleted) ---
[[ ! -f "$FILE_PATH" ]] && exit 0

# --- Skip: bypass flag ---
if [[ -f ".claude/skip-lint" ]]; then
  exit 0
fi

# --- Skip: non-lintable files ---
# Only lint known source code extensions
EXT="${FILE_PATH##*.}"

case "$EXT" in
  py|ts|tsx|js|jsx|dart|go|java|kt|rs|rb|swift|c|cpp|h|hpp|cs|tf|hcl|css|scss)
    # Lintable source file — continue
    ;;
  *)
    # Not lintable (md, json, yaml, toml, svg, png, lock, sh, etc.)
    exit 0
    ;;
esac

# --- Resolve active profile ---
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [[ -z "$PLUGIN_ROOT" ]]; then
  # Fallback: derive from this script's location (scripts/hooks/ -> root)
  PLUGIN_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fi

RESOLVE_SCRIPT="$PLUGIN_ROOT/scripts/resolve-profile.sh"
if [[ ! -x "$RESOLVE_SCRIPT" ]]; then
  exit 0
fi

PROFILE=$("$RESOLVE_SCRIPT" 2>/dev/null) || exit 0
[[ -z "$PROFILE" ]] && exit 0

# --- Read linter command from profile ---
PROFILE_FILE="$PLUGIN_ROOT/profiles/${PROFILE}.md"
if [[ ! -f "$PROFILE_FILE" ]]; then
  exit 0
fi

# Extract the linter command from the profile's Quality Tools YAML block.
# Profile format has a `linter:` key followed by `command: "..."` on the next line.
LINTER_CMD=$(awk '/^  linter:/{found=1; next} found && /command:/{gsub(/.*command:[[:space:]]*"?/,""); gsub(/".*$/,""); print; exit}' "$PROFILE_FILE")

if [[ -z "$LINTER_CMD" ]]; then
  exit 0
fi

# --- Build single-file lint command ---
# Linter commands from profiles target directories (e.g., "ruff check src/", "npx eslint src/").
# Replace the directory target with the specific file path for per-file linting.
# Some linters have no directory argument (e.g., "dart analyze", "tflint") — append the file.

# Known linter-to-single-file mapping:
# - "ruff check src/"       -> "ruff check <file>"
# - "npx eslint src/"       -> "npx eslint <file>"
# - "dart analyze"          -> "dart analyze <file>"
# - "tflint"                -> "tflint <file>"  (tflint doesn't support single-file; skip)

# tflint does not support single-file linting — skip
if echo "$LINTER_CMD" | grep -q "tflint"; then
  exit 0
fi

# Strip trailing directory arguments (e.g., "src/", "lib/", ".") to get the base command,
# then append the specific file path.
LINT_BASE=$(echo "$LINTER_CMD" | sed -E 's|[[:space:]]+[a-zA-Z_./ ]*/$||')
LINT_SINGLE="$LINT_BASE $FILE_PATH"

# --- Run linter on the file ---
LINT_OUTPUT=$($LINT_SINGLE 2>&1) || {
  echo "" >&2
  echo "LINT WARNING: Issues found in $FILE_PATH" >&2
  echo "Command: $LINT_SINGLE" >&2
  echo "" >&2
  echo "$LINT_OUTPUT" >&2
  echo "" >&2
  echo "Fix lint issues before proceeding, or bypass with: touch .claude/skip-lint" >&2
}

# PostToolUse hooks must always exit 0 (informational only, never blocking)
exit 0
