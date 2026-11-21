# Performance Anti-Patterns — Detection Catalog

Read this file when a code fragment smells wrong during the review but you cannot yet name the pattern, or when writing a report and wanting to name the anti-pattern precisely. Each entry gives the pattern, its code-level detection signature, the typical fix, and the verification that confirms it. The catalog follows the well-known cloud scalability anti-patterns (Azure Architecture Center) plus the code-level shapes they take in review.

## Quick Reference

| Anti-pattern | One-line shape | Typical severity |
| --- | --- | --- |
| N+1 queries | One data-store call per item of a list | MUST FIX on request paths |
| Chatty I/O | Many small remote calls for one logical operation | MUST FIX / SHOULD FIX |
| Extraneous fetching | Fetching more data than is used | SHOULD FIX |
| Synchronous I/O | Blocking calls on request paths | MUST FIX |
| No caching | Expensive identical work repeated | SHOULD FIX |
| Improper instantiation | Expensive objects built per call | SHOULD FIX |
| Busy database | Processing pushed into the data store | SHOULD FIX / CONSIDER |
| Busy front end | Heavy work on the request/UI thread | SHOULD FIX |
| Retry storm | Unbounded or tight retries amplify an outage | MUST FIX |
| Monolithic persistence | One store for very different access patterns | CONSIDER (design) |
| Noisy neighbor | One tenant starves the others | CONSIDER (design) |
| Unbounded concurrency | Work spawned without a bound or pool | MUST FIX |
| Unbounded accumulation | Cache/queue/listener that never shrinks | MUST FIX |

---

## N+1 Queries

- **Shape:** a list is fetched, then a related resource is fetched per item — in the loop body, or hidden in lazy loading during serialization.
- **Code signature:** a query/remote call inside an iteration over a collection; ORM relations accessed on each element of a loaded list.
- **Typical fix:** eager or batch loading; one `WHERE id IN (...)`/JOIN query; batch endpoints.
- **Verify:** query-count logging — count scales with list size.

## Chatty I/O

- **Shape:** one logical operation split into many small network round-trips; latency and overhead accumulate per call.
- **Code signature:** per-item remote calls where bulk endpoints exist; many fine-grained service calls composed serially; many small file writes instead of one buffered write.
- **Typical fix:** batch/bulk APIs; coalesce small operations into one request; buffer local writes.
- **Verify:** trace spans per operation — span count per logical request.

## Extraneous Fetching

- **Shape:** data is retrieved that the code then ignores or discards; whole rows/tables where a projection or filter would do.
- **Code signature:** `SELECT *`-style full-row fetches followed by use of a few fields; full-table fetch followed by in-app filtering/aggregation; payloads transferred and immediately dropped.
- **Typical fix:** select needed columns; filter/sort/aggregate in the data store; paginate.
- **Verify:** EXPLAIN plan plus transferred-bytes/payload metrics.

## Synchronous I/O

- **Shape:** blocking file/network/database calls on user-facing request paths stall the calling thread for the full round-trip.
- **Code signature:** blocking calls in request handlers; synchronous code waiting on async results; serial awaits on independent operations.
- **Typical fix:** asynchronous APIs on request paths; parallelize independent calls; move slow work off the request path.
- **Verify:** latency percentiles and worker/thread-pool metrics under load.

## No Caching

- **Shape:** identical expensive work repeated because results are not retained.
- **Code signature:** pure computations repeated per request; static data re-fetched/re-parsed per call; missing reuse the codebase already has elsewhere.
- **Typical fix:** cache with TTL, eviction, and a size cap; load static data once.
- **Verify:** expected hit rate from the access pattern; cache-hit metrics if introduced.

## Improper Instantiation

- **Shape:** objects designed to be shared and reused are created and destroyed per call, paying their initialization cost every time.
- **Code signature:** clients, connections, parsers, compiled patterns, codecs constructed inside request handlers or loop bodies.
- **Typical fix:** construct once and share (singleton/DI scope/pool) — matching how the codebase handles similar resources.
- **Verify:** profiler showing initialization cost dominating per-call time.

## Busy Database

- **Shape:** computation that belongs in application code (complex transforms, business logic, fine-grained loops) is pushed into the data store, or vice versa — the store and app repeatedly round-trip to do work one side could own.
- **Code signature:** many small queries composing application logic; stored procedures hosting business rules the app then redoes.
- **Typical fix:** give each side the work it does best; batch round-trips. (Design-level; usually discussion, not a defect.)
- **Verify:** query statistics — call counts and total time per operation.

## Busy Front End

- **Shape:** resource-intensive work runs on the thread that serves users instead of in the background.
- **Code signature:** heavy computation, large serialization, or report generation inline in request handlers or UI event handlers.
- **Typical fix:** move to background jobs/queues with status polling or notifications.
- **Verify:** request duration before/after; background job duration metric.

## Retry Storm

- **Shape:** failed calls retried immediately, without backoff/jitter/caps — retries multiply exactly when the dependency is weakest.
- **Code signature:** retry loops without sleep/backoff; retries without a max attempt count; retries at multiple layers stacking multiplicatively.
- **Typical fix:** exponential backoff with jitter, attempt caps, circuit breaking — using the retry mechanisms the codebase already has.
- **Verify:** request-rate metrics on the dependency during a failure window.

## Monolithic Persistence

- **Shape:** one data store serves access patterns with opposite requirements (heavy writes and analytical scans, relational joins and blob reads), so each pattern's growth degrades all others.
- **Code signature:** one store/database referenced from every module regardless of access pattern; growing mixed workloads on shared tables.
- **Typical fix:** split by access pattern (design-level — raise as discussion/CONSIDER unless the split is already in motion).
- **Verify:** per-pattern query latency trends on the shared store.

## Noisy Neighbor

- **Shape:** in multi-tenant systems, one tenant's workload consumes disproportionate resources and degrades everyone sharing the pool.
- **Code signature:** shared queues/pools/tables without per-tenant limits, quotas, or partitioning; tenant-unbounded batch jobs.
- **Typical fix:** per-tenant quotas, fair scheduling, partitioning (design-level; usually CONSIDER).
- **Verify:** per-tenant resource metrics under mixed load.

## Unbounded Concurrency

- **Shape:** work items each spawn a task/thread/worker with no cap on total concurrent work.
- **Code signature:** spawn-per-item over unbounded collections; fire-and-forget with no executor; fan-out to a downstream without a limit.
- **Typical fix:** bounded pools/queues, backpressure, rate limits.
- **Verify:** concurrency and downstream request-rate metrics under load; pool exhaustion events.

## Unbounded Accumulation

- **Shape:** something in the process grows with traffic and never shrinks — caches without eviction, queues without consumption bounds, listeners/timers never removed.
- **Code signature:** add-without-remove on long-lived structures; caches without TTL/size caps; per-request registrations on global objects.
- **Typical fix:** eviction/TTL/size caps; deregistration on teardown; bounded queues.
- **Verify:** memory/queue-length metrics across a long soak — steady state plateaus, this climbs.
