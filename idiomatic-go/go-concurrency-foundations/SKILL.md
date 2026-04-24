---
name: go-concurrency-foundations
description: >
  Guides the agent to avoid foundational concurrency mistakes in Go: confusing
  concurrency with parallelism, assuming concurrency is always faster, misusing
  channels vs mutexes, ignoring data races and race conditions, mis-sizing worker
  pools for CPU- vs I/O-bound work, and misunderstanding Go contexts. Use when
  writing, reviewing, or refactoring any concurrent Go code, goroutines, channels,
  mutexes, worker pools, or context usage.
---

# Go Concurrency Foundations

Rules derived from "100 Go Mistakes" #55-#60. Apply whenever writing or reviewing
concurrent Go code.

---

## 1. Concurrency vs Parallelism (#55)

- **Concurrency** is about *structure* -- decomposing a problem into independently
  executing steps that coordinate.
- **Parallelism** is about *execution* -- running the same step on multiple cores
  simultaneously.
- Concurrency *enables* parallelism but is not the same thing.
- When restructuring code, ask: "Am I changing the structure (concurrency) or
  adding more workers to the same step (parallelism)?"

---

## 2. Concurrency Is Not Always Faster (#56)

### Go scheduling essentials

- Goroutines are multiplexed onto OS threads (M) by the Go runtime, not the OS.
- `GOMAXPROCS` limits the number of OS threads executing user-level Go code
  simultaneously (defaults to logical CPU count since Go 1.5).
- The scheduler uses per-P local queues, a global queue, and **work stealing**.
- Since Go 1.14 the scheduler is **preemptive** (10 ms time slice).

### Key rule: small workloads kill parallelism

Spinning up a goroutine per tiny unit of work makes things *slower* -- the
goroutine creation and scheduling overhead dominates. Always use a **threshold**
to fall back to sequential execution for small inputs.

```go
const threshold = 2048 // tune via benchmarks on target hardware

func parallelMergesort(s []int) {
    if len(s) <= 1 {
        return
    }
    if len(s) <= threshold {
        sequentialMergesort(s) // fall back to sequential
        return
    }

    middle := len(s) / 2
    var wg sync.WaitGroup
    wg.Add(2)
    go func() {
        defer wg.Done()
        parallelMergesort(s[:middle])
    }()
    go func() {
        defer wg.Done()
        parallelMergesort(s[middle:])
    }()
    wg.Wait()
    merge(s, middle)
}
```

### Checklist before adding concurrency

1. Start with a correct sequential version.
2. Profile and benchmark to confirm the bottleneck.
3. Introduce concurrency with a tunable threshold or pool size.
4. Benchmark the concurrent version -- if it is not measurably faster, keep the
   sequential one.

---

## 3. Channels vs Mutexes (#57)

Use this decision guide:

| Situation | Prefer |
|---|---|
| **Parallel** goroutines accessing/mutating a shared resource | `sync.Mutex` (or `sync/atomic`) |
| **Concurrent** goroutines that need to coordinate, signal, or transfer ownership | Channels |
| Signaling completion or readiness (with or without data) | Channels (`chan struct{}` for no data) |
| Protecting a critical section (read/write to shared state) | `sync.Mutex` / `sync.RWMutex` |
| Transferring ownership of a resource from one stage to the next | Channels |

- Do NOT force channels everywhere just because Go says "share memory by
  communicating." Mutexes and channels are **complementary**.
- If goroutines are *parallel* (same step, multiple workers): think mutexes.
- If goroutines are *concurrent* (different steps in a pipeline): think channels.

---

## 4. Data Races vs Race Conditions (#58)

### Definitions

- **Data race**: two+ goroutines access the same memory location concurrently and
  at least one writes. Detected by `go test -race` / `go run -race`.
- **Race condition**: behavior depends on uncontrolled timing of events. A
  data-race-free program can still have race conditions.

Eliminating data races does NOT guarantee deterministic results.

### Preventing data races

Choose one of:

1. **Atomic operations** -- `sync/atomic` for simple numeric types.
2. **Mutex** -- `sync.Mutex` / `sync.RWMutex` to guard a critical section.
3. **Channel communication** -- ensure only one goroutine writes to the variable.

```go
// BAD -- data race
i := 0
go func() { i++ }()
go func() { i++ }()

// GOOD -- atomic
var i int64
go func() { atomic.AddInt64(&i, 1) }()
go func() { atomic.AddInt64(&i, 1) }()

// GOOD -- mutex
var mu sync.Mutex
i := 0
go func() { mu.Lock(); i++; mu.Unlock() }()
go func() { mu.Lock(); i++; mu.Unlock() }()

// GOOD -- channel (only parent writes)
ch := make(chan int)
go func() { ch <- 1 }()
go func() { ch <- 1 }()
i := <-ch + <-ch
```

### Race condition (data-race-free but non-deterministic)

```go
// No data race, but i is unpredictably 1 or 2
var mu sync.Mutex
i := 0
go func() { mu.Lock(); i = 1; mu.Unlock() }()
go func() { mu.Lock(); i = 2; mu.Unlock() }()
```

To enforce ordering, use channels for coordination, not just mutexes.

### Go memory model guarantees

Memorize these ordering rules:

1. **Goroutine creation** happens-before the goroutine starts executing.
2. **Goroutine exit** is NOT guaranteed to happen before any event -- always
   synchronize if the parent reads state written by the child.
3. **Channel send** happens-before the corresponding receive completes.
4. **Channel close** happens-before a receive observing the closure.
5. **Unbuffered channel receive** happens-before the send completes.
   - This means with an unbuffered channel, a write before the receive is
     guaranteed visible after the send returns.
   - This guarantee does NOT hold for buffered channels.

```go
// SAFE -- unbuffered channel guarantees ordering
i := 0
ch := make(chan struct{})
go func() {
    i = 1
    <-ch
}()
ch <- struct{}{}
fmt.Println(i) // guaranteed to print 1

// UNSAFE -- buffered channel, data race on i
ch := make(chan struct{}, 1)
go func() {
    i = 1
    <-ch
}()
ch <- struct{}{}
fmt.Println(i) // data race
```

---

## 5. Worker Pool Sizing by Workload Type (#59)

| Workload | Pool size guideline |
|---|---|
| **CPU-bound** | `runtime.GOMAXPROCS(0)` (number of OS threads, defaults to logical CPUs) |
| **I/O-bound** | Depends on the external system's capacity; tune via load testing |

- Use `runtime.GOMAXPROCS(0)` (read-only call) to get the current value.
- Do NOT use `runtime.NumCPU()` for pool sizing -- `GOMAXPROCS` may be set lower
  than the CPU count (e.g., in containers).
- For CPU-bound work, more goroutines than `GOMAXPROCS` causes unnecessary
  context switching with no throughput gain.

### Worker pool template

```go
func process(r io.Reader) (int, error) {
    var count int64
    n := runtime.GOMAXPROCS(0) // CPU-bound: match available threads

    ch := make(chan []byte, n)
    var wg sync.WaitGroup
    wg.Add(n)
    for i := 0; i < n; i++ {
        go func() {
            defer wg.Done()
            for b := range ch {
                v := task(b)
                atomic.AddInt64(&count, int64(v))
            }
        }()
    }

    for {
        b := make([]byte, 1024)
        _, err := r.Read(b)
        if err != nil {
            if err == io.EOF {
                break
            }
            close(ch)
            return 0, err
        }
        ch <- b
    }
    close(ch)
    wg.Wait()
    return int(count), nil
}
```

---

## 6. Go Contexts (#60)

### When to create which context

| Constructor | Use case |
|---|---|
| `context.WithTimeout(parent, d)` | Cancel after a duration (e.g., RPC deadline) |
| `context.WithDeadline(parent, t)` | Cancel at an absolute time |
| `context.WithCancel(parent)` | Manual cancellation signal (e.g., graceful shutdown) |
| `context.WithValue(parent, k, v)` | Carry request-scoped metadata (trace IDs, auth) |
| `context.Background()` | Top-level / main / test entry point |
| `context.TODO()` | Placeholder when the correct context is not yet available |

### Mandatory rules

1. **Always `defer cancel()`** after `WithTimeout`, `WithDeadline`, or
   `WithCancel`. Forgetting leaks the internal timer goroutine until the timeout
   fires.

   ```go
   ctx, cancel := context.WithTimeout(ctx, 4*time.Second)
   defer cancel() // always, even if the function returns early
   ```

2. **Use unexported key types** for context values to prevent cross-package
   collisions.

   ```go
   type ctxKey string
   const traceIDKey ctxKey = "traceID"

   ctx = context.WithValue(ctx, traceIDKey, "abc-123")
   ```

3. **Never block on channel send/receive in a context-aware function** without
   selecting on `ctx.Done()`.

   ```go
   // BAD -- blocks even if context is canceled
   ch <- msg
   v := <-ch

   // GOOD -- respects context cancellation
   select {
   case <-ctx.Done():
       return ctx.Err()
   case ch <- msg:
   }

   select {
   case <-ctx.Done():
       return ctx.Err()
   case v := <-ch:
       // use v
   }
   ```

4. **Check `ctx.Err()`** to distinguish cancellation causes:
   - `context.Canceled` -- explicit cancel.
   - `context.DeadlineExceeded` -- timeout or deadline passed.

5. Functions that users wait for should accept a `context.Context` as the first
   parameter so upstream callers can control cancellation.

6. Prefer `context.TODO()` over `context.Background()` when the right context
   is unclear or not yet propagated -- it signals intent to revisit.
