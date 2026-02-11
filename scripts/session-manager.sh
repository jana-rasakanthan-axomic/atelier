#!/usr/bin/env bash
# Session state manager for worktree-based commands
# Usage:
#   session-manager.sh create <session-id> <branch-name> <context-file> <command>
#   session-manager.sh get <session-id>
#   session-manager.sh update <session-id> <key> <value>
#   session-manager.sh list
#   session-manager.sh delete <session-id>

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-.claude}"
SESSIONS_FILE="$CLAUDE_DIR/sessions.json"

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

cmd="${1:-}"
session_id="${2:-}"

usage() {
  cat <<EOF
Usage: session-manager.sh <command> [args]

Commands:
  create <sid> <branch> <context> <command>   Create new session
  get <session-id>                            Get session details
  update <session-id> <key> <value>           Update session field
  list                                        List all sessions
  delete <session-id>                         Delete session
  cleanup-old <days>                          Delete sessions older than N days

Examples:
  session-manager.sh create abc-123 feature-branch context.md /build
  session-manager.sh get abc-123
  session-manager.sh update abc-123 status completed
  session-manager.sh list
  session-manager.sh delete abc-123
  session-manager.sh cleanup-old 7
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
