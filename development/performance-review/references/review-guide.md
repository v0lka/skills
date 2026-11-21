# Performance Review — Detailed Methodology

Read this file after the review scope and performance context are established: it expands each category from the main skill file into concrete checklists, gives per-finding verification recipes, and shows worked report examples.

---

## Data Access — Detailed Checklist

### N+1 and Chatty Persistence

- [ ] Is a database query, remote call, or file read executed inside a loop body? Find the loop bound — is the collection unbounded (user data, import batches, queue messages)?
- [ ] Does ORM lazy loading fire per item — e.g., a relation accessed inside iteration or serialization of a list? (Each access compiles to one query per item.)
- [ ] Can per-item calls be replaced by one batch query (`WHERE id IN (...)`), a JOIN, or eager/batch loading that the codebase or ORM already provides?
- [ ] Is a transaction opened or committed per row where one batched transaction covers the same work?

### Overfetching

- [ ] Are entire rows (or entire tables) selected when only a few columns are used?
- [ ] Is a dataset fetched fully so the application can filter, join, count, or aggregate it in memory — work the data store could do?
- [ ] Are wide payloads (all fields, all relations) returned to callers that use a subset?

### Unbounded Results

- [ ] Do list endpoints or report queries return everything when no pagination or explicit limit protects the query?
- [ ] Is offset-based pagination used on a table expected to grow large (deep offsets get slower as the offset grows)? Keyset/cursor pagination avoids that.

### Implied Missing Indexes

- [ ] Do filters, joins, or sort keys rest on columns for which no index plausibly exists? Static reading cannot prove an index is missing — report the suspect and name the check (see verification below).

---

## Blocking I/O and Network Usage — Detailed Checklist

- [ ] Do synchronous file, network, or database calls sit on user-facing request paths? Move them off the path, parallelize, or make them asynchronous.
- [ ] Are independent remote calls made serially when nothing depends on their order? (Latency adds up; parallel execution or batching removes the sum.)
- [ ] Is there a per-item remote call where a bulk or batch endpoint exists — the network version of N+1 (chatty I/O)?
- [ ] Are payloads transferred in full where pagination, compression, or field selection would do?
- [ ] Do retries lack backoff, jitter, or a cap? Unbounded or tight retry loops against a struggling dependency amplify the failure into a retry storm.
- [ ] Are connections reused (pooling, keep-alive) or re-established per call?

---

## Algorithms and Data Structures — Detailed Checklist

- [ ] Nested iteration over two unbounded collections — is a keyed lookup (hash map, set, database index) possible, turning the pair-join linear? This is the most common quadratic-in-disguise.
- [ ] Membership checks (contains/find) executed linearly inside a loop — replace with a set built once outside the loop.
- [ ] Values recomputed inside a loop that do not depend on the loop variable — hoist them out.
- [ ] Identical expensive computation repeated across requests or calls — compute once and share, or cache.
- [ ] Strings or collections grown by repeated concatenation/copying inside a loop — use the language's join/builder construct.
- [ ] Sorting executed inside a loop where one sort before the loop produces the same order.
- [ ] Complexity claims always judged against the largest realistic input — verify the bound (pagination, config cap, import size) before calling the data unbounded.

---

## Memory and Allocations — Detailed Checklist

- [ ] Large objects, buffers, or collections allocated inside hot loops or per-request code — allocate once and reuse.
- [ ] Entire datasets materialized in memory where streaming or chunked processing is available.
- [ ] Caches, maps, or queues that grow without eviction, TTL, or a size cap — every unbounded cache is a leak with a delay.
- [ ] Long-lived structures retaining large object graphs: listeners, timers, callbacks, closures, global registries that are never removed.
- [ ] Expensive objects (compiled patterns, parsers, serialization codecs, clients) constructed per call — share and reuse.
- [ ] Per-iteration temporary allocations in a tight loop — reduce or reuse buffers if the path is truly hot.

---

## Concurrency and Parallelism — Detailed Checklist

- [ ] Tasks, threads, or workers spawned per item of unbounded data with no bound on how many run at once — bound them with a pool/queue.
- [ ] Fire-and-forget work with no lifecycle management — track completion and failures; unbounded fire-and-forget is both a correctness and a resource hazard.
- [ ] Synchronous code blocking on asynchronous results — under load this exhausts the worker pool; the request path stalls while threads wait.
- [ ] Locks held across I/O operations — every concurrent caller queues behind the slowest network round-trip.
- [ ] One global lock guarding what could be partitioned — serialization of a hot path caps throughput at one core's worth of work.
- [ ] Busy-wait polling loops with sleep, where an event, signal, or notification mechanism exists.
- [ ] Work fan-out that could overwhelm a downstream service — check for rate limits, bounded concurrency, or backpressure.

---

## Caching and Repeated Work — Detailed Checklist

- [ ] Expensive pure computation repeated with identical inputs on a warm path — memoize or cache.
- [ ] Static or immutable data (config, schemas, reference tables) fetched or deserialized per request — load once.
- [ ] Cache entries without TTL, eviction, or size bound — unbounded growth.
- [ ] Cache granularity mismatch: caching at a level that makes invalidation harder or hit rates near zero.
- [ ] Cold-cache behavior: does an expiry spike re-run the expensive work in many threads at once (thundering herd)? Coalesce concurrent misses into one computation.

---

## Resource Lifecycle — Detailed Checklist

- [ ] Connections, files, handles, listeners, timers — released on every path, including error and early-return paths?
- [ ] Expensive shared resources constructed per request instead of initialized once and reused (improper instantiation).
- [ ] Heavy eager initialization at startup for resources rarely used — or lazy initialization paid repeatedly on a hot path.
- [ ] Unchanged static data re-parsed or re-deserialized per message/request.

---

## Verification Recipes

Reading finds suspects; measurement convicts them. Pick the cheapest measurement that would confirm or refute each finding, and name it in the report.

### Database Findings

- Run the suspected query's `EXPLAIN` / `EXPLAIN ANALYZE` plan: check index usage, scanned row counts, and whether estimates explode.
- Enable the ORM's query logging or the slow-query log, replay one representative request, and **count the round-trips** — the N+1 signature is a query count proportional to list size.
- Check the table's indexes against the filter/join/sort columns; check row counts to size the realistic n.
- Inspect query statistics views (`pg_stat_statements` and equivalents) for total time and call counts if the code runs in a live environment.

### Hot-Code Findings (complexity, allocations, caching)

- Run a profiler or a benchmark harness on the suspect function with **representative data sizes** — the same sizes used in the load-condition line. Compare against a candidate fix, not just the baseline.
- For allocation findings, use an allocation/heap profiler; look for allocation rates proportional to request or iteration counts.
- For caching proposals, compute the expected hit rate from the access pattern in code (repeated identical inputs per request?) before proposing the cache.

### Concurrency Findings

- Watch worker-pool or thread-pool metrics under a representative load — starvation shows as a saturated pool with requests queuing.
- Capture lock wait or contention metrics (or a paused profile) at the suspected lock to see how much time stacks up behind it.
- Load-test the endpoint with concurrent clients and watch latency percentiles, not averages: serialization shows up in p99 first.

### Memory-Lifecycle Findings (leaks)

- Take heap snapshots after warm-up and after many more iterations of the same workload; growth between snapshots that never plateaus is the leak signature.
- Watch the process memory metric across a long soak; steady state plateaus, a leak climbs.

### Load-Behavior Findings

- Replay the request path with production-shaped volume in staging and compare latency percentiles before/after the candidate fix.
- Read existing traces/metrics for the suspected signature (per-request query counts, payload sizes, retry counts) when a live or recorded environment exists.

If nothing can run in the current environment, leave the verification line as concrete instructions for the author — name the tool kind, the workload, and the metric to watch.

---

## Worked Report Examples

### Example: N+1 on a request path

> **#1 MUST FIX** — One database query per order while rendering the order list
>
> The order list loader fetches all orders, then reads each order's customer inside the rendering loop, issuing one query per order.
>
> **Why it is a problem:** The endpoint serves account dashboards where a customer routinely holds hundreds of orders; at 500 orders this is 501 round-trips per page view, and the page's query count scales with data instead of staying constant.
>
> **How to verify:** Enable ORM query logging and load the dashboard for a large account — the query count will be roughly the order count plus one.
>
> **Suggested fix:**
> a) Eager-load the customer relation in the initial query (JOIN or the ORM's eager-loading mechanism).
> b) Batch-load all customers for the fetched order set in one `WHERE id IN (...)` query before rendering.

### Example: Quadratic pair-join with headroom

> **#2 SHOULD FIX** — Duplicate detection joins every import row against every stored row
>
> The dedup pass compares each incoming record against all existing records for the account, in nested loops.
>
> **Why it is a problem:** Import batches are currently capped at 1,000 rows, so this is up to a million comparisons per import — tolerable today, but the cap is a config value and bulk imports have been trending larger; the cost grows quadratically with the cap.
>
> **How to verify:** Time the dedup pass at cap 1,000 and at a doubled cap in a benchmark harness; quadratic growth doubles the time again with each cap doubling.
>
> **Suggested fix:**
> a) Build a keyed lookup of existing records (hash of the dedup fields) before the loop and compare per incoming row.
> b) Push duplicate detection into the batch insert query using a unique constraint on the dedup fields.

### Example: Unproven micro-cost

> **#3 CONSIDER** — String formatting rebuilt per iteration in a logging call
>
> A formatted message is constructed on every loop iteration even when debug logging is disabled.
>
> **Why it is a problem:** Formatting cost is paid per iteration regardless of log level; on a hot loop over large collections this adds measurable overhead — on the current bounded loop (≤ 50 items) it almost certainly does not.
>
> **How to verify:** Profile the loop with formatting on and off at the largest realistic collection size; fix only if the delta is a meaningful share of loop time.
>
> **Suggested fix:**
> a) Guard the formatting behind the log-level check so the cost is paid only when logging is active.
> b) Leave as is if profiling shows no measurable delta at realistic sizes.
