#!/usr/bin/env bash
# Atelier Developer Setup
# Symlinks a local Atelier checkout to ~/.claude/plugins/atelier for fast iteration.
#
# Usage:
#   dev-setup.sh              # Create symlink to this checkout
#   dev-setup.sh --status     # Show current link state
#   dev-setup.sh --unlink     # Remove symlink, restore backup if one exists
#   dev-setup.sh -h | --help  # Show help
#
# Exit codes:
#   0 - Success
#   1 - Error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_DIR="$HOME/.claude/plugins"
PLUGIN_PATH="$PLUGIN_DIR/atelier"
BACKUP_PATH="$PLUGIN_DIR/atelier.backup"

usage() {
  cat <<EOF
Usage: dev-setup.sh [OPTIONS]

Symlink this Atelier checkout to ~/.claude/plugins/atelier for development.

Options:
  --status     Show current symlink state
  --unlink     Remove symlink and restore backup if one exists
  -h, --help   Show this help

Examples:
  # Link local checkout for development
  scripts/dev-setup.sh

  # Check what's currently linked
  scripts/dev-setup.sh --status

  # Unlink and restore previous install
  scripts/dev-setup.sh --unlink
EOF
}

show_status() {
  if [[ -L "$PLUGIN_PATH" ]]; then
    local target
    target=$(readlink "$PLUGIN_PATH")
    echo "[OK] Symlinked: $PLUGIN_PATH -> $target"
    if [[ "$target" == "$TOOLKIT_DIR" ]]; then
      echo "     Points to this checkout."
    else
      echo "     Points to a DIFFERENT checkout."
    fi
  elif [[ -d "$PLUGIN_PATH" ]]; then
    echo "[OK] Regular directory: $PLUGIN_PATH (not a symlink)"
  else
    echo "[WARN] Not installed: $PLUGIN_PATH does not exist"
  fi

  if [[ -d "$BACKUP_PATH" ]]; then
    echo "[OK] Backup exists: $BACKUP_PATH"
  fi
}

do_link() {
  # Already symlinked to this checkout
  if [[ -L "$PLUGIN_PATH" ]]; then
    local target
    target=$(readlink "$PLUGIN_PATH")
    if [[ "$target" == "$TOOLKIT_DIR" ]]; then
      echo "[OK] Already symlinked to this checkout. Nothing to do."
      return
    fi
    # Symlinked to different checkout — update
    echo "[OK] Updating symlink (was: $target)"
    rm "$PLUGIN_PATH"
  elif [[ -d "$PLUGIN_PATH" ]]; then
    # Real directory — back it up
    if [[ -d "$BACKUP_PATH" ]]; then
      echo "[FAIL] Cannot back up: $BACKUP_PATH already exists." >&2
      echo "Remove the backup first, then retry." >&2
      exit 1
    fi
    echo "[OK] Backing up existing install to $BACKUP_PATH"
    mv "$PLUGIN_PATH" "$BACKUP_PATH"
  fi

  # Ensure parent directory exists
  mkdir -p "$PLUGIN_DIR"

  ln -s "$TOOLKIT_DIR" "$PLUGIN_PATH"
  echo "[OK] Symlinked: $PLUGIN_PATH -> $TOOLKIT_DIR"
}

do_unlink() {
  if [[ ! -L "$PLUGIN_PATH" ]]; then
    if [[ -d "$PLUGIN_PATH" ]]; then
      echo "[WARN] $PLUGIN_PATH is a regular directory, not a symlink. Not removing."
    else
      echo "[OK] No symlink found at $PLUGIN_PATH. Nothing to do."
    fi
    return
  fi

  rm "$PLUGIN_PATH"
  echo "[OK] Removed symlink: $PLUGIN_PATH"

  if [[ -d "$BACKUP_PATH" ]]; then
    mv "$BACKUP_PATH" "$PLUGIN_PATH"
    echo "[OK] Restored backup: $BACKUP_PATH -> $PLUGIN_PATH"
  fi
}

# --- Main ---

main() {
  local action="link"

  while [[ $# -gt 0 ]]; do
    case $1 in
      --status) action="status"; shift ;;
      --unlink) action="unlink"; shift ;;
      -h|--help) usage; exit 0 ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  case "$action" in
    status) show_status ;;
    link)   do_link ;;
    unlink) do_unlink ;;
  esac
}

main "$@"
