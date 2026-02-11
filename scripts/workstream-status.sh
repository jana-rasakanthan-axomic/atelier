#!/usr/bin/env bash
# Workstream status manager for tracking ticket progress
# Usage:
#   workstream-status.sh init                                  # Initialize status.json
#   workstream-status.sh update <ticket-id> <key> <value>      # Update a ticket field
#   workstream-status.sh get <ticket-id>                       # Get ticket status
#   workstream-status.sh get-plannable [scope]                 # List tickets ready for planning
#   workstream-status.sh get-buildable [scope]                 # List tickets ready for building
#   workstream-status.sh get-blockers <ticket-id>              # Get blocking ticket IDs
#   workstream-status.sh list                                  # Show all tickets and status

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-.claude}"
STATUS_FILE="$CLAUDE_DIR/workstreams/status.json"
WORKSTREAMS_DOC="$CLAUDE_DIR/tickets/WORKSTREAMS.md"

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq not found. Install: brew install jq" >&2
  exit 1
fi

cmd="${1:-}"

usage() {
  cat <<EOF
Usage: workstream-status.sh <command> [args]

Commands:
  init                                  Initialize status.json
  update <ticket-id> <key> <value>      Update a ticket field (dot-path notation)
  get <ticket-id>                       Get ticket status
  get-plannable [scope]                 List tickets ready for planning
  get-buildable [scope]                 List tickets ready for building
  get-blockers <ticket-id>              Get blocking ticket IDs
  list                                  Show all tickets and status

Examples:
  workstream-status.sh init
  workstream-status.sh update PROJ-101 build.status completed
  workstream-status.sh get PROJ-101
  workstream-status.sh get-plannable WS-1
  workstream-status.sh get-buildable
  workstream-status.sh get-blockers PROJ-101
  workstream-status.sh list
EOF
}

ensure_status_file() {
  if [[ ! -f "$STATUS_FILE" ]]; then
    echo "Error: Status file not found: $STATUS_FILE" >&2
    echo "Run 'workstream-status.sh init' first." >&2
    exit 1
  fi
}

case "$cmd" in
  init)
    mkdir -p "$(dirname "$STATUS_FILE")"

    if [[ -f "$STATUS_FILE" ]]; then
      echo "Status file already exists: $STATUS_FILE"
      exit 0
    fi

    now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    # Parse WORKSTREAMS.md if it exists, otherwise create empty structure
    if [[ -f "$WORKSTREAMS_DOC" ]]; then
      tickets_json="{}"

      # Extract ticket IDs, workstreams, phases, and blocked_by from WORKSTREAMS.md
      while IFS= read -r line; do
        # Match table rows like: | PROJ-101 | ... | WS-1 | 1 | ... | PROJ-100 |
        if [[ "$line" =~ ^\|[[:space:]]*([-A-Z0-9]+)[[:space:]]*\| ]]; then
          ticket_id="${BASH_REMATCH[1]}"
          # Skip header rows
          [[ "$ticket_id" == "Ticket" || "$ticket_id" == "---" || "$ticket_id" =~ ^-+$ ]] && continue

          # Extract workstream (WS-N pattern)
          workstream=""
          if [[ "$line" =~ WS-[0-9]+ ]]; then
            workstream="${BASH_REMATCH[0]}"
          fi

          # Extract phase number
          phase=1
          if [[ "$line" =~ Phase[[:space:]]*([0-9]+) ]]; then
            phase="${BASH_REMATCH[1]}"
          fi

          # Extract blocked_by (comma-separated ticket IDs in a cell)
          blocked_by="[]"
          # Look for ticket IDs in "Blocked By" column patterns
          blockers=""
          if [[ "$line" =~ Blocked[[:space:]]By:[[:space:]]*([^|]+) ]] || \
             [[ "$line" =~ blocked_by:[[:space:]]*([^|]+) ]]; then
            blockers="${BASH_REMATCH[1]}"
          fi
          if [[ -n "$blockers" && "$blockers" != "None" && "$blockers" != "none" && "$blockers" != "-" ]]; then
            blocked_by=$(echo "$blockers" | grep -oE '[A-Z]+-[0-9]+' | jq -R . | jq -s . 2>/dev/null || echo "[]")
          fi

          tickets_json=$(echo "$tickets_json" | jq \
            --arg tid "$ticket_id" \
            --arg ws "$workstream" \
            --argjson phase "$phase" \
            --argjson blocked "$blocked_by" \
            '.[$tid] = {
              "workstream": $ws,
              "phase": $phase,
              "blocked_by": $blocked,
              "blocks": [],
              "plan": { "status": "pending", "approved_at": null },
              "build": { "status": "pending", "branch": null },
              "pr": { "url": null, "status": null }
            }')
        fi
      done < "$WORKSTREAMS_DOC"

      jq -n \
        --arg now "$now" \
        --argjson tickets "$tickets_json" \
        '{
          "version": "1.0",
          "metadata": { "created_at": $now, "updated_at": $now },
          "tickets": $tickets
        }' > "$STATUS_FILE"

      ticket_count=$(echo "$tickets_json" | jq 'length')
      echo "Initialized $STATUS_FILE with $ticket_count tickets from $WORKSTREAMS_DOC"
    else
      jq -n \
        --arg now "$now" \
        '{
          "version": "1.0",
          "metadata": { "created_at": $now, "updated_at": $now },
          "tickets": {}
        }' > "$STATUS_FILE"

      echo "Initialized empty $STATUS_FILE (no WORKSTREAMS.md found)"
    fi
    ;;

  update)
    if [[ $# -lt 4 ]]; then
      echo "Error: update requires ticket-id, key, and value" >&2
      usage
      exit 1
    fi
    ensure_status_file

    ticket_id="$2"
    key="$3"
    value="$4"

    if ! jq -e --arg tid "$ticket_id" '.tickets[$tid]' "$STATUS_FILE" > /dev/null 2>&1; then
      echo "Error: Ticket not found: $ticket_id" >&2
      exit 1
    fi

    # Build jq path from dot notation (e.g., "build.status" -> .tickets.PROJ-101.build.status)
    jq_path=".tickets[\"$ticket_id\"]"
    IFS='.' read -ra parts <<< "$key"
    for part in "${parts[@]}"; do
      jq_path="${jq_path}.${part}"
    done

    now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    jq --arg v "$value" --arg now "$now" \
      "${jq_path} = \$v | .metadata.updated_at = \$now" \
      "$STATUS_FILE" > "${STATUS_FILE}.tmp"

    mv "${STATUS_FILE}.tmp" "$STATUS_FILE"
    echo "Updated $ticket_id: $key = $value"
    ;;

  get)
    if [[ -z "${2:-}" ]]; then
      echo "Error: get requires ticket-id" >&2
      usage
      exit 1
    fi
    ensure_status_file

    ticket_id="$2"

    if ! jq -e --arg tid "$ticket_id" '.tickets[$tid]' "$STATUS_FILE" > /dev/null 2>&1; then
      echo "Error: Ticket not found: $ticket_id" >&2
      exit 1
    fi

    jq --arg tid "$ticket_id" '.tickets[$tid]' "$STATUS_FILE"
    ;;

  get-plannable)
    ensure_status_file
    scope="${2:-}"

    # Tickets where plan.status == "pending" and all blocked_by have build.status == "completed"
    jq -r --arg scope "$scope" '
      .tickets as $all |
      [ $all | to_entries[] |
        select(.value.plan.status == "pending") |
        select($scope == "" or .value.workstream == $scope) |
        select(
          [ .value.blocked_by[]? |
            . as $blocker |
            $all[$blocker].build.status != "completed"
          ] | any | not
        ) |
        .key
      ] | .[]
    ' "$STATUS_FILE"
    ;;

  get-buildable)
    ensure_status_file
    scope="${2:-}"

    # Tickets where plan.status == "approved" and build.status == "pending" and all blockers resolved
    jq -r --arg scope "$scope" '
      .tickets as $all |
      [ $all | to_entries[] |
        select(.value.plan.status == "approved") |
        select(.value.build.status == "pending") |
        select($scope == "" or .value.workstream == $scope) |
        select(
          [ .value.blocked_by[]? |
            . as $blocker |
            $all[$blocker].build.status != "completed"
          ] | any | not
        ) |
        .key
      ] | .[]
    ' "$STATUS_FILE"
    ;;

  get-blockers)
    if [[ -z "${2:-}" ]]; then
      echo "Error: get-blockers requires ticket-id" >&2
      usage
      exit 1
    fi
    ensure_status_file

    ticket_id="$2"

    if ! jq -e --arg tid "$ticket_id" '.tickets[$tid]' "$STATUS_FILE" > /dev/null 2>&1; then
      echo "Error: Ticket not found: $ticket_id" >&2
      exit 1
    fi

    jq --arg tid "$ticket_id" '.tickets[$tid].blocked_by' "$STATUS_FILE"
    ;;

  list)
    ensure_status_file

    ticket_count=$(jq '.tickets | length' "$STATUS_FILE")
    if [[ "$ticket_count" -eq 0 ]]; then
      echo "No tickets tracked."
      exit 0
    fi

    echo "Workstream Status:"
    echo "==================="
    jq -r '
      .tickets | to_entries | sort_by(.key)[] |
      "  \(.key): plan=\(.value.plan.status), build=\(.value.build.status), pr=\(.value.pr.status // "none")" +
      if (.value.blocked_by | length) > 0 then " [blocked by: \(.value.blocked_by | join(", "))]" else "" end
    ' "$STATUS_FILE"
    echo ""
    echo "Total: $ticket_count tickets"
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
