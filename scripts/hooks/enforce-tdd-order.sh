#!/usr/bin/env bash
# Hook: PreToolUse (Write, Edit)
# Purpose: Enforce TDD — test files must be modified before implementation files.
# Blocks writes to implementation files if no corresponding test file was modified first.
#
# Design: ALLOWLIST approach — only enforce for known source code extensions.
# Everything else (docs, configs, SVGs, templates, scripts) passes through freely.

set -euo pipefail

# Read tool input from stdin (JSON with file_path)
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // empty' 2>/dev/null)

[[ -z "$FILE_PATH" ]] && exit 0

# --- Skip: bypass flag ---
if [[ -f ".claude/skip-tdd" ]]; then
  exit 0
fi

# --- Skip: test files (always allowed) ---
if [[ "$FILE_PATH" == *test_* ]] || [[ "$FILE_PATH" == *_test.* ]] || \
   [[ "$FILE_PATH" == */tests/* ]] || [[ "$FILE_PATH" == */test/* ]] || \
   [[ "$FILE_PATH" == *.test.* ]] || [[ "$FILE_PATH" == *.spec.* ]]; then
  exit 0
fi

# --- Skip: toolkit authoring (commands, skills, agents, templates, profiles, docs, scripts) ---
if [[ "$FILE_PATH" == */commands/* ]] || [[ "$FILE_PATH" == */skills/* ]] || \
   [[ "$FILE_PATH" == */agents/* ]] || [[ "$FILE_PATH" == */templates/* ]] || \
   [[ "$FILE_PATH" == */profiles/* ]] || [[ "$FILE_PATH" == */docs/* ]] || \
   [[ "$FILE_PATH" == */scripts/* ]] || [[ "$FILE_PATH" == */.claude/* ]] || \
   [[ "$FILE_PATH" == */.atelier/* ]]; then
  exit 0
fi

# --- ALLOWLIST: only enforce TDD for actual source code ---
# Extract file extension
EXT="${FILE_PATH##*.}"

case "$EXT" in
  py|ts|tsx|js|jsx|dart|go|java|kt|kts|rs|rb|swift|c|cpp|h|hpp|cs|tf|hcl)
    # This is source code — enforce TDD below
    ;;
  *)
    # Not source code (md, yaml, json, toml, svg, png, sh, css, html, lock, etc.)
    exit 0
    ;;
esac

# --- Enforce: check if test files were modified first ---
TEST_FILES_MODIFIED=$(git diff --name-only HEAD 2>/dev/null | grep -E '(test_|_test\.|\.test\.|\.spec\.|/tests/|/test/)' || true)

if [[ -z "$TEST_FILES_MODIFIED" ]]; then
  echo "TDD VIOLATION: Writing implementation before tests."
  echo ""
  echo "File: $FILE_PATH"
  echo ""
  echo "Write the corresponding test file first, run it to confirm RED,"
  echo "then implement. See CLAUDE.md TDD State Machine."
  echo ""
  echo "To skip (non-code work): touch .claude/skip-tdd"
  exit 2
fi

exit 0
