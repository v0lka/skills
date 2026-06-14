---
name: go-optimizations
description: Guides the agent to write and review performance-sensitive Go code by applying CPU cache awareness, false sharing prevention, instruction-level parallelism, data alignment, escape analysis, allocation reduction, inlining, profiling, GC tuning, and Docker/Kubernetes GOMAXPROCS configuration. Use when writing hot-path Go code, reviewing performance-critical sections, reducing allocations, profiling applications, tuning GC behavior, or deploying Go services in containers.
---

# Go Optimization Patterns

> "Make it correct, make it clear, make it concise, make it fast, in that order." -- Wes Dyer

Apply these rules only to performance-sensitive code paths. Do NOT sacrifice readability for micro-optimizations unless profiling shows a bottleneck.

---

## 1. CPU Cache Awareness

### Cache Lines

A CPU fetches memory in **64-byte cache lines**, not individual variables. One cache line holds 8 `int64` values. Optimize data layout to maximize useful data per cache line.

**Key rule**: Iterating a slice where you skip elements is still fast if accesses fall within the same cache lines. The bottleneck is memory access, not iteration count.

### Slice of Structs vs. Struct of Slices

When iterating over a single field across many records, a **struct of slices** provides better spatial locality than a **slice of structs** because the target field values are contiguous in memory.

```go
// SLOWER when summing only field `a` -- fields interleaved in memory
type Foo struct {
    a int64
    b int64
}
func sumFoo(foos []Foo) int64 { /* iterates a, skips b, a, skips b... */ }

// FASTER -- all `a` values contiguous
type Bar struct {
    a []int64
    b []int64
}
func sumBar(bar Bar) int64 { /* iterates bar.a directly */ }
```

Use struct-of-slices layout when hot loops access only a subset of fields (column-oriented access pattern).

### Predictability and Stride

- **Unit stride** (contiguous elements): best -- predictable, minimal cache lines.
- **Constant stride** (e.g., every 2nd element): predictable but less efficient.
- **Non-unit stride** (linked list, slice of pointers): NOT predictable -- CPU cannot prefetch.

Prefer slices over linked lists and pointer-chasing structures in hot paths. Even if a linked list is allocated contiguously, the CPU cannot predict the access pattern.

### Critical Stride (Cache Placement)

Modern caches are **set-associative**. When stride size equals the critical stride (number of cache sets x cache line size, typically 4 KB for an 8-way 32 KB L1D), all accessed blocks map to the same cache set, causing **conflict misses**.

Practical example: a matrix with exactly 512 `int64` columns hits a critical stride on typical hardware. Using 513 columns avoids it and can be ~50% faster when reusing the same matrix.

**Rule**: When working with large matrices or strided access, avoid dimensions that are exact powers of 2 or multiples of the critical stride.

---

## 2. False Sharing

When two goroutines write to different variables that share the same cache line, the entire line is invalidated on each write across cores (MESI protocol). This is **false sharing**.

```go
// BAD -- sumA and sumB likely share a cache line
type Result struct {
    sumA int64
    sumB int64
}

// GOOD -- padding forces separate cache lines
type Result struct {
    sumA int64
    _    [56]byte  // 64 - 8 = 56 bytes padding
    sumB int64
}
```

**When to apply**: any struct whose fields are written concurrently by different goroutines on hot paths. Alternative: use channels so goroutines communicate local results instead of sharing memory.

---

## 3. Instruction-Level Parallelism (ILP)

Modern CPUs execute independent instructions in parallel (superscalar). **Data hazards** (one instruction depends on the result of another) prevent parallelism.

**Technique**: introduce a temporary variable to break dependency chains so the CPU can execute more instructions in parallel.

```go
// SLOWER -- s[0] increment must complete before checking s[0]
for i := 0; i < n; i++ {
    s[0]++
    if s[0]%2 == 0 {
        s[1]++
    }
}

// FASTER (~20%) -- v captures s[0], breaking the dependency chain
for i := 0; i < n; i++ {
    v := s[0]
    s[0] = v + 1
    if v%2 != 0 {  // note: check odd because v is pre-increment
        s[1]++
    }
}
```

**Caveat**: Go compiler output changes between versions. Verify with benchmarks and `go build -gcflags "-S"`.

---

## 4. Data Alignment

The Go compiler adds padding to ensure each field's memory address is a multiple of its size. Poorly ordered struct fields waste memory.

**Rule**: sort struct fields by size in **descending order**.

```go
// BAD -- 24 bytes (7 bytes padding after b1, 7 after b2)
type Foo struct {
    b1 byte   // 1 byte + 7 padding
    i  int64  // 8 bytes
    b2 byte   // 1 byte + 7 padding
}

// GOOD -- 16 bytes (only 6 bytes padding after b1+b2)
type Foo struct {
    i  int64  // 8 bytes
    b1 byte   // 1 byte
    b2 byte   // 1 byte + 6 padding
}
```

Compact structs reduce memory, improve cache utilization, and lower GC pressure when heap-allocated.

---

## 5. Stack vs. Heap and Escape Analysis

Stack allocation is nearly free and self-cleaning (no GC). Heap allocation requires GC work and is ~10x slower.

### Escape Rules

| Pattern | Escapes? |
|---|---|
| Returning a pointer to a local variable ("sharing up") | Yes |
| Passing a pointer to a callee ("sharing down") | No |
| Variable referenced after function returns | Yes |
| Global variables | Yes |
| Pointer sent to a channel | Yes |
| Variable referenced by a value sent to a channel | Yes |
| Local variable too large for the stack | Yes |
| Slice with runtime-determined length (`make([]int, n)`) | Yes |
| Backing array reallocated via `append` | May escape |
| Slice with compile-time constant length (`make([]int, 10)`) | No (usually) |

**Verify assumptions**: `go build -gcflags "-m=2"` shows escape decisions.

**Do NOT** return pointers "to avoid a copy" as a premature optimization. Copying within cache lines is extremely fast. Focus on readability and semantics first.

---

## 6. Reducing Allocations

### API Design (Sharing Down)

Design APIs so callers provide buffers instead of functions returning new allocations:

```go
// BAD -- returned slice escapes to heap
type Reader interface {
    Read(n int) ([]byte, error)
}

// GOOD -- caller provides the buffer (sharing down)
type Reader interface {
    Read(p []byte) (int, error)
}
```

### Compiler Optimizations

The Go compiler avoids `[]byte` to `string` conversion when used directly in a map lookup:

```go
// SLOWER -- intermediate string variable forces allocation
key := string(bytes)
v, ok = m[key]

// FASTER -- compiler optimizes away the conversion
v, ok = m[string(bytes)]
```

### sync.Pool

Use `sync.Pool` to reuse frequently allocated objects of the same type. It is NOT a cache (no size/capacity control); objects are drained each GC cycle.

```go
var pool = sync.Pool{
    New: func() any {
        return make([]byte, 1024)
    },
}

func write(w io.Writer) {
    buf := pool.Get().([]byte)
    buf = buf[:0]           // reset before use
    defer pool.Put(buf)
    getResponse(buf)
    _, _ = w.Write(buf)
}
```

### Other Allocation Reducers

- Use `strings.Builder` instead of `+` for string concatenation.
- Avoid unnecessary `[]byte` to `string` conversions.
- Preallocate slices and maps when length is known.
- Use compact struct layout (see Data Alignment above).

---

## 7. Inlining

The Go compiler inlines functions below a complexity budget (~80 cost units). Inlining eliminates call overhead AND enables further optimizations (e.g., keeping variables on the stack).

### Fast-Path Inlining

Extract the slow path into a separate function so the main function stays within the inlining budget:

```go
// The Lock method stays small enough to inline
func (m *Mutex) Lock() {
    if atomic.CompareAndSwapInt32(&m.state, 0, mutexLocked) {
        return  // fast path -- inlined
    }
    m.lockSlow()  // slow path -- separate function
}

func (m *Mutex) lockSlow() {
    // complex logic that exceeds inlining budget
}
```

**Check inlining decisions**: `go build -gcflags "-m=2"` reports which functions are inlined and which exceed the budget.

---

## 8. Go Diagnostics Tooling

### Profiling with pprof

Enable via `import _ "net/http/pprof"` (safe for production; CPU profile only runs when activated).

| Profile | Endpoint | What It Shows |
|---|---|---|
| CPU | `/debug/pprof/profile?seconds=30` | Where the app spends CPU time |
| Heap | `/debug/pprof/heap?gc=1` | Current heap allocations |
| Allocs | `/debug/pprof/allocs` | All past heap allocations |
| Goroutine | `/debug/pprof/goroutine/?debug=0` | Stack traces of all goroutines |
| Block | `/debug/pprof/block` | Where goroutines block on sync primitives |
| Mutex | `/debug/pprof/mutex` | Mutex contention |

**Key signals from CPU profile**:
- Excessive `runtime.mallogc` => too many small heap allocations.
- Time in channel/mutex ops => excessive contention.
- Time in `syscall.Read`/`syscall.Write` => improve I/O buffering.

**Memory leak detection**:
1. `GET /debug/pprof/heap?gc=1` (forces GC first)
2. Wait
3. `GET /debug/pprof/heap?gc=1` again
4. `go tool pprof -http=:8080 -diff_base <file2> <file1>`

**Important**: enable only ONE profiler at a time to avoid erroneous observations.

Block and mutex profiles must be explicitly enabled:
- `runtime.SetBlockProfileRate(rate)`
- `runtime.SetMutexProfileFraction(rate)`

### Execution Tracer

```bash
go test -bench=. -trace=trace.out
go tool trace trace.out
```

Shows: goroutine scheduling, GC phases, parallelism quality. Use `runtime/trace` for user-defined tasks:

```go
ctx, task := trace.NewTask(context.Background(), "myTask")
trace.WithRegion(ctx, "main", func() {
    // work
})
task.End()
```

**CPU profiling vs tracing**: profiling is sample-based per-function (10ms granularity); tracing is event-based per-goroutine (no rate bound).

---

## 9. Garbage Collector Tuning

Go GC is concurrent mark-and-sweep. Controlled by `GOGC` (default: 100), which sets heap growth percentage before next GC. A GC also runs if none has triggered in 2 minutes.

| Scenario | Recommendation |
|---|---|
| Steady load increase | `GOGC=100` is fine |
| Sudden traffic spike | Increase `GOGC` to reduce GC frequency during ramp |
| Extreme spike (seconds) | Pre-allocate a large byte slice to raise the heap floor |

**Pre-allocation trick** for extreme spikes:

```go
// In main.go -- lazy allocation via mmap, no physical memory until used
var _ = make([]byte, 1_000_000_000) // 1 GB virtual reservation
```

This raises the GC trigger threshold (next GC at 2 GB if `GOGC=100`) without consuming physical memory.

**Debug GC**: `GODEBUG=gctrace=1 go test -bench=. -v`

---

## 10. Go in Docker and Kubernetes

`GOMAXPROCS` defaults to the **host's** logical CPU count, NOT the container's CPU limit. With a 4-core limit on an 8-core host, Go spawns 8 OS threads. CFS (Completely Fair Scheduler) throttles after the quota is consumed, causing up to **300% latency penalty**.

**Example**: 8 threads x 50ms = 400ms quota consumed in 50ms, application paused for remaining 50ms.

**Fix**: use `go.uber.org/automaxprocs`:

```go
import _ "go.uber.org/automaxprocs"
```

This automatically sets `GOMAXPROCS` to match the container CPU quota, preventing CFS throttling.

**Track**: [Go issue #33803](https://github.com/golang/go/issues/33803) for native CFS awareness.
