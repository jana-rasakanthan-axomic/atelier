# Compliance Mapping

Regulatory compliance requirements and implementation guidance.

## Overview

This guide maps security controls to regulatory requirements.

## GDPR (General Data Protection Regulation)

### Key Articles

| Article | Requirement | Implementation |
|---------|-------------|----------------|
| Art. 5 | Data minimization | Collect only necessary data |
| Art. 6 | Lawful basis | Document legal basis for processing |
| Art. 7 | Consent | Clear consent mechanism |
| Art. 17 | Right to erasure | Data deletion endpoint |
| Art. 20 | Data portability | Data export feature |
| Art. 25 | Privacy by design | Default privacy settings |
| Art. 32 | Security measures | Encryption, access control |
| Art. 33 | Breach notification | 72-hour notification process |

### Implementation Checklist

```markdown
## GDPR Compliance

### Data Collection
- [ ] Privacy policy published
- [ ] Consent mechanism implemented
- [ ] Legal basis documented for each data type
- [ ] Data minimization reviewed

### Data Subject Rights
- [ ] Access request endpoint (Art. 15)
- [ ] Rectification endpoint (Art. 16)
- [ ] Erasure endpoint (Art. 17)
- [ ] Export endpoint (Art. 20)
- [ ] Opt-out mechanism

### Security (Art. 32)
- [ ] Encryption at rest
- [ ] Encryption in transit
- [ ] Access control implemented
- [ ] Audit logging enabled

### Data Processing
- [ ] Processing records maintained
- [ ] DPA with third parties
- [ ] Data retention policy
- [ ] Cross-border transfer assessment
```

## SOC 2 (Service Organization Control)

### Trust Service Criteria

| Category | Description | Controls |
|----------|-------------|----------|
| Security | Protection against unauthorized access | Firewalls, encryption, MFA |
| Availability | System uptime | Redundancy, backups, DR |
| Processing Integrity | Complete, accurate processing | Validation, reconciliation |
| Confidentiality | Data protection | Encryption, access control |
| Privacy | PII handling | Consent, data rights |

### Common Controls

```markdown
## SOC 2 Controls

### CC1 - Control Environment
- [ ] Security policies documented
- [ ] Roles and responsibilities defined
- [ ] Background checks for employees

### CC2 - Communication and Information
- [ ] Security awareness training
- [ ] Incident reporting process
- [ ] Change management process

### CC3 - Risk Assessment
- [ ] Risk assessment performed
- [ ] Threat modeling documented
- [ ] Vulnerability management

### CC4 - Monitoring Activities
- [ ] Security monitoring
- [ ] Log review process
- [ ] Performance monitoring

### CC5 - Control Activities
- [ ] Access control policies
- [ ] Change management
- [ ] Logical access controls

### CC6 - Logical and Physical Access
- [ ] Authentication mechanisms
- [ ] Authorization controls
- [ ] Physical security

### CC7 - System Operations
- [ ] Incident management
- [ ] Vulnerability management
- [ ] Capacity management

### CC8 - Change Management
- [ ] Change approval process
- [ ] Testing requirements
- [ ] Rollback procedures

### CC9 - Risk Mitigation
- [ ] Third-party risk management
- [ ] Business continuity
- [ ] Insurance coverage
```

## OWASP Controls

### Application Security

| OWASP | Risk | Control |
|-------|------|---------|
| A01 | Broken Access Control | RBAC, ownership checks |
| A02 | Cryptographic Failures | Strong encryption |
| A03 | Injection | Parameterized queries |
| A04 | Insecure Design | Threat modeling |
| A05 | Security Misconfiguration | Hardening guides |
| A06 | Vulnerable Components | Dependency scanning |
| A07 | Authentication Failures | MFA, strong passwords |
| A08 | Integrity Failures | Code signing, SBOM |
| A09 | Logging Failures | Comprehensive logging |
| A10 | SSRF | Input validation |

## Mapping Template

```json
{
  "feature": "User Authentication",
  "compliance_mapping": {
    "gdpr": {
      "articles": ["Art. 5", "Art. 7", "Art. 32"],
      "status": "compliant",
      "evidence": [
        "Consent collected at signup",
        "Passwords encrypted with Argon2",
        "MFA available"
      ]
    },
    "soc2": {
      "controls": ["CC6.1", "CC6.2", "CC6.3"],
      "status": "compliant",
      "evidence": [
        "JWT-based authentication",
        "Session timeout implemented",
        "Failed login monitoring"
      ]
    },
    "owasp": {
      "categories": ["A02", "A07"],
      "status": "compliant",
      "evidence": [
        "Password policy enforced",
        "No plaintext storage"
      ]
    }
  }
}
```

## Audit Evidence

For each control, maintain:

1. **Policy** - Written policy document
2. **Procedure** - How the control is implemented
3. **Evidence** - Screenshots, configs, logs
4. **Testing** - Regular verification

## Compliance Report Template

```markdown
# Compliance Assessment Report

## Executive Summary
- Assessment date: YYYY-MM-DD
- Scope: [Feature/System name]
- Overall status: Compliant / Non-compliant

## Regulatory Coverage
| Regulation | Controls Assessed | Compliant | Gaps |
|------------|------------------|-----------|------|
| GDPR | 10 | 9 | 1 |
| SOC 2 | 15 | 14 | 1 |
| OWASP | 10 | 10 | 0 |

## Gaps Identified
| ID | Regulation | Control | Gap | Remediation | Due Date |
|----|------------|---------|-----|-------------|----------|
| GAP-001 | GDPR | Art. 17 | No soft delete | Implement soft delete | 2024-02-01 |

## Recommendations
1. [Priority 1 items]
2. [Priority 2 items]

## Appendix
- Evidence artifacts
- Testing methodology
- Reviewer credentials
```
