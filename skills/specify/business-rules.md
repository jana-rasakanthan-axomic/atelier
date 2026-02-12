# Business Rules Extraction (PM-Facing)

Extract business rules from PRDs in PM-readable language for Product Manager review and approval.

## Purpose

Support the **specification phase** by:
1. Reading PRDs and extracting implicit business rules
2. Structuring rules in clear, PM-readable format (no technical jargon)
3. Writing rules to file for PM review and approval
4. Creating approved artifacts that feed into `/design`

## When to Use

- **For PM-facing extraction:** Use this skill via `/specify` command
- **For engineer-facing extraction:** Use `skills/design/business-rules-extraction.md` via `/design` command (includes Enforcement field)

## When NOT to Use

- **Rules already explicit** — PRD already contains structured rules (just copy them)
- **Engineering context needed** — Use the engineering version with Enforcement field
- **After design phase** — Rules should be extracted during specification, not during implementation

## Key Differences from Engineering Version

| Aspect | This Skill (PM-facing) | Engineering Version |
|--------|----------------------|---------------------|
| **Audience** | Product Managers, Business Analysts | Engineers, Tech Leads |
| **Language** | Business language only | Technical language (API, DB, services) |
| **Enforcement field** | No — PMs don't need to know where rules are enforced | Yes — engineers need to know where/how |
| **"Who it affects" field** | Yes — identifies impacted user roles | No |
| **Examples format** | "Allowed / Not allowed" in user terms | "✅ / ❌" with technical references |
| **Rationale focus** | Business/user value | Security architecture, system design |

## Rule Categories

### 1. Authorization Rules
Who can perform actions, access data, or use features.

**Examples:**
- Users can only export their own data
- Administrators can view all user accounts
- Guest users cannot create content

### 2. Validation Rules
Constraints on input data, formats, ranges.

**Examples:**
- Email addresses must be in a valid format
- Passwords must be at least 8 characters with a special character
- Uploaded files cannot exceed 10MB

### 3. Rate Limiting Rules
Frequency constraints, quotas, throttling.

**Examples:**
- Users can create a maximum of 5 exports per day
- Free tier users are limited to 100 operations per month

### 4. Performance Rules
Speed and scale expectations visible to users.

**Examples:**
- Exports of up to 100,000 records should complete within 60 seconds
- Search results should appear within 2 seconds

### 5. Data Retention Rules
How long data is available, when it expires.

**Examples:**
- Export files are available for download for 24 hours
- User sessions expire after 30 minutes of inactivity
- Deleted accounts are permanently removed after 30 days

### 6. Data Privacy Rules
What data is included/excluded, who can see what.

**Examples:**
- Exports exclude passwords, tokens, and security credentials
- Users can only see their own personal data
- All data access is logged for audit purposes

### 7. Business Logic Rules
Core domain constraints and business process rules.

**Examples:**
- Orders cannot be cancelled after shipment
- Refunds are processed within 3-5 business days
- Subscriptions auto-renew unless cancelled 24 hours in advance

### 8. Integration Rules
Constraints on interactions with external systems.

**Examples:**
- Payments are processed through the payment provider only
- Email notifications are sent for all major account actions

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
- "Cannot..." → Business logic rule

### Step 3: Structure Rules

**Template:**

```markdown
## Rule [N]: [Category] - [Short Name]

**Statement:** [Clear rule in business language]

**Rationale:** [Why this matters to users/business]

**Who it affects:** [User roles or personas impacted]

**Exceptions:** [Any exceptions]

**Examples:**
- Allowed: [Valid case in user terms]
- Not allowed: [Invalid case in user terms]
- Edge case: [Boundary condition]
```

### Step 4: Write to File

**Output location:** `.claude/design/[feature-name]-rules.md`

### Step 5: Present for PM Review

**Prompt:**
```markdown
I've extracted [N] business rules from the PRD:

1. Authorization: Users can only export their own data
2. Rate Limiting: Maximum 5 exports per day
3. Performance: Complete within 60 seconds for large datasets
4. Data Retention: Files available for 24 hours

**Review file:** .claude/design/[feature]-rules.md

Are these rules complete and accurate?
- Approve → Proceed to BDD scenarios
- Add/modify rules → Update file
```

### Step 6: Incorporate Feedback

Update rules file based on PM feedback, then proceed to BDD scenario generation.

## Output Format

**Output location:** `.claude/design/[feature-name]-rules.md`

Each rule follows the template from Step 3 above. The document includes a header (feature, date, source, status), numbered rules by category, a summary with counts per category, and an approval section.

See `reference/business-rules-output-example.md` for a complete output document example with multiple rules, summary, and approval sections.

## Limits

- Maximum 15 rules per feature
- If more than 15 rules are needed, the feature should likely be split

## Best Practices

### 1. Use Business Language

**Not this:** "API returns 429 with Retry-After header"
**This:** "The user is informed they've reached their daily limit and when they can try again"

### 2. Include Rationale in User/Business Terms

**Not this:** "Prevents database overload and reduces infrastructure costs"
**This:** "Ensures fair access for all users and keeps the system responsive"

### 3. Identify Who Is Affected

Every rule should clearly state which user roles or personas are impacted and how.

### 4. Provide Examples in User Terms

**Not this:** "✅ User A requests export → 200 OK"
**This:** "Allowed: Alice requests an export of her own data"

### 5. Capture Exceptions Clearly

State exceptions in terms PMs can validate against business requirements.

## Related Documentation

- **Skill overview:** [skills/specify/SKILL.md](SKILL.md)
- **BDD scenarios:** [skills/specify/bdd-scenarios.md](bdd-scenarios.md)
- **Engineering version:** [skills/design/business-rules-extraction.md](../design/business-rules-extraction.md)
