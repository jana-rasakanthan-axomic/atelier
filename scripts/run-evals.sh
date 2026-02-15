#!/usr/bin/env bash
# run-evals.sh — Run evaluation definitions from evals/ and report results
#
# Reads JSON eval files from evals/, runs each command, and checks:
#   - Expected exit code matches actual
#   - Expected output substrings are present in stdout+stderr
#
# Usage:
#   scripts/run-evals.sh                    # Run all evals
#   scripts/run-evals.sh evals/foo.json     # Run a single eval
#   scripts/run-evals.sh --verbose          # Show command output on failure
#
# Exit codes:
#   0 = all evals pass
#   1 = one or more evals fail

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EVALS_DIR="$TOOLKIT_DIR/evals"

# Counters
TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0

# Options
VERBOSE=false
EVAL_FILES=()

# ─── Argument parsing ────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      echo "Usage: scripts/run-evals.sh [--verbose] [eval-file...]"
      echo ""
      echo "Run evaluation definitions from evals/ and report results."
      echo ""
      echo "Options:"
      echo "  --verbose, -v   Show command output on failure"
      echo "  -h, --help      Show this help"
      exit 0
      ;;
    *)
      EVAL_FILES+=("$1")
      shift
      ;;
  esac
done

# ─── Dependency check ────────────────────────────────────────────────────────

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed."
  exit 1
fi

# ─── Collect eval files ──────────────────────────────────────────────────────

if [[ ${#EVAL_FILES[@]} -eq 0 ]]; then
  while IFS= read -r f; do
    EVAL_FILES+=("$f")
  done < <(find "$EVALS_DIR" -maxdepth 1 -name '*.json' -type f 2>/dev/null | sort)
fi

if [[ ${#EVAL_FILES[@]} -eq 0 ]]; then
  echo "No eval files found in $EVALS_DIR"
  exit 0
fi

# ─── Run a single eval ───────────────────────────────────────────────────────

run_eval() {
  local eval_file="$1"
  local basename
  basename="$(basename "$eval_file")"

  # Validate JSON
  if ! jq empty "$eval_file" 2>/dev/null; then
    echo "[FAIL] ${basename} — Invalid JSON"
    FAILED=$((FAILED + 1))
    return
  fi

  local name command expected_exit
  name="$(jq -r '.name // "unnamed"' "$eval_file")"
  command="$(jq -r '.command // ""' "$eval_file")"
  expected_exit="$(jq -r '.expected_exit_code // 0' "$eval_file")"

  # Skip if command is empty
  if [[ -z "$command" ]]; then
    echo "[SKIP] ${name} — No command specified"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  # Run the command from toolkit root, capture output and exit code
  local output actual_exit
  output="$(cd "$TOOLKIT_DIR" && eval "$command" 2>&1)" && actual_exit=0 || actual_exit=$?

  local failed=false
  local failure_reasons=""

  # Check exit code
  if [[ "$actual_exit" -ne "$expected_exit" ]]; then
    failed=true
    failure_reasons+="    Exit code: expected ${expected_exit}, got ${actual_exit}"$'\n'
  fi

  # Check expected output substrings
  local patterns
  patterns="$(jq -r '.expected_output_contains // [] | .[]' "$eval_file" 2>/dev/null)"
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    if ! echo "$output" | grep -qF "$pattern"; then
      failed=true
      failure_reasons+="    Missing output: \"${pattern}\""$'\n'
    fi
  done <<< "$patterns"

  # Report result
  if [[ "$failed" == true ]]; then
    echo "[FAIL] ${name}"
    printf '%s' "$failure_reasons"
    if [[ "$VERBOSE" == true ]]; then
      echo "    --- command output ---"
      echo "$output" | sed 's/^/    /'
      echo "    --- end output ---"
    fi
    FAILED=$((FAILED + 1))
  else
    echo "[PASS] ${name}"
    PASSED=$((PASSED + 1))
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

echo "Atelier Eval Runner"
echo "==================="
echo ""

for eval_file in "${EVAL_FILES[@]}"; do
  # Resolve relative paths
  if [[ "$eval_file" != /* ]]; then
    eval_file="$TOOLKIT_DIR/$eval_file"
  fi

  if [[ ! -f "$eval_file" ]]; then
    echo "[SKIP] $(basename "$eval_file") — File not found"
    SKIPPED=$((SKIPPED + 1))
    TOTAL=$((TOTAL + 1))
    continue
  fi

  TOTAL=$((TOTAL + 1))
  run_eval "$eval_file"
done

# ─── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "─── Summary ────────────────────────────────────────"
echo "  Total:   ${TOTAL}"
echo "  Passed:  ${PASSED}"
echo "  Failed:  ${FAILED}"
echo "  Skipped: ${SKIPPED}"
echo "────────────────────────────────────────────────────"

if [[ $FAILED -gt 0 ]]; then
  exit 1
fi
exit 0
