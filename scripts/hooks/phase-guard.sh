#!/usr/bin/env bash
# Hook: PreToolUse (Write, Edit)
# Purpose: Block implementation file writes during read-only phases.
# Reads .atelier/state.json to determine the active phase and prevents
# source code modifications during gather, specify, design, plan, and review.
#
# Design: Only blocks known source code extensions in read-only phases.
# Test files, toolkit files, and non-code files always pass through.

set -euo pipefail

# Read tool input from stdin (JSON with file_path)
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // empty' 2>/dev/null)

[[ -z "$FILE_PATH" ]] && exit 0

# --- Skip: bypass flag ---
if [[ -f ".claude/skip-phase-guard" ]]; then
  exit 0
fi

# --- Skip: no state file means no enforcement ---
if [[ ! -f ".atelier/state.json" ]]; then
  exit 0
fi

# --- Read current phase ---
PHASE=$(jq -r '.phase // empty' .atelier/state.json 2>/dev/null)

[[ -z "$PHASE" ]] && exit 0

# --- Skip: non-read-only phases (build, deploy, etc.) ---
case "$PHASE" in
  gather|specify|design|plan|review)
    # Read-only phase — enforce below
    ;;
  *)
    # Active phase (build, deploy, fix, etc.) — allow writes
    exit 0
    ;;
esac

# --- Skip: test files (always allowed) ---
if [[ "$FILE_PATH" == *test_* ]] || [[ "$FILE_PATH" == *_test.* ]] || \
   [[ "$FILE_PATH" == *.test.* ]] || [[ "$FILE_PATH" == *.spec.* ]] || \
   [[ "$FILE_PATH" == */tests/* ]] || [[ "$FILE_PATH" == */test/* ]]; then
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

# --- Check: is this an implementation file? ---
EXT="${FILE_PATH##*.}"

case "$EXT" in
  py|ts|tsx|js|jsx|dart|go|java|kt|rs|rb|swift|c|cpp|h|hpp|cs|tf|hcl)
    # Source code in a read-only phase — block
    ;;
  *)
    # Not source code (md, yaml, json, toml, svg, sh, css, html, lock, etc.)
    exit 0
    ;;
esac

# --- Block: implementation write during read-only phase ---
echo "PHASE GUARD: Cannot write implementation files during '${PHASE}' phase."
echo ""
echo "File: $FILE_PATH"
echo "Current phase: $PHASE"
echo ""
echo "Use /build to enter the build phase, or:"
echo "  touch .claude/skip-phase-guard"
exit 2
