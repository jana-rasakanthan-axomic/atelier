#!/usr/bin/env bash
# Session state manager for worktree-based commands and session persistence
#
# Worktree session commands (stored in .claude/sessions.json):
#   session-manager.sh create <session-id> <branch-name> <context-file> <command>
#   session-manager.sh get <session-id>
#   session-manager.sh update <session-id> <key> <value>
#   session-manager.sh list
#   session-manager.sh delete <session-id>
#   session-manager.sh cleanup-old <days>
#
# Persistent session commands (stored in .atelier/sessions/<id>.json):
#   session-manager.sh save [session_id]      Capture current session state
#   session-manager.sh resume <session_id>    Print session state for LLM consumption
#   session-manager.sh list-saved             List all saved sessions
#   session-manager.sh clean [--older-than N] Remove old session files (default 30 days)

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-.claude}"
SESSIONS_FILE="$CLAUDE_DIR/sessions.json"
ATELIER_DIR="${ATELIER_DIR:-.atelier}"
SAVED_SESSIONS_DIR="$ATELIER_DIR/sessions"

# Ensure Claude directory exists
mkdir -p "$CLAUDE_DIR"

# Ensure sessions file exists
if [[ ! -f "$SESSIONS_FILE" ]]; then
  echo "{}" > "$SESSIONS_FILE"
fi

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq not found. Install: brew install jq" >&2
  exit 1
fi

# Helper: log to stderr
log() {
  echo "[session-manager] $*" >&2
}

# Helper: generate ISO-8601 timestamp
timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Helper: generate default session ID from date and feature/branch
generate_session_id() {
  local date_part branch_part
  date_part=$(date +"%Y-%m-%d")
  branch_part=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-branch")
  echo "${date_part}_${branch_part}"
}

cmd="${1:-}"
session_id="${2:-}"

usage() {
  cat <<EOF
Usage: session-manager.sh <command> [args]

Worktree Session Commands:
  create <sid> <branch> <context> <command>   Create new worktree session
  get <session-id>                            Get worktree session details
  update <session-id> <key> <value>           Update worktree session field
  list                                        List all worktree sessions
  delete <session-id>                         Delete worktree session
  cleanup-old <days>                          Delete worktree sessions older than N days

Persistent Session Commands:
  save [session_id]                           Save current session state to .atelier/sessions/
  resume <session_id>                         Print saved session state for LLM consumption
  list-saved                                  List all saved sessions with date, feature, phase
  clean [--older-than N]                      Remove saved sessions older than N days (default 30)

Examples:
  session-manager.sh create abc-123 feature-branch context.md /build
  session-manager.sh get abc-123
  session-manager.sh update abc-123 status completed
  session-manager.sh list
  session-manager.sh delete abc-123
  session-manager.sh cleanup-old 7

  session-manager.sh save
  session-manager.sh save 2026-02-15_feature-auth
  session-manager.sh resume 2026-02-15_feature-auth
  session-manager.sh list-saved
  session-manager.sh clean --older-than 14
EOF
}

case "$cmd" in
  create)
    if [[ $# -lt 5 ]]; then
      echo "Error: create requires session-id, branch-name, context-file, and command" >&2
      usage
      exit 1
    fi

    branch_name="$3"
    context_file="${4:-}"
    command="${5:-}"

    # Create session entry
    jq --arg sid "$session_id" \
       --arg branch "$branch_name" \
       --arg context "$context_file" \
       --arg cmd "$command" \
       --arg created "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.[$sid] = {
         "branch": $branch,
         "context_file": $context,
         "command": $cmd,
         "created_at": $created,
         "updated_at": $created,
         "status": "active",
         "worktree_path": null
       }' "$SESSIONS_FILE" > "${SESSIONS_FILE}.tmp"

    mv "${SESSIONS_FILE}.tmp" "$SESSIONS_FILE"
    echo "Session $session_id created"
    ;;

  get)
    if [[ -z "$session_id" ]]; then
      echo "Error: get requires session-id" >&2
      usage
      exit 1
    fi

    jq --arg sid "$session_id" '.[$sid] // empty' "$SESSIONS_FILE"

    if ! jq -e --arg sid "$session_id" '.[$sid]' "$SESSIONS_FILE" > /dev/null; then
      echo "Error: Session not found: $session_id" >&2
      exit 1
    fi
    ;;

  update)
    if [[ $# -lt 4 ]]; then
      echo "Error: update requires session-id, key, and value" >&2
      usage
      exit 1
    fi

    key="$3"
    value="$4"

    # Check if session exists
    if ! jq -e --arg sid "$session_id" '.[$sid]' "$SESSIONS_FILE" > /dev/null; then
      echo "Error: Session not found: $session_id" >&2
      exit 1
    fi

    jq --arg sid "$session_id" \
       --arg k "$key" \
       --arg v "$value" \
       --arg updated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.[$sid][$k] = $v | .[$sid].updated_at = $updated' "$SESSIONS_FILE" > "${SESSIONS_FILE}.tmp"

    mv "${SESSIONS_FILE}.tmp" "$SESSIONS_FILE"
    echo "Session $session_id updated: $key = $value"
    ;;

  list)
    echo "Active Sessions:"
    echo "================"

    # Check if there are any sessions
    if [[ "$(jq 'length' "$SESSIONS_FILE")" -eq 0 ]]; then
      echo "(no active sessions)"
      exit 0
    fi

    jq -r '
      to_entries[] |
      "ID: \(.key)\n  Branch: \(.value.branch)\n  Status: \(.value.status)\n  Command: \(.value.command)\n  Created: \(.value.created_at)\n"
    ' "$SESSIONS_FILE"
    ;;

  delete)
    if [[ -z "$session_id" ]]; then
      echo "Error: delete requires session-id" >&2
      usage
      exit 1
    fi

    # Check if session exists
    if ! jq -e --arg sid "$session_id" '.[$sid]' "$SESSIONS_FILE" > /dev/null; then
      echo "Warning: Session not found: $session_id" >&2
      exit 0
    fi

    jq --arg sid "$session_id" 'del(.[$sid])' "$SESSIONS_FILE" > "${SESSIONS_FILE}.tmp"
    mv "${SESSIONS_FILE}.tmp" "$SESSIONS_FILE"
    echo "Session $session_id deleted"
    ;;

  cleanup-old)
    days="${2:-7}"

    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
      echo "Error: days must be a number" >&2
      exit 1
    fi

    cutoff_date=$(date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "${days} days ago" +"%Y-%m-%dT%H:%M:%SZ")

    echo "Cleaning up sessions older than $days days (before $cutoff_date)..."

    # Get sessions older than cutoff
    old_sessions=$(jq -r --arg cutoff "$cutoff_date" '
      to_entries[] |
      select(.value.created_at < $cutoff) |
      .key
    ' "$SESSIONS_FILE")

    if [[ -z "$old_sessions" ]]; then
      echo "No old sessions found"
      exit 0
    fi

    count=0
    while IFS= read -r sid; do
      jq --arg sid "$sid" 'del(.[$sid])' "$SESSIONS_FILE" > "${SESSIONS_FILE}.tmp"
      mv "${SESSIONS_FILE}.tmp" "$SESSIONS_FILE"
      echo "  Deleted: $sid"
      count=$((count + 1))
    done <<< "$old_sessions"

    echo "Cleaned up $count old session(s)"
    ;;

  # ─── Persistent session commands ──────────────────────────────────────────

  save)
    # Generate session ID if not provided
    if [[ -z "$session_id" ]]; then
      session_id=$(generate_session_id)
    fi

    mkdir -p "$SAVED_SESSIONS_DIR"
    session_file="$SAVED_SESSIONS_DIR/${session_id}.json"

    # Collect git state
    git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    last_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "")
    uncommitted_count=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

    # Collect atelier state from .atelier/state.json
    state_file="$ATELIER_DIR/state.json"
    if [[ -f "$state_file" ]]; then
      phase=$(jq -r '.phase // ""' "$state_file")
      feature=$(jq -r '.feature // ""' "$state_file")
      locked_files=$(jq -c '.locked_files // []' "$state_file")
    else
      phase=""
      feature=""
      locked_files="[]"
    fi

    # Collect workstream state if present
    workstream_file=".claude/workstreams/status.json"
    if [[ -f "$workstream_file" ]]; then
      workstream=$(jq -c '.' "$workstream_file")
    else
      workstream="null"
    fi

    # Accept optional notes from stdin or remaining args
    notes="${3:-}"

    # Build session JSON
    jq -n \
      --arg sid "$session_id" \
      --arg saved_at "$(timestamp)" \
      --arg phase "$phase" \
      --arg feature "$feature" \
      --arg branch "$git_branch" \
      --arg last_commit "$last_commit" \
      --argjson uncommitted_files "$uncommitted_count" \
      --argjson locked_files "$locked_files" \
      --argjson workstream "$workstream" \
      --arg notes "$notes" \
      '{
        "session_id": $sid,
        "saved_at": $saved_at,
        "phase": $phase,
        "feature": $feature,
        "branch": $branch,
        "last_commit": $last_commit,
        "uncommitted_files": $uncommitted_files,
        "locked_files": $locked_files,
        "workstream": $workstream,
        "notes": $notes
      }' > "$session_file"

    log "Session saved: $session_file"
    echo "Session '$session_id' saved to $session_file"
    ;;

  resume)
    if [[ -z "$session_id" ]]; then
      echo "Error: resume requires a session_id" >&2
      usage
      exit 1
    fi

    session_file="$SAVED_SESSIONS_DIR/${session_id}.json"

    if [[ ! -f "$session_file" ]]; then
      echo "Error: Session file not found: $session_file" >&2
      echo "Run 'session-manager.sh list-saved' to see available sessions." >&2
      exit 1
    fi

    # Print header for LLM consumption
    echo "=== Session Resume: $session_id ==="
    echo ""

    # Extract and format session state
    phase=$(jq -r '.phase // "unknown"' "$session_file")
    feature=$(jq -r '.feature // "none"' "$session_file")
    branch=$(jq -r '.branch // "none"' "$session_file")
    last_commit=$(jq -r '.last_commit // "none"' "$session_file")
    uncommitted=$(jq -r '.uncommitted_files // 0' "$session_file")
    saved_at=$(jq -r '.saved_at // "unknown"' "$session_file")
    notes=$(jq -r '.notes // ""' "$session_file")

    echo "Phase:            $phase"
    echo "Feature:          $feature"
    echo "Branch:           $branch"
    echo "Last commit:      $last_commit"
    echo "Uncommitted:      $uncommitted file(s)"
    echo "Saved at:         $saved_at"

    if [[ -n "$notes" ]]; then
      echo "Notes:            $notes"
    fi

    # Show locked files if any
    locked_count=$(jq '.locked_files | length' "$session_file")
    if [[ "$locked_count" -gt 0 ]]; then
      echo ""
      echo "Locked files:"
      jq -r '.locked_files[] | "  - " + .' "$session_file"
    fi

    # Show workstream status if present
    has_workstream=$(jq 'if .workstream == null then "no" else "yes" end' "$session_file" | tr -d '"')
    if [[ "$has_workstream" == "yes" ]]; then
      echo ""
      echo "Workstream state:"
      jq '.workstream' "$session_file"
    fi

    # Show files modified since last saved commit
    saved_commit=$(jq -r '.last_commit // ""' "$session_file")
    if [[ -n "$saved_commit" ]] && git rev-parse --verify "$saved_commit" &>/dev/null; then
      modified_files=$(git diff --name-only "$saved_commit"..HEAD 2>/dev/null || true)
      if [[ -n "$modified_files" ]]; then
        echo ""
        echo "Files modified since last session:"
        echo "$modified_files" | while IFS= read -r f; do
          echo "  - $f"
        done
      fi
    fi

    echo ""
    echo "=== End Session ==="
    ;;

  list-saved)
    if [[ ! -d "$SAVED_SESSIONS_DIR" ]]; then
      echo "No saved sessions found."
      echo "(Directory $SAVED_SESSIONS_DIR does not exist)"
      exit 0
    fi

    # Collect session files
    session_files=("$SAVED_SESSIONS_DIR"/*.json)
    if [[ ! -f "${session_files[0]:-}" ]]; then
      echo "No saved sessions found."
      exit 0
    fi

    echo "Saved Sessions:"
    echo "================"
    printf "%-35s %-12s %-20s %-25s\n" "SESSION ID" "PHASE" "FEATURE" "BRANCH"
    printf "%-35s %-12s %-20s %-25s\n" "----------" "-----" "-------" "------"

    for sf in "${session_files[@]}"; do
      if [[ -f "$sf" ]]; then
        sid=$(jq -r '.session_id // "unknown"' "$sf")
        phase=$(jq -r '.phase // ""' "$sf")
        feature=$(jq -r '.feature // ""' "$sf")
        branch=$(jq -r '.branch // ""' "$sf")
        saved_at=$(jq -r '.saved_at // ""' "$sf")

        # Truncate long values for display
        printf "%-35s %-12s %-20s %-25s\n" \
          "${sid:0:35}" \
          "${phase:0:12}" \
          "${feature:0:20}" \
          "${branch:0:25}"
      fi
    done

    echo ""
    echo "Total: ${#session_files[@]} session(s)"
    ;;

  clean)
    shift
    days=30

    # Parse --older-than flag
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --older-than)
          if [[ $# -lt 2 ]]; then
            echo "Error: --older-than requires a number of days" >&2
            exit 1
          fi
          days="$2"
          shift 2
          ;;
        *)
          echo "Error: Unknown option: $1" >&2
          echo "Usage: session-manager.sh clean [--older-than N]" >&2
          exit 1
          ;;
      esac
    done

    if ! [[ "$days" =~ ^[0-9]+$ ]]; then
      echo "Error: days must be a positive integer" >&2
      exit 1
    fi

    if [[ ! -d "$SAVED_SESSIONS_DIR" ]]; then
      echo "No saved sessions directory found. Nothing to clean."
      exit 0
    fi

    # Calculate cutoff date (macOS and GNU compatible)
    cutoff_date=$(date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "${days} days ago" +"%Y-%m-%dT%H:%M:%SZ")

    echo "Cleaning saved sessions older than $days days (before $cutoff_date)..."

    count=0
    for sf in "$SAVED_SESSIONS_DIR"/*.json; do
      if [[ ! -f "$sf" ]]; then
        continue
      fi

      saved_at=$(jq -r '.saved_at // ""' "$sf")
      if [[ -z "$saved_at" ]]; then
        continue
      fi

      # String comparison works for ISO-8601 timestamps
      if [[ "$saved_at" < "$cutoff_date" ]]; then
        sid=$(jq -r '.session_id // "unknown"' "$sf")
        rm -f "$sf"
        echo "  Deleted: $sid"
        count=$((count + 1))
      fi
    done

    if [[ "$count" -eq 0 ]]; then
      echo "No old sessions found."
    else
      echo "Cleaned up $count session(s)."
    fi
    ;;

  -h|--help)
    usage
    exit 0
    ;;

  *)
    echo "Error: Unknown command: $cmd" >&2
    usage
    exit 1
    ;;
esac
