#!/usr/bin/env bash
# Atelier Bootstrap Check
# Verifies that required tools are installed before starting a session.
# Checks core dependencies, then profile-specific tools and runtimes.
#
# Usage:
#   bootstrap.sh                           # Auto-detect profile, check current dir
#   bootstrap.sh --profile python-fastapi  # Check for a specific profile
#   bootstrap.sh --dir /path/to/project    # Check a specific project directory
#
# Exit codes:
#   0 - All required tools found
#   1 - Optional tool(s) missing (warnings only)
#   2 - Required tool(s) missing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Defaults
PROFILE=""
PROJECT_DIR="."

# Counters
MISSING_REQUIRED=0
MISSING_OPTIONAL=0

# --- Argument parsing ---

while [[ $# -gt 0 ]]; do
  case $1 in
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --dir)
      PROJECT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: bootstrap.sh [--profile PROFILE] [--dir PATH]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: bootstrap.sh [--profile PROFILE] [--dir PATH]" >&2
      exit 2
      ;;
  esac
done

# --- Output helpers ---

tool_ok() {
  local name="$1" version="$2"
  echo "  ✓ ${name} ${version}"
}

tool_warn() {
  local name="$1" detail="$2"
  echo "  ⚠ ${name} ${detail}"
  MISSING_OPTIONAL=$((MISSING_OPTIONAL + 1))
}

tool_fail() {
  local name="$1" detail="$2"
  echo "  ✗ ${name} ${detail}"
  MISSING_REQUIRED=$((MISSING_REQUIRED + 1))
}

# --- Version extraction helpers ---

version_of() {
  "$@" 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+[.0-9]*' | head -1
}

version_gte() {
  local actual="$1" required="$2"
  printf '%s\n%s' "$required" "$actual" | sort -V | head -1 | grep -qx "$required"
}

# --- Core dependency checks ---

check_core() {
  echo "Core tools:"

  # git (required)
  if command -v git &>/dev/null; then
    tool_ok "git" "$(version_of git --version)"
  else
    tool_fail "git" "— not found"
  fi

  # jq (required)
  if command -v jq &>/dev/null; then
    tool_ok "jq" "$(version_of jq --version)"
  else
    tool_fail "jq" "— not found"
  fi

  # gh (optional — needed for PR workflows)
  if command -v gh &>/dev/null; then
    tool_ok "gh" "$(version_of gh --version)"
  else
    tool_warn "gh" "not found (optional — needed for PR workflows)"
  fi
}

# --- Profile tool checks ---

check_profile_tool() {
  local label="$1" binary="$2"
  if command -v "$binary" &>/dev/null; then
    tool_ok "$binary" "($label)"
  else
    tool_fail "$binary" "($label) — not found"
  fi
}

check_profile_tools() {
  local profile_file="$TOOLKIT_DIR/profiles/${PROFILE}.md"

  if [[ ! -f "$profile_file" ]]; then
    echo "  ⚠ Profile file not found: profiles/${PROFILE}.md"
    MISSING_OPTIONAL=$((MISSING_OPTIONAL + 1))
    return
  fi

  echo ""
  echo "Profile tools:"

  # Extract tool commands from the profile's Quality Tools yaml block.
  # Lines like:  command: "pytest"  or  command: "ruff check src/"
  local commands
  commands=$(grep -E '^\s+command:\s*"' "$profile_file" \
    | sed 's/.*command:\s*"\([^"]*\)".*/\1/' \
    | grep -v '^$' \
    | sort -u || true)

  while IFS= read -r cmd_line; do
    [[ -z "$cmd_line" ]] && continue
    # Extract the binary name (first word, strip leading npx/uv run)
    local binary
    binary=$(echo "$cmd_line" | awk '{print $1}')
    # Skip npx-wrapped commands — check the underlying tool via npx
    if [[ "$binary" == "npx" ]]; then
      binary=$(echo "$cmd_line" | awk '{print $2}')
    fi
    check_profile_tool "$cmd_line" "$binary"
  done <<< "$commands"
}

# --- Runtime checks ---

check_runtime() {
  echo ""
  echo "Runtime:"

  case "$PROFILE" in
    python-fastapi)
      if command -v python3 &>/dev/null; then
        local pyver
        pyver=$(version_of python3 --version)
        if version_gte "$pyver" "3.10"; then
          tool_ok "python3" "$pyver (>= 3.10)"
        else
          tool_fail "python3" "$pyver — requires >= 3.10"
        fi
      else
        tool_fail "python3" "— not found (requires >= 3.10)"
      fi
      ;;
    flutter-dart)
      if command -v flutter &>/dev/null; then
        tool_ok "flutter" "$(version_of flutter --version)"
      else
        tool_fail "flutter" "— not found"
      fi
      if command -v dart &>/dev/null; then
        tool_ok "dart" "$(version_of dart --version)"
      else
        tool_fail "dart" "— not found"
      fi
      ;;
    react-typescript)
      if command -v node &>/dev/null; then
        local nodever
        nodever=$(version_of node --version)
        if version_gte "$nodever" "18.0"; then
          tool_ok "node" "$nodever (>= 18)"
        else
          tool_fail "node" "$nodever — requires >= 18"
        fi
      else
        tool_fail "node" "— not found (requires >= 18)"
      fi
      if command -v npm &>/dev/null; then
        tool_ok "npm" "$(version_of npm --version)"
      else
        tool_fail "npm" "— not found"
      fi
      ;;
    opentofu-hcl)
      if command -v tofu &>/dev/null; then
        tool_ok "tofu" "$(version_of tofu --version)"
      elif command -v terraform &>/dev/null; then
        tool_ok "terraform" "$(version_of terraform --version) (tofu not found, using terraform)"
      else
        tool_fail "tofu/terraform" "— neither found"
      fi
      ;;
    *)
      echo "  (no runtime checks defined for profile: $PROFILE)"
      ;;
  esac
}

# --- Profile resolution ---

resolve_profile() {
  if [[ -n "$PROFILE" ]]; then
    return
  fi

  local resolver="$TOOLKIT_DIR/scripts/resolve-profile.sh"
  if [[ -x "$resolver" ]]; then
    PROFILE=$("$resolver" --dir "$PROJECT_DIR" 2>/dev/null) || true
  fi

  if [[ -z "$PROFILE" || "$PROFILE" == "unknown" ]]; then
    PROFILE=""
  fi
}

# --- Main ---

main() {
  resolve_profile

  echo "Atelier Bootstrap Check"
  echo "━━━━━━━━━━━━━━━━━━━━━━━"
  if [[ -n "$PROFILE" ]]; then
    echo "Profile: $PROFILE"
  else
    echo "Profile: (none detected)"
  fi
  echo ""

  check_core

  if [[ -n "$PROFILE" ]]; then
    check_profile_tools
    check_runtime
  fi

  # Summary
  echo ""
  local total_missing=$((MISSING_REQUIRED + MISSING_OPTIONAL))
  if [[ $MISSING_REQUIRED -gt 0 ]]; then
    echo "RESULT: ${MISSING_REQUIRED} required tool(s) missing. Install before building."
    exit 2
  elif [[ $MISSING_OPTIONAL -gt 0 ]]; then
    echo "RESULT: ${MISSING_OPTIONAL} optional tool(s) missing. Some workflows may be limited."
    exit 1
  else
    echo "RESULT: All tools found. Ready to build."
    exit 0
  fi
}

main
