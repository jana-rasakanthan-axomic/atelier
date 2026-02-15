#!/usr/bin/env bash
# Atelier State Manager
# Manages workflow phase state in .atelier/state.json.
#
# Usage:
#   state_manager.sh init [--feature NAME]        Initialize state file
#   state_manager.sh transition PHASE             Move to a new phase
#   state_manager.sh status                       Print current state summary
#   state_manager.sh lock FILE...                 Add files to locked_files
#   state_manager.sh unlock FILE...               Remove files from locked_files
#   state_manager.sh get FIELD                    Get a specific field value
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments, invalid transition, or missing state file

set -euo pipefail

STATE_DIR="${ATELIER_DIR:-.atelier}"
STATE_FILE="$STATE_DIR/state.json"

VALID_PHASES=(gather specify design plan build review deploy)

# Helper: log to stderr
log() {
  echo "[state-manager] $*" >&2
}

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq not found. Install: brew install jq" >&2
  exit 1
fi

usage() {
  cat <<EOF
Usage: state_manager.sh <command> [args]

Commands:
  init [--feature NAME]        Create .atelier/state.json with initial state
  transition PHASE             Move to a new phase (validates allowed transitions)
  status                       Print current phase, feature, locked files count
  lock FILE...                 Add file paths to locked_files array
  unlock FILE...               Remove file paths from locked_files array
  get FIELD                    Get a field value (phase, feature, locked_files)

Valid phases (in order):
  gather -> specify -> design -> plan -> build -> review -> deploy

Transitions: forward to the next phase, or backward to any previous phase.

Examples:
  state_manager.sh init --feature user-auth
  state_manager.sh transition specify
  state_manager.sh status
  state_manager.sh lock src/auth.py src/models.py
  state_manager.sh unlock src/auth.py
  state_manager.sh get phase
EOF
}

# Validate that a phase name is one of the valid phases
validate_phase() {
  local phase="$1"
  for valid in "${VALID_PHASES[@]}"; do
    if [[ "$phase" == "$valid" ]]; then
      return 0
    fi
  done
  echo "Error: Invalid phase '$phase'. Valid phases: ${VALID_PHASES[*]}" >&2
  exit 1
}

# Get the index of a phase in the VALID_PHASES array (0-based)
phase_index() {
  local phase="$1"
  for i in "${!VALID_PHASES[@]}"; do
    if [[ "${VALID_PHASES[$i]}" == "$phase" ]]; then
      echo "$i"
      return
    fi
  done
  echo "-1"
}

# Require state file to exist
require_state() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "Error: State file not found: $STATE_FILE" >&2
    echo "Run 'state_manager.sh init' first." >&2
    exit 1
  fi
}

# Generate ISO-8601 timestamp
timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

cmd="${1:-}"

case "$cmd" in
  init)
    shift
    feature=""

    while [[ $# -gt 0 ]]; do
      case $1 in
        --feature)
          if [[ $# -lt 2 ]]; then
            echo "Error: --feature requires a value" >&2
            exit 1
          fi
          feature="$2"
          shift 2
          ;;
        *)
          echo "Error: Unknown option: $1" >&2
          usage
          exit 1
          ;;
      esac
    done

    mkdir -p "$STATE_DIR"

    jq -n \
      --arg feature "$feature" \
      --arg updated "$(timestamp)" \
      '{
        "version": 1,
        "phase": "gather",
        "feature": $feature,
        "locked_files": [],
        "updated_at": $updated
      }' > "$STATE_FILE"

    log "Initialized state: phase=gather feature=${feature:-<none>}"
    ;;

  transition)
    if [[ $# -lt 2 ]]; then
      echo "Error: transition requires a PHASE argument" >&2
      usage
      exit 1
    fi
    require_state

    target="$2"
    validate_phase "$target"

    current=$(jq -r '.phase' "$STATE_FILE")
    current_idx=$(phase_index "$current")
    target_idx=$(phase_index "$target")

    # Allowed: forward by exactly one step, or backward to any previous phase
    if [[ "$target_idx" -eq $((current_idx + 1)) ]] || [[ "$target_idx" -lt "$current_idx" ]]; then
      jq --arg phase "$target" --arg updated "$(timestamp)" \
        '.phase = $phase | .updated_at = $updated' "$STATE_FILE" > "${STATE_FILE}.tmp"
      mv "${STATE_FILE}.tmp" "$STATE_FILE"
      log "Transition: $current -> $target"
    else
      echo "Error: Invalid transition from '$current' to '$target'" >&2
      echo "Allowed: next phase '${VALID_PHASES[$((current_idx + 1))]:-<none>}' or any earlier phase" >&2
      exit 1
    fi
    ;;

  status)
    require_state

    phase=$(jq -r '.phase' "$STATE_FILE")
    feature=$(jq -r '.feature' "$STATE_FILE")
    locked_count=$(jq '.locked_files | length' "$STATE_FILE")
    updated=$(jq -r '.updated_at' "$STATE_FILE")

    echo "Phase:        $phase"
    echo "Feature:      ${feature:-<none>}"
    echo "Locked files: $locked_count"
    echo "Updated:      $updated"
    ;;

  lock)
    shift
    if [[ $# -lt 1 ]]; then
      echo "Error: lock requires at least one FILE argument" >&2
      usage
      exit 1
    fi
    require_state

    # Build a jq args array from the file arguments
    jq_args=()
    for f in "$@"; do
      jq_args+=(--arg "f_${#jq_args[@]}" "$f")
    done

    # Add each file if not already present
    cp "$STATE_FILE" "${STATE_FILE}.tmp"
    for f in "$@"; do
      jq --arg file "$f" --arg updated "$(timestamp)" \
        'if (.locked_files | index($file)) then . else .locked_files += [$file] | .updated_at = $updated end' \
        "${STATE_FILE}.tmp" > "${STATE_FILE}.tmp2"
      mv "${STATE_FILE}.tmp2" "${STATE_FILE}.tmp"
    done
    mv "${STATE_FILE}.tmp" "$STATE_FILE"

    log "Locked: $*"
    ;;

  unlock)
    shift
    if [[ $# -lt 1 ]]; then
      echo "Error: unlock requires at least one FILE argument" >&2
      usage
      exit 1
    fi
    require_state

    cp "$STATE_FILE" "${STATE_FILE}.tmp"
    for f in "$@"; do
      jq --arg file "$f" --arg updated "$(timestamp)" \
        '.locked_files -= [$file] | .updated_at = $updated' \
        "${STATE_FILE}.tmp" > "${STATE_FILE}.tmp2"
      mv "${STATE_FILE}.tmp2" "${STATE_FILE}.tmp"
    done
    mv "${STATE_FILE}.tmp" "$STATE_FILE"

    log "Unlocked: $*"
    ;;

  get)
    if [[ $# -lt 2 ]]; then
      echo "Error: get requires a FIELD argument (phase, feature, locked_files)" >&2
      usage
      exit 1
    fi
    require_state

    field="$2"
    case "$field" in
      phase|feature|updated_at|version)
        jq -r ".$field" "$STATE_FILE"
        ;;
      locked_files)
        jq -r '.locked_files[]' "$STATE_FILE"
        ;;
      *)
        echo "Error: Unknown field '$field'. Valid: phase, feature, locked_files, version, updated_at" >&2
        exit 1
        ;;
    esac
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
