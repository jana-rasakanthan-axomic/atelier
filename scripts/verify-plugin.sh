#!/usr/bin/env bash
# Atelier Plugin Registry Verification
# Checks plugin registration state and provides repair suggestions.
#
# Usage:
#   verify-plugin.sh              # Run all checks
#   verify-plugin.sh --verbose    # Show repair suggestions for each failure
#   verify-plugin.sh -h | --help  # Show help
#
# Exit codes:
#   0 - All checks pass
#   1 - Warnings only (plugin works but not optimal)
#   2 - Errors found (plugin may not function)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
PLUGIN_SYMLINK="$PLUGINS_DIR/atelier"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
REGISTRY_FILE="$PLUGINS_DIR/installed_plugins.json"

MARKETPLACE_NAME="atelier-marketplace"
PLUGIN_KEY="atelier@${MARKETPLACE_NAME}"

# Counters
PASS=0
WARN=0
FAIL=0

VERBOSE=false

usage() {
  cat <<EOF
Usage: verify-plugin.sh [OPTIONS]

Check Atelier plugin registration state and report issues.

Options:
  --verbose    Show repair suggestions for each failure
  -h, --help   Show this help

Exit codes:
  0  All checks pass
  1  Warnings only
  2  Errors found
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose) VERBOSE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Error: Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# --- Output helpers ---

pass() {
  echo "  [PASS] $1"
  PASS=$((PASS + 1))
}

warn() {
  echo "  [WARN] $1"
  WARN=$((WARN + 1))
}

fail() {
  echo "  [FAIL] $1"
  FAIL=$((FAIL + 1))
}

repair() {
  if [[ "$VERBOSE" == true ]]; then
    echo "         Repair: $1"
  fi
}

# --- Checks ---

check_symlink() {
  echo ""
  echo "Symlink"
  echo "-------"

  if [[ -L "$PLUGIN_SYMLINK" ]]; then
    local target
    target="$(readlink "$PLUGIN_SYMLINK")"
    if [[ -d "$PLUGIN_SYMLINK" ]]; then
      pass "$PLUGIN_SYMLINK -> $target"
    else
      fail "$PLUGIN_SYMLINK -> $target (target does not exist)"
      repair "rm $PLUGIN_SYMLINK && ln -s /path/to/atelier $PLUGIN_SYMLINK"
    fi
  elif [[ -d "$PLUGIN_SYMLINK" ]]; then
    pass "$PLUGIN_SYMLINK (directory, not symlink)"
  else
    warn "No symlink or directory at $PLUGIN_SYMLINK"
    repair "ln -s $TOOLKIT_DIR $PLUGIN_SYMLINK"
  fi
}

check_registry() {
  echo ""
  echo "Plugin Registry"
  echo "---------------"

  if [[ ! -f "$REGISTRY_FILE" ]]; then
    warn "No plugin registry found at $REGISTRY_FILE"
    repair "Run: scripts/dev-setup.sh"
    return
  fi

  if ! jq empty "$REGISTRY_FILE" 2>/dev/null; then
    fail "$REGISTRY_FILE contains invalid JSON"
    repair "Delete and re-register: rm $REGISTRY_FILE && scripts/dev-setup.sh"
    return
  fi

  local install_path
  install_path="$(jq -r --arg key "$PLUGIN_KEY" '
    .plugins[$key] // [] | .[0].installPath // empty
  ' "$REGISTRY_FILE" 2>/dev/null || echo "")"

  if [[ -n "$install_path" ]]; then
    pass "Registered as $PLUGIN_KEY (path: $install_path)"
  else
    warn "$PLUGIN_KEY not found in plugin registry"
    repair "Run: scripts/dev-setup.sh"
  fi
}

check_settings() {
  echo ""
  echo "Settings"
  echo "--------"

  if [[ ! -f "$SETTINGS_FILE" ]]; then
    warn "No settings file found at $SETTINGS_FILE"
    repair "Run: scripts/dev-setup.sh"
    return
  fi

  if ! jq empty "$SETTINGS_FILE" 2>/dev/null; then
    fail "$SETTINGS_FILE contains invalid JSON"
    repair "Fix JSON syntax in $SETTINGS_FILE"
    return
  fi

  # Check enabledPlugins
  local enabled
  enabled="$(jq -r --arg key "$PLUGIN_KEY" '.enabledPlugins[$key] // empty' "$SETTINGS_FILE" 2>/dev/null || echo "")"

  if [[ "$enabled" == "true" ]]; then
    pass "Plugin enabled in settings.json (enabledPlugins)"
  else
    warn "Plugin not enabled in settings.json"
    repair "Add to $SETTINGS_FILE: \"enabledPlugins\": { \"$PLUGIN_KEY\": true }"
  fi

  # Check for project-level plugins array (legacy/alternative install)
  local has_plugins_array
  has_plugins_array="$(jq 'has("plugins")' "$SETTINGS_FILE" 2>/dev/null || echo "false")"

  if [[ "$has_plugins_array" == "true" ]]; then
    local has_atelier
    has_atelier="$(jq '.plugins | map(select(test("atelier"))) | length' "$SETTINGS_FILE" 2>/dev/null || echo "0")"
    if [[ "$has_atelier" -gt 0 ]]; then
      pass "Project-level plugins array contains atelier entry"
    fi
  fi
}

check_plugin_files() {
  echo ""
  echo "Plugin Files"
  echo "------------"

  local plugin_dir="$TOOLKIT_DIR"

  # If symlink exists, check the target instead
  if [[ -L "$PLUGIN_SYMLINK" ]]; then
    local target
    target="$(readlink "$PLUGIN_SYMLINK")"
    if [[ -d "$target" ]]; then
      plugin_dir="$target"
    fi
  fi

  # Check essential files
  local essential_files=(
    "CLAUDE.md"
    "hooks/hooks.json"
    ".claude-plugin/plugin.json"
  )

  for file in "${essential_files[@]}"; do
    if [[ -f "$plugin_dir/$file" ]]; then
      pass "$file present"
    else
      fail "$file missing from $plugin_dir"
      repair "Re-clone: git clone https://github.com/jana-rasakanthan-axomic/atelier.git"
    fi
  done

  # Check essential directories
  local essential_dirs=(
    "commands"
    "agents"
    "skills"
    "scripts"
  )

  for dir in "${essential_dirs[@]}"; do
    if [[ -d "$plugin_dir/$dir" ]]; then
      pass "$dir/ present"
    else
      fail "$dir/ missing from $plugin_dir"
      repair "Re-clone: git clone https://github.com/jana-rasakanthan-axomic/atelier.git"
    fi
  done
}

check_git_state() {
  echo ""
  echo "Git State"
  echo "---------"

  local plugin_dir="$TOOLKIT_DIR"

  # Use symlink target if available
  if [[ -L "$PLUGIN_SYMLINK" ]]; then
    local target
    target="$(readlink "$PLUGIN_SYMLINK")"
    if [[ -d "$target" ]]; then
      plugin_dir="$target"
    fi
  fi

  if ! git -C "$plugin_dir" rev-parse --is-inside-work-tree &>/dev/null; then
    warn "Not a git repository ($plugin_dir)"
    repair "Re-clone: git clone https://github.com/jana-rasakanthan-axomic/atelier.git"
    return
  fi

  local hash date
  hash="$(git -C "$plugin_dir" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
  date="$(git -C "$plugin_dir" log -1 --format='%ci' 2>/dev/null || echo "unknown")"
  pass "Git repo: $hash ($date)"

  # Check if remote exists
  if ! git -C "$plugin_dir" remote get-url origin &>/dev/null; then
    warn "No 'origin' remote configured"
    repair "git -C $plugin_dir remote add origin https://github.com/jana-rasakanthan-axomic/atelier.git"
    return
  fi

  # Fetch and check if behind (best-effort, don't fail on network issues)
  if git -C "$plugin_dir" fetch origin --quiet 2>/dev/null; then
    local branch
    branch="$(git -C "$plugin_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")"
    local remote_ref="origin/$branch"

    if ! git -C "$plugin_dir" rev-parse "$remote_ref" &>/dev/null; then
      remote_ref="origin/main"
    fi

    if git -C "$plugin_dir" rev-parse "$remote_ref" &>/dev/null; then
      local behind
      behind="$(git -C "$plugin_dir" rev-list --count HEAD.."$remote_ref" 2>/dev/null || echo "0")"

      if [[ "$behind" -eq 0 ]]; then
        pass "Up to date with $remote_ref"
      else
        warn "$behind commit(s) behind $remote_ref"
        repair "Run: scripts/update.sh"
      fi
    fi
  else
    warn "Could not fetch from origin (network issue?)"
  fi

  # Check for uncommitted changes
  local dirty
  dirty="$(git -C "$plugin_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$dirty" -gt 0 ]]; then
    warn "$dirty uncommitted change(s) in plugin directory"
  fi
}

# --- Main ---

main() {
  echo "Plugin Registry Check"

  check_symlink
  check_registry
  check_settings
  check_plugin_files
  check_git_state

  # Summary
  echo ""
  echo "---"
  echo "Results: $PASS passed, $FAIL failed, $WARN warnings"

  if [[ $FAIL -gt 0 ]]; then
    echo "Status: ERRORS (plugin may not function correctly)"
    if [[ "$VERBOSE" == false ]]; then
      echo "Run with --verbose for repair suggestions."
    fi
    exit 2
  elif [[ $WARN -gt 0 ]]; then
    echo "Status: WARNINGS (plugin works but not optimal)"
    if [[ "$VERBOSE" == false ]]; then
      echo "Run with --verbose for repair suggestions."
    fi
    exit 1
  else
    echo "Status: OK"
    exit 0
  fi
}

main
