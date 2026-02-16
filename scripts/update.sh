#!/usr/bin/env bash
# Atelier Self-Update
# Detects install type and updates to the latest version.
#
# Usage:
#   update.sh              # Update atelier (auto-detect install type)
#   update.sh --check      # Check for updates without pulling
#   update.sh -h | --help  # Show help
#
# Install types:
#   global        ~/.claude/plugins/atelier (git pull)
#   project       .atelier/ in a project (git pull)
#   development   Git repo checkout (fetch only, no auto-pull)
#
# Exit codes:
#   0 - Success (up to date or updated)
#   1 - Error (not a git repo, no remote, network failure)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CHECK_ONLY=false

usage() {
  cat <<EOF
Usage: update.sh [OPTIONS]

Update Atelier to the latest version.

Options:
  --check      Check for updates without pulling
  -h, --help   Show this help

Install types detected:
  global       ~/.claude/plugins/atelier  (auto-pulls)
  project      .atelier/ in a project     (auto-pulls)
  development  git repo checkout          (fetch only)
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --check)   CHECK_ONLY=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Error: Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# --- Helpers ---

log() {
  echo "[update] $*"
}

# --- Install type detection ---

detect_install_type() {
  local resolved
  resolved="$(cd "$TOOLKIT_DIR" && pwd -P)"

  if [[ "$resolved" == "$HOME/.claude/plugins/atelier" ]]; then
    echo "global"
  elif [[ "$(basename "$TOOLKIT_DIR")" == ".atelier" ]]; then
    echo "project"
  else
    echo "development"
  fi
}

# --- Git validation ---

validate_git_repo() {
  if ! git -C "$TOOLKIT_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: $TOOLKIT_DIR is not a git repository." >&2
    echo "Cannot update without git. Re-clone from:" >&2
    echo "  git clone https://github.com/jana-rasakanthan-axomic/atelier.git" >&2
    exit 1
  fi

  if ! git -C "$TOOLKIT_DIR" remote get-url origin &>/dev/null; then
    echo "Error: No 'origin' remote configured." >&2
    echo "Add one with:" >&2
    echo "  git -C $TOOLKIT_DIR remote add origin https://github.com/jana-rasakanthan-axomic/atelier.git" >&2
    exit 1
  fi
}

# --- Version info ---

show_version() {
  local semver hash date
  semver="$(tr -d '[:space:]' < "$TOOLKIT_DIR/VERSION" 2>/dev/null || echo "unknown")"
  hash="$(git -C "$TOOLKIT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
  date="$(git -C "$TOOLKIT_DIR" log -1 --format='%ci' 2>/dev/null || echo "unknown")"
  echo "Version: $semver ($hash, $date)"
}

# --- Fetch and compare ---

fetch_remote() {
  log "Fetching from origin..."
  if ! git -C "$TOOLKIT_DIR" fetch origin 2>&1; then
    echo "Error: Network failure — could not fetch from origin." >&2
    echo "Check your internet connection and try again." >&2
    exit 1
  fi
}

show_changelog() {
  local branch
  branch="$(git -C "$TOOLKIT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")"
  local remote_ref="origin/$branch"

  # Check if remote ref exists
  if ! git -C "$TOOLKIT_DIR" rev-parse "$remote_ref" &>/dev/null; then
    remote_ref="origin/main"
    if ! git -C "$TOOLKIT_DIR" rev-parse "$remote_ref" &>/dev/null; then
      log "No remote tracking branch found. Skipping changelog."
      return
    fi
  fi

  local behind
  behind="$(git -C "$TOOLKIT_DIR" rev-list --count HEAD.."$remote_ref" 2>/dev/null || echo "0")"

  if [[ "$behind" -eq 0 ]]; then
    log "Already up to date."
    return 1  # Signal: nothing to update
  fi

  log "$behind new commit(s) available:"
  echo ""
  git -C "$TOOLKIT_DIR" log --oneline HEAD.."$remote_ref"
  echo ""
  return 0  # Signal: updates available
}

# --- Pull ---

do_pull() {
  local branch
  branch="$(git -C "$TOOLKIT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")"

  log "Pulling latest changes on $branch..."
  if git -C "$TOOLKIT_DIR" pull --ff-only origin "$branch" 2>&1; then
    log "Update complete."
  else
    echo "Error: Could not fast-forward. Local changes may conflict." >&2
    echo "Resolve manually:" >&2
    echo "  cd $TOOLKIT_DIR && git status" >&2
    exit 1
  fi
}

# --- Main ---

main() {
  local install_type
  install_type="$(detect_install_type)"

  echo "Atelier Update"
  echo "Install: $install_type ($TOOLKIT_DIR)"
  show_version
  echo ""

  validate_git_repo
  fetch_remote

  local has_updates=true
  if ! show_changelog; then
    has_updates=false
  fi

  if [[ "$CHECK_ONLY" == true ]]; then
    if [[ "$has_updates" == true ]]; then
      log "Run 'scripts/update.sh' to apply updates."
    fi
    exit 0
  fi

  if [[ "$has_updates" == false ]]; then
    exit 0
  fi

  case "$install_type" in
    global|project)
      do_pull
      echo ""
      show_version
      ;;
    development)
      log "Development install detected — skipping auto-pull."
      log "Pull manually when ready:"
      echo "  cd $TOOLKIT_DIR && git pull"
      ;;
  esac
}

main
