#!/usr/bin/env bash
# Atelier Gather Interview
# Outputs a structured requirements questionnaire template for /gather.
# Captures context (persona, problem, success criteria, features, constraints,
# exclusions) before the LLM processes input.
#
# Usage:
#   gather_interview.sh [output_file]
#
# If output_file is provided, writes the template there.
# Otherwise, writes to stdout.
#
# Exit codes:
#   0 - Success
#   1 - Cannot write to output file

set -euo pipefail

# ─── Input handling ─────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: gather_interview.sh [output_file]

Generates a structured requirements questionnaire template for /gather.
Outputs markdown with sections for persona, problem, success criteria,
features, constraints, and exclusions.

If output_file is provided, writes the template to that file.
Otherwise, writes to stdout.

Examples:
  gather_interview.sh                          # Print to stdout
  gather_interview.sh .claude/context/reqs.md  # Write to file
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

OUTPUT_FILE="${1:-}"

# ─── Template ───────────────────────────────────────────────────────────────

generate_template() {
  cat <<'TEMPLATE'
# Requirements Gathering

> Fill in each section below. Leave items blank if unknown -- they will be
> clarified during /specify.

---

## Persona

Who is the primary user? Describe their role, technical level, and goals.

- **Role:**
- **Technical level:** (non-technical / semi-technical / developer / ops)
- **Primary goal:**

---

## Problem Statement

What problem are we solving? Describe the current pain, its impact, and how
frequently it occurs.

- **Current pain:**
- **Impact:** (time lost / revenue / user frustration / risk)
- **Frequency:** (daily / weekly / per-release / one-time)

---

## Success Criteria / KPIs

How will we know it is working? List measurable outcomes.

- [ ]
- [ ]
- [ ]

---

## Key Features

What are the must-have features? List in priority order (highest first).

1.
2.
3.

---

## Constraints

What are the boundaries? Check all that apply and add details.

- [ ] **Timeline:** (deadline or time-box)
- [ ] **Tech stack:** (language, framework, platform restrictions)
- [ ] **Budget:** (cost limits, infrastructure caps)
- [ ] **Compliance:** (GDPR, SOC2, HIPAA, accessibility)
- [ ] **Dependencies:** (other teams, APIs, third-party services)

---

## Out of Scope

What are we NOT building? List explicit exclusions to prevent scope creep.

-
-
-
TEMPLATE
}

# ─── Output ─────────────────────────────────────────────────────────────────

if [[ -n "$OUTPUT_FILE" ]]; then
  # Ensure parent directory exists
  output_dir="$(dirname "$OUTPUT_FILE")"
  if [[ ! -d "$output_dir" ]]; then
    mkdir -p "$output_dir" || {
      echo "Error: Cannot create directory: $output_dir" >&2
      exit 1
    }
  fi

  generate_template > "$OUTPUT_FILE" || {
    echo "Error: Cannot write to file: $OUTPUT_FILE" >&2
    exit 1
  }

  echo "Interview template written to: $OUTPUT_FILE" >&2
else
  generate_template
fi

exit 0
