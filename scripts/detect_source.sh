#!/usr/bin/env bash
# Atelier Source Detector
# Parses an input string and returns a structured source type as JSON.
# Used by /gather to deterministically classify input sources.
#
# Usage:
#   detect_source.sh <input_string>
#
# Output (JSON on stdout):
#   {"type": "url|file|jira|confluence|github_pr|github_issue|text", "value": "..."}
#
# Exit codes:
#   0 - Always (any input is valid; unrecognized input becomes type "text")

set -euo pipefail

# ─── Input validation ───────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: detect_source.sh <input_string>

Detects the source type of the given input and outputs JSON.

Detection order:
  1. Confluence URL (contains "confluence" or "/wiki/")
  2. GitHub PR URL (github.com/*/pull/*)
  3. GitHub issue URL (github.com/*/issues/*)
  4. Generic URL (http:// or https://)
  5. File path (/, ./, ../, ~ prefix and file exists)
  6. Jira ticket ([A-Z]+-[0-9]+)
  7. GitHub PR shorthand (#123 or owner/repo#123)
  8. GitHub issue shorthand (GH-123)
  9. Plain text (fallback)

Examples:
  detect_source.sh "https://github.com/org/repo/pull/42"
  detect_source.sh "PROJ-123"
  detect_source.sh "#42"
  detect_source.sh "./README.md"
  detect_source.sh "Add CSV export feature"
EOF
}

if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && exit 0
  echo "Error: input string argument required" >&2
  exit 0
fi

INPUT="$1"

# ─── Helper: JSON-escape a string ──────────────────────────────────────────

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# ─── Helper: extract domain from URL ───────────────────────────────────────

extract_domain() {
  local url="$1"
  # Strip protocol, then everything after first /
  local domain="${url#*://}"
  domain="${domain%%/*}"
  # Strip port if present
  domain="${domain%%:*}"
  printf '%s' "$domain"
}

# ─── Helper: extract file extension ────────────────────────────────────────

extract_extension() {
  local path="$1"
  local basename="${path##*/}"
  if [[ "$basename" == *.* ]]; then
    printf '%s' "${basename##*.}"
  fi
}

# ─── Detection (order matters) ─────────────────────────────────────────────

# 1. Confluence URL (must check before generic URL)
if [[ "$INPUT" =~ ^https?:// ]] && { [[ "$INPUT" == *confluence* ]] || [[ "$INPUT" == */wiki/* ]]; }; then
  domain=$(extract_domain "$INPUT")
  val=$(json_escape "$INPUT")
  dom=$(json_escape "$domain")
  echo "{\"type\": \"confluence\", \"value\": \"${val}\", \"domain\": \"${dom}\"}"
  exit 0
fi

# 2. GitHub PR URL
if [[ "$INPUT" =~ ^https?://github\.com/([^/]+/[^/]+)/pull/([0-9]+) ]]; then
  repo="${BASH_REMATCH[1]}"
  number="${BASH_REMATCH[2]}"
  val=$(json_escape "$INPUT")
  echo "{\"type\": \"github_pr\", \"value\": \"${val}\", \"repo\": \"${repo}\", \"number\": \"${number}\"}"
  exit 0
fi

# 3. GitHub issue URL
if [[ "$INPUT" =~ ^https?://github\.com/([^/]+/[^/]+)/issues/([0-9]+) ]]; then
  repo="${BASH_REMATCH[1]}"
  number="${BASH_REMATCH[2]}"
  val=$(json_escape "$INPUT")
  echo "{\"type\": \"github_issue\", \"value\": \"${val}\", \"repo\": \"${repo}\", \"number\": \"${number}\"}"
  exit 0
fi

# 4. Generic URL
if [[ "$INPUT" =~ ^https?:// ]]; then
  domain=$(extract_domain "$INPUT")
  val=$(json_escape "$INPUT")
  dom=$(json_escape "$domain")
  echo "{\"type\": \"url\", \"value\": \"${val}\", \"domain\": \"${dom}\"}"
  exit 0
fi

# 5. File path (starts with /, ./, ../, or ~ and file exists)
if [[ "$INPUT" =~ ^(/|\./|\.\./|~) ]]; then
  # Expand tilde
  expanded="${INPUT/#\~/$HOME}"
  if [[ -e "$expanded" ]]; then
    ext=$(extract_extension "$expanded")
    val=$(json_escape "$INPUT")
    if [[ -n "$ext" ]]; then
      echo "{\"type\": \"file\", \"value\": \"${val}\", \"extension\": \"${ext}\"}"
    else
      echo "{\"type\": \"file\", \"value\": \"${val}\"}"
    fi
    exit 0
  fi
fi

# 6. Jira ticket (e.g., PROJ-123)
if [[ "$INPUT" =~ ^([A-Z][A-Z0-9]+-[0-9]+)$ ]]; then
  project="${INPUT%%-*}"
  number="${INPUT##*-}"
  val=$(json_escape "$INPUT")
  echo "{\"type\": \"jira\", \"value\": \"${val}\", \"project\": \"${project}\", \"number\": \"${number}\"}"
  exit 0
fi

# 7. GitHub PR shorthand (#123 or owner/repo#123)
if [[ "$INPUT" =~ ^([a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+)?#([0-9]+)$ ]]; then
  repo="${BASH_REMATCH[1]}"
  number="${BASH_REMATCH[2]}"
  val=$(json_escape "$INPUT")
  if [[ -n "$repo" ]]; then
    echo "{\"type\": \"github_pr\", \"value\": \"${val}\", \"repo\": \"${repo}\", \"number\": \"${number}\"}"
  else
    echo "{\"type\": \"github_pr\", \"value\": \"${val}\", \"number\": \"${number}\"}"
  fi
  exit 0
fi

# 8. GitHub issue shorthand (GH-123)
if [[ "$INPUT" =~ ^GH-([0-9]+)$ ]]; then
  number="${BASH_REMATCH[1]}"
  val=$(json_escape "$INPUT")
  echo "{\"type\": \"github_issue\", \"value\": \"${val}\", \"number\": \"${number}\"}"
  exit 0
fi

# 9. Plain text (fallback)
val=$(json_escape "$INPUT")
echo "{\"type\": \"text\", \"value\": \"${val}\"}"
exit 0
