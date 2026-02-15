#!/usr/bin/env bash
# Atelier Cross-Platform Path Library
# Shared library of platform-agnostic path functions.
# macOS realpath doesn't support --relative-to, and path handling
# varies across scripts. This library provides consistent behavior.
#
# Usage (sourced by other scripts):
#   source "${SCRIPT_DIR}/../lib/paths.sh"
#   PROJECT_ROOT=$(find_project_root)
#   REL=$(relative_path "$PROJECT_ROOT" "$FILE")
#
# All functions are POSIX-compatible (no GNU coreutils required).

# normalize_path <path>
# Remove trailing slashes, resolve . and .. components.
# Does NOT resolve symlinks or require the path to exist.
normalize_path() {
  local path="$1"
  # Handle empty input
  if [[ -z "$path" ]]; then
    echo "."
    return
  fi

  # Determine if absolute
  local is_absolute=false
  [[ "$path" == /* ]] && is_absolute=true

  # Split on / and resolve . and ..
  local -a parts=()
  local IFS='/'
  local segment
  for segment in $path; do
    case "$segment" in
      ''|'.') continue ;;
      '..')
        if [[ ${#parts[@]} -gt 0 && "${parts[-1]}" != ".." ]]; then
          unset 'parts[-1]'
        elif [[ "$is_absolute" == false ]]; then
          parts+=("..")
        fi
        ;;
      *) parts+=("$segment") ;;
    esac
  done

  # Reconstruct
  local result=""
  if [[ "$is_absolute" == true ]]; then
    result="/"
  fi

  local joined
  joined=$(printf '%s/' "${parts[@]}")
  joined="${joined%/}"  # Remove trailing slash

  if [[ -z "$joined" && "$is_absolute" == true ]]; then
    echo "/"
  elif [[ -z "$joined" ]]; then
    echo "."
  else
    echo "${result}${joined}"
  fi
}

# resolve_path <path>
# Resolve to absolute path. Works on macOS and Linux without GNU realpath.
# Resolves symlinks and requires the path (or its parent) to exist.
resolve_path() {
  local target="$1"

  if [[ -d "$target" ]]; then
    (cd "$target" && pwd -P)
  elif [[ -f "$target" ]]; then
    local dir
    dir=$(cd "$(dirname "$target")" && pwd -P)
    echo "${dir}/$(basename "$target")"
  elif [[ -d "$(dirname "$target")" ]]; then
    # Path doesn't exist yet, but parent does -- resolve parent
    local dir
    dir=$(cd "$(dirname "$target")" && pwd -P)
    echo "${dir}/$(basename "$target")"
  else
    # Neither target nor parent exists; normalize against CWD
    if [[ "$target" == /* ]]; then
      normalize_path "$target"
    else
      normalize_path "$(pwd)/$target"
    fi
  fi
}

# relative_path <from> <to>
# Get relative path from one absolute path to another.
# Pure bash implementation, no realpath --relative-to needed.
# Both arguments must be absolute paths.
relative_path() {
  local from to
  from=$(normalize_path "$1")
  to=$(normalize_path "$2")

  # Both must be absolute
  if [[ "$from" != /* || "$to" != /* ]]; then
    echo "Error: relative_path requires absolute paths" >&2
    return 1
  fi

  # Split into arrays
  local IFS='/'
  local -a from_parts=($from)
  local -a to_parts=($to)

  # Find common prefix length (skip empty first element from leading /)
  local common=1
  while [[ $common -lt ${#from_parts[@]} && $common -lt ${#to_parts[@]} ]]; do
    if [[ "${from_parts[$common]}" != "${to_parts[$common]}" ]]; then
      break
    fi
    ((common++))
  done

  # Build relative path: go up from $from, then down to $to
  local result=""
  local i

  # Number of levels to go up from $from
  for (( i=common; i<${#from_parts[@]}; i++ )); do
    if [[ -n "$result" ]]; then
      result="${result}/.."
    else
      result=".."
    fi
  done

  # Append remaining path to $to
  for (( i=common; i<${#to_parts[@]}; i++ )); do
    if [[ -n "$result" ]]; then
      result="${result}/${to_parts[$i]}"
    else
      result="${to_parts[$i]}"
    fi
  done

  # Same directory
  if [[ -z "$result" ]]; then
    result="."
  fi

  echo "$result"
}

# ensure_dir <path>
# Create directory if it doesn't exist, return resolved absolute path.
ensure_dir() {
  local dir="$1"
  mkdir -p "$dir"
  resolve_path "$dir"
}

# is_subpath <parent> <child>
# Check if child path is under the parent directory.
# Returns 0 (true) if child is under parent, 1 (false) otherwise.
is_subpath() {
  local parent child
  parent=$(normalize_path "$1")
  child=$(normalize_path "$2")

  # Ensure trailing slash on parent for prefix matching
  # (prevents /foo matching /foobar)
  [[ "$parent" != */ ]] && parent="${parent}/"

  # Child is a subpath if it starts with parent prefix, or equals parent (without trailing /)
  if [[ "$child/" == "$parent"* ]]; then
    return 0
  fi
  return 1
}

# find_project_root [start_dir]
# Walk up from start_dir (default: CWD) looking for project root markers:
# .git, .atelier, or CLAUDE.md
find_project_root() {
  local dir
  dir=$(resolve_path "${1:-.}")

  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.git" || -d "$dir/.atelier" || -f "$dir/CLAUDE.md" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done

  # Check root as well
  if [[ -d "/.git" || -d "/.atelier" || -f "/CLAUDE.md" ]]; then
    echo "/"
    return 0
  fi

  echo "Error: Could not find project root (no .git, .atelier, or CLAUDE.md found)" >&2
  return 1
}
