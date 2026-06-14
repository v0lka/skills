---
name: go-testing-mistakes
description: >
  Guides the agent to avoid common Go testing mistakes when writing or reviewing test code.
  Covers test categorization (build tags, env vars, short mode), race detection, test execution
  modes (parallel, shuffle), table-driven tests, avoiding sleeps in tests, handling the time API
  deterministically, using httptest/iotest utility packages, writing accurate benchmarks, and
  leveraging Go testing features (coverage, external test packages, utility functions,
  setup/teardown). Use when writing, reviewing, or refactoring Go tests, benchmarks, or test
  helpers, or when setting up CI test pipelines for Go projects.
---

# Go Testing Mistakes

Rules and patterns for robust, accurate Go testing based on common mistakes #82-#90.

---

## 1. Categorize Tests (#82)

**Rule:** Always categorize tests so unit, integration, and long-running tests can be run independently. Use one or more of these three mechanisms.

### Build tags (file-level)

Use `//go:build` tags to separate integration tests from unit tests.

```go
// File: db_test.go
//go:build integration

package db

func TestInsert(t *testing.T) {
    // ...
}
```

- `go test ./...` runs only files without build tags.
- `go test --tags=integration ./...` includes files tagged `integration`.
- To run *only* integration tests, add `//go:build !integration` to unit test files.

### Environment variables (test-level)

Prefer this when you want skipped tests to appear explicitly in output.

```go
func TestInsert(t *testing.T) {
    if os.Getenv("INTEGRATION") != "true" {
        t.Skip("skipping integration test")
    }
    // ...
}
```

### Short mode (speed-based)

Use `testing.Short()` to skip long-running tests during fast feedback loops.

```go
func TestLongRunning(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping long-running test")
    }
    // ...
}
```

Run with `go test -short ./...`.

**Combine approaches:** Use build tags or env vars for test *kind* (unit vs integration) and short mode for test *speed*.

---

## 2. Enable the -race Flag (#83)

**Rule:** Always run `go test -race ./...` in local development and CI. The race detector finds real data races at runtime with zero false positives.

**Overhead:** Memory 5-10x, execution 2-20x. Do not enable in production binaries (canary releases excepted).

**Key points:**
- The race detector can produce false negatives. Loop concurrent test logic to increase detection probability:

```go
func TestDataRace(t *testing.T) {
    for i := 0; i < 100; i++ {
        // concurrent logic under test
    }
}
```

- To exclude a file from race detection, use `//go:build !race`.

---

## 3. Use Test Execution Modes (#84)

### Parallel execution

Mark independent tests with `t.Parallel()` to speed up long-running test suites.

```go
func TestA(t *testing.T) {
    t.Parallel()
    // ...
}
```

- Sequential tests run first; parallel tests are paused then resumed together.
- Default max parallel = `GOMAXPROCS`. Override with `go test -parallel 16 ./...`.

### Shuffle mode

Use `-shuffle=on` to detect hidden inter-test dependencies.

```sh
go test -shuffle=on -v ./...
```

- Reproduce a specific order with the seed: `go test -shuffle=1636399552801504000 -v ./...`
- The seed is printed in verbose output.

---

## 4. Use Table-Driven Tests (#85)

**Rule:** When multiple tests share the same structure (call, compare, report), use table-driven tests with subtests.

```go
func TestRemoveNewLineSuffix(t *testing.T) {
    tests := map[string]struct {
        input    string
        expected string
    }{
        "empty":                  {input: "", expected: ""},
        "ending with \\r\\n":     {input: "a\r\n", expected: "a"},
        "ending with \\n":        {input: "a\n", expected: "a"},
        "ending with multiple":   {input: "a\n\n\n", expected: "a"},
        "no newline":             {input: "a", expected: "a"},
    }

    for name, tt := range tests {
        t.Run(name, func(t *testing.T) {
            got := removeNewLineSuffixes(tt.input)
            if got != tt.expected {
                t.Errorf("got: %s, expected: %s", got, tt.expected)
            }
        })
    }
}
```

**Parallel subtests:** When combining table-driven tests with `t.Parallel()`, shadow the loop variable to avoid closure capture bugs:

```go
for name, tt := range tests {
    tt := tt // shadow to capture current value
    t.Run(name, func(t *testing.T) {
        t.Parallel()
        // use tt safely
    })
}
```

> Note: Go 1.22+ fixes the loop variable capture issue, but shadowing remains safe for backward compatibility.

---

## 5. Never Sleep in Unit Tests (#86)

**Rule:** Never use `time.Sleep` as a synchronization mechanism in tests. It causes flakiness.

### Option A: Retry with polling (acceptable)

```go
func assertEventually(t *testing.T, assertion func() bool, maxRetries int, waitTime time.Duration) {
    t.Helper()
    for i := 0; i < maxRetries; i++ {
        if assertion() {
            return
        }
        time.Sleep(waitTime)
    }
    t.Fatal("assertion never became true")
}
```

Use short intervals with many retries instead of a single long sleep. Libraries like testify provide `Eventually`.

### Option B: Channel synchronization (preferred)

```go
type publisherMock struct {
    ch chan []Foo
}

func (p *publisherMock) Publish(got []Foo) {
    p.ch <- got
}

func TestGetBestFoo(t *testing.T) {
    mock := publisherMock{ch: make(chan []Foo)}
    defer close(mock.ch)
    h := Handler{publisher: &mock, n: 2}

    foo := h.getBestFoo(42)
    // check foo ...

    select {
    case published := <-mock.ch:
        if len(published) != 2 {
            t.Fatalf("expected 2, got %d", len(published))
        }
    case <-time.After(time.Second):
        t.Fatal("timed out waiting for publish")
    }
}
```

**Prefer synchronization over retries.** If synchronization is impossible, reconsider the design.

---

## 6. Handle the time API Deterministically (#87)

**Rule:** Do not call `time.Now()` directly inside code under test. Inject the time dependency so tests are deterministic.

### Option A: Inject a `now` function dependency

```go
type now func() time.Time

type Cache struct {
    mu     sync.RWMutex
    events []Event
    now    now
}

func NewCache() *Cache {
    return &Cache{now: time.Now}
}
```

In tests, inject a fixed time:

```go
cache := &Cache{now: func() time.Time {
    return parseTime(t, "2020-01-01T12:00:00.06Z")
}}
```

### Option B: Accept time as a parameter (simpler, more limited)

```go
func (c *Cache) TrimOlderThan(t time.Time) {
    // no internal time.Now() call
}
```

Caller computes the time; test passes a deterministic value.

**Do not** use a global `var now = time.Now` -- it prevents parallel test execution due to shared mutable state.

---

## 7. Use Testing Utility Packages (#88)

### httptest

**For testing HTTP handlers** -- avoid real HTTP transport:

```go
func TestHandler(t *testing.T) {
    req := httptest.NewRequest(http.MethodGet, "http://localhost", strings.NewReader("foo"))
    w := httptest.NewRecorder()
    Handler(w, req)

    if got := w.Result().Header.Get("X-API-VERSION"); got != "1.0" {
        t.Errorf("expected 1.0, got %s", got)
    }
    body, _ := io.ReadAll(w.Result().Body)
    if string(body) != "hello foo" {
        t.Errorf("unexpected body: %s", body)
    }
}
```

**For testing HTTP clients** -- use `httptest.NewServer` to spin up a local server with a stub handler, then pass `srv.URL` to the client under test. Call `defer srv.Close()`. Also available: `httptest.NewTLSServer`, `httptest.NewUnstartedServer`.

### iotest

**Test custom `io.Reader` correctness** with `iotest.TestReader(reader, expected)`.

**Test resilience to I/O errors** using wrappers:

| Function | Behavior |
|---|---|
| `iotest.ErrReader(err)` | Always returns the given error |
| `iotest.HalfReader(r)` | Reads half as many bytes as requested |
| `iotest.OneByteReader(r)` | Reads one byte at a time |
| `iotest.TimeoutReader(r)` | Fails on second read, then recovers |
| `iotest.TruncateWriter(w, n)` | Silently stops after n bytes |

Wrap readers/writers with these to verify error tolerance.

---

## 8. Write Accurate Benchmarks (#89)

### Reset or pause the timer for setup

```go
// One-time setup: reset before the loop
func BenchmarkFoo(b *testing.B) {
    expensiveSetup()
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        functionUnderTest()
    }
}

// Per-iteration setup: stop/start around it
func BenchmarkBar(b *testing.B) {
    for i := 0; i < b.N; i++ {
        b.StopTimer()
        data := expensiveSetup()
        b.StartTimer()
        functionUnderTest(data)
    }
}
```

**Caveat:** If the function under test is very fast relative to setup, the benchmark may take excessively long. Decrease `-benchtime` to mitigate.

### Do not trust single micro-benchmark runs

- Micro-benchmarks are affected by machine activity, thermal scaling, cache alignment, and instruction ordering.
- Use `-count=10` and `benchstat` for statistical comparison:

```sh
go test -bench=. -count=10 | tee stats.txt
benchstat stats.txt
```

- Use tools like `perflock` to limit CPU contention from background processes.

### Prevent compiler optimizations from eliminating your benchmark

The compiler may inline and then dead-code-eliminate calls with no observable side effects.

```go
// BAD: compiler may optimize away the call entirely
func BenchmarkPopcnt(b *testing.B) {
    for i := 0; i < b.N; i++ {
        popcnt(uint64(i))
    }
}

// GOOD: assign to local, then to global to prevent elimination
var globalResult uint64

func BenchmarkPopcnt(b *testing.B) {
    var v uint64
    for i := 0; i < b.N; i++ {
        v = popcnt(uint64(i))
    }
    globalResult = v
}
```

**Pattern:** (1) assign result to a local variable each iteration, (2) assign final value to a package-level global after the loop. Do not write directly to a global each iteration (heap writes are slower).

### Beware the observer effect

Reusing the same data across benchmark iterations lets CPU caches warm up, skewing results for CPU-bound functions.

```go
// BAD: matrix cached in L1 after first iterations
func BenchmarkCalcSum(b *testing.B) {
    s := createMatrix(rows)
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        calculateSum(s)
    }
}

// GOOD: fresh data each iteration prevents cache bias
func BenchmarkCalcSum(b *testing.B) {
    for i := 0; i < b.N; i++ {
        b.StopTimer()
        s := createMatrix(rows)
        b.StartTimer()
        calculateSum(s)
    }
}
```

---

## 9. Leverage All Go Testing Features (#90)

### Code coverage

```sh
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

To include cross-package coverage (e.g., `foo.go` tested by `bar_test.go`):

```sh
go test -coverpkg=./... -coverprofile=coverage.out ./...
```

Do not chase 100% coverage mechanically -- reason about what your tests actually cover.

### Test from an external package

Use `package foo_test` to enforce black-box testing that only exercises the public API. This prevents tests from depending on unexported internals.

### Utility functions with *testing.T

Pass `*testing.T` to test helpers and call `t.Fatal` on error instead of returning errors. Mark helpers with `t.Helper()` so failure locations point to the caller.

```go
func createCustomer(t *testing.T, name string) Customer {
    t.Helper()
    c, err := newCustomer(name)
    if err != nil {
        t.Fatal(err)
    }
    return c
}
```

### Setup and teardown

**Per test:** Call setup directly, teardown via `defer` or `t.Cleanup`.

```go
func TestMySQL(t *testing.T) {
    db := createConnection(t, dsn)
    // t.Cleanup registered inside createConnection closes db
    // ...
}

func createConnection(t *testing.T, dsn string) *sql.DB {
    t.Helper()
    db, err := sql.Open("mysql", dsn)
    if err != nil {
        t.FailNow()
    }
    t.Cleanup(func() { _ = db.Close() })
    return db
}
```

Multiple `t.Cleanup` calls execute LIFO (like `defer`).

**Per package:** Use `TestMain`.

```go
func TestMain(m *testing.M) {
    setup()
    code := m.Run()
    teardown()
    os.Exit(code)
}
```

---

## Quick Reference

| # | Mistake | Rule |
|---|---|---|
| 82 | Not categorizing tests | Use build tags, env vars, and/or `-short` to separate test kinds and speeds |
| 83 | No `-race` flag | Always `go test -race` in dev and CI |
| 84 | Ignoring execution modes | Use `t.Parallel()` for speed; `-shuffle=on` to detect hidden dependencies |
| 85 | No table-driven tests | Use map/slice + `t.Run` subtests; shadow loop vars for parallel subtests |
| 86 | Sleeping in tests | Use channel sync (preferred) or retry/poll; never bare `time.Sleep` |
| 87 | Brittle time API usage | Inject `now` as a dependency or accept `time.Time` as parameter |
| 88 | Not using httptest/iotest | `httptest` for handler/client tests; `iotest` for reader correctness and error resilience |
| 89 | Inaccurate benchmarks | Reset timer for setup; use `-count`+benchstat; prevent compiler elision; avoid observer effect |
| 90 | Missing testing features | Use `-coverpkg`, `_test` packages, `t.Helper`, `t.Cleanup`, `TestMain` |
