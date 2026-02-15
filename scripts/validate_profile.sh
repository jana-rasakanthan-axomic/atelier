#!/usr/bin/env bash
# Atelier Profile Validation
# Verifies that all tool references in a profile resolve to installed commands,
# and that all ${profile.tools.*} references in commands have matching entries.
#
# Usage:
#   validate_profile.sh                    # Auto-detect profile
#   validate_profile.sh python-fastapi     # Validate a specific profile
#
# Exit codes:
#   0 - All tool references resolved
#   1 - One or more unresolved references

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Counters
UNRESOLVED=0

# --- Output helpers ---

tool_ok() {
  local name="$1" location="$2"
  echo "  ✓ ${name} — found at ${location}"
}

tool_fail() {
  local name="$1"
  echo "  ✗ ${name} — not found"
  UNRESOLVED=$((UNRESOLVED + 1))
}

ref_ok() {
  local ref="$1" target="$2"
  echo "  ✓ \${profile.tools.${ref}} → ${target}"
}

ref_missing() {
  local ref="$1" target="$2"
  echo "  ✓ \${profile.tools.${ref}} → ${target} (MISSING)"
  UNRESOLVED=$((UNRESOLVED + 1))
}

ref_undefined() {
  local ref="$1"
  echo "  ✗ \${profile.tools.${ref}} — no entry in profile"
  UNRESOLVED=$((UNRESOLVED + 1))
}

# --- Profile resolution ---

PROFILE="${1:-}"

if [[ -z "$PROFILE" ]]; then
  local_resolver="$TOOLKIT_DIR/scripts/resolve-profile.sh"
  if [[ -x "$local_resolver" ]]; then
    PROFILE=$("$local_resolver" 2>/dev/null) || true
  fi
  if [[ -z "$PROFILE" || "$PROFILE" == "unknown" ]]; then
    echo "Error: No profile specified and auto-detection failed." >&2
    echo "Usage: validate_profile.sh [PROFILE_NAME]" >&2
    exit 1
  fi
fi

# --- Locate profile file ---

PROFILE_FILE=""
if [[ -f "$TOOLKIT_DIR/profiles/${PROFILE}.md" ]]; then
  PROFILE_FILE="$TOOLKIT_DIR/profiles/${PROFILE}.md"
elif [[ -d "$TOOLKIT_DIR/profiles/${PROFILE}" ]]; then
  # Profile is a directory — look for the top-level markdown file inside
  for candidate in "$TOOLKIT_DIR/profiles/${PROFILE}/${PROFILE}.md" "$TOOLKIT_DIR/profiles/${PROFILE}/profile.md"; do
    if [[ -f "$candidate" ]]; then
      PROFILE_FILE="$candidate"
      break
    fi
  done
fi

if [[ -z "$PROFILE_FILE" ]]; then
  echo "Error: Profile file not found for '${PROFILE}'" >&2
  echo "Searched: profiles/${PROFILE}.md, profiles/${PROFILE}/" >&2
  exit 1
fi

# --- Extract tool commands from profile ---

# Parses lines like:  command: "ruff check src/"
# Returns: binary_name|full_command (one per line, deduplicated)
extract_tools() {
  grep -E '^\s+command:\s*"' "$PROFILE_FILE" \
    | sed 's/.*command:\s*"\([^"]*\)".*/\1/' \
    | grep -v '^$' \
    | while IFS= read -r cmd_line; do
        local binary
        binary=$(echo "$cmd_line" | awk '{print $1}')
        # Strip npx wrapper to check the real binary
        if [[ "$binary" == "npx" ]]; then
          binary=$(echo "$cmd_line" | awk '{print $2}')
        fi
        echo "${binary}|${cmd_line}"
      done \
    | sort -u
}

# --- Extract ${profile.tools.*} references from commands ---

extract_profile_refs() {
  local commands_dir="$TOOLKIT_DIR/commands"
  [[ -d "$commands_dir" ]] || return
  grep -rhoE '\$\{profile\.tools\.[a-z_]+\}' "$commands_dir" 2>/dev/null \
    | sed 's/.*tools\.\([a-z_]*\).*/\1/' \
    | sort -u
}

# --- Map tool key names to their command binaries ---

# Reads the yaml tools block and extracts key: command pairs
# e.g. test_runner -> pytest, linter -> ruff
resolve_tool_key() {
  local key="$1"
  # Find the key in the profile, then the next "command:" line
  awk -v key="$key:" '
    $0 ~ "^  " key { found=1; next }
    found && /command:/ {
      gsub(/.*command:\s*"/, ""); gsub(/".*/, "");
      if ($0 != "") { print $1 }
      exit
    }
    found && /^  [a-z]/ { exit }
  ' "$PROFILE_FILE"
}

# --- Main ---

main() {
  echo "Profile Validation: ${PROFILE}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Check tools
  echo "Tools:"
  local tools
  tools=$(extract_tools)

  if [[ -z "$tools" ]]; then
    echo "  (no tool commands found in profile)"
  else
    while IFS='|' read -r binary full_cmd; do
      [[ -z "$binary" ]] && continue
      local location
      location=$(command -v "$binary" 2>/dev/null || true)
      if [[ -n "$location" ]]; then
        tool_ok "$binary" "$location"
      else
        tool_fail "$binary"
      fi
    done <<< "$tools"
  fi

  # Check ${profile.tools.*} references from commands
  echo ""
  echo "References:"
  local refs
  refs=$(extract_profile_refs)

  if [[ -z "$refs" ]]; then
    echo "  (no \${profile.tools.*} references found in commands)"
  else
    while IFS= read -r ref_key; do
      [[ -z "$ref_key" ]] && continue
      local target_binary
      target_binary=$(resolve_tool_key "$ref_key")
      if [[ -z "$target_binary" ]]; then
        ref_undefined "$ref_key"
      else
        local location
        location=$(command -v "$target_binary" 2>/dev/null || true)
        if [[ -n "$location" ]]; then
          ref_ok "$ref_key" "$target_binary"
        else
          ref_missing "$ref_key" "$target_binary"
        fi
      fi
    done <<< "$refs"
  fi

  # Summary
  echo ""
  if [[ $UNRESOLVED -gt 0 ]]; then
    echo "RESULT: ${UNRESOLVED} unresolved reference(s)"
    exit 1
  else
    echo "RESULT: All tools and references resolved."
    exit 0
  fi
}

main
