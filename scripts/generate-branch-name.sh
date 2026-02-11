#!/usr/bin/env bash
# Generate Axomic-compliant branch name
# Format: <INITIALS>_<description>_<TICKET-ID>
#
# Usage:
#   generate-branch-name.sh <context-file>
#   generate-branch-name.sh --description "add user export" --ticket SHRED-2119
#   generate-branch-name.sh --description "fix auth" --auto-ticket

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-.claude}"

# Get user initials from config or default to CLAUDE
get_initials() {
  local config_file="$CLAUDE_DIR/config.json"
  if [[ -f "$config_file" ]]; then
    if command -v jq &> /dev/null; then
      jq -r '.user.initials // "CLAUDE"' "$config_file" 2>/dev/null || echo "CLAUDE"
    else
      echo "CLAUDE"
    fi
  else
    echo "CLAUDE"
  fi
}

# Convert title to branch description
# "Add User Export Functionality" -> "add-user-export-functionality"
slugify() {
  echo "$1" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9]/-/g' | \
    sed 's/--*/-/g' | \
    sed 's/^-//' | \
    sed 's/-$//' | \
    cut -c1-50  # Limit to 50 chars for description
}

# Generate short random ID for auto-generated tickets
generate_ticket_id() {
  if command -v openssl &> /dev/null; then
    echo "TOOLKIT-$(openssl rand -hex 2)"
  else
    echo "TOOLKIT-$(date +%s | tail -c 5)"
  fi
}

usage() {
  cat <<EOF
Usage: generate-branch-name.sh [options]

Options:
  <context-file>                      Generate from context file
  --description <desc> --ticket <id>  Manual description and ticket
  --description <desc> --auto-ticket  Auto-generate ticket ID
  -h, --help                          Show this help

Examples:
  generate-branch-name.sh .claude/context/SHRED-2119.md
  generate-branch-name.sh --description "Add user export" --ticket SHRED-2119
  generate-branch-name.sh --description "Fix auth bug" --auto-ticket

Output format: INITIALS_description_TICKET-ID
  Example: JRA_add-user-export_SHRED-2119
EOF
}

# Parse arguments
if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

# Check for help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi

# Check if first arg is a context file
if [[ $# -eq 1 && -f "$1" ]]; then
  context_file="$1"

  # Check if parse-context.py exists
  if [[ ! -x "$SCRIPT_DIR/parse-context.py" ]]; then
    echo "Error: parse-context.py not found or not executable" >&2
    exit 1
  fi

  # Extract ticket ID
  ticket_id=$("$SCRIPT_DIR/parse-context.py" "$context_file" --extract ticket-id 2>/dev/null || echo "")

  if [[ -z "$ticket_id" ]]; then
    echo "Error: Could not extract ticket ID from context file" >&2
    exit 1
  fi

  # Extract summary and slugify
  summary=$("$SCRIPT_DIR/parse-context.py" "$context_file" --extract summary 2>/dev/null || echo "")

  if [[ -z "$summary" ]]; then
    echo "Error: Could not extract summary from context file" >&2
    exit 1
  fi

  description=$(slugify "$summary")

else
  # Manual arguments
  description=""
  ticket_id=""
  auto_ticket=false

  while [[ $# -gt 0 ]]; do
    case $1 in
      --description)
        if [[ $# -lt 2 ]]; then
          echo "Error: --description requires a value" >&2
          exit 1
        fi
        description=$(slugify "$2")
        shift 2
        ;;
      --ticket)
        if [[ $# -lt 2 ]]; then
          echo "Error: --ticket requires a value" >&2
          exit 1
        fi
        ticket_id="$2"
        shift 2
        ;;
      --auto-ticket)
        auto_ticket=true
        shift
        ;;
      *)
        echo "Error: Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
  done

  if [[ -z "$description" ]]; then
    echo "Error: --description required" >&2
    usage
    exit 1
  fi

  if [[ -z "$ticket_id" && "$auto_ticket" == "true" ]]; then
    ticket_id=$(generate_ticket_id)
  elif [[ -z "$ticket_id" ]]; then
    echo "Error: --ticket or --auto-ticket required" >&2
    usage
    exit 1
  fi
fi

# Get initials
initials=$(get_initials)

# Generate branch name: INITIALS_description_TICKET-ID
branch_name="${initials}_${description}_${ticket_id}"

# Validate branch name (git branch name rules)
if ! echo "$branch_name" | grep -qE '^[a-zA-Z0-9_-]+$'; then
  echo "Error: Generated invalid branch name: $branch_name" >&2
  exit 1
fi

echo "$branch_name"
