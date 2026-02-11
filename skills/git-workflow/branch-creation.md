# Branch Creation

**Purpose:** Generate properly-formatted branch names following Axomic conventions.

**Format:** `<INITIALS>_<description>_<TICKET-ID>`

---

## Branch Name Format

```
<INITIALS>_<description>_<TICKET-ID>
```

### Components

| Component | Rules | Examples |
|-----------|-------|----------|
| **INITIALS** | Uppercase, 2-4 letters | `JRA`, `ABC`, `CLAUDE` |
| **description** | lowercase-with-hyphens, 3-5 words max, letters/numbers/hyphens only | `add-user-export`, `fix-dockerfile`, `update-healthcheck` |
| **TICKET-ID** | PROJECT-NUMBER format | `SHRED-2119`, `OA-1655`, `AXO-492`, `TOOLKIT-a7f3` |

---

## Generation Logic

### Step 1: Get User Initials

```bash
# Read from .claude/config.json or default to CLAUDE
if [ -f ".claude/config.json" ]; then
    INITIALS=$(jq -r '.user.initials // "CLAUDE"' .claude/config.json)
else
    INITIALS="CLAUDE"
fi

# Ensure uppercase
INITIALS=$(echo "$INITIALS" | tr '[:lower:]' '[:upper:]')
```

**Config file** (`.claude/config.json`):
```json
{
  "user": {
    "initials": "JRA"
  }
}
```

---

### Step 2: Generate Description

**From context file title:**
```bash
# Extract ticket title from context file
# Example: "Add user export functionality" → "add-user-export-functionality"

TITLE=$(extract_ticket_title_from_context)
DESCRIPTION=$(echo "$TITLE" | \
    tr '[:upper:]' '[:lower:]' | \  # Lowercase
    sed 's/[^a-z0-9]/-/g' | \       # Replace non-alphanumeric with hyphens
    sed 's/--*/-/g' | \             # Collapse multiple hyphens
    sed 's/^-//' | \                # Remove leading hyphen
    sed 's/-$//')                   # Remove trailing hyphen

# Limit to 5 words (first 5 hyphen-separated parts)
DESCRIPTION=$(echo "$DESCRIPTION" | cut -d'-' -f1-5)
```

**From command argument:**
```bash
# Example: /build "Add rate limiting"
# User provides: "Add rate limiting"
# Convert to: "add-rate-limiting"

USER_INPUT="$1"  # "Add rate limiting"
DESCRIPTION=$(echo "$USER_INPUT" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9]/-/g' | \
    sed 's/--*/-/g' | \
    sed 's/^-//' | \
    sed 's/-$//')

# Result: "add-rate-limiting"
```

**Examples:**
- Input: "Add user export functionality" → `add-user-export-functionality`
- Input: "Fix Dockerfile multi-stage build" → `fix-dockerfile-multi-stage-build`
- Input: "Update healthcheck endpoint" → `update-healthcheck-endpoint`

---

### Step 3: Extract or Generate Ticket ID

**Option A: Extract from context file**
```bash
# Look for Jira ticket ID in context file
# Patterns: SHRED-2119, OA-1655, AXO-492

TICKET_ID=$(grep -oE '[A-Z]+-[0-9]+' "$CONTEXT_FILE" | head -1)

# Examples:
# SHRED-2119
# OA-1655
# AXO-492
```

**Option B: Generate if no ticket**
```bash
# Use first 4 chars of session ID
SHORT_ID=$(echo "$SESSION_ID" | head -c 4)
TICKET_ID="TOOLKIT-${SHORT_ID}"

# Example: TOOLKIT-a7f3
```

---

### Step 4: Combine Components

```bash
BRANCH_NAME="${INITIALS}_${DESCRIPTION}_${TICKET_ID}"

# Examples:
# JRA_add-user-export-functionality_SHRED-2119
# ABC_fix-dockerfile-multi-stage-build_OA-1655
# CLAUDE_update-healthcheck-endpoint_TOOLKIT-a7f3
```

---

## Validation Rules

Before creating branch, validate:

```bash
# 1. Check format matches pattern
if ! echo "$BRANCH_NAME" | grep -qE '^[A-Z]{2,4}_[a-z0-9-]+_[A-Z]+-[0-9a-z]+$'; then
    echo "Error: Branch name doesn't match format"
    exit 1
fi

# 2. Check description not too long (max 50 chars)
DESC_LENGTH=$(echo "$DESCRIPTION" | wc -c)
if [ "$DESC_LENGTH" -gt 50 ]; then
    echo "Warning: Description is long, consider shortening"
fi

# 3. Check branch doesn't already exist
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    echo "Error: Branch '$BRANCH_NAME' already exists"
    echo "Suggestions:"
    echo "  - Use different description"
    echo "  - Delete old branch: git branch -D $BRANCH_NAME"
    exit 1
fi
```

---

## Complete Example

```bash
#!/usr/bin/env bash
# Generate branch name for /build SHRED-2119

# Inputs
CONTEXT_FILE=".claude/context/SHRED-2119.md"
SESSION_ID="abc123-def456"

# Step 1: Get initials
INITIALS=$(jq -r '.user.initials // "CLAUDE"' .claude/config.json 2>/dev/null || echo "CLAUDE")
INITIALS=$(echo "$INITIALS" | tr '[:lower:]' '[:upper:]')
# Result: "JRA"

# Step 2: Generate description
TITLE=$(grep -m1 "^# " "$CONTEXT_FILE" | sed 's/^# //')
DESCRIPTION=$(echo "$TITLE" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9]/-/g' | \
    sed 's/--*/-/g' | \
    sed 's/^-//' | \
    sed 's/-$//' | \
    cut -d'-' -f1-5)
# Result: "add-user-export-functionality"

# Step 3: Extract ticket ID
TICKET_ID=$(grep -oE '[A-Z]+-[0-9]+' "$CONTEXT_FILE" | head -1)
# Result: "SHRED-2119"

# Step 4: Combine
BRANCH_NAME="${INITIALS}_${DESCRIPTION}_${TICKET_ID}"
# Result: "JRA_add-user-export-functionality_SHRED-2119"

# Step 5: Validate
if echo "$BRANCH_NAME" | grep -qE '^[A-Z]{2,4}_[a-z0-9-]+_[A-Z]+-[0-9a-z]+$'; then
    echo "$BRANCH_NAME"
else
    echo "Error: Invalid branch name format" >&2
    exit 1
fi
```

---

## Script Integration

The toolkit provides `scripts/generate-branch-name.sh`:

```bash
# Usage
BRANCH_NAME=$(./scripts/generate-branch-name.sh \
    --context-file ".claude/context/SHRED-2119.md" \
    --description "add user export functionality" \
    --session-id "$SESSION_ID")

# Or with arguments
BRANCH_NAME=$(./scripts/generate-branch-name.sh \
    --description "fix authentication timeout" \
    --ticket "OA-1700")

# Returns: JRA_add-user-export-functionality_SHRED-2119
```

---

## Common Patterns

| Context | Ticket | Description | Branch Name |
|---------|--------|-------------|-------------|
| Jira ticket | SHRED-2119 | "Add user export" | `JRA_add-user-export_SHRED-2119` |
| Bug fix | OA-1655 | "Fix Dockerfile build" | `JRA_fix-dockerfile-build_OA-1655` |
| Feature | AXO-492 | "Implement proposal service" | `JRA_implement-proposal-service_AXO-492` |
| No ticket | - | "Add rate limiting" | `JRA_add-rate-limiting_TOOLKIT-a7f3` |
| Command input | - | User types: "Update healthcheck" | `JRA_update-healthcheck_TOOLKIT-b2d9` |

---

## Troubleshooting

### Branch Already Exists

```bash
Error: Branch 'JRA_add-export_SHRED-2119' already exists

Solutions:
1. Use more specific description: JRA_add-user-export-csv_SHRED-2119
2. Delete old branch: git branch -D JRA_add-export_SHRED-2119
3. Use existing branch: cd .claude/worktrees/<old-session>/
```

### Description Too Generic

```bash
Warning: Description 'fix' is too short

Suggestions:
- Be specific: fix-auth-timeout, fix-database-connection
- Include what's being fixed: fix-dockerfile-build
- Aim for 3-5 words
```

### Invalid Characters

```bash
Error: Invalid characters in description

Problem: User typed "Add feature (v2)"
Result: add-feature--v2-- (invalid)

Fix: Remove special chars before processing:
echo "Add feature (v2)" | sed 's/[^a-zA-Z0-9 ]//g'
Result: add-feature-v2
```

---

## Related Documentation

- [Worktree Setup](./worktree-setup.md) - Calls branch creation
- [Session Management](./session-management.md) - Stores branch name
- [Axomic Branch Naming Convention](../../docs/standards/conventions/branch-naming.md) - Source of truth

---

**Integration:** This logic is used in Step 3 of [worktree-setup.md](./worktree-setup.md).
