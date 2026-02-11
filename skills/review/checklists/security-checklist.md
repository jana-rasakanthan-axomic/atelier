# Security Review Checklist

Structured checklist for security code reviews.

## Authentication (AUTH)

- [ ] **AUTH-01** Authentication mechanism uses proven library (not custom)
- [ ] **AUTH-02** Passwords hashed with bcrypt/Argon2 (cost factor >=10)
- [ ] **AUTH-03** MFA available for sensitive operations
- [ ] **AUTH-04** Session tokens are cryptographically random
- [ ] **AUTH-05** Session timeout implemented
- [ ] **AUTH-06** Session invalidated on logout
- [ ] **AUTH-07** Failed login attempts rate-limited
- [ ] **AUTH-08** Account lockout after repeated failures

## Authorization (AUTHZ)

- [ ] **AUTHZ-01** Authorization checked on every protected endpoint
- [ ] **AUTHZ-02** Authorization enforced server-side (not client)
- [ ] **AUTHZ-03** Default deny for all resources
- [ ] **AUTHZ-04** Resource ownership validated
- [ ] **AUTHZ-05** Role/permission checks use centralized mechanism
- [ ] **AUTHZ-06** CORS properly configured (for browser-facing APIs)
- [ ] **AUTHZ-07** API endpoints require authentication
- [ ] **AUTHZ-08** Function-level access control (regular users can't access admin methods)

## Input Validation (INPUT)

- [ ] **INPUT-01** All user input validated (type, length, format)
- [ ] **INPUT-02** Allowlist validation preferred over blocklist
- [ ] **INPUT-03** File uploads validated (type, size, content)
- [ ] **INPUT-04** File paths sanitized (no traversal)
- [ ] **INPUT-05** JSON/XML parsing has depth limits
- [ ] **INPUT-06** Regular expressions safe from ReDoS
- [ ] **INPUT-07** Protection against mass assignment (users can't inject fields like `is_admin`)

## Injection Prevention (INJ)

- [ ] **INJ-01** SQL queries use parameterized statements
- [ ] **INJ-02** No string concatenation in queries
- [ ] **INJ-03** ORM used for database operations
- [ ] **INJ-04** OS commands use safe APIs (no shell=True)
- [ ] **INJ-05** LDAP queries properly escaped
- [ ] **INJ-06** Template rendering uses auto-escaping (if using server-side templates)
- [ ] **INJ-07** Outbound request URLs validated (SSRF prevention)
- [ ] **INJ-08** No insecure deserialization (avoid `pickle.load` with untrusted data)

## Output Encoding (OUTPUT)

- [ ] **OUTPUT-01** HTML output encoded (if rendering HTML/email templates)
- [ ] **OUTPUT-02** JSON output uses proper serialization
- [ ] **OUTPUT-03** URL parameters encoded
- [ ] **OUTPUT-04** HTTP headers don't include user input
- [ ] **OUTPUT-05** Content-Type headers set correctly
- [ ] **OUTPUT-06** Security headers configured (HSTS, X-Content-Type-Options, X-Frame-Options)

## Cryptography (CRYPTO)

- [ ] **CRYPTO-01** TLS 1.2+ enforced for all connections
- [ ] **CRYPTO-02** Strong algorithms used (AES-256, RSA-2048+, SHA-256+)
- [ ] **CRYPTO-03** No deprecated algorithms (MD5, SHA1, DES, RC4)
- [ ] **CRYPTO-04** Keys from secure random source
- [ ] **CRYPTO-05** Keys not hardcoded in source
- [ ] **CRYPTO-06** Key rotation mechanism exists
- [ ] **CRYPTO-07** Initialization vectors unique per encryption

## Data Protection (DATA)

- [ ] **DATA-01** Sensitive data encrypted at rest
- [ ] **DATA-02** PII minimized (collect only needed)
- [ ] **DATA-03** Data retention policy implemented
- [ ] **DATA-04** Secure deletion when required
- [ ] **DATA-05** Backups encrypted
- [ ] **DATA-06** Data classification documented

## Secrets Management (SECRET)

- [ ] **SECRET-01** No secrets in source code
- [ ] **SECRET-02** No secrets in logs
- [ ] **SECRET-03** Environment variables or vault used
- [ ] **SECRET-04** Different secrets per environment
- [ ] **SECRET-05** API keys have minimal permissions
- [ ] **SECRET-06** Secrets rotated regularly

## Logging & Monitoring (LOG)

- [ ] **LOG-01** Security events logged
- [ ] **LOG-02** Login success/failure logged
- [ ] **LOG-03** Authorization failures logged
- [ ] **LOG-04** Logs don't contain secrets/PII
- [ ] **LOG-05** Log tampering prevented
- [ ] **LOG-06** Alerting for suspicious patterns

## Error Handling (ERR)

- [ ] **ERR-01** Error messages don't expose internals
- [ ] **ERR-02** Stack traces not shown to users
- [ ] **ERR-03** Debug mode disabled in production
- [ ] **ERR-04** Errors logged with context
- [ ] **ERR-05** Graceful degradation on failure

## Dependencies (DEP)

- [ ] **DEP-01** Dependencies from trusted sources
- [ ] **DEP-02** Versions pinned
- [ ] **DEP-03** No known critical vulnerabilities
- [ ] **DEP-04** Regular security updates
- [ ] **DEP-05** SBOM maintained

## Availability (AVAIL)

- [ ] **AVAIL-01** Global rate limiting implemented (per IP or token)
- [ ] **AVAIL-02** Request size limits enforced (prevent memory exhaustion)
- [ ] **AVAIL-03** Timeouts configured for upstream service calls
- [ ] **AVAIL-04** Circuit breakers for external dependencies

## Severity Classification

| Level | Description | Example |
|-------|-------------|---------|
| Critical | Immediate exploitation possible | SQL injection, RCE, SSRF |
| High | Significant risk with effort | Auth bypass, data exposure, mass assignment |
| Medium | Limited risk | XSS, CSRF (with auth), missing rate limits |
| Low | Minor security impact | Info disclosure, hardening |
