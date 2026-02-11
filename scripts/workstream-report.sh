#!/usr/bin/env bash
# Workstream progress report generator
# Usage:
#   workstream-report.sh generate                    # Print markdown report to stdout
#   workstream-report.sh generate --output FILE      # Write report to file

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-.claude}"
STATUS_FILE="$CLAUDE_DIR/workstreams/status.json"

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq not found. Install: brew install jq" >&2
  exit 1
fi

cmd="${1:-}"

usage() {
  cat <<EOF
Usage: workstream-report.sh <command> [options]

Commands:
  generate                    Print markdown progress report to stdout
  generate --output FILE      Write report to a file

Examples:
  workstream-report.sh generate
  workstream-report.sh generate --output .claude/workstreams/report.md
EOF
}

ensure_status_file() {
  if [[ ! -f "$STATUS_FILE" ]]; then
    echo "Error: Status file not found: $STATUS_FILE" >&2
    echo "Run 'workstream-status.sh init' first." >&2
    exit 1
  fi
}

generate_report() {
  ensure_status_file

  local now
  now="$(date -u +"%Y-%m-%d %H:%M") UTC"

  # Categorize tickets using jq
  local completed in_progress blocked pending

  completed=$(jq -r '
    .tickets | to_entries[] |
    select(
      .value.build.status == "completed" or
      .value.pr.status == "merged"
    ) | .key
  ' "$STATUS_FILE" | sort)

  in_progress=$(jq -r '
    .tickets as $all |
    .tickets | to_entries[] |
    select(
      (.value.build.status == "in_progress") or
      (.value.plan.status == "in_progress") or
      (.value.pr.status == "open")
    ) |
    select(.value.build.status != "completed") |
    select(.value.pr.status != "merged") |
    .key
  ' "$STATUS_FILE" | sort)

  blocked=$(jq -r '
    .tickets as $all |
    .tickets | to_entries[] |
    select(.value.build.status != "completed") |
    select(.value.build.status != "in_progress") |
    select(.value.pr.status != "merged") |
    select(.value.pr.status != "open") |
    select(.value.plan.status != "in_progress") |
    select(
      [ .value.blocked_by[]? |
        . as $blocker |
        $all[$blocker].build.status != "completed"
      ] | any
    ) |
    .key
  ' "$STATUS_FILE" | sort)

  pending=$(jq -r '
    .tickets as $all |
    .tickets | to_entries[] |
    select(.value.build.status != "completed") |
    select(.value.build.status != "in_progress") |
    select(.value.pr.status != "merged") |
    select(.value.pr.status != "open") |
    select(.value.plan.status != "in_progress") |
    select(
      [ .value.blocked_by[]? |
        . as $blocker |
        $all[$blocker].build.status != "completed"
      ] | any | not
    ) |
    .key
  ' "$STATUS_FILE" | sort)

  count_lines() {
    local input="$1"
    if [[ -z "$input" ]]; then
      echo 0
    else
      echo "$input" | wc -l | tr -d ' '
    fi
  }

  local count_completed count_in_progress count_blocked count_pending
  count_completed=$(count_lines "$completed")
  count_in_progress=$(count_lines "$in_progress")
  count_blocked=$(count_lines "$blocked")
  count_pending=$(count_lines "$pending")

  # Build the report
  cat <<EOF
# Workstream Progress Report

Generated: $now

## Summary
| Status | Count |
|--------|-------|
| Completed | $count_completed |
| In Progress | $count_in_progress |
| Pending | $count_pending |
| Blocked | $count_blocked |

## Tickets
EOF

  # Completed section
  echo ""
  echo "### Completed"
  if [[ "$count_completed" -eq 0 ]]; then
    echo "_(none)_"
  else
    while IFS= read -r tid; do
      [[ -z "$tid" ]] && continue
      local detail
      detail=$(jq -r --arg tid "$tid" '
        .tickets[$tid] |
        "plan=\(.plan.status), build=\(.build.status)" +
        if .pr.url then ", PR=\(.pr.url)" else "" end
      ' "$STATUS_FILE")
      echo "- $tid: $detail"
    done <<< "$completed"
  fi

  # In Progress section
  echo ""
  echo "### In Progress"
  if [[ "$count_in_progress" -eq 0 ]]; then
    echo "_(none)_"
  else
    while IFS= read -r tid; do
      [[ -z "$tid" ]] && continue
      local detail
      detail=$(jq -r --arg tid "$tid" '
        .tickets[$tid] |
        "plan=\(.plan.status), build=\(.build.status)" +
        if .pr.status == "open" then ", PR=open" else "" end
      ' "$STATUS_FILE")
      echo "- $tid: $detail"
    done <<< "$in_progress"
  fi

  # Blocked section
  echo ""
  echo "### Blocked"
  if [[ "$count_blocked" -eq 0 ]]; then
    echo "_(none)_"
  else
    while IFS= read -r tid; do
      [[ -z "$tid" ]] && continue
      local blockers
      blockers=$(jq -r --arg tid "$tid" '
        .tickets as $all |
        .tickets[$tid].blocked_by |
        [ .[]? | select(. as $b | $all[$b].build.status != "completed") ] |
        join(", ")
      ' "$STATUS_FILE")
      echo "- $tid: blocked by $blockers"
    done <<< "$blocked"
  fi

  # Pending section
  echo ""
  echo "### Pending"
  if [[ "$count_pending" -eq 0 ]]; then
    echo "_(none)_"
  else
    while IFS= read -r tid; do
      [[ -z "$tid" ]] && continue
      local detail
      detail=$(jq -r --arg tid "$tid" '
        .tickets[$tid] |
        "plan=\(.plan.status)"
      ' "$STATUS_FILE")
      echo "- $tid: $detail"
    done <<< "$pending"
  fi
}

case "$cmd" in
  generate)
    output_file=""

    # Parse --output flag
    shift
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --output)
          if [[ -z "${2:-}" ]]; then
            echo "Error: --output requires a file path" >&2
            exit 1
          fi
          output_file="$2"
          shift 2
          ;;
        *)
          echo "Error: Unknown option: $1" >&2
          usage
          exit 1
          ;;
      esac
    done

    if [[ -n "$output_file" ]]; then
      mkdir -p "$(dirname "$output_file")"
      generate_report > "$output_file"
      echo "Report written to $output_file"
    else
      generate_report
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
