#!/usr/bin/env bash
# Atelier Version Bump
# Increments the patch version in VERSION and syncs to plugin.json.
#
# Usage:
#   bump-version.sh              # Bump patch (0.1.0 → 0.1.1)
#   bump-version.sh --dry-run    # Show what would change without writing
#   bump-version.sh -h | --help  # Show help
#
# The VERSION file is the single source of truth. plugin.json is updated
# to match. For minor/major bumps, edit VERSION directly.
#
# Exit codes:
#   0 - Success
#   1 - Error (missing VERSION file, invalid format)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$TOOLKIT_DIR/VERSION"
PLUGIN_JSON="$TOOLKIT_DIR/.claude-plugin/plugin.json"

DRY_RUN=false

usage() {
  cat <<EOF
Usage: bump-version.sh [OPTIONS]

Increment the patch version and sync to plugin.json.

Options:
  --dry-run    Show what would change without writing
  -h, --help   Show this help

Examples:
  bump-version.sh              # 0.1.0 → 0.1.1
  bump-version.sh --dry-run    # Preview only
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)  DRY_RUN=true; shift ;;
    -h|--help)  usage; exit 0 ;;
    *)
      echo "Error: Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# --- Validate ---

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "Error: VERSION file not found at $VERSION_FILE" >&2
  exit 1
fi

CURRENT=$(tr -d '[:space:]' < "$VERSION_FILE")

if [[ ! "$CURRENT" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Invalid version format '$CURRENT' — expected MAJOR.MINOR.PATCH" >&2
  exit 1
fi

# --- Bump patch ---

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

echo "Version: $CURRENT → $NEW_VERSION"

if [[ "$DRY_RUN" == true ]]; then
  echo "(dry run — no files modified)"
  exit 0
fi

# --- Write VERSION ---

echo "$NEW_VERSION" > "$VERSION_FILE"
echo "Updated: $VERSION_FILE"

# --- Sync plugin.json ---

if [[ -f "$PLUGIN_JSON" ]]; then
  # Replace the version field in plugin.json using sed
  sed -i.bak "s/\"version\": *\"[^\"]*\"/\"version\": \"$NEW_VERSION\"/" "$PLUGIN_JSON"
  rm -f "${PLUGIN_JSON}.bak"
  echo "Updated: $PLUGIN_JSON"
else
  echo "Warning: $PLUGIN_JSON not found — skipping plugin.json sync" >&2
fi
