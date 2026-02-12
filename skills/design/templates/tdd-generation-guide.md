# TDD (Technical Design Document) Generation Guide

Instructions for populating the [tdd.md](tdd.md) template.

## Section Guidance

### Problem Statement

Write from the user/business perspective. Focus on the pain point, not the technical solution. A good problem statement makes the "why" obvious without mentioning implementation details.

### Goals vs Non-Goals

- **Goals:** Specific, measurable outcomes. "Reduce query latency to <50ms" not "Make it faster."
- **Non-Goals:** Explicitly call out what is out of scope to prevent scope creep. Anything deferred to a future iteration belongs here.

### Architecture Overview

Provide a high-level diagram (Mermaid or ASCII). Show the flow from user action through each layer. This is the 30-second explanation of how the feature works.

### Component Design

For each component, define:
1. **Responsibility** -- single sentence describing what this component owns
2. **Interface** -- exact method/endpoint signatures (this becomes the builder's contract)
3. **Error handling** -- which exceptions are thrown and when
4. **Business rules** -- domain logic that lives in this component

### Alternatives Considered

Document at least two alternatives for any non-trivial decision. The table format forces concise reasoning. Every "Chosen" decision should have a clear rationale.

### Security Considerations

Use the STRIDE model for threat analysis:
- **S**poofing, **T**ampering, **R**epudiation, **I**nformation Disclosure, **D**enial of Service, **E**levation of Privilege

At minimum address: authorization, authentication, rate limiting, data protection, audit logging, and input validation.

### Performance Considerations

Provide concrete numbers, not aspirations. Include:
- Expected load (concurrent users, RPS, data volume)
- Latency targets per component
- Optimization strategies (indexes, caching, batching)
- Load testing scenarios and success criteria

### Rollout Plan

For features requiring phased rollout, define:
- **Phases:** Name, timeframe, actions, success criteria per phase
- **Rollback plan:** Trigger conditions, rollback process, impact assessment

### Implementation Plan

Break into phases that map to tickets. Each phase should be independently deployable and testable. Include story point estimates and file-level scope.

## Appendix Sections (Optional)

Add these only when relevant:
- **Glossary:** Domain terms that may be unfamiliar
- **Diagrams:** Detailed sequence/flow diagrams
- **Research Notes:** Benchmarks, POC results, vendor comparisons
