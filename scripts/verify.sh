#!/usr/bin/env bash
# Atelier Health Check
# Validates installation, hook registration, and profile configuration.
#
# Usage:
#   verify.sh                  # Run all checks
#   verify.sh --hooks          # Check hook registration only
#   verify.sh --structure      # Check directory structure only
#   verify.sh --profile        # Check profile detection only
#   verify.sh --verbose        # Show extra detail on failures
#   verify.sh -h | --help      # Show help
#
# Exit codes:
#   0 - All checks pass (warnings are OK)
#   1 - One or more checks failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Attempt to find project root: if toolkit is inside a project (e.g. .atelier/),
# the project root is the parent. Otherwise, toolkit IS the project.
if [[ "$(basename "$TOOLKIT_DIR")" == ".atelier" ]]; then
  PROJECT_ROOT="$(cd "$TOOLKIT_DIR/.." && pwd)"
  INSTALLED_AS_PROJECT=true
else
  PROJECT_ROOT="$TOOLKIT_DIR"
  INSTALLED_AS_PROJECT=false
fi

# Counters
PASS=0
FAIL=0
WARN=0
VERBOSE=false

# What to check (empty = all)
CHECK_HOOKS=false
CHECK_STRUCTURE=false
CHECK_PROFILE=false
CHECK_ALL=true

usage() {
  cat <<EOF
Usage: verify.sh [OPTIONS]

Atelier health check. Validates installation, hooks, and profile.

Options:
  --hooks       Check hook registration only
  --structure   Check directory structure only
  --profile     Check profile detection only
  --verbose     Show extra detail on failures
  -h, --help    Show this help

Exit codes:
  0  All checks pass (warnings are OK)
  1  One or more checks failed
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --hooks)     CHECK_HOOKS=true; CHECK_ALL=false; shift ;;
    --structure) CHECK_STRUCTURE=true; CHECK_ALL=false; shift ;;
    --profile)   CHECK_PROFILE=true; CHECK_ALL=false; shift ;;
    --verbose)   VERBOSE=true; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
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

fail() {
  echo "  [FAIL] $1"
  FAIL=$((FAIL + 1))
}

warn() {
  echo "  [WARN] $1"
  WARN=$((WARN + 1))
}

detail() {
  if [[ "$VERBOSE" == true ]]; then
    echo "         $1"
  fi
}

section() {
  echo ""
  echo "=== $1 ==="
}

# --- Checks ---

check_prerequisites() {
  section "Prerequisites"

  if command -v jq &>/dev/null; then
    pass "jq installed ($(jq --version 2>&1 || echo 'unknown version'))"
  else
    fail "jq not installed (required for hook management)"
    detail "Install with: brew install jq (macOS) or apt install jq (Linux)"
  fi

  if command -v git &>/dev/null; then
    pass "git installed ($(git --version 2>&1 | head -1))"
  else
    fail "git not installed"
  fi
}

check_structure() {
  section "Directory Structure"

  local dirs=(
    "commands"
    "agents"
    "skills"
    "profiles"
    "scripts"
    "scripts/hooks"
    "templates"
    "docs"
    "hooks"
    ".claude-plugin"
  )

  for dir in "${dirs[@]}"; do
    if [[ -d "$TOOLKIT_DIR/$dir" ]]; then
      pass "$dir/"
    else
      fail "$dir/ missing"
    fi
  done

  if [[ -f "$TOOLKIT_DIR/CLAUDE.md" ]]; then
    pass "CLAUDE.md"
  else
    fail "CLAUDE.md missing"
  fi

  # Plugin manifest
  if [[ -f "$TOOLKIT_DIR/.claude-plugin/plugin.json" ]]; then
    pass ".claude-plugin/plugin.json"
  else
    fail ".claude-plugin/plugin.json missing"
  fi

  # Plugin hooks manifest
  if [[ -f "$TOOLKIT_DIR/hooks/hooks.json" ]]; then
    pass "hooks/hooks.json"
  else
    fail "hooks/hooks.json missing"
  fi
}

check_hook_scripts() {
  section "Hook Scripts"

  local hooks=(
    "scripts/hooks/enforce-tdd-order.sh"
    "scripts/hooks/protect-main.sh"
    "scripts/hooks/regression-reminder.sh"
  )

  for hook in "${hooks[@]}"; do
    local path="$TOOLKIT_DIR/$hook"
    if [[ ! -f "$path" ]]; then
      fail "$hook not found"
    elif [[ ! -x "$path" ]]; then
      warn "$hook exists but not executable"
      detail "Fix with: chmod +x $path"
    else
      pass "$hook (executable)"
    fi
  done
}

check_hook_registration() {
  section "Hook Registration"

  local expected_hooks=(
    "enforce-tdd-order.sh"
    "protect-main.sh"
    "regression-reminder.sh"
  )

  # Check plugin hooks manifest (hooks/hooks.json)
  local hooks_json="$TOOLKIT_DIR/hooks/hooks.json"
  if [[ -f "$hooks_json" ]]; then
    if ! jq empty "$hooks_json" 2>/dev/null; then
      fail "hooks/hooks.json contains invalid JSON"
      return
    fi

    for hook_name in "${expected_hooks[@]}"; do
      local found
      found=$(jq -r --arg name "$hook_name" '
        [.hooks // {} | to_entries[] | .value[] | .hooks[]? | .command // empty]
        | map(select(contains($name)))
        | length
      ' "$hooks_json" 2>/dev/null || echo "0")

      if [[ "$found" -gt 0 ]]; then
        pass "$hook_name registered in hooks/hooks.json"
      else
        fail "$hook_name not registered in hooks/hooks.json"
      fi
    done
    return
  fi

  # Fallback: check .claude/settings.json (project-specific install)
  local settings_file="$PROJECT_ROOT/.claude/settings.json"

  if [[ ! -f "$settings_file" ]]; then
    if [[ "$INSTALLED_AS_PROJECT" == true ]]; then
      fail ".claude/settings.json not found — hooks not registered"
      detail "Run: $TOOLKIT_DIR/scripts/setup.sh"
    else
      fail "No hook registration found (hooks/hooks.json missing, no .claude/settings.json)"
    fi
    return
  fi

  if ! jq empty "$settings_file" 2>/dev/null; then
    fail ".claude/settings.json contains invalid JSON"
    return
  fi

  for hook_name in "${expected_hooks[@]}"; do
    local found
    found=$(jq -r --arg name "$hook_name" '
      [.hooks // {} | to_entries[] | .value[] | .hooks[]? | .command // empty]
      | map(select(contains($name)))
      | length
    ' "$settings_file" 2>/dev/null || echo "0")

    if [[ "$found" -gt 0 ]]; then
      pass "$hook_name registered in settings.json"
    else
      fail "$hook_name not registered in settings.json"
      detail "Run: $TOOLKIT_DIR/scripts/setup.sh"
    fi
  done
}

check_profile() {
  section "Profile"

  local resolver="$TOOLKIT_DIR/scripts/resolve-profile.sh"

  if [[ ! -x "$resolver" ]]; then
    fail "resolve-profile.sh not found or not executable"
    return
  fi

  local profile
  profile=$("$resolver" --dir "$PROJECT_ROOT" 2>/dev/null) || true

  if [[ -n "$profile" && "$profile" != "unknown" ]]; then
    pass "Profile detected: $profile"

    # Check if profile file exists
    if [[ -f "$TOOLKIT_DIR/profiles/${profile}.md" ]]; then
      pass "Profile file exists: profiles/${profile}.md"
    else
      warn "Profile file not found: profiles/${profile}.md"
    fi
  else
    warn "No profile detected for $PROJECT_ROOT"
    detail "Run: $TOOLKIT_DIR/scripts/setup.sh to configure"
  fi

  # Check config.yaml
  if [[ -f "$PROJECT_ROOT/.atelier/config.yaml" ]]; then
    pass ".atelier/config.yaml exists"
  else
    warn ".atelier/config.yaml not found"
    detail "Run: $TOOLKIT_DIR/scripts/setup.sh to create"
  fi
}

check_shared_scripts() {
  section "Shared Scripts"

  local scripts=(
    "scripts/resolve-profile.sh"
    "scripts/worktree-manager.sh"
    "scripts/generate-branch-name.sh"
    "scripts/session-manager.sh"
  )

  for script in "${scripts[@]}"; do
    local path="$TOOLKIT_DIR/$script"
    if [[ ! -f "$path" ]]; then
      warn "$script not found"
    elif [[ ! -x "$path" ]]; then
      warn "$script exists but not executable"
    else
      pass "$script"
    fi
  done
}

# --- Main ---

main() {
  echo "Atelier Health Check"
  echo "Toolkit: $TOOLKIT_DIR"
  echo "Project: $PROJECT_ROOT"
  if [[ "$INSTALLED_AS_PROJECT" == true ]]; then
    echo "Install: project-specific (.atelier/)"
  else
    echo "Install: standalone / plugin"
  fi

  if [[ "$CHECK_ALL" == true ]] || [[ "$CHECK_STRUCTURE" == true ]]; then
    check_prerequisites
    check_structure
  fi

  if [[ "$CHECK_ALL" == true ]] || [[ "$CHECK_HOOKS" == true ]]; then
    check_hook_scripts
    check_hook_registration
  fi

  if [[ "$CHECK_ALL" == true ]] || [[ "$CHECK_PROFILE" == true ]]; then
    check_profile
  fi

  if [[ "$CHECK_ALL" == true ]]; then
    check_shared_scripts
  fi

  # Summary
  echo ""
  echo "---"
  echo "Results: $PASS passed, $FAIL failed, $WARN warnings"

  if [[ $FAIL -gt 0 ]]; then
    echo "Status: UNHEALTHY"
    exit 1
  else
    echo "Status: HEALTHY"
    exit 0
  fi
}

main
