#!/usr/bin/env bash
# validate_design.sh — Validate a design ticket for required elements
#
# Usage:
#   validate_design.sh <path-to-design-ticket.md>
#
# Checks:
#   1. Required sections (Acceptance Criteria/AC, Implementation/Technical Design,
#      API Contract/Interface/Schema)
#   2. Target files listed (file paths or extensions)
#   3. Effort estimates present
#   4. Dependencies listed (info only)
#
# Exit codes:
#   0 = pass (no errors or warnings)
#   1 = warnings only
#   2 = errors found

set -euo pipefail

# ─── Input validation ───────────────────────────────────────────────────────

if [[ $# -ne 1 ]]; then
  echo "Usage: validate_design.sh <path-to-design-ticket.md>"
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
INFOS=0

# ─── Output helpers ──────────────────────────────────────────────────────────

ERRORS_OUTPUT=""
WARNINGS_OUTPUT=""
INFOS_OUTPUT=""

emit_error() {
  ERRORS_OUTPUT+="  ✗ $1"$'\n'
  ERRORS=$((ERRORS + 1))
}

emit_warning() {
  WARNINGS_OUTPUT+="  ⚠ $1"$'\n'
  WARNINGS=$((WARNINGS + 1))
}

emit_info() {
  INFOS_OUTPUT+="  ℹ $1"$'\n'
  INFOS=$((INFOS + 1))
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

check_section "Acceptance Criteria"            "acceptance[[:space:]]+criteria" "\bAC\b"
check_section "Implementation / Technical Design" "implementation" "technical[[:space:]]+design"
check_section "API Contract / Interface / Schema" "api[[:space:]]+contract" "interface" "schema"

# ─── 2. Target files listed ──────────────────────────────────────────────────

if ! grep -qE '(src/|lib/|app/|test/|tests/|\.[a-z]{1,4}[[:space:]"'\''`),]|\.[a-z]{1,4}$)' "$FILE" 2>/dev/null; then
  emit_warning "No target files identified"
fi

# ─── 3. Estimates present ────────────────────────────────────────────────────

if ! grep -qiE '\bhours?\b|\bpoints?\b|\bestimate\b|\b[SMXL]{1,2}\b|\bsmall\b|\bmedium\b|\blarge\b|\bx-?large\b' "$FILE" 2>/dev/null; then
  emit_warning "No effort estimate found"
fi

# ─── 4. Dependencies listed ──────────────────────────────────────────────────

if ! grep -qiE '\bdepends[[:space:]]+on\b|\bdependenc(y|ies)\b|\bprerequisite\b|\bblocked[[:space:]]+by\b' "$FILE" 2>/dev/null; then
  emit_info "No dependencies listed"
fi

# ─── Report ──────────────────────────────────────────────────────────────────

echo "Design Ticket Validation: ${FILE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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

if [[ $INFOS -gt 0 ]]; then
  echo "INFO:"
  printf '%s' "$INFOS_OUTPUT"
  echo ""
fi

echo "SUMMARY: ${ERRORS} error(s), ${WARNINGS} warning(s), ${INFOS} info(s)"

# ─── Exit code ───────────────────────────────────────────────────────────────

if [[ $ERRORS -gt 0 ]]; then
  exit 2
elif [[ $WARNINGS -gt 0 ]]; then
  exit 1
else
  exit 0
fi
