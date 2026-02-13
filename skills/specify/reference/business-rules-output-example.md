# Business Rules — Output Format Example

Full example of a completed business rules extraction document.

```markdown
# Business Rules: [Feature Name]

**Feature:** [Feature description from PRD]
**Date:** [YYYY-MM-DD]
**Source:** [Link to PRD file]
**Status:** Draft | Under Review | Approved

---

## Rule 1: Authorization - User Data Access

**Statement:** Users can only export their own account data. Administrators can export any user's data.

**Rationale:** Users expect their personal data to remain private. Only authorized personnel should access other users' information.

**Who it affects:**
- Standard users (can export own data only)
- Administrators (can export any user's data)
- Support staff (can export with user consent)

**Exceptions:**
- Administrators can export any user's data
- Support staff can export with an approved support ticket

**Examples:**
- Allowed: Alice exports Alice's data
- Not allowed: Alice exports Bob's data
- Allowed: An administrator exports Bob's data
- Edge case: Support staff exports with ticket #12345

---

## Rule 2: Rate Limiting - Daily Export Quota

**Statement:** Users can create a maximum of 5 exports per 24-hour period. Administrators have unlimited exports.

**Rationale:** Prevents system overuse and ensures fair access for all users.

**Who it affects:**
- Standard users (5 per day limit)
- Administrators (no limit)

**Exceptions:**
- Administrators have no rate limit
- Limit resets 24 hours after first export, not at midnight

**Examples:**
- Allowed: User creates their 1st through 5th export
- Not allowed: User creates a 6th export within 24 hours
- Edge case: User waits 24 hours and can export again

---

## Summary

**Total Rules:** [N]

**By Category:**
- Authorization: [count]
- Validation: [count]
- Rate Limiting: [count]
- Performance: [count]
- Data Retention: [count]
- Data Privacy: [count]
- Business Logic: [count]
- Integration: [count]

---

## Approval

**Status:** Draft | Under Review | **Approved**
**Approved by:** [Name]
**Approval date:** [YYYY-MM-DD]
```
