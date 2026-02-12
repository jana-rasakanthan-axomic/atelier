# Branch Creation — Extended Examples

## Complete Script Example

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
