#!/usr/bin/env bash
# Worktree manager for code-modifying commands
# Usage:
#   worktree-manager.sh create <session-id> <branch-name> [base-branch]
#   worktree-manager.sh complete <session-id>
#   worktree-manager.sh cleanup <session-id> [--force]
#   worktree-manager.sh list

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-.claude}"

# Get project root and parent directory for sibling worktrees
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
PROJECT_PARENT="$(dirname "$PROJECT_ROOT")"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cmd="${1:-}"
session_id="${2:-}"

usage() {
  cat <<EOF
Usage: worktree-manager.sh <command> [args]

Commands:
  create <session-id> <branch-name> [base-branch]   Create sibling worktree
  complete <session-id>                             Mark complete
  cleanup <session-id> [--force]                    Remove worktree
  list                                              List worktrees

Worktrees are created as siblings to the main project:
  Main project: /path/to/mise
  Worktree:     /path/to/mise-MISE-101

Examples:
  worktree-manager.sh create abc-123 JRA_auth-signup_MISE-101 main
  worktree-manager.sh complete abc-123
  worktree-manager.sh cleanup abc-123
  worktree-manager.sh cleanup abc-123 --force
  worktree-manager.sh list
EOF
}

case "$cmd" in
  create)
    if [[ $# -lt 3 ]]; then
      echo "Error: create requires session-id and branch-name" >&2
      usage
      exit 1
    fi

    branch_name="$3"
    base_branch="${4:-main}"

    # Extract ticket ID from branch name (e.g., MISE-101 from JRA_auth-signup_MISE-101)
    # Try common patterns: _TICKET-ID at end, or just TICKET-ID format anywhere
    ticket_id=""
    if [[ "$branch_name" =~ _([A-Z]+-[0-9]+)$ ]]; then
      ticket_id="${BASH_REMATCH[1]}"
    elif [[ "$branch_name" =~ ([A-Z]+-[0-9]+) ]]; then
      ticket_id="${BASH_REMATCH[1]}"
    else
      # Fallback to session ID if no ticket pattern found
      ticket_id="$session_id"
    fi

    # Create sibling worktree path: <project-parent>/<project-name>-<ticket-id>
    worktree_path="$PROJECT_PARENT/${PROJECT_NAME}-${ticket_id}"

    # Validate git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
      echo -e "${RED}Error: Not in a git repository${NC}" >&2
      exit 1
    fi

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
      echo -e "${YELLOW}Warning: You have uncommitted changes in your working directory${NC}"
      echo "These won't affect the worktree, but consider committing them first."
      echo ""
    fi

    # Ensure base branch exists
    if ! git rev-parse --verify "$base_branch" > /dev/null 2>&1; then
      echo -e "${RED}Error: Base branch not found: $base_branch${NC}" >&2
      exit 1
    fi

    # Fetch latest
    echo -e "${BLUE}Fetching latest from remote...${NC}"
    git fetch origin "$base_branch" --quiet 2>/dev/null || true
    echo ""

    # Check if worktree already exists
    if [[ -d "$worktree_path" ]]; then
      echo -e "${RED}Error: Worktree already exists: $worktree_path${NC}" >&2
      exit 1
    fi

    # Create worktree as sibling directory
    echo -e "${BLUE}Creating sibling worktree at: $worktree_path${NC}"

    if [[ -x "$SCRIPT_DIR/setup-worktree" ]]; then
      # Use existing setup-worktree script
      "$SCRIPT_DIR/setup-worktree" "$worktree_path" -b "$branch_name" "$base_branch"
    else
      # Fallback to direct git worktree command
      git worktree add -b "$branch_name" "$worktree_path" "$base_branch"
    fi

    # Store session ID to worktree mapping in .claude/worktree-sessions.json
    mkdir -p "$CLAUDE_DIR"
    sessions_file="$CLAUDE_DIR/worktree-sessions.json"
    if [[ ! -f "$sessions_file" ]]; then
      echo '{}' > "$sessions_file"
    fi
    # Update mapping: session_id -> worktree_path
    tmp_file=$(mktemp)
    jq --arg sid "$session_id" --arg path "$worktree_path" \
      '.[$sid] = $path' "$sessions_file" > "$tmp_file" && mv "$tmp_file" "$sessions_file"

    echo ""
    echo -e "${GREEN}✓ Sibling worktree created successfully${NC}"
    echo ""
    echo "Branch: $branch_name"
    echo "Ticket: $ticket_id"
    echo "Path: $worktree_path"
    echo ""
    echo "Main project: $PROJECT_ROOT"
    echo "Worktree:     $worktree_path"
    echo ""
    echo "To work in this worktree:"
    echo "  cd $worktree_path"
    echo ""

    # Update session with worktree path
    if [[ -x "$SCRIPT_DIR/session-manager.sh" ]]; then
      "$SCRIPT_DIR/session-manager.sh" update "$session_id" "worktree_path" "$worktree_path" 2>/dev/null || true
    fi

    # Output absolute path for scripts
    echo "$worktree_path"
    ;;

  complete)
    if [[ -z "$session_id" ]]; then
      echo "Error: complete requires session-id" >&2
      usage
      exit 1
    fi

    # Look up worktree path from session mapping
    sessions_file="$CLAUDE_DIR/worktree-sessions.json"
    if [[ -f "$sessions_file" ]]; then
      worktree_path=$(jq -r --arg sid "$session_id" '.[$sid] // empty' "$sessions_file")
    fi

    # Fallback: check if session_id is a ticket ID (e.g., MISE-101)
    if [[ -z "$worktree_path" || ! -d "$worktree_path" ]]; then
      potential_path="$PROJECT_PARENT/${PROJECT_NAME}-${session_id}"
      if [[ -d "$potential_path" ]]; then
        worktree_path="$potential_path"
      fi
    fi

    if [[ -z "$worktree_path" || ! -d "$worktree_path" ]]; then
      echo -e "${RED}Error: Worktree not found for session: $session_id${NC}" >&2
      exit 1
    fi

    cd "$worktree_path"

    # Get branch name
    branch_name=$(git rev-parse --abbrev-ref HEAD)

    # Update session status
    if [[ -x "$SCRIPT_DIR/session-manager.sh" ]]; then
      "$SCRIPT_DIR/session-manager.sh" update "$session_id" "status" "completed" 2>/dev/null || true
    fi

    echo -e "${GREEN}✓ Session $session_id completed${NC}"
    echo ""
    echo "Branch: $branch_name"
    echo "Worktree: $worktree_path"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Review changes: cd $worktree_path && git diff"
    echo "  2. Push branch: git push origin $branch_name"
    echo "  3. Create PR or merge locally"
    echo "  4. Cleanup: $SCRIPT_DIR/worktree-manager.sh cleanup $session_id"
    ;;

  cleanup)
    if [[ -z "$session_id" ]]; then
      echo "Error: cleanup requires session-id" >&2
      usage
      exit 1
    fi

    force="${3:-}"

    # Look up worktree path from session mapping
    sessions_file="$CLAUDE_DIR/worktree-sessions.json"
    worktree_path=""
    if [[ -f "$sessions_file" ]]; then
      worktree_path=$(jq -r --arg sid "$session_id" '.[$sid] // empty' "$sessions_file")
    fi

    # Fallback: check if session_id is a ticket ID (e.g., MISE-101)
    if [[ -z "$worktree_path" || ! -d "$worktree_path" ]]; then
      potential_path="$PROJECT_PARENT/${PROJECT_NAME}-${session_id}"
      if [[ -d "$potential_path" ]]; then
        worktree_path="$potential_path"
      fi
    fi

    if [[ -z "$worktree_path" || ! -d "$worktree_path" ]]; then
      echo -e "${YELLOW}Warning: Worktree not found for session: $session_id${NC}"
      echo "(already cleaned up?)"

      # Clean up session metadata anyway
      if [[ -x "$SCRIPT_DIR/session-manager.sh" ]]; then
        "$SCRIPT_DIR/session-manager.sh" delete "$session_id" 2>/dev/null || true
      fi

      # Remove from worktree-sessions.json
      if [[ -f "$sessions_file" ]]; then
        tmp_file=$(mktemp)
        jq --arg sid "$session_id" 'del(.[$sid])' "$sessions_file" > "$tmp_file" && mv "$tmp_file" "$sessions_file"
      fi
      exit 0
    fi

    cd "$worktree_path"
    branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    # Check for uncommitted changes
    if [[ "$force" != "--force" ]] && ! git diff-index --quiet HEAD -- 2>/dev/null; then
      echo -e "${RED}Error: Worktree has uncommitted changes${NC}" >&2
      echo ""
      echo "Options:"
      echo "  1. Commit changes first"
      echo "  2. Use --force to cleanup anyway (changes will be lost)"
      echo ""
      echo "Example:"
      echo "  $0 cleanup $session_id --force"
      exit 1
    fi

    # Navigate back to main project
    cd "$PROJECT_ROOT"

    # Remove worktree
    echo -e "${BLUE}Removing sibling worktree: $worktree_path${NC}"

    if [[ "$force" == "--force" ]]; then
      git worktree remove "$worktree_path" --force
    else
      git worktree remove "$worktree_path"
    fi

    # Remove from worktree-sessions.json
    if [[ -f "$sessions_file" ]]; then
      tmp_file=$(mktemp)
      jq --arg sid "$session_id" 'del(.[$sid])' "$sessions_file" > "$tmp_file" && mv "$tmp_file" "$sessions_file"
    fi

    # Delete session
    if [[ -x "$SCRIPT_DIR/session-manager.sh" ]]; then
      "$SCRIPT_DIR/session-manager.sh" delete "$session_id" 2>/dev/null || true
    fi

    echo -e "${GREEN}✓ Cleaned up session $session_id${NC}"
    echo ""
    echo -e "${YELLOW}Note: Branch $branch_name still exists${NC}"
    echo "Delete manually if no longer needed:"
    echo "  git branch -D $branch_name"
    ;;

  list)
    echo "Git Worktrees (sibling directories):"
    echo "====================================="
    git worktree list

    echo ""
    echo "Session -> Worktree Mapping:"
    echo "============================"
    sessions_file="$CLAUDE_DIR/worktree-sessions.json"
    if [[ -f "$sessions_file" ]]; then
      jq -r 'to_entries[] | "  \(.key) -> \(.value)"' "$sessions_file"
    else
      echo "  (no sessions tracked)"
    fi

    echo ""
    echo "Sessions:"
    echo "========="

    if [[ -x "$SCRIPT_DIR/session-manager.sh" ]]; then
      "$SCRIPT_DIR/session-manager.sh" list
    else
      echo "(session-manager.sh not found)"
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
