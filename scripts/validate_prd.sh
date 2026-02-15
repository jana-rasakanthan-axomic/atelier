#!/usr/bin/env bash
# validate_prd.sh — Validate a PRD file for required sections and ambiguous language
#
# Usage:
#   validate_prd.sh <path-to-prd.md>
#
# Checks:
#   1. Required sections (Problem Statement, Target Users/Personas, User Stories,
#      Feature Requirements/Requirements, Out of Scope)
#   2. Ambiguous language (should, might, easy, simple, obvious, just, etc, TBD)
#   3. Placeholder markers ([?], TODO, FIXME, XXX)
#
# Exit codes:
#   0 = pass (no errors or warnings)
#   1 = warnings only
#   2 = errors found

set -euo pipefail

# ─── Input validation ───────────────────────────────────────────────────────

if [[ $# -ne 1 ]]; then
  echo "Usage: validate_prd.sh <path-to-prd.md>"
  exit 2
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
  echo "Error: File not found: $FILE"
  exit 2
fi

# ─── Counters ────────────────────────────────────────────────────────────────

ERRORS=0
WARNINGS=0

# ─── Output helpers ──────────────────────────────────────────────────────────

ERRORS_OUTPUT=""
WARNINGS_OUTPUT=""

emit_error() {
  ERRORS_OUTPUT+="  ✗ $1"$'\n'
  ERRORS=$((ERRORS + 1))
}

emit_warning() {
  WARNINGS_OUTPUT+="  ⚠ $1"$'\n'
  WARNINGS=$((WARNINGS + 1))
}

# ─── 1. Required sections ────────────────────────────────────────────────────

check_section() {
  local label="$1"
  shift
  local found=false
  for pattern in "$@"; do
    if grep -qiE "^#{1,6}[[:space:]]+${pattern}" "$FILE"; then
      found=true
      break
    fi
  done
  if [[ "$found" == false ]]; then
    emit_error "Missing section: \"${label}\""
  fi
}

check_section "Problem Statement"              "problem[[:space:]]+statement"
check_section "Target Users / Personas"        "target[[:space:]]+users" "personas"
check_section "User Stories"                   "user[[:space:]]+stories"
check_section "Feature Requirements"           "feature[[:space:]]+requirements" "requirements"
check_section "Out of Scope"                   "out[[:space:]]+of[[:space:]]+scope"

# ─── 2. Ambiguous language detection ─────────────────────────────────────────

# Each pattern is: <grep-regex>|<label>
AMBIGUOUS_PATTERNS=(
  '\bshould\b|Ambiguous language: "should"'
  '\bmight\b|Ambiguous language: "might"'
  '\beasy\b|\beasily\b|Ambiguous language: "easy/easily"'
  '\bsimple\b|\bsimply\b|Ambiguous language: "simple/simply"'
  '\bobvious\b|\bobviously\b|Ambiguous language: "obvious/obviously"'
  '\bjust\b|Ambiguous language: "just"'
  '\betc\b|\band so on\b|Ambiguous language: "etc/and so on"'
  '\bTBD\b|\bTBA\b|Ambiguous language: "TBD/TBA"'
)

for entry in "${AMBIGUOUS_PATTERNS[@]}"; do
  label="${entry##*|}"
  pattern="${entry%|*}"

  while IFS=: read -r lineno content; do
    [[ -z "$lineno" ]] && continue
    # Skip "should" inside MoSCoW priority labels (e.g., "Should Have")
    if [[ "$label" == 'Ambiguous language: "should"' ]]; then
      if echo "$content" | grep -qiE '\bshould[[:space:]]+have\b'; then
        continue
      fi
    fi
    trimmed="$(echo "$content" | sed 's/^[[:space:]]*//' | cut -c1-80)"
    emit_warning "Line ${lineno}: ${label} — \"${trimmed}\""
  done < <(grep -niE "$pattern" "$FILE" 2>/dev/null || true)
done

# ─── 3. Placeholder detection ────────────────────────────────────────────────

while IFS=: read -r lineno content; do
  [[ -z "$lineno" ]] && continue
  trimmed="$(echo "$content" | sed 's/^[[:space:]]*//' | cut -c1-80)"
  emit_warning "Line ${lineno}: Placeholder — \"${trimmed}\""
done < <(grep -nE '\[\?\]|\bTODO\b|\bFIXME\b|\bXXX\b' "$FILE" 2>/dev/null || true)

# ─── Report ──────────────────────────────────────────────────────────────────

echo "PRD Validation: ${FILE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $ERRORS -gt 0 ]]; then
  echo "ERRORS:"
  printf '%s' "$ERRORS_OUTPUT"
  echo ""
fi

if [[ $WARNINGS -gt 0 ]]; then
  echo "WARNINGS:"
  printf '%s' "$WARNINGS_OUTPUT"
  echo ""
fi

echo "SUMMARY: ${ERRORS} error(s), ${WARNINGS} warning(s)"

# ─── Exit code ───────────────────────────────────────────────────────────────

if [[ $ERRORS -gt 0 ]]; then
  exit 2
elif [[ $WARNINGS -gt 0 ]]; then
  exit 1
else
  exit 0
fi
