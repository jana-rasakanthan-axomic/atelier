#!/usr/bin/env bash
set -euo pipefail

# Atelier Profile Resolver
# Detects the appropriate development profile for a project.
#
# Usage:
#   resolve-profile.sh                    # Detect in current directory
#   resolve-profile.sh --dir /path/to    # Detect in specified directory
#   resolve-profile.sh --verbose         # Show detection reasoning
#
# Exit codes:
#   0 - Profile detected (name on stdout)
#   1 - No profile detected

# Parse arguments
DIR="."
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --dir)
      DIR="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Usage: resolve-profile.sh [--dir PATH] [--verbose]" >&2
      exit 1
      ;;
  esac
done

# Helper: verbose logging to stderr
log() {
  if [[ "$VERBOSE" == true ]]; then
    echo "[resolve-profile] $*" >&2
  fi
}

# Validate target directory exists
if [[ ! -d "$DIR" ]]; then
  echo "Error: directory does not exist: $DIR" >&2
  exit 1
fi

log "Scanning directory: $DIR"

# ---------------------------------------------------------------------------
# Step 1: Check explicit config
# If .atelier/config.yaml exists and declares a profile, use it directly.
# This allows projects to override auto-detection.
# ---------------------------------------------------------------------------
if [[ -f "$DIR/.atelier/config.yaml" ]]; then
  log "Found .atelier/config.yaml, checking for explicit profile"
  PROFILE=$(grep -E '^\s*profile:\s*' "$DIR/.atelier/config.yaml" | head -1 | sed 's/.*profile:\s*//' | tr -d ' "'"'"'')
  if [[ -n "$PROFILE" ]]; then
    log "Found explicit profile in .atelier/config.yaml: $PROFILE"
    echo "$PROFILE"
    exit 0
  fi
  log "No profile field found in .atelier/config.yaml, falling through to auto-detection"
fi

# ---------------------------------------------------------------------------
# Step 2: python-fastapi
# pyproject.toml exists AND contains "fastapi" (case-insensitive)
# ---------------------------------------------------------------------------
if [[ -f "$DIR/pyproject.toml" ]]; then
  log "Found pyproject.toml, checking for fastapi dependency"
  if grep -qi "fastapi" "$DIR/pyproject.toml" 2>/dev/null; then
    log "Detected: pyproject.toml contains 'fastapi'"
    echo "python-fastapi"
    exit 0
  fi
  log "pyproject.toml exists but does not contain 'fastapi'"
fi

# ---------------------------------------------------------------------------
# Step 3: flutter-dart
# pubspec.yaml exists (standard Flutter/Dart project marker)
# ---------------------------------------------------------------------------
if [[ -f "$DIR/pubspec.yaml" ]]; then
  log "Detected: pubspec.yaml exists"
  echo "flutter-dart"
  exit 0
fi

# ---------------------------------------------------------------------------
# Step 4: react-typescript
# package.json exists AND contains "react" AND (tsconfig.json exists OR
# package.json contains "typescript")
# ---------------------------------------------------------------------------
if [[ -f "$DIR/package.json" ]]; then
  log "Found package.json, checking for react + typescript"
  if grep -q '"react"' "$DIR/package.json" 2>/dev/null; then
    if [[ -f "$DIR/tsconfig.json" ]] || grep -q '"typescript"' "$DIR/package.json" 2>/dev/null; then
      log "Detected: package.json with react + typescript"
      echo "react-typescript"
      exit 0
    fi
    log "package.json has react but no typescript indicator"
  fi
fi

# ---------------------------------------------------------------------------
# Step 5: opentofu-hcl
# Any *.tf file exists in the directory
# ---------------------------------------------------------------------------
if compgen -G "$DIR/*.tf" > /dev/null 2>&1; then
  log "Detected: *.tf files exist"
  echo "opentofu-hcl"
  exit 0
fi

# ---------------------------------------------------------------------------
# No match found
# ---------------------------------------------------------------------------
log "No profile detected in: $DIR"
log "Checked: .atelier/config.yaml (explicit), pyproject.toml (fastapi), pubspec.yaml, package.json (react+ts), *.tf"
echo "unknown" >&2
exit 1
