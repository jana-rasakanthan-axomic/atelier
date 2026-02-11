# Business Rules Extraction Skill

Extract high-level business rules and constraints from Product Requirements Documents (PRDs) for user review and approval.

## Purpose

Support the **design phase** by:
1. Reading PRDs and extracting implicit business rules
2. Structuring rules in clear, reviewable format
3. Writing rules to file for user review/approval
4. Providing foundation for BDD scenarios and implementation

## When to Use

- **For PM-facing extraction:** Use `skills/specify/business-rules.md` via `/specify` command (mandatory before `/design`)
- **For engineer reference:** This skill documents the engineering-focused format (includes Enforcement field)

**Note:** Business rules extraction is now handled exclusively by `/specify` as a mandatory prerequisite for `/design`. This file serves as the engineering reference for rule format and categories.

**Specific use cases:**
- **Reference for rule categories** - Understanding the 8 rule types
- **PRD contains implicit rules** - Rules embedded in user stories/requirements
- **Need explicit constraints** - Convert informal requirements to formal rules
- **Multi-stakeholder review** - Rules document becomes contract between product/engineering

## When NOT to Use

- **Rules already explicit** - PRD already contains structured rules (just copy them)
- **Implementation details** - This is for business logic, not technical decisions
- **After design phase** - Rules should be extracted during design, not during implementation

## Rule Categories

### 1. Authorization Rules
Who can perform actions, access data, or use features.

**Examples:**
- Users can only export their own data
- Admins can view all user accounts
- Guest users cannot create content

### 2. Validation Rules
Constraints on input data, formats, ranges.

**Examples:**
- Email must match RFC 5322 format
- Password must be 8+ characters with special character
- File uploads limited to 10MB

### 3. Rate Limiting Rules
Frequency constraints, quotas, throttling.

**Examples:**
- Users can create maximum 5 exports per day
- API calls limited to 1000 requests per hour
- Free tier: 100 API calls per month

### 4. Performance Rules
Latency requirements, timeout constraints, scale expectations.

**Examples:**
- API responses must complete within 500ms
- Exports up to 100k records must complete within 60 seconds
- System must handle 10k concurrent users

### 5. Data Retention Rules
How long data is stored, when it's deleted, archival policies.

**Examples:**
- Export files expire after 24 hours
- User sessions timeout after 30 minutes of inactivity
- Audit logs retained for 7 years

### 6. Data Privacy Rules
PII handling, sensitive data exclusions, audit requirements.

**Examples:**
- Exports exclude password hashes and tokens
- User deletion removes all personal data
- All data access logged for audit trail

### 7. Business Logic Rules
Core domain constraints, business process rules.

**Examples:**
- Orders cannot be cancelled after shipment
- Refunds processed within 3-5 business days
- Subscriptions auto-renew unless cancelled 24h before

### 8. Integration Rules
Constraints on external system interactions.

**Examples:**
- Payment processing via Stripe only
- Email delivery uses SendGrid with fallback to SES
- File storage in S3 with 11 nines durability

## Extraction Process

### Step 1: Read PRD Thoroughly

Identify sections containing requirements, user stories, acceptance criteria, constraints.

### Step 2: Identify Implicit Rules

Look for phrases indicating rules:
- "Users can..." → Authorization rule
- "Must be..." → Validation rule
- "Limited to..." → Rate limiting rule
- "Should complete within..." → Performance rule
- "Available for..." → Data retention rule
- "Exclude..." → Data privacy rule

### Step 3: Structure Rules

**Template:**
```markdown
## Business Rules: [Feature Name]

### Rule: [Category] - [Short Name]

**Statement:** [Clear, concise rule statement]

**Rationale:** [Why this rule exists]

**Enforcement:** [Where/how rule is enforced]

**Exceptions:** [Any exceptions to the rule]

**Examples:**
- ✅ [Valid case]
- ❌ [Invalid case]
```

### Step 4: Write to File

**Output location:** `.claude/design/[feature-name]-rules.md`

### Step 5: Present for User Review

**Prompt:**
```markdown
I've extracted [N] business rules from the PRD:

1. Authorization: Users can only export their own data
2. Rate Limiting: Maximum 5 exports per day
3. Performance: Complete within 60s for 100k records
4. Data Retention: Files expire after 24 hours
5. Data Privacy: Exclude passwords from exports

**Review file:** .claude/design/[feature]-rules.md

Are these rules complete and accurate? Should I:
- ✅ Proceed with these rules
- ✏️ Add missing rule: [description]
- ✏️ Modify rule #N: [changes]
- ❌ Start over with different interpretation
```

### Step 6: Incorporate Feedback

Update rules file based on user feedback, then proceed to next stage.

## Output Format

```markdown
# Business Rules: [Feature Name]

**Feature:** [Feature description from PRD]
**Date:** [YYYY-MM-DD]
**Source:** [Link to PRD file]
**Status:** Draft | Under Review | Approved

---

## Rule 1: Authorization - User Data Access

**Statement:** Users can only export their own account data. Admins can export any user's data.

**Rationale:** Privacy and security - users should not access other users' data without authorization.

**Enforcement:**
- API layer: JWT token validation extracts user_id
- Service layer: Compare request user_id with authenticated user_id
- Raise `ForbiddenError` if mismatch (unless admin role)

**Exceptions:**
- Admin users (role=admin) can export any user's data
- Support staff (role=support) can export with user consent ticket

**Examples:**
- ✅ User A requests export of User A's data → Allowed
- ❌ User A requests export of User B's data → Forbidden (403)
- ✅ Admin requests export of User B's data → Allowed
- ✅ Support staff requests export with ticket #12345 → Allowed

---

## Rule 2: Rate Limiting - Daily Export Quota

**Statement:** Standard users can create maximum 5 exports per 24-hour period. Admin users have unlimited exports.

**Rationale:** Prevent system abuse, manage infrastructure costs, ensure fair resource allocation.

**Enforcement:**
- Service layer: Query export_jobs table for count of jobs created in last 24 hours
- If count >= 5, raise `RateLimitExceededError` with retry_after timestamp
- Return 429 Too Many Requests with Retry-After header

**Exceptions:**
- Admin users (role=admin) have no rate limit
- Rate limit resets exactly 24 hours after first export (not at midnight)

**Examples:**
- ✅ User creates 1st export → Allowed
- ✅ User creates 5th export → Allowed
- ❌ User creates 6th export within 24h → Rate Limited (429)
- ⏰ User waits 24h, creates export → Allowed (reset)
- ✅ Admin creates 100th export → Allowed (no limit)

---

## Rule 3: Performance - Export Completion Time

**Statement:** Exports containing up to 100,000 records must complete within 60 seconds. Larger exports are rejected.

**Rationale:** Ensure predictable performance, prevent resource exhaustion, manage user expectations.

**Enforcement:**
- API layer: Validate request before creating job
- Service layer: Estimate row count from filters
- If estimated rows > 100k, raise `ExportTooLargeError` (400 Bad Request)
- Background worker: Timeout job after 120 seconds (2x target)

**Exceptions:**
- Admin-initiated exports can exceed 100k (with explicit confirmation)
- Batched exports (future feature) can handle larger datasets

**Examples:**
- ✅ Export 50k users → Completes in ~30 seconds
- ✅ Export 100k users → Completes in ~60 seconds
- ❌ Export 150k users → Rejected immediately (400)
- ⏰ Export times out after 120s → Job marked as failed

---

## Rule 4: Data Retention - Export File Expiration

**Statement:** Export files are available for 24 hours via signed URL, then automatically deleted.

**Rationale:** Security (limit exposure of sensitive data), cost management (S3 storage costs), compliance (no long-term storage of exports).

**Enforcement:**
- Service layer: Generate S3 signed URL with 24-hour expiry
- Background job: Daily cleanup deletes files older than 24 hours
- Database: Mark export_jobs as expired after 24h

**Exceptions:**
- Users can re-request export if file expired (new job, not extension)
- Archived exports (future feature) have longer retention

**Examples:**
- ✅ Export created at 10:00, accessible until 10:00 next day
- ⏰ Export created at 10:00, accessed at 09:30 next day → Success
- ❌ Export created at 10:00, accessed at 10:05 next day → Expired (410 Gone)
- 🗑️ Cleanup job runs daily at midnight, deletes files > 24h old

---

## Rule 5: Data Privacy - Sensitive Field Exclusion

**Statement:** Exports exclude sensitive fields: password hashes, API tokens, OAuth secrets, session IDs.

**Rationale:** Security - prevent credential leakage. Compliance - GDPR/CCPA require protection of sensitive data.

**Enforcement:**
- Repository layer: SELECT statement explicitly lists included columns
- Exclude: password_hash, api_key, oauth_token, session_id, refresh_token
- Service layer: Validate export does not contain sensitive fields

**Exceptions:**
- Admin-initiated forensic exports (with explicit flag) can include hashed passwords
- User can export their own API keys (separate endpoint, not bulk export)

**Examples:**
- ✅ Export includes: id, email, name, created_at, subscription_status
- ❌ Export excludes: password_hash, api_key, oauth_token
- 🔒 Forensic export (admin, explicit flag) includes password_hash (still hashed)

---

## Rule 6: Business Logic - Concurrent Export Limit

**Statement:** Users can have maximum 3 exports in "pending" or "processing" status simultaneously.

**Rationale:** Prevent resource exhaustion, ensure queue fairness, improve job completion rates.

**Enforcement:**
- Service layer: Query export_jobs for count where status IN (pending, processing)
- If count >= 3, raise `TooManyConcurrentExportsError` (429)

**Exceptions:**
- Completed or failed exports do not count toward limit
- Admin users have higher limit (10 concurrent exports)

**Examples:**
- ✅ User has 2 pending exports, requests 3rd → Allowed
- ❌ User has 3 pending exports, requests 4th → Rejected (429)
- ✅ User's export completes, requests new export → Allowed
- ✅ Admin has 10 concurrent exports → Allowed

---

## Rule 7: Integration - Storage Requirements

**Statement:** Export files stored in S3 with server-side encryption (AES-256). Signed URLs use SigV4.

**Rationale:** Security (encryption at rest), compliance (SOC2 requirement), reliability (S3 durability).

**Enforcement:**
- Storage service: S3 upload with ServerSideEncryption=AES256
- Signed URL generation: Use boto3 with signature_version='s3v4'
- Bucket policy: Enforce encryption, deny unencrypted uploads

**Exceptions:**
- None - encryption is mandatory for all exports

**Examples:**
- ✅ Upload to S3 with encryption → Success
- ❌ Upload without encryption → Rejected by bucket policy
- 🔒 All exports encrypted at rest automatically

---

## Summary

**Total Rules:** 7

**By Category:**
- Authorization: 1 rule
- Rate Limiting: 2 rules (daily quota, concurrent limit)
- Performance: 1 rule
- Data Retention: 1 rule
- Data Privacy: 1 rule
- Integration: 1 rule

**Critical Rules (Must Have for MVP):**
- ✅ Rule 1: Authorization (security)
- ✅ Rule 2: Rate Limiting - Daily Quota (cost control)
- ✅ Rule 4: Data Retention (compliance)
- ✅ Rule 5: Data Privacy (security)

**Nice-to-Have (Can Defer):**
- Rule 3: Performance limit (can be soft limit initially)
- Rule 6: Concurrent limit (can be added post-MVP)
- Rule 7: S3 encryption (should have, but can use default encryption)

---

## Open Questions

1. **Q:** Should rate limit reset at midnight UTC or 24h rolling window?
   **A:** 24h rolling window (more predictable for users)

2. **Q:** What happens to in-progress exports when user hits rate limit?
   **A:** In-progress exports continue, rate limit only applies to new requests

3. **Q:** Can users see their rate limit status?
   **A:** Yes (future enhancement) - add endpoint GET /api/users/me/export-quota

---

## Approval

**Status:** Draft | Under Review | **Approved**

**Approved by:** [Name]
**Approval date:** [YYYY-MM-DD]

**Notes:**
[Any clarifications or changes made during review]
```

## Best Practices

### 1. Be Explicit

❌ **Vague:**
> Users should be able to export data quickly

✅ **Explicit:**
> Exports up to 100k records must complete within 60 seconds

### 2. Include Rationale

Every rule should explain WHY it exists:
- Security concern?
- Performance requirement?
- Business constraint?
- Compliance requirement?

### 3. Provide Examples

For every rule, show:
- ✅ Valid cases (what's allowed)
- ❌ Invalid cases (what's forbidden)
- ⏰ Edge cases (boundary conditions)

### 4. Specify Enforcement

State WHERE and HOW the rule is enforced:
- API layer (validation)
- Service layer (business logic)
- Repository layer (database constraints)
- Infrastructure (bucket policies, rate limiters)

### 5. Capture Exceptions

Rules often have exceptions - document them:
- Admin privileges
- Special circumstances
- Grandfathered cases

### 6. Mark as Reviewable

Always write rules to file and prompt user for review before proceeding.

## Integration with Workflow

**Business rules extraction is handled by `/specify` (mandatory before `/design`):**

```
/gather → /specify (extracts rules + BDD) → /design (uses approved rules) → /plan → /build
```

**In /specify command:**
1. **Stage 0:** Load & Clarify
2. **Stage 1:** Extract Business Rules ⭐ (PM-facing version: `skills/specify/business-rules.md`)
3. **Stage 2:** Generate BDD Scenarios
4. **Stage 3:** Finalize & Handoff

**In /design command (consumes approved rules):**
- Rules are used as input for requirements analysis, contract definition, and ticket generation
- `/design` does NOT extract rules — it reads them from `.claude/design/[feature]-rules.md`

## Output Location

**Primary output:** `.claude/design/[feature-name]-rules.md`

**Referenced by:**
- BDD scenarios (validates rules)
- Tickets (specifies constraints)
- Contracts (enforces rules)
- Tests (verifies rule compliance)

## Related Documentation

- **Workflow:** [docs/contract-first-design-workflow.md](../../docs/contract-first-design-workflow.md)
- **Design Skill:** [skills/design/SKILL.md](SKILL.md)
- **BDD Skill:** [skills/testing/bdd-scenario-generation.md](../testing/bdd-scenario-generation.md)
