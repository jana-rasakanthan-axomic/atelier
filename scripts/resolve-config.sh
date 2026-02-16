#!/usr/bin/env bash
# Atelier Config Resolver
# Resolves configuration from project, user, and auto-detection sources.
# XDG-compliant: user config lives at ~/.config/atelier/config.yaml
#
# Usage:
#   resolve-config.sh get <key>              Get a config value
#   resolve-config.sh set <key> <value>      Set a user-level config value
#   resolve-config.sh show                   Show resolved config with sources
#   resolve-config.sh init-global            Create ~/.config/atelier/config.yaml
#
# Resolution order (highest to lowest priority):
#   1. Project:     .atelier/config.yaml
#   2. User:        ~/.config/atelier/config.yaml
#   3. Auto-detect: Marker files (via resolve-profile.sh)
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments, missing dependency, or key not found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_CONFIG_DIR="$XDG_CONFIG_HOME/atelier"
USER_CONFIG_FILE="$USER_CONFIG_DIR/config.yaml"
PROJECT_CONFIG_FILE=".atelier/config.yaml"

# Helper: log to stderr
log() {
  echo "[resolve-config] $*" >&2
}

# Check for required tools
for tool in grep sed; do
  if ! command -v "$tool" &> /dev/null; then
    echo "Error: $tool not found." >&2
    exit 1
  fi
done

usage() {
  cat <<EOF
Usage: resolve-config.sh <command> [args]

Commands:
  get <key>              Get a resolved config value (project > user > auto)
  set <key> <value>      Set a user-level config value (~/.config/atelier/config.yaml)
  show                   Show resolved config with source for each value
  init-global            Create ~/.config/atelier/config.yaml with defaults

Supported keys:
  profile                Default development profile
  default_model          Preferred Claude model
  output_dir             Directory for worklogs
  session_dir            Directory for session files
  git.initials           Initials for branch naming
  git.auto_worktree      Auto-create worktrees (true/false)
  daily_brief.output_dir Output directory for daily briefs
  daily_brief.level      Default engineer level (ic/senior/staff)
  daily_brief.repos      GitHub repos to monitor (comma-separated)
  daily_brief.editor     Editor command to open briefs

Resolution order (highest priority first):
  1. Project (.atelier/config.yaml)
  2. User   (~/.config/atelier/config.yaml)
  3. Auto   (marker file detection)

Examples:
  resolve-config.sh get profile
  resolve-config.sh set git.initials jr
  resolve-config.sh show
  resolve-config.sh init-global
EOF
}

# ---------------------------------------------------------------------------
# Read a value from a YAML file (simple flat + one-level nested keys)
# Usage: yaml_get <file> <key>
# For nested keys like "git.initials", reads the "initials" field under "git:"
# ---------------------------------------------------------------------------
yaml_get() {
  local file="$1"
  local key="$2"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  if [[ "$key" == *.* ]]; then
    # Nested key: e.g., git.initials -> find "initials:" under "git:" section
    local parent="${key%%.*}"
    local child="${key#*.}"
    local in_section=false

    while IFS= read -r line; do
      # Skip comments and empty lines
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ -z "${line// /}" ]] && continue

      # Check if we entered the parent section
      if [[ "$line" =~ ^${parent}:[[:space:]]*$ ]]; then
        in_section=true
        continue
      fi

      # If we are in the section and line is indented, check for child key
      if [[ "$in_section" == true ]]; then
        if [[ "$line" =~ ^[[:space:]]+${child}:[[:space:]]*(.*) ]]; then
          local value="${BASH_REMATCH[1]}"
          # Strip inline comments and surrounding quotes
          value=$(echo "$value" | sed 's/[[:space:]]*#.*$//' | sed "s/^['\"]//;s/['\"]$//")
          echo "$value"
          return 0
        fi
        # If line is not indented, we left the section
        if [[ ! "$line" =~ ^[[:space:]] ]]; then
          in_section=false
        fi
      fi
    done < "$file"
  else
    # Top-level key: e.g., profile
    while IFS= read -r line; do
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      [[ -z "${line// /}" ]] && continue

      if [[ "$line" =~ ^${key}:[[:space:]]*(.*) ]]; then
        local value="${BASH_REMATCH[1]}"
        # Strip inline comments and surrounding quotes
        value=$(echo "$value" | sed 's/[[:space:]]*#.*$//' | sed "s/^['\"]//;s/['\"]$//")
        echo "$value"
        return 0
      fi
    done < "$file"
  fi

  return 1
}

# ---------------------------------------------------------------------------
# Write a value to the user config file
# Usage: yaml_set <file> <key> <value>
# ---------------------------------------------------------------------------
yaml_set() {
  local file="$1"
  local key="$2"
  local value="$3"

  # Ensure directory exists
  mkdir -p "$(dirname "$file")"

  # Create file if it does not exist
  if [[ ! -f "$file" ]]; then
    cat "$SCRIPT_DIR/../templates/user-config.yaml" > "$file" 2>/dev/null || touch "$file"
  fi

  if [[ "$key" == *.* ]]; then
    local parent="${key%%.*}"
    local child="${key#*.}"

    # Check if parent section exists
    if grep -q "^${parent}:" "$file"; then
      # Check if child key exists in section
      if grep -q "^[[:space:]]*${child}:" "$file"; then
        # Replace existing value
        sed -i.bak "s/^\([[:space:]]*${child}:\).*/\1 ${value}/" "$file"
        rm -f "${file}.bak"
      else
        # Add child under parent section
        sed -i.bak "/^${parent}:/a\\
  ${child}: ${value}" "$file"
        rm -f "${file}.bak"
      fi
    else
      # Add parent section and child
      printf '\n%s:\n  %s: %s\n' "$parent" "$child" "$value" >> "$file"
    fi
  else
    # Top-level key
    if grep -q "^${key}:" "$file"; then
      sed -i.bak "s/^${key}:.*/${key}: ${value}/" "$file"
      rm -f "${file}.bak"
    elif grep -q "^# *${key}:" "$file"; then
      # Uncomment and set
      sed -i.bak "s/^# *${key}:.*/${key}: ${value}/" "$file"
      rm -f "${file}.bak"
    else
      printf '%s: %s\n' "$key" "$value" >> "$file"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Auto-detect a config value from environment
# Currently only supports "profile" via resolve-profile.sh
# ---------------------------------------------------------------------------
auto_detect() {
  local key="$1"

  case "$key" in
    profile)
      if [[ -x "$SCRIPT_DIR/resolve-profile.sh" ]]; then
        "$SCRIPT_DIR/resolve-profile.sh" 2>/dev/null || true
      fi
      ;;
    output_dir)
      echo "$USER_CONFIG_DIR/logs"
      ;;
    session_dir)
      echo "$USER_CONFIG_DIR/sessions"
      ;;
    daily_brief.output_dir)
      echo "$HOME/worklogs/daily-briefs"
      ;;
    daily_brief.level)
      echo "senior"
      ;;
    daily_brief.editor)
      echo "code"
      ;;
    *)
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Resolve a key: project > user > auto-detect
# Prints: value
# Returns: 0 if found, 1 if not
# ---------------------------------------------------------------------------
resolve_value() {
  local key="$1"
  local value=""

  # 1. Project config
  if value=$(yaml_get "$PROJECT_CONFIG_FILE" "$key" 2>/dev/null) && [[ -n "$value" ]]; then
    echo "$value"
    return 0
  fi

  # 2. User config
  if value=$(yaml_get "$USER_CONFIG_FILE" "$key" 2>/dev/null) && [[ -n "$value" ]]; then
    echo "$value"
    return 0
  fi

  # 3. Auto-detect
  if value=$(auto_detect "$key" 2>/dev/null) && [[ -n "$value" ]]; then
    echo "$value"
    return 0
  fi

  return 1
}

# ---------------------------------------------------------------------------
# Resolve a key and return its source
# Prints: source (project|user|auto|<none>)
# ---------------------------------------------------------------------------
resolve_source() {
  local key="$1"
  local value=""

  if value=$(yaml_get "$PROJECT_CONFIG_FILE" "$key" 2>/dev/null) && [[ -n "$value" ]]; then
    echo "project"
    return 0
  fi

  if value=$(yaml_get "$USER_CONFIG_FILE" "$key" 2>/dev/null) && [[ -n "$value" ]]; then
    echo "user"
    return 0
  fi

  if value=$(auto_detect "$key" 2>/dev/null) && [[ -n "$value" ]]; then
    echo "auto"
    return 0
  fi

  echo "<none>"
  return 1
}

# ---------------------------------------------------------------------------
# Subcommand dispatch
# ---------------------------------------------------------------------------
cmd="${1:-}"

case "$cmd" in
  get)
    if [[ $# -lt 2 ]]; then
      echo "Error: get requires a <key> argument" >&2
      usage
      exit 1
    fi

    key="$2"
    if value=$(resolve_value "$key"); then
      echo "$value"
    else
      echo "Error: Key '$key' not found in any config source" >&2
      exit 1
    fi
    ;;

  set)
    if [[ $# -lt 3 ]]; then
      echo "Error: set requires <key> and <value> arguments" >&2
      usage
      exit 1
    fi

    key="$2"
    value="$3"

    yaml_set "$USER_CONFIG_FILE" "$key" "$value"
    log "Set $key = $value in $USER_CONFIG_FILE"
    ;;

  show)
    ALL_KEYS=(profile default_model output_dir session_dir git.initials git.auto_worktree daily_brief.output_dir daily_brief.level daily_brief.repos daily_brief.editor)

    printf "%-22s %-30s %s\n" "KEY" "VALUE" "SOURCE"
    printf "%-22s %-30s %s\n" "---" "-----" "------"

    for key in "${ALL_KEYS[@]}"; do
      value=$(resolve_value "$key" 2>/dev/null) || value="<not set>"
      source=$(resolve_source "$key" 2>/dev/null) || source="<none>"
      printf "%-22s %-30s %s\n" "$key" "$value" "$source"
    done

    echo ""
    echo "Config files:"
    if [[ -f "$PROJECT_CONFIG_FILE" ]]; then
      echo "  project: $PROJECT_CONFIG_FILE"
    else
      echo "  project: (not found)"
    fi
    if [[ -f "$USER_CONFIG_FILE" ]]; then
      echo "  user:    $USER_CONFIG_FILE"
    else
      echo "  user:    (not found)"
    fi
    ;;

  init-global)
    if [[ -f "$USER_CONFIG_FILE" ]]; then
      echo "User config already exists: $USER_CONFIG_FILE"
      echo "Use 'resolve-config.sh set <key> <value>' to update individual values."
      exit 0
    fi

    mkdir -p "$USER_CONFIG_DIR"
    mkdir -p "$USER_CONFIG_DIR/logs"
    mkdir -p "$USER_CONFIG_DIR/sessions"

    # Copy template
    TEMPLATE="$SCRIPT_DIR/../templates/user-config.yaml"
    if [[ -f "$TEMPLATE" ]]; then
      cp "$TEMPLATE" "$USER_CONFIG_FILE"
    else
      # Fallback: create minimal config
      cat > "$USER_CONFIG_FILE" <<'YAML'
# Atelier user-level configuration
# Overridden by project-level .atelier/config.yaml
profile: ""
default_model: sonnet
output_dir: ~/.config/atelier/logs
session_dir: ~/.config/atelier/sessions
git:
  initials: ""
  auto_worktree: true
YAML
    fi

    log "Created user config: $USER_CONFIG_FILE"
    log "Created directories: $USER_CONFIG_DIR/{logs,sessions}"
    echo "User config initialized: $USER_CONFIG_FILE"
    echo ""
    echo "Next steps:"
    echo "  1. Set your initials:  resolve-config.sh set git.initials <YOUR_INITIALS>"
    echo "  2. Set your profile:   resolve-config.sh set profile <PROFILE_NAME>"
    echo "  3. Verify:             resolve-config.sh show"
    ;;

  -h|--help)
    usage
    exit 0
    ;;

  *)
    echo "Error: Unknown command: ${cmd:-<none>}" >&2
    usage
    exit 1
    ;;
esac
