# STRIDE Threat Modeling

Systematic threat identification using STRIDE framework.

## Overview

STRIDE is a threat modeling methodology that categorizes threats into six types:

- **S**poofing Identity
- **T**ampering with Data
- **R**epudiation
- **I**nformation Disclosure
- **D**enial of Service
- **E**levation of Privilege

## Process

### 1. Identify Assets

```markdown
## Assets

| Asset | Type | Sensitivity |
|-------|------|-------------|
| User credentials | Data | Critical |
| Session tokens | Data | Critical |
| User PII | Data | High |
| API keys | Secrets | Critical |
| Business data | Data | Medium |
```

### 2. Identify Entry Points

```markdown
## Entry Points

| Entry Point | Protocol | Authentication |
|-------------|----------|----------------|
| /api/auth/login | HTTPS | None |
| /api/users | HTTPS | JWT |
| /api/admin | HTTPS | JWT + Admin Role |
| Database | TCP | Username/Password |
```

### 3. Apply STRIDE

For each asset and entry point combination:

#### Spoofing

**Question**: Can an attacker impersonate a legitimate user or system?

**Mitigations**: Strong authentication (MFA, WebAuthn), certificate pinning, API key rotation, session management

#### Tampering

**Question**: Can an attacker modify data in transit or at rest?

**Mitigations**: HTTPS for transport, input validation, parameterized queries, integrity checks (HMAC)

#### Repudiation

**Question**: Can a user deny performing an action?

**Mitigations**: Comprehensive audit logging, non-repudiation signatures, immutable logs, timestamps

#### Information Disclosure

**Question**: Can sensitive data be exposed?

**Mitigations**: Encryption at rest and transit, access control, data masking, secure error handling

#### Denial of Service

**Question**: Can an attacker disrupt service availability?

**Mitigations**: Rate limiting, input validation (size limits), resource quotas, auto-scaling

#### Elevation of Privilege

**Question**: Can a user gain unauthorized access?

**Mitigations**: Principle of least privilege, role-based access control, input validation, authorization checks

See `reference/stride-code-examples.md` for implementation examples of each mitigation category.

### 4. Document Findings

```markdown
## STRIDE Analysis Results

| ID | Category | Asset | Threat | Likelihood | Impact | Risk | Mitigation |
|----|----------|-------|--------|------------|--------|------|------------|
| T-001 | Spoofing | Auth | Credential stuffing | High | Critical | High | MFA, rate limiting |
| T-002 | Injection | API | SQL injection | Medium | Critical | High | Parameterized queries |
| T-003 | Info Disclosure | Logs | PII in logs | Medium | High | Medium | Log sanitization |
```

### 5. Risk Score

```
Risk = Likelihood × Impact

Likelihood: 1 (Low), 2 (Medium), 3 (High)
Impact: 1 (Low), 2 (Medium), 3 (High), 4 (Critical)

Risk Score:
- 1-3: Low
- 4-6: Medium
- 7-9: High
- 10-12: Critical
```

## Template Output

Output a JSON document with `analysis_date`, `feature`, `assets`, `entry_points`, `threats` (each with id, category, asset, description, likelihood, impact, risk_score, risk_level, mitigations), and `recommendations`.

See `reference/stride-code-examples.md` for the full JSON template.
