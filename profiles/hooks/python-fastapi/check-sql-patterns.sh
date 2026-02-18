#!/usr/bin/env bash
# Profile Hook: python-fastapi
# Purpose: Flag dangerous SQL patterns in Python files.
# Catches raw SQL via f-strings, .format(), and string concatenation.
# Does NOT flag SQLAlchemy query builder or Alembic migration patterns.
#
# Exit codes:
#   0 - Clean (no dangerous patterns found)
#   2 - Block (dangerous SQL patterns detected)

set -euo pipefail

# Read tool input from stdin
INPUT=$(cat)

# --- Extract file path ---
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.file // empty' 2>/dev/null)
[[ -z "$FILE_PATH" ]] && exit 0

# --- Only check Python files ---
[[ "$FILE_PATH" != *.py ]] && exit 0

# --- Skip test files (tests may legitimately use raw SQL for fixtures) ---
if [[ "$FILE_PATH" == *test_* ]] || [[ "$FILE_PATH" == *_test.* ]] || \
   [[ "$FILE_PATH" == */tests/* ]] || [[ "$FILE_PATH" == */test/* ]]; then
  exit 0
fi

# --- Skip Alembic migration files ---
if [[ "$FILE_PATH" == */alembic/* ]] || [[ "$FILE_PATH" == */migrations/* ]] || \
   [[ "$FILE_PATH" == */versions/* ]]; then
  exit 0
fi

# --- Get content to check ---
# For Write tool: content is in tool_input.content
# For Edit tool: check old_string/new_string — only scan new_string
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null)
[[ -z "$CONTENT" ]] && exit 0

# --- Dangerous SQL patterns ---
# These patterns indicate raw SQL construction vulnerable to injection.
FINDINGS=""

# Pattern 1: f-string SQL (f"SELECT ...", f'INSERT ...", etc.)
if echo "$CONTENT" | grep -nE 'f["\x27](SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE)\b' > /dev/null 2>&1; then
  MATCHES=$(echo "$CONTENT" | grep -nE 'f["\x27](SELECT|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE)\b' 2>/dev/null | head -5)
  FINDINGS="${FINDINGS}f-string SQL construction:\n${MATCHES}\n\n"
fi

# Pattern 2: .format() SQL
if echo "$CONTENT" | grep -nE '"(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER)\b.*"\.format\(' > /dev/null 2>&1; then
  MATCHES=$(echo "$CONTENT" | grep -nE '"(SELECT|INSERT|UPDATE|DELETE|DROP|ALTER)\b.*"\.format\(' 2>/dev/null | head -5)
  FINDINGS="${FINDINGS}.format() SQL construction:\n${MATCHES}\n\n"
fi

# Pattern 3: String concatenation with SQL keywords
if echo "$CONTENT" | grep -nE '"(SELECT|INSERT|UPDATE|DELETE)\b.*"\s*\+' > /dev/null 2>&1; then
  MATCHES=$(echo "$CONTENT" | grep -nE '"(SELECT|INSERT|UPDATE|DELETE)\b.*"\s*\+' 2>/dev/null | head -5)
  FINDINGS="${FINDINGS}String concatenation SQL:\n${MATCHES}\n\n"
fi

# Pattern 4: execute() with f-string or .format()
if echo "$CONTENT" | grep -nE '\.execute\(\s*f["\x27]' > /dev/null 2>&1; then
  MATCHES=$(echo "$CONTENT" | grep -nE '\.execute\(\s*f["\x27]' 2>/dev/null | head -5)
  FINDINGS="${FINDINGS}execute() with f-string:\n${MATCHES}\n\n"
fi

# Pattern 5: text() with f-string (SQLAlchemy text() should use bound params)
if echo "$CONTENT" | grep -nE 'text\(\s*f["\x27]' > /dev/null 2>&1; then
  MATCHES=$(echo "$CONTENT" | grep -nE 'text\(\s*f["\x27]' 2>/dev/null | head -5)
  FINDINGS="${FINDINGS}text() with f-string (use bound parameters instead):\n${MATCHES}\n\n"
fi

# --- Report findings ---
if [[ -n "$FINDINGS" ]]; then
  echo "SQL INJECTION RISK: Dangerous SQL patterns detected in $FILE_PATH"
  echo ""
  echo -e "$FINDINGS"
  echo "Use SQLAlchemy query builder or parameterized queries instead:"
  echo "  - select(Model).where(Model.id == value)"
  echo "  - text('SELECT * FROM t WHERE id = :id').bindparams(id=value)"
  echo "  - session.execute(stmt, {'param': value})"
  exit 2
fi

exit 0
