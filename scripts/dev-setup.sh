#!/usr/bin/env bash
# Atelier Developer Setup (Plugin Mode)
# Installs this checkout as a Claude Code plugin via the marketplace mechanism.
# Commands become available with namespace prefix (e.g. /atelier:design, /atelier:build).
#
# Usage:
#   dev-setup.sh                  # Install as plugin from local checkout
#   dev-setup.sh --from-github    # Install from GitHub
#   dev-setup.sh --status         # Show current plugin state
#   dev-setup.sh --unlink         # Uninstall plugin
#   dev-setup.sh -h | --help      # Show help
#
# Exit codes:
#   0 - Success
#   1 - Error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
REGISTRY_FILE="$PLUGINS_DIR/installed_plugins.json"

MARKETPLACE_NAME="atelier-marketplace"
PLUGIN_KEY="atelier@${MARKETPLACE_NAME}"

# Legacy directories that were individually symlinked in the pre-plugin setup
LEGACY_DIRS=(commands agents skills scripts)

# Legacy registry keys from earlier dev-setup versions
LEGACY_REGISTRY_KEY="atelier@local"

usage() {
  cat <<EOF
Usage: dev-setup.sh [OPTIONS]

Install Atelier as a Claude Code plugin.

Options:
  --from-github  Install from GitHub instead of local checkout
  --status       Show current plugin state
  --unlink       Uninstall plugin and clean up
  -h, --help     Show this help

Examples:
  # Install from local checkout (for development)
  scripts/dev-setup.sh

  # Install from GitHub
  scripts/dev-setup.sh --from-github

  # Check installation status
  scripts/dev-setup.sh --status

  # Uninstall
  scripts/dev-setup.sh --unlink
EOF
}

# --- Prerequisites ---

check_claude() {
  if ! command -v claude &>/dev/null; then
    echo "[FAIL] claude CLI is required but not found in PATH." >&2
    exit 1
  fi
}

check_jq() {
  if ! command -v jq &>/dev/null; then
    echo "[FAIL] jq is required but not installed." >&2
    echo "Install with: brew install jq (macOS) or apt install jq (Linux)" >&2
    exit 1
  fi
}

# --- Cleanup helpers ---

cleanup_legacy_symlinks() {
  local cleaned=0

  # Remove legacy individual directory symlinks
  for dir in "${LEGACY_DIRS[@]}"; do
    local target_path="$CLAUDE_DIR/$dir"
    if [[ -L "$target_path" ]]; then
      local target
      target=$(readlink "$target_path")
      if [[ "$target" == "$TOOLKIT_DIR/$dir" || "$target" == *"/atelier/$dir" ]]; then
        local backup_path="$target_path.atelier-backup"
        rm "$target_path"
        echo "[OK] Removed legacy symlink: $dir (was: $target)"
        cleaned=$((cleaned + 1))

        if [[ -d "$backup_path" ]]; then
          mv "$backup_path" "$target_path"
          echo "     Restored backup: $backup_path"
        fi
      fi
    fi
  done

  # Remove legacy plugin symlink
  local plugin_link="$PLUGINS_DIR/atelier"
  if [[ -L "$plugin_link" ]]; then
    rm "$plugin_link"
    echo "[OK] Removed legacy plugin symlink"
    cleaned=$((cleaned + 1))
  fi

  if [[ $cleaned -gt 0 ]]; then
    echo "[OK] Cleaned up $cleaned legacy symlink(s)"
  fi
}

cleanup_legacy_registry() {
  check_jq

  # Remove legacy "atelier@local" from installed_plugins.json
  if [[ -f "$REGISTRY_FILE" ]] && jq empty "$REGISTRY_FILE" 2>/dev/null; then
    local has_key
    has_key=$(jq --arg key "$LEGACY_REGISTRY_KEY" '
      has("plugins") and (.plugins | has($key))
    ' "$REGISTRY_FILE" 2>/dev/null || echo "false")

    if [[ "$has_key" == "true" ]]; then
      local registry
      registry=$(jq --arg key "$LEGACY_REGISTRY_KEY" 'del(.plugins[$key])' "$REGISTRY_FILE")
      echo "$registry" | jq '.' > "$REGISTRY_FILE"
      echo "[OK] Removed legacy registry entry: $LEGACY_REGISTRY_KEY"
    fi
  fi

  # Remove legacy "atelier@local" from enabledPlugins
  if [[ -f "$SETTINGS_FILE" ]] && jq empty "$SETTINGS_FILE" 2>/dev/null; then
    local has_enabled
    has_enabled=$(jq --arg key "$LEGACY_REGISTRY_KEY" '
      has("enabledPlugins") and (.enabledPlugins | has($key))
    ' "$SETTINGS_FILE" 2>/dev/null || echo "false")

    if [[ "$has_enabled" == "true" ]]; then
      local settings
      settings=$(jq --arg key "$LEGACY_REGISTRY_KEY" 'del(.enabledPlugins[$key])' "$SETTINGS_FILE")
      echo "$settings" | jq '.' > "$SETTINGS_FILE"
      echo "[OK] Removed legacy enabledPlugins entry: $LEGACY_REGISTRY_KEY"
    fi
  fi

  # Remove stale "plugins" array from settings.json
  if [[ -f "$SETTINGS_FILE" ]] && jq empty "$SETTINGS_FILE" 2>/dev/null; then
    local has_plugins_array
    has_plugins_array=$(jq 'has("plugins")' "$SETTINGS_FILE" 2>/dev/null || echo "false")

    if [[ "$has_plugins_array" == "true" ]]; then
      local settings
      settings=$(jq 'del(.plugins)' "$SETTINGS_FILE")
      echo "$settings" | jq '.' > "$SETTINGS_FILE"
      echo "[OK] Cleaned up stale 'plugins' array from settings.json"
    fi
  fi
}

# --- Plugin operations ---

do_install_local() {
  check_claude
  check_jq

  echo "Installing Atelier from local checkout..."
  echo "Toolkit: $TOOLKIT_DIR"
  echo ""

  # Clean up any legacy setup
  cleanup_legacy_symlinks
  cleanup_legacy_registry

  # Write marketplace.json with absolute path to this checkout
  local marketplace_dir="${TOOLKIT_DIR}/.claude-marketplace/.claude-plugin"
  local marketplace_file="${marketplace_dir}/marketplace.json"
  mkdir -p "$marketplace_dir"

  jq -n --arg path "$TOOLKIT_DIR" '{
    "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
    "name": "atelier-marketplace",
    "description": "Atelier — Process-agnostic development toolkit",
    "owner": { "name": "Axomic" },
    "plugins": [{
      "name": "atelier",
      "description": "Process-agnostic development toolkit with TDD, outside-in workflows, and profile-based stack support",
      "author": { "name": "Axomic" },
      "source": { "source": "directory", "path": $path },
      "category": "development"
    }]
  }' > "$marketplace_file"
  echo "[OK] Wrote marketplace.json with local path: $TOOLKIT_DIR"

  # Register marketplace from local directory
  echo ""
  echo "Registering marketplace..."
  claude plugin marketplace add "${TOOLKIT_DIR}/.claude-marketplace"

  # Install the plugin
  echo ""
  echo "Installing plugin..."
  claude plugin install "$PLUGIN_KEY"

  echo ""
  echo "Setup complete. Restart Claude Code to activate."
  echo "Commands available as: /atelier:design, /atelier:build, /atelier:plan, ..."
  echo ""
  echo "To uninstall: scripts/dev-setup.sh --unlink"
}

do_install_github() {
  check_claude
  check_jq

  echo "Installing Atelier from GitHub..."
  echo ""

  # Clean up any legacy setup
  cleanup_legacy_symlinks
  cleanup_legacy_registry

  # Write marketplace.json with GitHub URL source
  local marketplace_dir="${TOOLKIT_DIR}/.claude-marketplace/.claude-plugin"
  local marketplace_file="${marketplace_dir}/marketplace.json"
  mkdir -p "$marketplace_dir"

  cat > "$marketplace_file" <<'MKJSON'
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "atelier-marketplace",
  "description": "Atelier — Process-agnostic development toolkit",
  "owner": { "name": "Axomic" },
  "plugins": [{
    "name": "atelier",
    "description": "Process-agnostic development toolkit with TDD, outside-in workflows, and profile-based stack support",
    "author": { "name": "Axomic" },
    "source": { "source": "url", "url": "https://github.com/jana-rasakanthan-axomic/atelier.git" },
    "category": "development",
    "homepage": "https://github.com/jana-rasakanthan-axomic/atelier"
  }]
}
MKJSON
  echo "[OK] Wrote marketplace.json with GitHub source"

  # Register marketplace from GitHub
  echo ""
  echo "Registering marketplace..."
  claude plugin marketplace add "github:jana-rasakanthan-axomic/atelier/.claude-marketplace"

  # Install the plugin
  echo ""
  echo "Installing plugin..."
  claude plugin install "$PLUGIN_KEY"

  echo ""
  echo "Setup complete. Restart Claude Code to activate."
  echo "Commands available as: /atelier:design, /atelier:build, /atelier:plan, ..."
  echo ""
  echo "To uninstall: scripts/dev-setup.sh --unlink"
}

do_unlink() {
  check_claude

  echo "Uninstalling Atelier plugin..."

  # Uninstall via claude CLI
  claude plugin uninstall "$PLUGIN_KEY" 2>/dev/null || echo "[OK] Plugin already uninstalled"

  # Clean up legacy artifacts
  cleanup_legacy_symlinks
  cleanup_legacy_registry

  echo ""
  echo "Uninstall complete."
  echo "To reinstall: scripts/dev-setup.sh"
}

show_status() {
  check_jq

  echo "Plugin status:"

  # Check installed_plugins.json for the plugin
  if [[ -f "$REGISTRY_FILE" ]] && jq empty "$REGISTRY_FILE" 2>/dev/null; then
    local install_path
    install_path=$(jq -r --arg key "$PLUGIN_KEY" '
      .plugins[$key] // [] | .[0].installPath // empty
    ' "$REGISTRY_FILE" 2>/dev/null || echo "")

    if [[ -n "$install_path" ]]; then
      echo "  [OK] Installed: $PLUGIN_KEY"
      echo "       Path: $install_path"
    else
      echo "  [WARN] Not installed ($PLUGIN_KEY not in plugin registry)"
    fi
  else
    echo "  [WARN] No plugin registry found"
  fi

  # Check enabledPlugins
  if [[ -f "$SETTINGS_FILE" ]] && jq empty "$SETTINGS_FILE" 2>/dev/null; then
    local enabled
    enabled=$(jq -r --arg key "$PLUGIN_KEY" '.enabledPlugins[$key] // empty' "$SETTINGS_FILE" 2>/dev/null || echo "")
    if [[ "$enabled" == "true" ]]; then
      echo "  [OK] Enabled in settings.json"
    else
      echo "  [WARN] Not enabled in settings.json"
    fi
  fi

  # Check for legacy artifacts
  local legacy_found=false
  for dir in "${LEGACY_DIRS[@]}"; do
    local target_path="$CLAUDE_DIR/$dir"
    if [[ -L "$target_path" ]]; then
      local target
      target=$(readlink "$target_path")
      if [[ "$target" == "$TOOLKIT_DIR/$dir" || "$target" == *"/atelier/$dir" ]]; then
        if [[ "$legacy_found" == false ]]; then
          echo ""
          echo "  Legacy artifacts (run without flags to clean up):"
          legacy_found=true
        fi
        echo "    [WARN] Symlink: $dir -> $target"
      fi
    fi
  done

  if [[ -L "$PLUGINS_DIR/atelier" ]]; then
    if [[ "$legacy_found" == false ]]; then
      echo ""
      echo "  Legacy artifacts:"
    fi
    echo "    [WARN] Symlink: plugins/atelier -> $(readlink "$PLUGINS_DIR/atelier")"
  fi
}

# --- Main ---

main() {
  local action="install_local"

  while [[ $# -gt 0 ]]; do
    case $1 in
      --from-github) action="install_github"; shift ;;
      --status)      action="status"; shift ;;
      --unlink)      action="unlink"; shift ;;
      -h|--help)     usage; exit 0 ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  case "$action" in
    install_local)  do_install_local ;;
    install_github) do_install_github ;;
    status)         show_status ;;
    unlink)         do_unlink ;;
  esac
}

main "$@"
