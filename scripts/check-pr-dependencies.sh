#!/usr/bin/env bash
# Check PR merge dependencies for workstream tickets.
# Reads depends_on from status.json, checks PR merge status via gh CLI,
# and reports which PRs are ready to merge vs blocked by unmerged dependencies.
#
# Usage:
#   check-pr-dependencies.sh                  # Check all tickets with open PRs
#   check-pr-dependencies.sh <ticket-id>      # Check a specific ticket
#
# Exit codes:
#   0 - All checked PRs are clear to merge (or no PRs to check)
#   1 - One or more PRs are blocked by unmerged dependencies

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-.claude}"
STATUS_FILE="$CLAUDE_DIR/workstreams/status.json"

# Check prerequisites
if ! command -v jq &> /dev/null; then
  echo "Error: jq not found. Install: brew install jq" >&2
  exit 1
fi

if ! command -v gh &> /dev/null; then
  echo "Error: gh CLI not found. Install: brew install gh" >&2
  exit 1
fi

if [[ ! -f "$STATUS_FILE" ]]; then
  echo "Error: Status file not found: $STATUS_FILE" >&2
  echo "Run 'workstream-status.sh init' first." >&2
  exit 1
fi

ticket_filter="${1:-}"

# Collect tickets that have open PRs and depends_on entries
tickets_to_check=$(jq -r --arg filter "$ticket_filter" '
  .tickets | to_entries[] |
  select($filter == "" or .key == $filter) |
  select(.value.pr.status != null and .value.pr.status != "merged") |
  select((.value.depends_on // []) | length > 0) |
  .key
' "$STATUS_FILE")

if [[ -z "$tickets_to_check" ]]; then
  echo "No tickets with open PRs and depends_on constraints found."
  exit 0
fi

blocked_count=0
ready_count=0

echo "PR Dependency Check"
echo "==================="
echo ""

while IFS= read -r ticket_id; do
  [[ -z "$ticket_id" ]] && continue

  # Read depends_on list for this ticket
  depends_on=$(jq -r --arg tid "$ticket_id" '
    .tickets[$tid].depends_on // [] | .[]
  ' "$STATUS_FILE")

  if [[ -z "$depends_on" ]]; then
    continue
  fi

  # Check each dependency's PR merge status
  unmerged_deps=()
  while IFS= read -r dep_id; do
    [[ -z "$dep_id" ]] && continue

    dep_pr_status=$(jq -r --arg tid "$dep_id" '
      .tickets[$tid].pr.status // "none"
    ' "$STATUS_FILE")

    if [[ "$dep_pr_status" != "merged" ]]; then
      unmerged_deps+=("$dep_id ($dep_pr_status)")
    fi
  done <<< "$depends_on"

  pr_status=$(jq -r --arg tid "$ticket_id" '
    .tickets[$tid].pr.status // "none"
  ' "$STATUS_FILE")

  if [[ ${#unmerged_deps[@]} -eq 0 ]]; then
    echo "  $ticket_id (PR: $pr_status) .... READY to merge"
    ready_count=$((ready_count + 1))
  else
    echo "  $ticket_id (PR: $pr_status) .... BLOCKED"
    for dep in "${unmerged_deps[@]}"; do
      echo "    - waiting on: $dep"
    done
    blocked_count=$((blocked_count + 1))
  fi
done <<< "$tickets_to_check"

echo ""
echo "Summary: $ready_count ready, $blocked_count blocked"

if [[ "$blocked_count" -gt 0 ]]; then
  exit 1
fi

exit 0
