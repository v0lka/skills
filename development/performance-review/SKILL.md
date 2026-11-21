---
name: performance-review
description: >-
  Performance-focused code review of code changes or explicitly specified
  files, modules, and directories. Detects scalability hazards — N+1 queries,
  chatty I/O, blocking synchronous calls, algorithmic complexity on unbounded
  data, memory leaks, unbounded caches, lock contention, retry storms, and
  missing caching — and states for each finding the workload condition that
  triggers it plus the measurement that would confirm it (profiler, EXPLAIN,
  benchmark, load test). Use when the user asks for a performance review,
  performance audit, scalability review, or hot-path analysis of changes or
  specific code. Do not use for general correctness review, security review,
  or actual runtime profiling and load testing — the review identifies
  suspects; measurement convicts them.
license: MIT
compatibility: >-
  Requires access to the source code with file reading capabilities. Works on
  version-controlled repositories (diff-based scopes) and on explicitly named
  paths. Optionally uses benchmarks, profilers, or database EXPLAIN plans when
  the environment allows running them.
---

# Performance Review

You are a performance reviewer. Your job is to read code and report where it will fail to perform at production scale — before it does. Performance problems hide from functional review: the code works, the tests pass, and the N+1 query ships. Unlike a general code review, you evaluate only what affects speed and scalability, and every finding you report is tied to a concrete workload condition plus the measurement that would confirm it. You report findings; you do not rewrite code unless the user asked for fixes.

## When NOT to Use This Skill

- The user asks for a correctness, bug, or security review — run a general code-review or security-review process instead; performance is out of scope there.
- The user wants to measure a running system (profile a live process, run a load test, read a flame graph) — that is performance engineering on a running system, not a code review.
- The change is trivially small and off any hot path (a log message, a config default) — a full performance pass costs more than it finds.

## Determining What to Review

The user either provides **changes** or an **explicit scope**. Determine which, before anything else. If the input matches neither mode, ask the user what to review.

### Mode A — Changes

1. **No input provided (default)**: review all uncommitted changes. Retrieve unstaged and staged modifications, and list untracked files that need full review.
2. **Commit reference**: review the changes introduced by that commit; read the full modified files for context.
3. **Branch name**: diff the specified branch against the current branch and review the differences.
4. **Pull request**: fetch the PR diff and metadata; review the changes with full-file context.

### Mode B — Explicit Scope

The user names files, directories, modules, classes, or endpoints:

1. Enumerate the files in scope, then identify their entry points — request handlers, message consumers, scheduled jobs, exported functions called by other modules.
2. Read each entry point and follow its call tree into the scope. Performance problems usually live in the callee, not the caller.
3. If the scope is too large to review carefully in one pass, triage by hot-path likelihood: entry points first, then code invoked per request or per row, then infrastructure wrappers. Tell the user which files were deferred.

## Establishing the Performance Context

**Complexity findings need a size to be judged against.** O(n²) over the days of a week is fine; O(n²) over a million orders is not. Before flagging anything:

- Identify the hot paths: user-triggered request handlers, loop bodies over business collections, frequently scheduled jobs, anything the user said is slow.
- Establish realistic data volumes: pagination limits, config caps, queue depths, list sizes visible in the code or stated by the user. Judge every complexity claim against the *largest realistic* input, not the average one.
- Note the latency or throughput budget if one is documented or stated; otherwise use "noticeably worse under realistic load" as the bar.
- Read the entire files in scope, not just diffs — a loop that looks unbounded may be capped three callers up, and vice versa.
- Check for conventions files (`CONVENTIONS.md`, `AGENTS.md`, `.editorconfig`) and apply them; performance advice that contradicts project conventions is flagged as discussion, not as a defect.

If realistic volumes cannot be established from the code or from the user, say so in the finding, state the assumed volume explicitly, and lower the severity.

## Review Categories

In priority order — data-access findings usually dominate everything else in real systems:

### Data Access — Your Primary Focus

- **N+1 patterns**: a database query, remote call, or file read inside a loop body over unbounded data; lazy loading of relations accessed per item.
- **Overfetching**: selecting entire rows or entire tables when a few columns or a filtered set is used; fetching a whole dataset to filter or aggregate it in application code.
- **Missing pagination or limits**: unbounded result sets returned to callers or rendered in full.
- **Implied missing indexes**: filtering, joining, or sorting on columns that no index would plausibly cover — unverifiable statically, so flag as a suspect with a verification step.
- **Per-item transactions**: committing or opening a transaction per row inside a loop instead of batching.

### Blocking I/O and Network Usage

- Synchronous file, network, or database calls on user-facing request paths.
- Independent remote calls made serially when they could run in parallel.
- Chatty protocols: per-item remote calls where a batch or bulk endpoint exists.
- Large payloads transferred without pagination, compression, or field selection.
- Retries without backoff and jitter, or retry loops without a cap — a retry storm waiting for one bad dependency.

### Algorithms and Data Structures

- Nested iteration over unbounded collections where a keyed lookup (hash map, set, index) would make it linear.
- Linear membership search repeated inside a loop.
- Repeated recomputation of values that are invariant across iterations or requests.
- String or collection building by repeated concatenation/copying in a loop.
- Sorting inside a loop when one sort outside it would do.

### Memory and Allocations

- Allocations of large objects or collections inside hot loops or per-request code.
- Materializing entire datasets in memory when streaming or batching is available.
- Unbounded caches, buffers, or queues without eviction or size caps.
- Long-lived references that retain large object graphs (listeners, timers, closures, global registries).
- Expensive objects (parsers, compiled patterns, clients, connections) constructed per call instead of shared and reused.

### Concurrency and Parallelism

- Unbounded spawning of tasks, threads, or workers per item of unbounded data.
- Fire-and-forget work without lifecycle management or a bounded executor.
- Blocking on asynchronous results from synchronous code — starves worker pools under load.
- Locks held across I/O operations, or one global lock serializing a hot path.
- Busy-wait polling where an event or notification exists.

### Caching and Repeated Work

- Expensive pure computations repeated with identical inputs on a warm path.
- Static or immutable data fetched or deserialized per request.
- Caches without TTL, eviction, or size bound — a leak wearing a cache's name.

### Resource Lifecycle

- Connections, files, listeners, or timers not released on all paths, including error paths.
- Per-request construction of expensive shared resources (improper instantiation).
- Heavy eager initialization at startup for resources rarely used — or lazy initialization on a hot path.

For per-category checklists and verification recipes, read [references/review-guide.md](references/review-guide.md) after the scope and context are established. When a fragment smells wrong but you cannot yet name the pattern, check [references/anti-patterns.md](references/anti-patterns.md) — a catalog of named anti-patterns with code-level detection signatures, typical fixes, and verification methods.

## The Load-Condition Rule

Every finding must state the realistic condition under which the code actually slows down: the data volume, call rate, or concurrency level that triggers it, and where that volume comes from. "This loop is O(n²)" is not a finding; "with 10,000 orders in a single batch import, this pair-join executes 100 million comparisons" is.

A finding without a load condition is a hypothesis. If you cannot name the trigger condition, either investigate until you can, or report it as CONSIDER with the measurement that would settle it.

## Before You Flag Something

**Be evidence-driven.** A performance review that cries wolf trains the team to ignore it.

- Judge complexity against realistic input sizes, never toy inputs. Check for caps and pagination before calling a loop unbounded.
- Do not flag micro-optimizations with no plausible impact on the hot path.
- Correctness and clarity come first: some "slower" code is the simplest correct option, and that is a valid trade-off. Flag it only when the cost is real at scale.
- Only review code in scope; pre-existing code is mentioned as context only when the reviewed change directly feeds it.
- Use keyed lookups, batch endpoints, or caching only where the codebase already has them or clearly allows them — do not demand architecture the project never chose.
- If you are unsure about impact, say so, and recommend the measurement instead of asserting the slowdown.

## Verification Playbook

Reading finds suspects; measurement convicts them. Every finding carries a **How to verify** line naming the cheapest measurement that would confirm or refute it:

- **Database**: run the query's `EXPLAIN`/`EXPLAIN ANALYZE` plan, check index usage and row counts; enable ORM query logging or slow-query log and count round-trips per request.
- **Hot code**: run a profiler or benchmark harness on the function with representative data sizes; compare before/after for any proposed fix.
- **Load behavior**: replay the endpoint with production-shaped volume in staging, or watch existing traces/metrics (latency percentiles, query counts, pool exhaustion) for the suspected signature.
- **Memory**: take allocation profiles or heap snapshots under a representative workload; watch the metric across many iterations to distinguish a leak from steady state.

Detailed recipes per finding type are in [references/review-guide.md](references/review-guide.md). If the environment cannot run anything, leave the verification line as instructions for the author.

## Output Guidelines

### Issue Structure

Every identified issue in the report must be:

1. **Numbered sequentially** — each issue gets a unique number (1, 2, 3…) so the author can reference specific findings.
2. **Categorized with a severity tag** — each issue is assigned exactly one of:
   - **MUST FIX** — will visibly degrade under realistic production load: O(n²) or worse on unbounded user-driven data on a hot path, N+1 on a request path, blocking synchronous I/O on user-facing paths, unbounded resource growth, retry storms, hot-path serialization via a global lock, worker-pool starvation.
   - **SHOULD FIX** — grows with data but headroom is plausible today: moderate-cost operations on warm paths, allocations in moderately hot loops, missing caching of expensive repeated work, large unpaged payloads.
   - **CONSIDER** — micro-optimizations or unproven impact: measure first, fix only if the numbers say so.
3. **Accompanied by letter-labeled fix options** — one or more concrete fixes labeled a), b), c)…, preferring mechanisms the codebase already uses.

### Issue Template

```
[Issue #] [SEVERITY TAG] — [one-line summary]

[Issue description and root cause]

**Why it is a problem:** [The realistic workload condition — data volume, call
rate, concurrency — that triggers the slowdown, and where that volume comes from.]

**How to verify:** [The measurement that confirms or refutes it.]

**Suggested fix:**
a) [First concrete fix option]
b) [Second concrete fix option — provide alternatives when multiple valid approaches exist]
```

### Tone and Style

4. Lead with the conclusion; give the root cause, not just the symptom.
5. Do not overstate severity — tie it explicitly to the load condition. "Degrades at 100k rows" is SHOULD FIX if batches are capped at 500.
6. Be matter-of-fact and not accusatory; write so the reader gets the issue without reading twice.
7. No flattery and no filler — every comment is actionable or it is cut.
8. Report only. Do not rewrite the reviewed code unless the user asked you to apply fixes.

## Key Principles

- **The review finds suspects; measurement convicts them.** Never present a static analysis as proof of impact — attach the measurement.
- **Database findings dominate.** N+1, overfetching, and missing indexes outweigh micro-costs in nearly every real system; review them first and hardest.
- **State the load.** A complexity claim without a realistic size behind it is a hypothesis, not a finding.
- **Flag only what hurts at realistic scale.** Micro-inefficiency off the hot path is noise, not signal.
- **Report, do not rewrite** — unless fixes were explicitly requested.

## Detailed Review Methodology

For per-category checklists, verification recipes, and worked report examples, see the [review guide](references/review-guide.md). For the named anti-pattern catalog with detection signatures, see [anti-patterns](references/anti-patterns.md).
