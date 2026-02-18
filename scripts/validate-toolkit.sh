#!/usr/bin/env bash
# validate-toolkit.sh — Deterministic validation for toolkit components (commands, agents, skills)
# The "test runner" for markdown-based toolkit files.
#
# Usage:
#   scripts/validate-toolkit.sh <file> [<file>...]   # Validate specific files
#   scripts/validate-toolkit.sh --all                 # Validate all components + CLAUDE.md + profiles
#   scripts/validate-toolkit.sh --meta                 # Validate CLAUDE.md and profiles only
#   scripts/validate-toolkit.sh --commands             # Validate all commands
#   scripts/validate-toolkit.sh --agents               # Validate all agents
#   scripts/validate-toolkit.sh --skills               # Validate all SKILL.md files
#
# Exit codes:
#   0 = all checks passed
#   1 = one or more findings (errors or warnings)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Counters
ERRORS=0
WARNINGS=0
PASSES=0

# ─── Utility ──────────────────────────────────────────────────────────────────

# Portable relative path (macOS lacks realpath --relative-to)
rel_path() {
  python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$1" "$TOOLKIT_DIR"
}

# ─── Output helpers ───────────────────────────────────────────────────────────

emit_error() {
  local file="$1" line="$2" msg="$3"
  echo "[ERROR] ${file}:${line} — ${msg}"
  ERRORS=$((ERRORS + 1))
}

emit_warn() {
  local file="$1" line="$2" msg="$3"
  echo "[WARN]  ${file}:${line} — ${msg}"
  WARNINGS=$((WARNINGS + 1))
}

emit_pass() {
  local file="$1"
  echo "[PASS]  ${file} — All checks passed"
  PASSES=$((PASSES + 1))
}

# ─── Frontmatter parsing ─────────────────────────────────────────────────────

has_frontmatter() {
  local file="$1"
  head -1 "$file" | grep -q '^---$'
}

get_frontmatter_field() {
  local file="$1" field="$2"
  awk '/^---$/{n++; next} n==1{print}' "$file" | grep "^${field}:" | sed "s/^${field}:[[:space:]]*//"
}

get_frontmatter_end_line() {
  local file="$1"
  awk '/^---$/{n++; if(n==2){print NR; exit}}' "$file"
}

# ─── Section detection ────────────────────────────────────────────────────────

has_section() {
  local file="$1" section="$2"
  grep -q "^##\+ ${section}" "$file"
}

# ─── Cross-reference resolution ───────────────────────────────────────────────

check_cross_references() {
  local file="$1"
  local rel_file
  rel_file="$(rel_path "$file")"

  # Collect file references like skills/foo/bar.md, commands/review.md
  local refs
  refs="$(grep -oE '(skills|agents|commands)/[a-zA-Z0-9_-]+(/[a-zA-Z0-9_.-]+)*\.[a-z]+' "$file" 2>/dev/null | sort -u || true)"
  # Also match directory references like skills/authoring/ (trailing slash)
  local dir_refs
  dir_refs="$(grep -oE '(skills|agents|commands)/[a-zA-Z0-9_-]+/' "$file" 2>/dev/null | sed 's|/$||' | sort -u || true)"
  refs="$(printf '%s\n%s' "$refs" "$dir_refs" | sort -u)"
  # Filter out false positives where path segment is another top-level dir (e.g. "agents/skills/commands" from prose)
  refs="$(echo "$refs" | grep -vE '^(skills|agents|commands)/(skills|agents|commands)' || true)"

  local ref
  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    # Skip glob patterns and placeholders
    [[ "$ref" == *'*'* ]] && continue
    [[ "$ref" == *'${'* ]] && continue

    local target="$TOOLKIT_DIR/$ref"
    if [[ ! -e "$target" ]]; then
      emit_error "$rel_file" "0" "Referenced path \"${ref}\" does not exist"
    fi
  done <<< "$refs"
}

# ─── CLAUDE.md consistency ────────────────────────────────────────────────────

check_claude_md_reference() {
  local file="$1" component_type="$2"
  local rel_file
  rel_file="$(rel_path "$file")"
  local name
  name="$(get_frontmatter_field "$file" "name")"

  [[ -z "$name" ]] && return 0

  local claude_md="$TOOLKIT_DIR/CLAUDE.md"
  [[ ! -f "$claude_md" ]] && return 0

  case "$component_type" in
    command)
      if ! grep -q "/${name}" "$claude_md"; then
        emit_warn "$rel_file" "0" "Command \"/${name}\" not found in CLAUDE.md quick reference"
      fi
      ;;
    agent)
      local capitalized
      capitalized="$(echo "${name:0:1}" | tr '[:lower:]' '[:upper:]')${name:1}"
      if ! grep -qi "${capitalized}" "$claude_md"; then
        emit_warn "$rel_file" "0" "Agent \"${capitalized}\" not found in CLAUDE.md quick reference"
      fi
      ;;
    skill)
      if ! grep -q "${name}/" "$claude_md"; then
        emit_warn "$rel_file" "0" "Skill \"${name}/\" not found in CLAUDE.md quick reference"
      fi
      ;;
  esac
}

# ─── File size checks ────────────────────────────────────────────────────────

check_file_size() {
  local file="$1" component_type="$2"
  local rel_file
  rel_file="$(rel_path "$file")"
  local line_count
  line_count="$(wc -l < "$file" | tr -d ' ')"

  local hard_limit=500
  local soft_limit=200

  if [[ "$component_type" == "skill" ]]; then
    soft_limit=300
  fi

  if (( line_count > hard_limit )); then
    emit_error "$rel_file" "${line_count}" "File exceeds ${hard_limit} lines (${line_count} lines, limit: ${hard_limit})"
  elif (( line_count > soft_limit )); then
    emit_warn "$rel_file" "0" "File exceeds ${soft_limit} lines (${line_count} lines, soft limit: ${soft_limit})"
  fi
}

# ─── CLAUDE.md audit ─────────────────────────────────────────────────────────

check_claude_md() {
  local claude_md="$TOOLKIT_DIR/CLAUDE.md"
  if [[ ! -f "$claude_md" ]]; then
    emit_error "CLAUDE.md" "0" "CLAUDE.md not found at toolkit root"
    return 0
  fi

  local rel_file="CLAUDE.md"
  local line_count
  line_count="$(wc -l < "$claude_md" | tr -d ' ')"

  # Size limits: hard 500, soft 350 (Anthropic recommends <500 lines)
  if (( line_count > 500 )); then
    emit_error "$rel_file" "${line_count}" "CLAUDE.md exceeds 500 lines (${line_count} lines) — agent context window impact"
  elif (( line_count > 350 )); then
    emit_warn "$rel_file" "0" "CLAUDE.md exceeds 350 lines (${line_count} lines) — consider trimming"
  fi

  # Estimate tokens (~1.3 tokens per word for technical markdown)
  local word_count
  word_count="$(wc -w < "$claude_md" | tr -d ' ')"
  local est_tokens=$(( word_count * 13 / 10 ))
  if (( est_tokens > 4000 )); then
    emit_warn "$rel_file" "0" "Estimated ~${est_tokens} tokens (${word_count} words) — may consume significant context"
  fi

  # Required sections in CLAUDE.md
  local -a required=("Quick Reference" "TDD" "Design Principles" "Strict Compliance" "Model Hints")
  for section in "${required[@]}"; do
    if ! grep -qi "$section" "$claude_md"; then
      emit_warn "$rel_file" "0" "Missing expected section: \"${section}\""
    fi
  done

  # Check that all commands in commands/ are referenced
  local cmd_name
  while IFS= read -r cmd_file; do
    [[ -z "$cmd_file" ]] && continue
    cmd_name="$(get_frontmatter_field "$cmd_file" "name")"
    [[ -z "$cmd_name" ]] && continue
    if ! grep -q "/${cmd_name}" "$claude_md"; then
      emit_warn "$rel_file" "0" "Command \"/${cmd_name}\" exists but not listed in CLAUDE.md"
    fi
  done < <(collect_commands)

  # Check that all agents in agents/ are referenced
  local agent_name
  while IFS= read -r agent_file; do
    [[ -z "$agent_file" ]] && continue
    agent_name="$(get_frontmatter_field "$agent_file" "name")"
    [[ -z "$agent_name" ]] && continue
    local capitalized
    capitalized="$(echo "${agent_name:0:1}" | tr '[:lower:]' '[:upper:]')${agent_name:1}"
    if ! grep -qi "${capitalized}" "$claude_md"; then
      emit_warn "$rel_file" "0" "Agent \"${capitalized}\" exists but not listed in CLAUDE.md"
    fi
  done < <(collect_agents)

  # Check that all skills in skills/ are referenced
  local skill_name
  while IFS= read -r skill_file; do
    [[ -z "$skill_file" ]] && continue
    skill_name="$(get_frontmatter_field "$skill_file" "name")"
    [[ -z "$skill_name" ]] && continue
    if ! grep -q "${skill_name}/" "$claude_md"; then
      emit_warn "$rel_file" "0" "Skill \"${skill_name}/\" exists but not listed in CLAUDE.md"
    fi
  done < <(collect_skills)

  local errors_after=$ERRORS
  local warnings_after=$WARNINGS
  if (( errors_after == 0 && warnings_after == 0 )); then
    emit_pass "$rel_file"
  fi
}

# ─── Profile validation ──────────────────────────────────────────────────────

check_profiles() {
  local profiles_dir="$TOOLKIT_DIR/profiles"
  [[ ! -d "$profiles_dir" ]] && return 0

  local profile_file
  for profile_file in "$profiles_dir"/*.md; do
    [[ -f "$profile_file" ]] || continue
    local rel_file
    rel_file="$(rel_path "$profile_file")"
    local line_count
    line_count="$(wc -l < "$profile_file" | tr -d ' ')"

    if (( line_count > 500 )); then
      emit_error "$rel_file" "${line_count}" "Profile exceeds 500 lines (${line_count} lines)"
    elif (( line_count > 300 )); then
      emit_warn "$rel_file" "0" "Profile exceeds 300 lines (${line_count} lines)"
    fi

    # Profiles should have key sections
    local -a expected_sections=("Test" "Lint")
    for section in "${expected_sections[@]}"; do
      if ! grep -qi "$section" "$profile_file"; then
        emit_warn "$rel_file" "0" "Profile may be missing \"${section}\" configuration"
      fi
    done
  done
}

# ─── Frontmatter validation ──────────────────────────────────────────────────

check_frontmatter() {
  local file="$1"
  local rel_file
  rel_file="$(rel_path "$file")"

  if ! has_frontmatter "$file"; then
    emit_error "$rel_file" "1" "Missing frontmatter (expected --- block at top with name, description, allowed-tools)"
    return 0
  fi

  local fm_end
  fm_end="$(get_frontmatter_end_line "$file")"
  if [[ -z "$fm_end" ]]; then
    emit_error "$rel_file" "1" "Frontmatter not closed (missing second --- delimiter)"
    return 0
  fi

  local name
  name="$(get_frontmatter_field "$file" "name")"
  if [[ -z "$name" ]]; then
    emit_error "$rel_file" "1" "Frontmatter missing required field: \"name\""
  else
    if [[ ${#name} -gt 64 ]]; then
      emit_warn "$rel_file" "2" "Frontmatter \"name\" exceeds 64 characters (${#name} chars)"
    fi
    if ! echo "$name" | grep -qE '^[a-z][a-z0-9-]*$'; then
      emit_warn "$rel_file" "2" "Frontmatter \"name\" should be lowercase with hyphens only (got: \"${name}\")"
    fi
  fi

  local desc
  desc="$(get_frontmatter_field "$file" "description")"
  if [[ -z "$desc" ]]; then
    emit_error "$rel_file" "1" "Frontmatter missing required field: \"description\""
  elif [[ ${#desc} -gt 1024 ]]; then
    emit_warn "$rel_file" "3" "Frontmatter \"description\" exceeds 1024 characters (${#desc} chars)"
  fi
}

# ─── Required sections by type ────────────────────────────────────────────────

check_required_sections() {
  local file="$1" component_type="$2"
  local rel_file
  rel_file="$(rel_path "$file")"

  local -a required_sections

  case "$component_type" in
    command)
      required_sections=("Input Formats" "When to Use" "When NOT to Use" "Workflow")
      ;;
    agent)
      required_sections=("When to Use" "When NOT to Use" "Workflow" "Tools Used")
      ;;
    skill)
      required_sections=("When to Use" "When NOT to Use")
      ;;
    *)
      return 0
      ;;
  esac

  for section in "${required_sections[@]}"; do
    if ! has_section "$file" "$section"; then
      emit_error "$rel_file" "0" "Missing required section: \"${section}\""
    fi
  done
}

# ─── Validate a single file ──────────────────────────────────────────────────

detect_component_type() {
  local file="$1"
  local rp
  rp="$(rel_path "$file")"

  if [[ "$rp" == commands/* ]]; then
    echo "command"
  elif [[ "$rp" == agents/* ]]; then
    echo "agent"
  elif [[ "$(basename "$file")" == "SKILL.md" ]]; then
    echo "skill"
  else
    echo "unknown"
  fi
}

validate_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "[ERROR] ${file}:0 — File not found"
    ERRORS=$((ERRORS + 1))
    return 0
  fi

  local component_type
  component_type="$(detect_component_type "$file")"

  if [[ "$component_type" == "unknown" ]]; then
    local rp
    rp="$(rel_path "$file")"
    echo "[WARN]  ${rp}:0 — Cannot determine component type (not in commands/, agents/, or a SKILL.md)"
    WARNINGS=$((WARNINGS + 1))
    return 0
  fi

  local errors_before=$ERRORS
  local warnings_before=$WARNINGS

  check_file_size "$file" "$component_type"
  check_frontmatter "$file"
  check_required_sections "$file" "$component_type"
  check_cross_references "$file"
  check_claude_md_reference "$file" "$component_type"

  if (( ERRORS == errors_before && WARNINGS == warnings_before )); then
    emit_pass "$(rel_path "$file")"
  fi
}

# ─── Collect files ────────────────────────────────────────────────────────────

collect_commands() {
  find "$TOOLKIT_DIR/commands" -name '*.md' -type f 2>/dev/null | sort
}

collect_agents() {
  find "$TOOLKIT_DIR/agents" -name '*.md' -type f 2>/dev/null | sort
}

collect_skills() {
  find "$TOOLKIT_DIR/skills" -name 'SKILL.md' -type f 2>/dev/null | sort
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: scripts/validate-toolkit.sh <file> [<file>...] | --all | --meta | --commands | --agents | --skills"
    exit 1
  fi

  local files=()
  local run_meta=false

  case "$1" in
    --all)
      run_meta=true
      while IFS= read -r f; do files+=("$f"); done < <(collect_commands)
      while IFS= read -r f; do files+=("$f"); done < <(collect_agents)
      while IFS= read -r f; do files+=("$f"); done < <(collect_skills)
      ;;
    --meta)
      run_meta=true
      ;;
    --commands)
      while IFS= read -r f; do files+=("$f"); done < <(collect_commands)
      ;;
    --agents)
      while IFS= read -r f; do files+=("$f"); done < <(collect_agents)
      ;;
    --skills)
      while IFS= read -r f; do files+=("$f"); done < <(collect_skills)
      ;;
    *)
      for arg in "$@"; do
        if [[ "$arg" == /* ]]; then
          files+=("$arg")
        else
          files+=("$TOOLKIT_DIR/$arg")
        fi
      done
      ;;
  esac

  # Validate component files
  if [[ ${#files[@]} -gt 0 ]]; then
    for file in "${files[@]}"; do
      validate_file "$file"
    done
  fi

  # Validate meta files (CLAUDE.md, profiles)
  if [[ "$run_meta" == true ]]; then
    echo ""
    echo "─── Meta Validation ────────────────────────────────"
    check_claude_md
    check_profiles
  fi

  if [[ ${#files[@]} -eq 0 && "$run_meta" == false ]]; then
    echo "No files found to validate."
    exit 0
  fi

  # Summary
  echo ""
  echo "─── Summary ────────────────────────────────────────"
  echo "  Errors:   ${ERRORS}"
  echo "  Warnings: ${WARNINGS}"
  echo "  Passed:   ${PASSES}"
  echo "────────────────────────────────────────────────────"

  if (( ERRORS > 0 || WARNINGS > 0 )); then
    exit 1
  fi
  exit 0
}

main "$@"
