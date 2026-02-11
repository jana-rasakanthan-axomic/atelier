# Product Review Checklist

Structured checklist for requirements and UX reviews.

## Requirements Coverage (REQ)

- [ ] **REQ-01** All acceptance criteria implemented
- [ ] **REQ-02** Feature matches PRD/spec
- [ ] **REQ-03** User stories completed
- [ ] **REQ-04** No scope creep (unasked features)
- [ ] **REQ-05** MVP scope appropriate
- [ ] **REQ-06** Dependencies tracked

## API Usability (API-UX)

- [ ] **API-UX-01** Happy path returns expected status codes (200/201 for valid requests)
- [ ] **API-UX-02** Empty result sets return empty array, not error
- [ ] **API-UX-03** Response body contains created/updated resource confirmation
- [ ] **API-UX-04** API follows existing patterns and conventions
- [ ] **API-UX-05** Status endpoints or webhooks for long operations
- [ ] **API-UX-06** Consistent response structure across endpoints

## Error Handling (ERR)

- [ ] **ERR-01** Error messages are user-friendly
- [ ] **ERR-02** Errors explain what went wrong
- [ ] **ERR-03** Errors suggest next action
- [ ] **ERR-04** No technical jargon in errors
- [ ] **ERR-05** User can recover from errors
- [ ] **ERR-06** Validation errors are specific

## Edge Cases (EDGE)

- [ ] **EDGE-01** Empty input handled
- [ ] **EDGE-02** Maximum limits enforced
- [ ] **EDGE-03** Minimum values validated
- [ ] **EDGE-04** Special characters handled
- [ ] **EDGE-05** Unicode text supported
- [ ] **EDGE-06** Concurrent access considered
- [ ] **EDGE-07** Upstream service failures handled (timeouts, retries)

## Data Validation (DATA)

- [ ] **DATA-01** Required fields enforced
- [ ] **DATA-02** Field formats validated
- [ ] **DATA-03** Defaults are sensible
- [ ] **DATA-04** Null/undefined handled
- [ ] **DATA-05** Date/time zones correct
- [ ] **DATA-06** Currency handling correct

## Internationalization (I18N)

- [ ] **I18N-01** Error codes returned for client-side translation (or localized messages if required)
- [ ] **I18N-02** Date formats use ISO 8601 or configurable locale
- [ ] **I18N-03** Number formats handled correctly
- [ ] **I18N-04** Currency handling correct (amounts as integers, currency code separate)

## API Error Response Guidelines

### Bad Examples

```json
{"error": "500"}
{"message": "NullPointerException at UserService.java:42"}
{"error": "Invalid input"}
{"message": "Something went wrong"}
```

### Good Examples

```json
{
  "error": "ORDER_NOT_FOUND",
  "message": "Order with ID 12345 not found",
  "details": {"order_id": "12345"}
}

{
  "error": "VALIDATION_ERROR",
  "message": "Password must be at least 8 characters",
  "field": "password"
}

{
  "error": "EMAIL_ALREADY_EXISTS",
  "message": "This email is already registered",
  "field": "email"
}
```

### Structure

1. **Error code** (machine-readable, for client-side handling)
2. **Message** (human-readable, can be shown to user)
3. **Details** (additional context for debugging/display)

## User Story Validation

```markdown
Story: As a [user type], I want to [action] so that [benefit]

Validation:
- [ ] User can start the action
- [ ] User can complete the action
- [ ] User achieves the benefit
- [ ] Flow is intuitive
- [ ] Errors are recoverable
- [ ] Edge cases handled
```

## Priority Classification

| Priority | Description | Action |
|----------|-------------|--------|
| Must Fix | Blocks user from completing task | Before release |
| Should Fix | Degrades experience significantly | Before release |
| Could Fix | Minor inconvenience | Consider for release |
| Won't Fix | Cosmetic or rare edge case | Backlog |
