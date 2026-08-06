# Idiomatic Go Skills

A set of eleven [Agent Skills](https://agentskills.io/specification) that help write correct, idiomatic, and performant Go code. Each skill is a focused rule set distilled from common Go mistakes — primarily the catalog in [*100 Go Mistakes and How to Avoid Them*](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them) — covering a single area of the language or its standard library.

The skills are **complementary and context-triggered**, not a sequential workflow. An agent activates the relevant skill(s) based on the Go constructs it is writing or reviewing. They provide concrete wrong/fix patterns applied in place — no artifacts, files, or external services are produced or required.

## How the skills are organized

The suite spans six areas, from language fundamentals to performance and testing:

```
  Language core                       Concurrency
  ─────────────                       ───────────
  go-data-types                       go-concurrency-foundations
  go-strings                          go-concurrency-practice
  go-control-structures
  go-functions-methods
  go-error-management

  Organization      Stdlib            Performance      Testing
  ─────────────     ───────           ────────────     ───────
  go-code-          go-standard-      go-optimizations go-testing-
   organization      library                            mistakes
```

| Skill                       | Area              | What it enforces                                                                                                                                                                                                                                                                                                                                |
| --------------------------- | ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `go-data-types`             | Language core     | Correct use of integer literals, numeric overflow, floating-point arithmetic, slice initialization/slicing/appending/copying, map initialization, and value comparison.                                                                                                                                                                          |
| `go-strings`                | Language core     | Rune semantics, string iteration, `trim` vs. suffix/prefix functions, `strings.Builder` concatenation, avoiding needless `string`/`[]byte` conversions, and preventing substring memory leaks.                                                                                                                                                 |
| `go-control-structures`     | Language core     | Correct `range` loops, `break` inside `switch`/`select` within loops, and the pitfalls of `defer` placed inside loops.                                                                                                                                                                                                                          |
| `go-functions-methods`      | Language core     | Receiver type selection, named result parameters, nil-receiver pitfalls, preferring `io.Reader` over filenames, and `defer` argument evaluation.                                                                                                                                                                                                |
| `go-error-management`       | Language core     | Panic usage, error wrapping vs. transforming, `errors.As`/`errors.Is` checks, handling an error exactly once, explicitly ignoring errors, and handling `defer` errors.                                                                                                                                                                         |
| `go-code-organization`      | Organization      | Variable scoping/shadowing, nested control flow, `init` functions, getters/setters, interfaces, generics, type embedding, functional options, package structure/naming, utility packages, code documentation, and linter configuration.                                                                                                        |
| `go-concurrency-foundations`| Concurrency       | Concurrency vs. parallelism, the "concurrency is always faster" myth, channels vs. mutexes, data races and race conditions, worker-pool sizing for CPU- vs. I/O-bound work, and `context` semantics.                                                                                                                                            |
| `go-concurrency-practice`   | Concurrency       | Practical rules for goroutines, channels, `select`, and `sync` primitives (`Mutex`, `WaitGroup`, `Cond`, `errgroup`), plus context propagation. Catches goroutine leaks, loop-variable captures, channel misuse, data races in `append`/slices/maps, `sync` type copying, and deadlocks caused by string formatting.                          |
| `go-standard-library`       | Standard library  | `time.Duration` misuse and `time.After` leaks, JSON pitfalls (type embedding, monotonic clock, `map[string]any`), SQL mistakes (`sql.Open`, connection pooling, prepared statements, null values, row-iteration errors), closing transient resources (HTTP body, `sql.Rows`, `os.File`), missing `return` after an HTTP error, and default clients/servers without timeouts. |
| `go-optimizations`          | Performance       | CPU-cache awareness, false sharing, instruction-level parallelism, data alignment, escape analysis, allocation reduction, inlining, profiling, GC tuning, and `GOMAXPROCS` configuration for containers.                                                                                                                                        |
| `go-testing-mistakes`       | Testing           | Test categorization (build tags, env vars, short mode), race detection, execution modes (parallel, shuffle), table-driven tests, avoiding sleeps, deterministic handling of the time API, `httptest`/`iotest`, accurate benchmarks, coverage, external test packages, and setup/teardown.                                                    |

## When to use which skill

The skills are selected from the Go constructs in play, not from a fixed order. A single change often engages several of them at once:

| If the code involves…                                                                 | Engage                                                                                                   |
| ------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Slices, maps, integers, floats, value comparison                                      | `go-data-types`                                                                                          |
| `string`, `[]byte`, runes, concatenation, trimming                                    | `go-strings`                                                                                             |
| `range`, `break`/`continue`, `switch`/`select` inside loops, `defer` in a loop       | `go-control-structures`                                                                                  |
| Receivers, named results, `defer` argument evaluation, `io.Reader`                    | `go-functions-methods`                                                                                   |
| `errors.Is`/`As`, wrapping, `panic`, sentinel/custom errors                           | `go-error-management`                                                                                    |
| Interfaces, generics, packages, `init`, functional options, linter config             | `go-code-organization`                                                                                   |
| Goroutines, channels, `select`, `sync.*`, worker pools, `context`                     | `go-concurrency-foundations` + `go-concurrency-practice`                                                 |
| `time`, `encoding/json`, `database/sql`, `net/http`, `os`                             | `go-standard-library`                                                                                    |
| Hot paths, allocations, profiling, GC, container `GOMAXPROCS`                         | `go-optimizations`                                                                                       |
| Tests, benchmarks, test helpers, CI test pipelines                                     | `go-testing-mistakes`                                                                                    |

## How the skills relate

The skills are independent but overlap on a few recurring themes. Treat the more specific skill as authoritative for its construct, and apply both where they intersect:

- **`defer`** appears in three places — `go-control-structures` (defer inside loops), `go-functions-methods` (argument evaluation timing), and `go-error-management` (handling deferred errors).
- **`context`** spans concurrency (`go-concurrency-foundations`/`go-concurrency-practice`) and the standard library (`go-standard-library`, for HTTP/SQL timeouts).
- **Concurrency data races** on slices and maps are owned by `go-concurrency-practice`, while the underlying slice/map mistakes belong to `go-data-types`.
- **`go-code-organization`** sets project-wide conventions (package layout, linter rules) that the other skills assume are in place.

For a typical feature, an agent might consult `go-code-organization` (structure) → the relevant language-core skill (correctness) → `go-standard-library` / `go-concurrency-practice` (stdlib or sync) → `go-testing-mistakes` (tests) → optionally `go-optimizations` (if the path is hot).

## Source

The rules are primarily drawn from [*100 Go Mistakes and How to Avoid Them*](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them) by Teiva Harsanyi, decomposed into per-area skills so an agent loads only the rules relevant to the code at hand. Skill descriptions reference the original mistake numbers and chapters where applicable.

## Compatibility

The skills are agent-agnostic. They describe **what** correct Go looks like, not which specific tools to call, so they work with any AI agent that can read, write, and search files. No external services, APIs, or runtime dependencies are required beyond a Go toolchain when the rules are applied to real code.

All skills follow the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
