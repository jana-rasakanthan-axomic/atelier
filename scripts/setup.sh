#!/usr/bin/env bash
# Atelier Project Setup
# Registers Atelier hooks into the target project's .claude/settings.json,
# detects the project profile, and creates initial config.
#
# Usage:
#   setup.sh                 # Full setup (hooks + profile + config)
#   setup.sh --hooks-only    # Only register hooks
#   setup.sh --uninstall     # Remove Atelier hooks (preserves user hooks)
#   setup.sh --dry-run       # Show what would change without modifying files
#   setup.sh -h | --help     # Show help
#
# Exit codes:
#   0 - Setup completed successfully
#   1 - Error (missing dependency, invalid JSON, etc.)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Resolve project root: if installed as .atelier/, project is the parent
if [[ "$(basename "$TOOLKIT_DIR")" == ".atelier" ]]; then
  PROJECT_ROOT="$(cd "$TOOLKIT_DIR/.." && pwd)"
else
  # Running from within toolkit repo itself — use toolkit as project
  PROJECT_ROOT="$TOOLKIT_DIR"
fi

# Compute relative path from project root to toolkit (for hook commands)
HOOK_PREFIX="$(python3 -c "import os; print(os.path.relpath('$TOOLKIT_DIR', '$PROJECT_ROOT'))" 2>/dev/null || echo ".atelier")"

# Flags
UNINSTALL=false
HOOKS_ONLY=false
DRY_RUN=false

usage() {
  cat <<EOF
Usage: setup.sh [OPTIONS]

Configure a project to use Atelier. Registers hooks, detects profile,
and creates initial configuration.

Options:
  --hooks-only   Only register hooks (skip profile/config)
  --uninstall    Remove Atelier hooks from .claude/settings.json
  --dry-run      Show what would change without modifying files
  -h, --help     Show this help

Examples:
  # From a project with Atelier cloned as .atelier/
  .atelier/scripts/setup.sh

  # Remove Atelier hooks
  .atelier/scripts/setup.sh --uninstall
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --uninstall)  UNINSTALL=true; shift ;;
    --hooks-only) HOOKS_ONLY=true; shift ;;
    --dry-run)    DRY_RUN=true; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# --- Prerequisites ---

if ! command -v jq &>/dev/null; then
  echo "[FAIL] jq is required but not installed." >&2
  echo "Install with: brew install jq (macOS) or apt install jq (Linux)" >&2
  exit 1
fi

# --- Hook Definitions ---

# Each hook: event_type::matcher::command (using :: as delimiter since matchers can contain |)
HOOK_DEFS=(
  "PreToolUse::Write|Edit::bash ${HOOK_PREFIX}/scripts/hooks/enforce-tdd-order.sh"
  "PostToolUse::Bash::bash ${HOOK_PREFIX}/scripts/hooks/regression-reminder.sh"
  "PreToolUse::Bash::bash ${HOOK_PREFIX}/scripts/hooks/protect-main.sh"
)

# --- Functions ---

ensure_hooks_executable() {
  local hooks_dir="$TOOLKIT_DIR/scripts/hooks"
  local fixed=0

  for script in "$hooks_dir"/*.sh; do
    [[ -f "$script" ]] || continue
    if [[ ! -x "$script" ]]; then
      chmod +x "$script"
      fixed=$((fixed + 1))
    fi
  done

  if [[ $fixed -gt 0 ]]; then
    echo "[OK] Made $fixed hook script(s) executable"
  fi
}

merge_hooks() {
  local settings_file="$PROJECT_ROOT/.claude/settings.json"

  # Ensure .claude/ directory exists
  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$PROJECT_ROOT/.claude"
  fi

  # Load or create settings
  local settings
  if [[ -f "$settings_file" ]]; then
    if ! jq empty "$settings_file" 2>/dev/null; then
      echo "[FAIL] $settings_file contains invalid JSON. Fix it manually before running setup." >&2
      exit 1
    fi
    settings=$(cat "$settings_file")
  else
    settings='{}'
    echo "[OK] Creating $settings_file"
  fi

  # Ensure .hooks exists
  settings=$(echo "$settings" | jq '.hooks //= {}')

  local added=0
  local skipped=0

  for hook_def in "${HOOK_DEFS[@]}"; do
    # Parse definition: event_type::matcher::command
    local event_type matcher command
    IFS='::' read -r event_type _ matcher _ command <<< "$hook_def"

    # Check if a hook with the same script name is already registered
    # (matches regardless of path prefix to handle . vs .atelier vs scripts/)
    local hook_script_name
    hook_script_name=$(basename "$command" | xargs)
    local already_exists
    already_exists=$(echo "$settings" | jq -r --arg et "$event_type" --arg name "$hook_script_name" '
      .hooks[$et] // []
      | map(.hooks[]? | .command // empty)
      | map(select(endswith($name)))
      | length
    ' 2>/dev/null || echo "0")

    if [[ "$already_exists" -gt 0 ]]; then
      skipped=$((skipped + 1))
      continue
    fi

    # Build the new hook entry
    local new_entry
    new_entry=$(jq -n --arg matcher "$matcher" --arg command "$command" '{
      matcher: $matcher,
      hooks: [{ type: "command", command: $command }]
    }')

    # Append to the event type array
    settings=$(echo "$settings" | jq --arg et "$event_type" --argjson entry "$new_entry" '
      .hooks[$et] = (.hooks[$et] // []) + [$entry]
    ')

    added=$((added + 1))
  done

  if [[ $added -eq 0 ]]; then
    echo "[OK] All hooks already registered ($skipped skipped)"
  else
    if [[ "$DRY_RUN" == true ]]; then
      echo "[DRY-RUN] Would add $added hook(s) to $settings_file"
      echo "$settings" | jq '.hooks'
    else
      echo "$settings" | jq '.' > "$settings_file"
      echo "[OK] Registered $added hook(s) in $settings_file ($skipped already present)"
    fi
  fi
}

remove_hooks() {
  local settings_file="$PROJECT_ROOT/.claude/settings.json"

  if [[ ! -f "$settings_file" ]]; then
    echo "[OK] No settings file found — nothing to uninstall"
    return
  fi

  if ! jq empty "$settings_file" 2>/dev/null; then
    echo "[FAIL] $settings_file contains invalid JSON. Fix it manually." >&2
    exit 1
  fi

  local settings
  settings=$(cat "$settings_file")

  local removed=0

  # Known Atelier hook script names
  local atelier_hooks=("enforce-tdd-order.sh" "protect-main.sh" "regression-reminder.sh")

  # Remove hook entries whose command ends with a known Atelier hook script name
  for event_type in PreToolUse PostToolUse; do
    local original_count new_settings
    original_count=$(echo "$settings" | jq --arg et "$event_type" '
      .hooks[$et] // [] | length
    ')

    # Build jq array of hook names to match
    local names_json
    names_json=$(printf '%s\n' "${atelier_hooks[@]}" | jq -R . | jq -s .)

    new_settings=$(echo "$settings" | jq --arg et "$event_type" --argjson names "$names_json" '
      .hooks[$et] = (
        (.hooks[$et] // [])
        | map(select(
            (.hooks // [])
            | all(.command // "" | split("/") | last | IN($names[]) | not)
          ))
      )
    ')

    local new_count
    new_count=$(echo "$new_settings" | jq --arg et "$event_type" '
      .hooks[$et] // [] | length
    ')

    local diff=$((original_count - new_count))
    removed=$((removed + diff))
    settings="$new_settings"
  done

  # Clean up empty arrays
  settings=$(echo "$settings" | jq '
    .hooks |= with_entries(select(.value | length > 0))
    | if .hooks == {} then del(.hooks) else . end
  ')

  if [[ $removed -eq 0 ]]; then
    echo "[OK] No Atelier hooks found to remove"
  else
    if [[ "$DRY_RUN" == true ]]; then
      echo "[DRY-RUN] Would remove $removed Atelier hook(s)"
    else
      echo "$settings" | jq '.' > "$settings_file"
      echo "[OK] Removed $removed Atelier hook(s) — user hooks preserved"
    fi
  fi
}

detect_profile() {
  local resolver="$TOOLKIT_DIR/scripts/resolve-profile.sh"

  if [[ ! -x "$resolver" ]]; then
    echo "[WARN] resolve-profile.sh not found or not executable"
    return
  fi

  local profile
  profile=$("$resolver" --dir "$PROJECT_ROOT" 2>/dev/null) || true

  if [[ -n "$profile" && "$profile" != "unknown" ]]; then
    echo "[OK] Detected profile: $profile"
    echo "$profile"
  else
    echo "[WARN] No profile auto-detected"
    echo ""
  fi
}

create_config() {
  local config_dir="$PROJECT_ROOT/.atelier"
  local config_file="$config_dir/config.yaml"

  if [[ -f "$config_file" ]]; then
    echo "[OK] .atelier/config.yaml already exists"
    return
  fi

  local profile="$1"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY-RUN] Would create $config_file"
    return
  fi

  mkdir -p "$config_dir"

  if [[ -n "$profile" ]]; then
    cat > "$config_file" <<EOF
# Atelier project configuration
# See CLAUDE.md for available profiles and options.
profile: $profile
EOF
    echo "[OK] Created .atelier/config.yaml (profile: $profile)"
  else
    cat > "$config_file" <<EOF
# Atelier project configuration
# Uncomment and set your profile, or let auto-detection handle it.
# See CLAUDE.md for available profiles.
# profile: python-fastapi
EOF
    echo "[OK] Created .atelier/config.yaml (no profile set — using auto-detection)"
  fi
}

# --- Main ---

main() {
  echo "Atelier Setup"
  echo "Toolkit: $TOOLKIT_DIR"
  echo "Project: $PROJECT_ROOT"
  echo "Hook prefix: $HOOK_PREFIX"
  echo ""

  if [[ "$UNINSTALL" == true ]]; then
    remove_hooks
    echo ""
    echo "Uninstall complete. Config files (.atelier/config.yaml) were not removed."
    return
  fi

  # Step 1: Ensure hook scripts are executable
  ensure_hooks_executable

  # Step 2: Merge hooks into settings.json
  merge_hooks

  if [[ "$HOOKS_ONLY" == true ]]; then
    echo ""
    echo "Hook-only setup complete."
    return
  fi

  # Step 3: Detect profile
  echo ""
  local profile
  profile=$(detect_profile | tail -1)

  # Step 4: Create config.yaml
  create_config "$profile"

  # Summary
  echo ""
  echo "---"
  echo "Project setup complete (hooks registered in .claude/settings.json)."
  echo ""
  echo "NOTE: For global installation, prefer the plugin method instead:"
  echo "  claude plugins install axomic/atelier"
  echo "  # or: scripts/dev-setup.sh (for local development)"
  echo ""
  echo "Next steps:"
  echo "  1. Verify:  $TOOLKIT_DIR/scripts/verify.sh"
  echo "  2. Start:   /gather to begin a workflow"
}

main
