#!/usr/bin/env bash
# validate_skill.sh — Structural validation for toolkit components
#
# Complements validate-toolkit.sh with deeper checks:
#   - Frontmatter field validation (required fields by component type)
#   - Section structure (required sections by component type)
#   - Cross-reference resolution (referenced files must exist)
#   - Size limits (warn on oversized components)
#   - Naming conventions (kebab-case, no spaces)
#
# Usage:
#   scripts/validate_skill.sh <file>              # Validate a single file
#   scripts/validate_skill.sh <directory>          # Validate all .md files in directory
#   scripts/validate_skill.sh --all                # Validate all commands, agents, skills
#
# Exit codes:
#   0 = all checks pass
#   1 = warnings only
#   2 = errors found

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Counters
ERRORS=0
WARNINGS=0
PASSES=0

# ─── Utility ────────────────────────────────────────────────────────────────

rel_path() {
  python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$1" "$TOOLKIT_DIR"
}

# ─── Output helpers ─────────────────────────────────────────────────────────

emit_error() {
  local file="$1" msg="$2"
  echo "[ERROR] ${file} — ${msg}"
  ERRORS=$((ERRORS + 1))
}

emit_warn() {
  local file="$1" msg="$2"
  echo "[WARN]  ${file} — ${msg}"
  WARNINGS=$((WARNINGS + 1))
}

emit_pass() {
  local file="$1"
  echo "[PASS]  ${file}"
  PASSES=$((PASSES + 1))
}

# ─── Component type detection ───────────────────────────────────────────────

detect_type() {
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

# ─── Frontmatter helpers ────────────────────────────────────────────────────

has_frontmatter() {
  head -1 "$1" | grep -q '^---$'
}

get_field() {
  local file="$1" field="$2"
  awk '/^---$/{n++; next} n==1{print}' "$file" | grep "^${field}:" | sed "s/^${field}:[[:space:]]*//"
}

has_section() {
  local file="$1" section="$2"
  grep -q "^##\+ ${section}" "$file"
}

# ─── Frontmatter validation ─────────────────────────────────────────────────

check_frontmatter() {
  local file="$1" ctype="$2"
  local rp
  rp="$(rel_path "$file")"

  case "$ctype" in
    command|agent)
      if ! has_frontmatter "$file"; then
        emit_error "$rp" "Missing frontmatter (commands and agents require --- block with name, description)"
        return
      fi
      local name desc
      name="$(get_field "$file" "name")"
      desc="$(get_field "$file" "description")"
      if [[ -z "$name" ]]; then
        emit_error "$rp" "Frontmatter missing required field: name"
      fi
      if [[ -z "$desc" ]]; then
        emit_error "$rp" "Frontmatter missing required field: description"
      fi
      ;;
    skill)
      # Skills may optionally have frontmatter; not required
      if has_frontmatter "$file"; then
        local name
        name="$(get_field "$file" "name")"
        if [[ -z "$name" ]]; then
          emit_warn "$rp" "Frontmatter present but missing name field"
        fi
      fi
      ;;
  esac
}

# ─── Required sections ──────────────────────────────────────────────────────

check_sections() {
  local file="$1" ctype="$2"
  local rp
  rp="$(rel_path "$file")"

  case "$ctype" in
    command)
      local -a required=("When to Use" "Workflow" "Error Handling")
      for section in "${required[@]}"; do
        if ! has_section "$file" "$section"; then
          # "When to Use / When NOT to Use" is an acceptable combined form
          if [[ "$section" == "When to Use" ]]; then
            if grep -q "When to Use" "$file"; then
              continue
            fi
          fi
          emit_error "$rp" "Missing required section: \"${section}\""
        fi
      done
      ;;
    agent)
      # Agents need: role description (checked via H1 or intro paragraph),
      # trigger info, capabilities
      local has_role=false has_trigger=false has_capabilities=false

      # Role description: first paragraph after H1 heading
      if grep -q '^# ' "$file"; then
        has_role=true
      fi

      # Trigger: "When to Use" section or mention of trigger command
      if has_section "$file" "When to Use" || grep -qE '`/[a-z]+`' "$file"; then
        has_trigger=true
      fi

      # Capabilities: "Workflow" or "Tools Used" section
      if has_section "$file" "Workflow" || has_section "$file" "Tools Used"; then
        has_capabilities=true
      fi

      if [[ "$has_role" == false ]]; then
        emit_error "$rp" "Missing role description (expected H1 heading)"
      fi
      if [[ "$has_trigger" == false ]]; then
        emit_warn "$rp" "No trigger information found (expected \"When to Use\" or command reference)"
      fi
      if [[ "$has_capabilities" == false ]]; then
        emit_warn "$rp" "No capabilities section (expected \"Workflow\" or \"Tools Used\")"
      fi
      ;;
    skill)
      # Skills need SKILL.md with an overview
      if ! grep -q '^# ' "$file"; then
        emit_error "$rp" "SKILL.md missing overview heading"
      fi
      if ! has_section "$file" "When to Use"; then
        emit_warn "$rp" "SKILL.md missing \"When to Use\" section"
      fi
      ;;
  esac
}

# ─── Cross-reference check ──────────────────────────────────────────────────

check_cross_refs() {
  local file="$1"
  local rp
  rp="$(rel_path "$file")"

  # Extract file path references like skills/building/templates/foo.md
  local refs
  refs="$(grep -oE '(skills|agents|commands|templates|profiles)/[a-zA-Z0-9_/-]+\.[a-z]{1,4}' "$file" 2>/dev/null | sort -u || true)"

  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    # Skip glob patterns and placeholders
    [[ "$ref" == *'*'* ]] && continue
    [[ "$ref" == *'${'* ]] && continue
    [[ "$ref" == *'{profile}'* ]] && continue
    [[ "$ref" == *'{layer}'* ]] && continue

    local target="$TOOLKIT_DIR/$ref"
    if [[ ! -e "$target" ]]; then
      emit_warn "$rp" "Referenced path \"${ref}\" does not exist"
    fi
  done <<< "$refs"
}

# ─── Size limits ─────────────────────────────────────────────────────────────

check_size() {
  local file="$1" ctype="$2"
  local rp
  rp="$(rel_path "$file")"
  local lines
  lines="$(wc -l < "$file" | tr -d ' ')"

  case "$ctype" in
    command)
      if (( lines > 200 )); then
        emit_warn "$rp" "Command exceeds 200 lines (${lines} lines)"
      fi
      ;;
    agent)
      if (( lines > 150 )); then
        emit_warn "$rp" "Agent exceeds 150 lines (${lines} lines)"
      fi
      ;;
    skill)
      if (( lines > 100 )); then
        emit_warn "$rp" "SKILL.md exceeds 100 lines (${lines} lines)"
      fi
      ;;
  esac
}

# ─── Naming conventions ─────────────────────────────────────────────────────

check_naming() {
  local file="$1"
  local rp
  rp="$(rel_path "$file")"
  local basename
  basename="$(basename "$file")"

  # SKILL.md is exempt from kebab-case check
  if [[ "$basename" == "SKILL.md" ]]; then
    return
  fi

  # Check for spaces in filename
  if [[ "$basename" == *" "* ]]; then
    emit_error "$rp" "Filename contains spaces (use kebab-case)"
    return
  fi

  # Check kebab-case: lowercase letters, digits, hyphens, and the .md extension
  local name_part="${basename%.md}"
  if ! echo "$name_part" | grep -qE '^[a-z][a-z0-9-]*$'; then
    emit_warn "$rp" "Filename \"${basename}\" is not kebab-case (expected lowercase-with-hyphens.md)"
  fi
}

# ─── Validate a single file ─────────────────────────────────────────────────

validate_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    emit_error "$file" "File not found"
    return
  fi

  local ctype
  ctype="$(detect_type "$file")"

  if [[ "$ctype" == "unknown" ]]; then
    local rp
    rp="$(rel_path "$file")"
    emit_warn "$rp" "Cannot determine component type (not in commands/, agents/, or a SKILL.md)"
    return
  fi

  local errors_before=$ERRORS
  local warnings_before=$WARNINGS

  check_frontmatter "$file" "$ctype"
  check_sections "$file" "$ctype"
  check_cross_refs "$file"
  check_size "$file" "$ctype"
  check_naming "$file"

  if (( ERRORS == errors_before && WARNINGS == warnings_before )); then
    emit_pass "$(rel_path "$file")"
  fi
}

# ─── Collect files ───────────────────────────────────────────────────────────

collect_from_dir() {
  local dir="$1"
  find "$dir" -name '*.md' -type f 2>/dev/null | sort
}

# ─── Main ────────────────────────────────────────────────────────────────────

main() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: scripts/validate_skill.sh <file_or_directory> | --all"
    echo ""
    echo "Structural validation for toolkit components (commands, agents, skills)."
    echo ""
    echo "Exit codes:"
    echo "  0 = all checks pass"
    echo "  1 = warnings only"
    echo "  2 = errors found"
    exit 1
  fi

  local files=()

  case "$1" in
    --all)
      while IFS= read -r f; do files+=("$f"); done < <(find "$TOOLKIT_DIR/commands" -name '*.md' -type f 2>/dev/null | sort)
      while IFS= read -r f; do files+=("$f"); done < <(find "$TOOLKIT_DIR/agents" -name '*.md' -type f 2>/dev/null | sort)
      while IFS= read -r f; do files+=("$f"); done < <(find "$TOOLKIT_DIR/skills" -name 'SKILL.md' -type f 2>/dev/null | sort)
      ;;
    *)
      for arg in "$@"; do
        local target
        if [[ "$arg" == /* ]]; then
          target="$arg"
        else
          target="$TOOLKIT_DIR/$arg"
        fi

        if [[ -d "$target" ]]; then
          while IFS= read -r f; do files+=("$f"); done < <(collect_from_dir "$target")
        elif [[ -f "$target" ]]; then
          files+=("$target")
        else
          emit_error "$arg" "Path not found"
        fi
      done
      ;;
  esac

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "No files found to validate."
    exit 0
  fi

  echo "Atelier Skill Validator"
  echo "======================="
  echo ""

  for file in "${files[@]}"; do
    validate_file "$file"
  done

  # Summary
  echo ""
  echo "─── Summary ────────────────────────────────────────"
  echo "  Errors:   ${ERRORS}"
  echo "  Warnings: ${WARNINGS}"
  echo "  Passed:   ${PASSES}"
  echo "────────────────────────────────────────────────────"

  if (( ERRORS > 0 )); then
    exit 2
  elif (( WARNINGS > 0 )); then
    exit 1
  fi
  exit 0
}

main "$@"
