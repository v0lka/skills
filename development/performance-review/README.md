# Performance Review

A standalone [Agent Skill](https://agentskills.io/specification) that reviews code for performance and scalability hazards. It detects N+1 queries, chatty I/O, blocking synchronous calls, algorithmic complexity on unbounded data, memory leaks, unbounded caches, lock contention, retry storms, and missing caching — and ties every finding to the workload condition that triggers it plus the measurement that would confirm it.

## When to use

| Situation                                                            | Use this skill |
| -------------------------------------------------------------------- | -------------- |
| Reviewing uncommitted changes for performance (the default)          | ✅             |
| Reviewing a specific commit, branch diff, or pull request            | ✅             |
| Reviewing explicitly named files, modules, or endpoints              | ✅             |
| General correctness, bug, or security review                         | ❌             |
| Profiling a live system or running load tests                        | ❌             |

## How it works

```
Determine scope  ──►  Establish load context  ──►  Review  ──►  Report + verify
```

1. **Determine scope** — Mode A: no input → uncommitted changes; commit ref → that commit; branch name → branch diff; PR → pull request. Mode B: explicit paths, modules, or endpoints.
2. **Establish load context** — complexity findings need a size to be judged against. The skill identifies hot paths and realistic data volumes, and reads entire files — a loop that looks unbounded may be capped three callers up.
3. **Review** — evaluates code across the categories below, in priority order (data-access findings dominate real systems).
4. **Report** — every finding states the workload condition that triggers it, the cheapest measurement that confirms it, and letter-labeled fix options. The review finds suspects; measurement convicts them.

### Review categories

| Category | Focus |
| -------- | ----- |
| **Data access** *(primary)* | N+1, overfetching, missing pagination, implied missing indexes, per-item transactions |
| **Blocking I/O & network** | Sync calls on request paths, serial independent calls, chatty protocols, retry storms |
| **Algorithms & data structures** | Quadratic pair-joins, linear membership searches, loop-invariant recomputation |
| **Memory & allocations** | Hot-loop allocations, full materialization, unbounded caches and buffers, retained graphs |
| **Concurrency** | Unbounded spawning, sync-over-async, locks held across I/O, busy-wait polling |
| **Caching & repeated work** | Repeated pure computation, static data re-fetched per request, unbounded caches |
| **Resource lifecycle** | Leaks, improper instantiation, eager/lazy initialization mismatches |

## Bundled resources

| File | Purpose |
| ---- | ------- |
| `SKILL.md` | Skill definition, scope determination, review workflow, and output format |
| `references/review-guide.md` | Per-category checklists, verification recipes, worked report examples |
| `references/anti-patterns.md` | Named anti-pattern catalog with code-level detection signatures |

## Compatibility

The skill is agent-agnostic. It requires access to the source code with file-reading capabilities and works on version-controlled repositories (diff-based scopes) as well as explicitly named paths. Optionally uses benchmarks, profilers, or database `EXPLAIN` plans when the environment allows running them.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
