# Requirements Analysis

**Purpose:** Extract and classify requirements from PRDs, epics, and user stories.

**Part of:** Design skill

---

## Overview

Requirements analysis is the process of reading product requirements documents and extracting structured, actionable requirements that can be turned into design tickets.

---

## Classification

### Functional Requirements

**Definition:** What the system must DO.

**Examples:**
- User can log in with email magic link
- System exports data to CSV or JSON
- API returns list of recipes filtered by tag
- Assets can be reordered within a block

**Format:**
- Start with action verbs: "User can...", "System must...", "API returns..."
- Be specific about inputs and outputs
- Avoid implementation details (HOW)

### Non-Functional Requirements

**Definition:** How the system must PERFORM or BEHAVE.

**Categories:**
1. **Performance:** Speed, throughput, latency
   - Example: "Complete export in <60s for 100k records"
2. **Security:** Auth, authorization, data protection
   - Example: "Validate JWT signature using Auth0 JWKS"
3. **Scalability:** Load handling, concurrent users
   - Example: "Support 1000 concurrent users"
4. **Reliability:** Uptime, error handling
   - Example: "99.9% uptime"
5. **Compatibility:** Backwards compatibility, API versioning
   - Example: "No breaking changes to existing endpoints"
6. **Testability:** Coverage targets
   - Example: ">85% test coverage for auth code"

---

## Extraction Process

### Step 1: Read PRD

Scan for:
- **User stories:** "As a [role], I want to [action], so that [benefit]"
- **Acceptance criteria:** Specific conditions for success
- **Technical requirements:** Performance, security, scale
- **Constraints:** What must NOT change or be used

### Step 2: Identify User Value

For each requirement, ask:
- What user problem does this solve?
- What business value does this deliver?
- What pain point does this address?

If unclear, it may be a technical task, not a user-facing requirement.

### Step 3: Classify Requirements

Create two lists:
1. **Functional:** What the system does
2. **Non-Functional:** How it performs

### Step 4: Extract Constraints

Identify:
- **Must use:** Required technologies, patterns, services
- **Must NOT change:** Existing APIs, data models
- **Must follow:** Architectural patterns, security policies

### Step 5: Identify Out of Scope

Explicitly list what is NOT included:
- Future enhancements mentioned in PRD
- Nice-to-have features
- Related features that are separate efforts

---

## Example

See `reference/requirements-analysis-example.md` for a worked example (User Data Export) showing the full extraction process applied to a PRD.

---

## Tips for Success

### 1. Focus on Capabilities, Not Implementation

**Bad (Too Implementation-Heavy):**
> "Create a Celery task that queries the database for all user records and writes them to a CSV file in S3"

**Good (Capability-Focused):**
> "Export user data asynchronously to handle large datasets"

### 2. Be Specific About Success

**Bad (Vague):**
> "Export should be fast"

**Good (Specific):**
> "Export completes in <60s for 100k records (P95)"

### 3. Extract Hidden Requirements

PRDs often imply requirements without stating them explicitly.

**Example:**
- PRD says: "User sees loading spinner"
- Hidden requirement: **Async operation** (long-running process)

**Example:**
- PRD says: "User can download file"
- Hidden requirement: **File storage** (where is file stored?)
- Hidden requirement: **Expiring links** (how long is file available?)

### 4. Translate UI Language to Backend Needs

| PRD Statement (UI) | Backend Requirement |
|--------------------|---------------------|
| "User clicks Export button" | API endpoint: `POST /api/users/export` |
| "User sees loading spinner" | Async job pattern (long-running) |
| "User selects CSV or JSON" | Request param: `format: "csv" \| "json"` |
| "File downloads when ready" | Return signed URL or file stream |
| "User sees error message" | HTTP error responses with clear messages |

See [prd-translation.md](prd-translation.md) for full guide.

---

## Common Mistakes

### ❌ Mistake 1: Listing Technical Tasks as Requirements

**Wrong:**
- "Create ExportService class"
- "Add database migration for exports table"
- "Implement Celery task"

**Right:**
- "Export user data asynchronously"
- "Track export job status"
- "Store export results for download"

### ❌ Mistake 2: Over-Specifying Performance

**Wrong:**
- "Must complete in exactly 45 seconds"
- "Must use Redis with 1-hour TTL"

**Right:**
- "Complete in <60s for 100k records"
- "Cache results to reduce load"

### ❌ Mistake 3: Missing Non-Functional Requirements

Don't forget:
- Security (who can access what?)
- Performance (how fast? how much data?)
- Reliability (what if it fails?)
- Compatibility (breaking changes?)

---

## Checklist

Use this to validate your requirements analysis:

- [ ] All user stories extracted
- [ ] Functional requirements listed (what system does)
- [ ] Non-functional requirements listed (how system performs)
- [ ] Constraints identified (must/must not)
- [ ] Out of scope explicitly listed
- [ ] Requirements are capabilities, not tasks
- [ ] Requirements are specific and measurable
- [ ] Hidden requirements surfaced (implied by PRD)
- [ ] UI language translated to backend needs

---

## Related

- **PRD Translation:** [prd-translation.md](prd-translation.md)
- **Constraint Definition:** [constraint-definition.md](constraint-definition.md)
- **Main Skill:** [SKILL.md](SKILL.md)
