---
name: go-concurrency-practice
description: >
  Enforces practical Go concurrency rules from "100 Go Mistakes" (Ch.9, #61-#74)
  when writing or reviewing concurrent Go code. Use when code involves goroutines,
  channels, select statements, sync primitives (Mutex, WaitGroup, Cond, errgroup),
  or when passing contexts across goroutine boundaries. Catches context propagation
  bugs, goroutine leaks, loop variable captures, channel misuse, data races with
  append/slices/maps, sync type copying, and deadlocks from string formatting.
---

# Go Concurrency Practice Rules

## Context & Goroutine Lifecycle

### #61: Do not propagate a cancel-bound context into a goroutine that must outlive it

When spawning a goroutine from an HTTP handler (or any scoped context) to do
async work (e.g., publish to Kafka, send metrics), **do not pass the request context**
directly. The context cancels when the response is written, racing with the async work.

**Rules:**
- If the goroutine must outlive the parent scope, use `context.Background()` or a
  detached context that preserves values but strips cancellation.
- If values (trace IDs, correlation IDs) must be carried, create a detach wrapper:

```go
// detach strips cancellation/deadline but keeps values.
type detach struct{ ctx context.Context }

func (d detach) Deadline() (time.Time, bool) { return time.Time{}, false }
func (d detach) Done() <-chan struct{}        { return nil }
func (d detach) Err() error                  { return nil }
func (d detach) Value(key any) any           { return d.ctx.Value(key) }
```

```go
// BAD - context cancels when response is written
go func() { publish(r.Context(), response) }()

// GOOD - detach cancellation, keep values
go func() { publish(detach{ctx: r.Context()}, response) }()
```

### #62: Every goroutine must have a known stopping condition

Before writing `go func()`, answer: **when does this goroutine stop?**

**Rules:**
- If a goroutine holds resources (connections, files), the parent must **wait** for
  cleanup, not just signal. Use `defer w.close()` or a `sync.WaitGroup`.
- Signaling (context cancellation) is not enough on its own -- it does not guarantee
  the goroutine had time to release resources.
- Return the goroutine's owner (struct with a `Close` method) so the caller can
  manage its lifetime.

```go
// BAD - no way to wait for cleanup
func newWatcher(ctx context.Context) {
    w := watcher{}
    go w.watch(ctx)
}

// GOOD - caller controls shutdown
func newWatcher() watcher {
    w := watcher{}
    go w.watch()
    return w
}
// in main:
w := newWatcher()
defer w.close()
```

## Goroutines & Loop Variables

### #63: Capture loop variables before launching goroutines

Closure goroutines capture the **variable**, not the **value**. All goroutines share the
same loop variable and will read whatever value it holds at execution time.

**Rules:**
- Create a local copy: `val := i` before the `go func()`.
- Or pass the variable as a function argument: `go func(v int) { ... }(i)`.

> **Note:** Go 1.22+ changed `for` loop variable semantics so each iteration gets a
> new variable. If the module's `go` directive is `>= 1.22`, this is no longer a bug,
> but applying the fix is still safe and communicates intent.

```go
// BAD (before Go 1.22)
for _, i := range s {
    go func() { fmt.Print(i) }() // may print same value repeatedly
}

// GOOD - local copy
for _, i := range s {
    val := i
    go func() { fmt.Print(val) }()
}

// GOOD - function argument
for _, i := range s {
    go func(val int) { fmt.Print(val) }(i)
}
```

## Channel Patterns

### #64: select on multiple channels picks randomly, not by source order

When multiple cases in a `select` can proceed, Go picks one **uniformly at random**.
Writing `case <-messageCh` above `case <-disconnectCh` does **not** create priority.

**Rules:**
- For a single producer: use an unbuffered channel or a single channel carrying
  both message types to enforce ordering.
- For multiple producers needing priority drain: after receiving the low-priority
  signal, use an inner `for/select` with `default` to drain the high-priority channel.

```go
// Priority drain pattern
for {
    select {
    case v := <-messageCh:
        fmt.Println(v)
    case <-disconnectCh:
        // Drain remaining messages before returning
        for {
            select {
            case v := <-messageCh:
                fmt.Println(v)
            default:
                return
            }
        }
    }
}
```

### #65: Use `chan struct{}` for notification channels

If a channel carries no meaningful data (only the event of receiving matters), use
`chan struct{}`, not `chan bool`. An empty struct is zero bytes; `bool` wastes space
and creates ambiguity about what `false` means.

### #66: Use nil channels to disable select cases

Receiving from or sending to a `nil` channel blocks forever. This is useful: after a
channel is closed, set it to `nil` to remove that case from a `select`.

**Key pattern -- merging channels:**

```go
func merge(ch1, ch2 <-chan int) <-chan int {
    ch := make(chan int, 1)
    go func() {
        for ch1 != nil || ch2 != nil {
            select {
            case v, open := <-ch1:
                if !open {
                    ch1 = nil // disable this case
                    break
                }
                ch <- v
            case v, open := <-ch2:
                if !open {
                    ch2 = nil
                    break
                }
                ch <- v
            }
        }
        close(ch)
    }()
    return ch
}
```

**Without nil channels** the closed-channel case fires continuously in a busy loop
(receiving the zero value), wasting CPU.

### #67: Default buffered channel size should be 1

- Use **unbuffered** channels when you need synchronization (sender blocks until
  receiver is ready) or for close-based notifications.
- Use **buffered with size 1** as the default when a buffer is needed.
- Only use larger sizes for: worker pools (tie to goroutine count) or rate limiting
  (tie to the limit). Document the rationale for any magic number.
- Unbuffered channels are easier to reason about; buffered channels can hide
  deadlocks.

## String Formatting Side Effects

### #68: fmt functions can cause data races and deadlocks in concurrent code

**Data race (etcd pattern):**
`fmt.Sprintf("%v", ctx)` traverses all values in a context chain. If any value is a
mutable pointer and another goroutine mutates it concurrently, this is a data race.
Avoid formatting entire contexts; extract only the specific immutable key you need.

**Deadlock (Stringer + mutex pattern):**
If a method holds a mutex lock and formats `%v` on the receiver, and the receiver's
`String()` method also acquires the same lock, you get a deadlock.

```go
// BAD - deadlock: UpdateAge holds Lock, fmt calls String which calls RLock
func (c *Customer) UpdateAge(age int) error {
    c.mutex.Lock()
    defer c.mutex.Unlock()
    if age < 0 {
        return fmt.Errorf("age should be positive for customer %v", c)
        //                                                       ^^ calls String()
    }
    c.age = age
    return nil
}

func (c *Customer) String() string {
    c.mutex.RLock() // DEADLOCK: Lock already held
    defer c.mutex.RUnlock()
    return fmt.Sprintf("id %s, age %d", c.id, c.age)
}
```

**Fixes:**
1. Validate inputs **before** acquiring the lock.
2. In the error message, access fields directly (`c.id`) instead of formatting the
   whole struct.
3. Never call a method that acquires the same lock from within a locked section.

## Data Races with Slices and Maps

### #69: append is not always data-race-free

`append` on a **full** slice (len == cap) allocates a new backing array -- race-free.
`append` on a **non-full** slice mutates the existing backing array -- data race if
concurrent.

**Rules:**
- Never use `append` concurrently on a shared slice unless you are certain the slice
  is full (and you almost never are).
- If multiple goroutines need to append, give each a **copy** of the slice.

```go
// BAD - data race when cap > len
s := make([]int, 0, 1)
go func() { s1 := append(s, 1); _ = s1 }()
go func() { s2 := append(s, 1); _ = s2 }()

// GOOD - each goroutine works on a copy
go func() {
    sCopy := make([]int, len(s), cap(s))
    copy(sCopy, s)
    s1 := append(sCopy, 1)
    _ = s1
}()
```

**Map note:** Any concurrent access to a map with at least one writer is a data race,
regardless of key. Different slice indices are fine; different map keys are not.

### #70: Assigning a slice or map to a local variable does not copy the data

`balances := c.balances` copies the header/pointer, not the underlying data. Both
variables share the same backing storage. Mutating one is visible (and racy) through
the other.

**Rules:**
- If the operation is lightweight, hold the lock for the entire operation.
- If the operation is heavy, deep-copy the data inside the lock, then release and
  operate on the copy.

```go
// BAD - balances shares backing data with c.balances
func (c *Cache) AverageBalance() float64 {
    c.mu.RLock()
    balances := c.balances // NOT a deep copy
    c.mu.RUnlock()
    // iterating here races with writers
}

// GOOD option 1 - hold lock for entire read
func (c *Cache) AverageBalance() float64 {
    c.mu.RLock()
    defer c.mu.RUnlock()
    sum := 0.
    for _, b := range c.balances { sum += b }
    return sum / float64(len(c.balances))
}

// GOOD option 2 - deep copy then release
func (c *Cache) AverageBalance() float64 {
    c.mu.RLock()
    m := make(map[string]float64, len(c.balances))
    for k, v := range c.balances { m[k] = v }
    c.mu.RUnlock()
    // safe to iterate m without lock
}
```

## Sync Primitives

### #71: Call WaitGroup.Add before launching the goroutine

`wg.Add(1)` inside the goroutine is a race: `wg.Wait()` may return before the
goroutine has even called `Add`.

**Rules:**
- Call `wg.Add(n)` in the **parent** goroutine, before `go func()`.
- Call `wg.Done()` inside the goroutine (typically via `defer`).

```go
// BAD
for i := 0; i < 3; i++ {
    go func() {
        wg.Add(1) // race: parent may call Wait() before this runs
        doWork()
        wg.Done()
    }()
}
wg.Wait()

// GOOD
for i := 0; i < 3; i++ {
    wg.Add(1)
    go func() {
        defer wg.Done()
        doWork()
    }()
}
wg.Wait()
```

### #72: Use sync.Cond to broadcast to multiple waiting goroutines

Channels deliver each message to **one** goroutine (round-robin). Only a channel
close is broadcast, and it can only happen once. When you need to **repeatedly**
notify **multiple** goroutines of state changes, use `sync.Cond`.

**Key API:**
- `sync.NewCond(&sync.Mutex{})` -- create with a Locker.
- `cond.Wait()` -- must be called inside `cond.L.Lock()`/`Unlock()`. Internally it
  unlocks, suspends, then re-locks on wake.
- `cond.Broadcast()` -- wakes **all** waiting goroutines.
- `cond.Signal()` -- wakes **one** waiting goroutine.

**Caveat:** If no goroutine is waiting when `Broadcast`/`Signal` is called, the
notification is lost (unlike a buffered channel).

```go
donation := &Donation{cond: sync.NewCond(&sync.Mutex{})}

// Listener
go func() {
    donation.cond.L.Lock()
    for donation.balance < goal {
        donation.cond.Wait()
    }
    fmt.Printf("$%d goal reached\n", donation.balance)
    donation.cond.L.Unlock()
}()

// Updater
donation.cond.L.Lock()
donation.balance++
donation.cond.L.Unlock()
donation.cond.Broadcast()
```

### #73: Use errgroup for parallel goroutines that return errors

Do not hand-roll `sync.WaitGroup` + shared error slice + mutex for parallel work
that can fail. Use `golang.org/x/sync/errgroup`.

**Benefits:**
- `g.Go(func() error)` -- spawns goroutine, collects first non-nil error.
- `g.Wait()` -- blocks until all goroutines finish, returns first error.
- `errgroup.WithContext(ctx)` -- creates a shared context canceled on first error,
  so remaining goroutines can bail out early. The goroutines must be context-aware
  for this to be effective.

```go
g, ctx := errgroup.WithContext(ctx)
for i, item := range items {
    i, item := i, item
    g.Go(func() error {
        result, err := process(ctx, item)
        if err != nil {
            return err
        }
        results[i] = result
        return nil
    })
}
if err := g.Wait(); err != nil {
    return nil, err
}
```

### #74: Never copy a sync type

All sync types must not be copied. This includes:
`sync.Mutex`, `sync.RWMutex`, `sync.WaitGroup`, `sync.Cond`, `sync.Map`,
`sync.Once`, `sync.Pool`.

Copying happens silently when:
1. A method has a **value receiver** on a struct containing a sync field.
2. A function takes a struct containing a sync field **by value**.
3. Assigning a struct containing a sync field to another variable.

**Fixes:**
- Use a **pointer receiver** on any method of a struct with sync fields.
- Or make the sync field a **pointer** (`mu *sync.Mutex`), but then you must
  initialize it explicitly in the constructor.

```go
// BAD - value receiver copies the mutex
func (c Counter) Increment(name string) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.counters[name]++
}

// GOOD - pointer receiver
func (c *Counter) Increment(name string) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.counters[name]++
}
```

Run `go vet` or enable the `copylocks` analyzer -- it detects most sync copy issues
at compile time.
