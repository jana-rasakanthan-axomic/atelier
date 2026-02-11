#!/usr/bin/env bash
# Hook: PreToolUse (Write, Edit)
# Purpose: Enforce TDD — test files must be modified before implementation files.
# Blocks writes to implementation files if no corresponding test file was modified first.

set -euo pipefail

# Read tool input from stdin (JSON with file_path)
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // empty' 2>/dev/null)

[[ -z "$FILE_PATH" ]] && exit 0

# Skip if this IS a test file
if [[ "$FILE_PATH" == *test_* ]] || [[ "$FILE_PATH" == *_test.* ]] || \
   [[ "$FILE_PATH" == */tests/* ]] || [[ "$FILE_PATH" == */test/* ]] || \
   [[ "$FILE_PATH" == *.test.* ]] || [[ "$FILE_PATH" == *.spec.* ]]; then
  exit 0
fi

# Skip non-source files (configs, docs, templates, etc.)
if [[ "$FILE_PATH" == *.md ]] || [[ "$FILE_PATH" == *.yaml ]] || \
   [[ "$FILE_PATH" == *.yml ]] || [[ "$FILE_PATH" == *.json ]] || \
   [[ "$FILE_PATH" == *.toml ]] || [[ "$FILE_PATH" == *.cfg ]] || \
   [[ "$FILE_PATH" == *.txt ]] || [[ "$FILE_PATH" == *.sh ]] || \
   [[ "$FILE_PATH" == *Makefile* ]] || [[ "$FILE_PATH" == *.lock ]]; then
  exit 0
fi

# Skip if --skip-tests mode is active
if [[ -f ".claude/skip-tdd" ]]; then
  exit 0
fi

# Check if any test file has been modified in the current git session
TEST_FILES_MODIFIED=$(git diff --name-only HEAD 2>/dev/null | grep -E '(test_|_test\.|\.test\.|\.spec\.|/tests/|/test/)' || true)

if [[ -z "$TEST_FILES_MODIFIED" ]]; then
  echo "TDD VIOLATION: Writing implementation before tests."
  echo ""
  echo "File: $FILE_PATH"
  echo ""
  echo "Write the corresponding test file first, run it to confirm RED,"
  echo "then implement. See CLAUDE.md TDD State Machine."
  echo ""
  echo "To skip (prototyping only): touch .claude/skip-tdd"
  exit 2
fi

exit 0
