# ADR-[NNNN]: [Short Title in Title Case]

**Date:** [YYYY-MM-DD]
**Status:** Proposed | Accepted | Rejected | Deprecated | Superseded by ADR-XXXX
**Context:** [Link to ticket, epic, or TDD]

## Decision

[State the architecture decision in one clear sentence]

Example: "Use asynchronous job pattern (Celery + Redis) for user data export."

## Context

[Describe the problem and why this decision is needed. Include:]
- Business/user requirements
- Technical constraints
- Current system state
- What prompted this decision

Example:
```
Users need to export their data for compliance and analysis. Requirements specify:
- Support for 100k users
- Export must complete within 60s or fail gracefully
- CSV and JSON formats
- Rate limiting to prevent abuse

Current system uses synchronous REST endpoints with 30s timeout, which is insufficient
for large exports.
```

## Alternatives Considered

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| **[Option 1]** | [List pros] | [List cons] | ❌ Rejected - [Reason] |
| **[Option 2]** | [List pros] | [List cons] | ✅ **Chosen** - [Reason] |
| **[Option 3]** | [List pros] | [List cons] | ⏸️ Future consideration - [Reason] |

Example:
```
| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| **Sync REST** | Simple, immediate response, no queue management | Timeout risk (60s+ for 100k users), blocks API | ❌ Rejected - exceeds API timeout limits |
| **Async Job** | Scalable, handles large data, progress tracking, retries | More complexity (queue, polling, status tracking) | ✅ **Chosen** - meets scale and reliability requirements |
| **Streaming** | Memory efficient, real-time data | Can't show progress, harder to retry, complex error handling | ⏸️ Future consideration - good for real-time use cases |
```

## Decision Rationale

[Explain in detail why the chosen approach was selected. Include:]
- How it meets requirements
- Why rejected alternatives don't fit
- Trade-offs you're accepting
- Constraints that drove the decision

Example:
```
1. **Scale**: 100k users requires ~60s processing time, which exceeds typical API timeout (30s).
   Async job pattern allows long-running operations without blocking the API.

2. **User Experience**: Async job enables progress tracking and notifications, improving UX
   for long-running exports. Users can continue working while export processes.

3. **Reliability**: Job queue (Celery) provides automatic retries, failure handling, and
   dead-letter queues for debugging. Critical for production reliability.

4. **Existing Infrastructure**: We already have Celery + Redis configured for other
   background jobs. Reusing infrastructure reduces operational complexity.

5. **Trade-offs Accepted**: We accept additional complexity (job management, status polling)
   because the scale and reliability requirements justify it. The alternative (sync REST)
   cannot meet requirements without significant risk.
```

## Consequences

### Positive

- [List positive outcomes of this decision]
- [Include benefits, capabilities unlocked]

Example:
```
- **Scalability**: Can handle exports of any size without timeout concerns
- **User Experience**: Progress tracking and notifications improve perceived performance
- **Reliability**: Automatic retries and failure handling reduce manual intervention
- **Observability**: Job queue provides metrics (duration, failure rate, queue depth)
- **Flexibility**: Easy to add new export types or formats in the future
```

### Negative

- [List negative outcomes, costs, or limitations]
- [Be honest about downsides]

Example:
```
- **Complexity**: More moving parts (queue, workers, status tracking) increase system complexity
- **Latency**: Users must wait and poll for results instead of immediate response
- **Operational Overhead**: Need to monitor queue health, worker capacity, job failures
- **State Management**: Must persist job state, handle cleanup of completed jobs
```

### Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| [Risk 1] | [High/Med/Low] | [High/Med/Low] | [How we mitigate] |
| [Risk 2] | [High/Med/Low] | [High/Med/Low] | [How we mitigate] |

Example:
```
| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Queue backup during peak usage | High (delayed exports) | Medium | Rate limit (5/user/day), auto-scale workers, monitor queue depth with alerts |
| Worker failure mid-export | Medium (partial exports) | Low | Retry 3x with exponential backoff, store progress checkpoints, alert on failures |
| S3 upload failure | Medium (lost export) | Low | Retry 3x, fallback to database storage, alert on persistent failures |
| Job state inconsistency | Medium (stuck jobs) | Low | TTL on job records (7 days), cleanup cron job, monitoring for stuck jobs |
```

## Implementation Notes

[Practical details for implementing this decision]

Example:
```
- Use existing Celery setup in `app/tasks/`
- Store job status in new `export_jobs` table (see migration below)
- Reuse `S3Service` from `app/services/storage.py` for file uploads
- Follow async repository pattern (see `app/repositories/base.py`)
- Chunk processing: 1000 rows per iteration to limit memory usage
- Retry logic: 3 attempts with exponential backoff (1s, 2s, 4s)
- Job TTL: Delete completed jobs after 7 days (cron job)
```

## Related

- **TDD:** [Link to technical design document]
- **Tickets:** [List related Jira tickets]
- **Code:** [Links to key files or PRs]
- **Supersedes:** [Link to ADR this replaces, if applicable]
- **Superseded by:** [Link to ADR that replaces this, if deprecated]

Example:
```
- **TDD:** docs/design/user-export.md
- **Tickets:** SHRED-2119 (Infrastructure), SHRED-2120 (Core Logic), SHRED-2121 (API)
- **Code:** app/tasks/export_tasks.py, app/services/export_service.py
```

## Appendix

[Optional: Additional context, benchmarks, research notes, diagrams]

### Example Benchmark Results

```
Test: Export 100k users
- Sync REST: Timeout after 35s (incomplete)
- Async Job: Completed in 58s (success)
- Streaming: Completed in 45s (success, but no progress tracking)

Conclusion: Async job meets requirements with acceptable performance
```

### Example Architecture Diagram

```
┌─────────┐
│ Client  │
└────┬────┘
     │ POST /api/users/export
     ▼
┌─────────────────┐
│  API Gateway    │
└────┬────────────┘
     │ Create job
     ▼
┌─────────────────┐      ┌──────────┐
│ ExportService   │─────▶│  Redis   │ (Job Queue)
└────┬────────────┘      └────┬─────┘
     │ Store job state        │
     ▼                        │ Dequeue
┌─────────────────┐          ▼
│   PostgreSQL    │    ┌────────────┐
│ (export_jobs)   │    │   Worker   │
└─────────────────┘    └─────┬──────┘
                             │ Upload result
                             ▼
                       ┌──────────┐
                       │    S3    │
                       └──────────┘
```

---

## ADR Guidelines

### When to Create an ADR

Create an ADR for:
- **Significant technical decisions** that affect architecture, scalability, or maintainability
- **Trade-off decisions** where multiple valid approaches exist
- **Technology choices** (databases, frameworks, libraries, cloud services)
- **Architectural patterns** (sync/async, REST/GraphQL, monolith/microservices)
- **Security or compliance decisions** (auth methods, encryption, data handling)

Don't create an ADR for:
- Obvious or standard choices (e.g., "Use SQLAlchemy with FastAPI")
- Implementation details (e.g., variable naming, function structure)
- Decisions easily reversible without cost

### ADR Numbering

- Sequential: ADR-0001, ADR-0002, ADR-0003, ...
- Zero-padded to 4 digits
- Never reuse numbers (even if deprecated)

### ADR Status

- **Proposed**: Under discussion, not yet approved
- **Accepted**: Approved and ready to implement
- **Rejected**: Considered but not chosen (document why)
- **Deprecated**: No longer recommended (document replacement)
- **Superseded by ADR-XXXX**: Replaced by newer decision

### File Naming

Format: `NNNN-short-kebab-case-title.md`

Examples:
- `0001-use-postgresql-for-primary-database.md`
- `0023-async-job-pattern-for-exports.md`
- `0042-adopt-event-driven-architecture.md`

### Keep It Concise

- Aim for 1-2 pages
- Focus on **why**, not **how** (implementation goes in TDD)
- Use tables for comparisons
- Be specific about trade-offs

### Update When Deprecated

When an ADR is superseded:
1. Update status to "Superseded by ADR-XXXX"
2. Link to replacement ADR
3. Keep original content (historical record)
4. Create new ADR explaining why the change was needed
