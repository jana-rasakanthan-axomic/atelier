#!/usr/bin/env bash
# Hook: PreToolUse (Bash)
# Purpose: Scan staged files for potential secrets and credentials.
# Blocks commits and adds containing suspicious files or content patterns.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

[[ -z "$COMMAND" ]] && exit 0

# Determine which files to scan based on the command
FILES_TO_SCAN=""

if echo "$COMMAND" | grep -qE 'git\s+commit'; then
  FILES_TO_SCAN=$(git diff --cached --name-only 2>/dev/null)
elif echo "$COMMAND" | grep -qE 'git\s+add'; then
  # Extract file paths from git add command (everything after "git add" minus flags)
  FILES_TO_SCAN=$(echo "$COMMAND" | sed -E 's/git\s+add\s+//' | tr ' ' '\n' | grep -v '^-')
else
  exit 0
fi

[[ -z "$FILES_TO_SCAN" ]] && exit 0

SUSPICIOUS_FILES=""
SUSPICIOUS_PATTERNS=""
FOUND_ISSUE=false

# Suspicious filename patterns
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  BASENAME=$(basename "$file")

  if echo "$BASENAME" | grep -qiE '^\.env$|\.pem$|\.key$|credential|secret|^id_rsa$|^id_ed25519$'; then
    SUSPICIOUS_FILES="${SUSPICIOUS_FILES}  - ${file}\n"
    FOUND_ISSUE=true
  fi
done <<< "$FILES_TO_SCAN"

# Content pattern scanning (only for files that exist and are staged)
CONTENT_PATTERNS='API_KEY=|SECRET_KEY=|PASSWORD=|aws_access_key_id|PRIVATE KEY|sk-[a-zA-Z0-9]|ghp_[a-zA-Z0-9]|Bearer '

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  [[ ! -f "$file" ]] && continue

  # For git commit, scan staged content; for git add, scan file content
  if echo "$COMMAND" | grep -qE 'git\s+commit'; then
    MATCHES=$(git diff --cached -- "$file" 2>/dev/null | grep -oE "$CONTENT_PATTERNS" | head -5 || true)
  else
    MATCHES=$(grep -oE "$CONTENT_PATTERNS" "$file" 2>/dev/null | head -5 || true)
  fi

  if [[ -n "$MATCHES" ]]; then
    while IFS= read -r match; do
      [[ -z "$match" ]] && continue
      SUSPICIOUS_PATTERNS="${SUSPICIOUS_PATTERNS}  - ${file}: ${match}\n"
      FOUND_ISSUE=true
    done <<< "$MATCHES"
  fi
done <<< "$FILES_TO_SCAN"

if [[ "$FOUND_ISSUE" == true ]]; then
  echo "SECRETS DETECTED: Potential credentials in staged files."
  echo ""

  if [[ -n "$SUSPICIOUS_FILES" ]]; then
    echo "Suspicious files:"
    echo -e "$SUSPICIOUS_FILES"
  fi

  if [[ -n "$SUSPICIOUS_PATTERNS" ]]; then
    echo "Suspicious patterns:"
    echo -e "$SUSPICIOUS_PATTERNS"
  fi

  echo "Review these files before committing. To bypass: git commit --no-verify"
  exit 2
fi

exit 0
