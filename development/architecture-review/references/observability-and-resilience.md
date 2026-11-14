# Observability and Resilience

Detailed checks for the operational qualities of the architecture: can the system be debugged in production (observability), and does it survive the failure of its dependencies (resilience)? These are architectural properties — where logging, metrics, and failure handling *live* in the structure matters as much as how they are written.

## Observability

### Structured logging

What to check:

- One logging approach across the codebase — not `print`/`console.log` mixed with a logger library.
- Structured output (JSON or key-value) with standard fields: timestamp, level, service/component, and a correlation identifier.
- Log levels used consistently: ERROR for failures needing attention, WARN for degraded-but-handled situations, INFO for significant business events, DEBUG/TRACE for detail.
- Sensitive data never logged: passwords, tokens, API keys, personal data. Search logs-related code for obvious secrets patterns.

Detection heuristics:

- `console.log(...)` / `print(...)` used for operational logging.
- String-concatenated log messages with interpolated values where structured fields should be.
- Log statements referencing `password`, `token`, `api_key`, `authorization` values.

### Correlation IDs

What to check:

- A request/correlation ID generated at the system's entry point (HTTP middleware, message consumer, job runner).
- The ID propagated through every internal call (context, thread-local, message header) and attached to logs, and ideally to downstream requests (`X-Request-ID`).
- Trace/span identifiers present if the system distributes work across services.

Absence of correlation IDs is a legitimate HIGH finding for any multi-component system: incidents become unreproducible.

### Metrics and alerting

What to check:

- The failure-prone paths (external calls, queues, caches, jobs) emit metrics: request rate, error rate, latency distribution, queue depth, cache hit ratio.
- Metrics carry useful labels (service, environment, operation) without cardinality explosions.
- Anything that pages a human is defined somewhere — alerting on symptoms (latency, error rate), not causes.

### Tracing

What to check (for distributed systems):

- Spans around significant operations (external calls, transactions), with proper error capture.
- Context propagation across process boundaries (OpenTelemetry or equivalent).
- Sensible sampling: keep errors, sample the healthy traffic.

Recommendation baseline: structured logging (one library, JSON), Prometheus-style metrics for RED (rate/errors/duration) per dependency, OpenTelemetry tracing across service boundaries, PII redaction applied at the logging pipeline.

## Resilience

Every external dependency — HTTP API, database, cache, message broker, filesystem — needs deliberate failure handling. Check each outbound dependency for the five patterns below.

### 1. Timeouts

- Purpose: prevent indefinite waits that exhaust connections/threads.
- Check: every HTTP client, DB driver, and RPC has explicit connect and read timeouts configured. Framework defaults (often infinite or OS-level ~2 minutes) count as "not configured".
- Condensed compliant shape:

```python
requests.get("https://api.example.com", timeout=(3.05, 10))  # (connect, read)
```

### 2. Retry with backoff

- Purpose: survive transient failures without hammering a struggling dependency.
- Check: retries exist for idempotent operations, are bounded (2–3 attempts), use exponential backoff with jitter, and only retry transient error classes — not business errors.

### 3. Circuit breaker

- Purpose: stop cascading failure; fail fast when a dependency is down.
- Check: a breaker (or equivalent fail-fast guard) in front of dependencies whose outage would otherwise exhaust thread/connection pools. State changes are logged and metricized.

### 4. Bulkhead

- Purpose: isolate resource pools per dependency so one slow dependency cannot consume everything.
- Check: separate connection pools / thread pools / worker limits per external dependency; queue capacities are bounded.

### 5. Rate limiting

- Purpose: protect the system and its dependencies from overload.
- Check: limits at public entry points (per-IP/per-user/per-API-key) and on outbound calls to rate-limited third parties.

### Configuration guidelines

| Pattern | Recommended starting point | Notes |
| ------- | -------------------------- | ----- |
| Timeout | 1–30 s | derive from the dependency's SLA |
| Retry attempts | 2–3 | exponential backoff + jitter, idempotent calls only |
| Circuit breaker | trip on ~5 failures / 60 s | with recovery (half-open) probing |
| Bulkhead | small, bounded pools per dependency | size to capacity, not hope |
| Rate limit | at every trust boundary | stricter on expensive endpoints |

### Detection heuristics

- HTTP client construction without a timeout parameter (`requests.get(...)`, `http.Get(url)`, `axios.get(...)` with no `timeout`).
- Promises/futures without failure handling (`.then(...)` with no `.catch`, fire-and-forget goroutines).
- Loops calling external services with no bound on concurrency (unbounded fan-out).
- Unbounded queues and channels; caches without size or TTL limits.
- Retry loops with constant sleep, or retries wrapping non-idempotent operations (payments!).

### Failure semantics

Beyond the five patterns, check *what happens* when each dependency fails:

- Degrade deliberately (fallback to cached/default data) or fail loudly — never hang or corrupt state.
- Errors from infrastructure translated at the boundary; raw driver errors do not leak to API responses.
- Async work survives process restarts (durable queue) where the business requires delivery.
