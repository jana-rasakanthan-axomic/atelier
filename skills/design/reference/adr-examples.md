# ADR Template — Extended Examples

## Context Example

```
Users need to export their data for compliance and analysis. Requirements specify:
- Support for 100k users
- Export must complete within 60s or fail gracefully
- CSV and JSON formats
- Rate limiting to prevent abuse

Current system uses synchronous REST endpoints with 30s timeout, which is insufficient
for large exports.
```

## Alternatives Comparison Example

```
| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| **Sync REST** | Simple, immediate response, no queue management | Timeout risk (60s+ for 100k users), blocks API | Rejected - exceeds API timeout limits |
| **Async Job** | Scalable, handles large data, progress tracking, retries | More complexity (queue, polling, status tracking) | Chosen - meets scale and reliability requirements |
| **Streaming** | Memory efficient, real-time data | Can't show progress, harder to retry, complex error handling | Future consideration - good for real-time use cases |
```

## Decision Rationale Example

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
   because the scale and reliability requirements justify it.
```

## Consequences Examples

### Positive

```
- **Scalability**: Can handle exports of any size without timeout concerns
- **User Experience**: Progress tracking and notifications improve perceived performance
- **Reliability**: Automatic retries and failure handling reduce manual intervention
- **Observability**: Job queue provides metrics (duration, failure rate, queue depth)
- **Flexibility**: Easy to add new export types or formats in the future
```

### Negative

```
- **Complexity**: More moving parts (queue, workers, status tracking) increase system complexity
- **Latency**: Users must wait and poll for results instead of immediate response
- **Operational Overhead**: Need to monitor queue health, worker capacity, job failures
- **State Management**: Must persist job state, handle cleanup of completed jobs
```

## Risks & Mitigations Example

```
| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Queue backup during peak usage | High (delayed exports) | Medium | Rate limit (5/user/day), auto-scale workers, monitor queue depth with alerts |
| Worker failure mid-export | Medium (partial exports) | Low | Retry 3x with exponential backoff, store progress checkpoints, alert on failures |
| S3 upload failure | Medium (lost export) | Low | Retry 3x, fallback to database storage, alert on persistent failures |
| Job state inconsistency | Medium (stuck jobs) | Low | TTL on job records (7 days), cleanup cron job, monitoring for stuck jobs |
```

## Implementation Notes Example

```
- Use existing Celery setup in `app/tasks/`
- Store job status in new `export_jobs` table (see migration below)
- Reuse `S3Service` from `app/services/storage.py` for file uploads
- Follow async repository pattern (see `app/repositories/base.py`)
- Chunk processing: 1000 rows per iteration to limit memory usage
- Retry logic: 3 attempts with exponential backoff (1s, 2s, 4s)
- Job TTL: Delete completed jobs after 7 days (cron job)
```

## Appendix Examples

### Benchmark Results

```
Test: Export 100k users
- Sync REST: Timeout after 35s (incomplete)
- Async Job: Completed in 58s (success)
- Streaming: Completed in 45s (success, but no progress tracking)

Conclusion: Async job meets requirements with acceptable performance
```

### Architecture Diagram

```
+-----------+
|  Client   |
+-----+-----+
      | POST /api/users/export
      v
+-----------------+
|  API Gateway    |
+-----+-----------+
      | Create job
      v
+-----------------+      +----------+
| ExportService   |----->|  Redis   | (Job Queue)
+-----+-----------+      +----+-----+
      | Store job state       |
      v                       | Dequeue
+-----------------+           v
|   PostgreSQL    |     +----------+
| (export_jobs)   |     |  Worker  |
+-----------------+     +-----+----+
                              | Upload result
                              v
                        +----------+
                        |    S3    |
                        +----------+
```
