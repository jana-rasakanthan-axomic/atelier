---
name: security
description: Security analysis using STRIDE, OWASP, and compliance mapping. Use for threat modeling, vulnerability scanning, and compliance assessments.
allowed-tools: Read, Grep, Glob
---

# Security Skill

Security analysis and validation for FastAPI applications.

## When to Use

- Threat modeling for new features
- Security review of code changes
- Compliance validation (GDPR, SOC 2)
- Authentication/authorization review

## When NOT to Use

**Only for security analysis and threat modeling.** Do not use for general code review or implementation.

- Non-security code review → use review skill
- Performance optimization → use analysis skill
- General code quality → use analysis skill

## Guides

| Guide | Purpose |
|-------|---------|
| `stride-analysis.md` | STRIDE threat modeling |
| `crypto-validation.md` | Cryptographic standards |
| `compliance-mapping.md` | Regulatory compliance |

## Checklists

| Checklist | Coverage |
|-----------|----------|
| `checklists/owasp-top-10.json` | Web vulnerabilities |
| `checklists/gdpr-compliance.json` | Data protection |
| `checklists/soc2-controls.json` | Security controls |

## Running Security Scans

Use the project Makefile:
```bash
make security        # Run bandit + pip-audit + secrets check
make security-bandit # Run bandit only
```

## Quick Reference

### STRIDE Categories

| Threat | Description | Mitigation |
|--------|-------------|------------|
| **S**poofing | Identity falsification | Strong authentication |
| **T**ampering | Data modification | Integrity checks |
| **R**epudiation | Denying actions | Audit logging |
| **I**nformation Disclosure | Data exposure | Encryption, access control |
| **D**enial of Service | Availability attacks | Rate limiting, scaling |
| **E**levation of Privilege | Unauthorized access | Least privilege |

### OWASP Top 10 (2021)

1. Broken Access Control
2. Cryptographic Failures
3. Injection
4. Insecure Design
5. Security Misconfiguration
6. Vulnerable Components
7. Authentication Failures
8. Integrity Failures
9. Logging Failures
10. SSRF

## Severity Levels

| Level | Response Time | Example |
|-------|---------------|---------|
| Critical | Immediate | SQL injection, auth bypass |
| High | 24 hours | XSS, IDOR |
| Medium | 1 week | Missing headers |
| Low | Best effort | Informational |
