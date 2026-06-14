---
name: go-control-structures
description: Enforces correct usage of Go control structures including range loops, break statements, and defer in loops. Use when writing or reviewing Go code that iterates over slices, arrays, maps, or channels with range, uses break inside switch/select within loops, or places defer calls inside loops.
---

# Go Control Structures

Rules for avoiding common mistakes with range loops, break statements, and defer in Go.

## Range Loops Copy the Value Variable

The value variable in a range loop is a **copy** of the element. Mutating it does not modify the original collection.

**Wrong** -- mutates only the copy:
```go
for _, a := range accounts {
    a.balance += 1000 // has no effect on the slice
}
```

**Correct** -- access via index:
```go
for i := range accounts {
    accounts[i].balance += 1000
}
```

Rules:
- When you need to **mutate** struct elements in a slice/array, use the index variable (`for i := range`), not the value variable.
- If the slice already holds pointers (`[]*T`), mutation through the value variable works, but be aware of CPU cache implications for large collections.
- Read-only iteration with the value variable is fine.

## Range Expression Is Evaluated Once

The expression passed to `range` is copied once before the loop starts. The loop iterates over this snapshot.

### Slices

Appending to a slice during `range` does not extend the iteration -- the loop uses the original length:

```go
s := []int{0, 1, 2}
for range s {
    s = append(s, 10) // loop still runs exactly 3 times
}
```

A classic `for i := 0; i < len(s); i++` re-evaluates `len(s)` each iteration and **would** loop forever with the same append logic.

### Channels

Reassigning the channel variable inside the loop body has no effect -- `range` iterates over the channel captured at the start:

```go
ch := ch1
for v := range ch {
    ch = ch2 // has no effect; range still reads from ch1
}
```

### Arrays

`range` copies the **entire array** (not just a slice header). Modifications to the original array are not visible through the value variable:

```go
a := [3]int{0, 1, 2}
for i, v := range a {
    a[2] = 10
    if i == 2 {
        fmt.Println(v) // prints 2, not 10
    }
}
```

To see mutations, either:
- Access the element via index: `a[i]`
- Range over a pointer: `for i, v := range &a { ... }`

Ranging over `&a` avoids the full array copy -- prefer this for large arrays.

## Pointer to Range Variable Trap

The range value variable has a **single address** across all iterations. Storing `&v` always stores the same pointer, which ends up pointing to the **last** element.

**Wrong** -- all map entries point to the last customer:
```go
for _, customer := range customers {
    s.m[customer.ID] = &customer // same address every iteration
}
```

**Fix 1** -- local copy:
```go
for _, customer := range customers {
    current := customer
    s.m[current.ID] = &current
}
```

**Fix 2** -- pointer via index:
```go
for i := range customers {
    customer := &customers[i]
    s.m[customer.ID] = customer
}
```

Rules:
- **Never** store `&rangeValueVar` across iterations. The agent must flag this pattern in reviews.
- Apply the same caution with slices and maps alike.

## Map Iteration Assumptions

### No ordering guarantees

Maps in Go provide:
- No sorting by key
- No preservation of insertion order
- No deterministic iteration order (order varies between runs)

Never write code that depends on map iteration order. If ordered traversal is needed, collect keys into a slice, sort it, and iterate over the sorted slice.

### Inserting during iteration is non-deterministic

A new map entry added during iteration **may or may not** be visited in that same iteration. The behavior varies per entry and per run.

**Wrong** -- unpredictable results:
```go
for k, v := range m {
    if v {
        m[10+k] = true // may or may not appear in this iteration
    }
}
```

**Correct** -- read from original, write to a copy:
```go
m2 := copyMap(m)
for k, v := range m {
    m2[k] = v
    if v {
        m2[10+k] = true
    }
}
```

Rules:
- Deleting map entries during iteration is safe (deleted keys will not appear later).
- Inserting entries during iteration produces non-deterministic results. Separate the read map from the write map when adding entries.

## Break Terminates the Innermost for/switch/select

`break` inside a `switch` or `select` that is inside a `for` loop breaks the **switch/select**, not the loop.

**Wrong** -- break exits switch, loop continues:
```go
for i := 0; i < 5; i++ {
    switch i {
    case 2:
        break // breaks the switch, NOT the for loop
    }
}
```

**Correct** -- use a label:
```go
loop:
    for i := 0; i < 5; i++ {
        switch i {
        case 2:
            break loop // breaks the for loop
        }
    }
```

Same pattern applies to `select` inside a loop:

```go
loop:
    for {
        select {
        case <-ch:
            // handle
        case <-ctx.Done():
            break loop // breaks the for loop, not select
        }
    }
```

Rules:
- Whenever `break` appears inside a `switch` or `select` nested in a loop, verify that the intent is to break the inner statement. If the intent is to exit the loop, require a labeled break.
- `continue` with a label can similarly target an outer loop.
- Labeled breaks are idiomatic Go (used in the standard library, e.g., `net/http`).

## Defer Inside a Loop

`defer` executes when the **surrounding function** returns, not at the end of each loop iteration. Placing `defer` directly in a loop body defers all calls until the function exits, leaking resources for the loop's lifetime.

**Wrong** -- file descriptors stay open until `readFiles` returns:
```go
func readFiles(ch <-chan string) error {
    for path := range ch {
        file, err := os.Open(path)
        if err != nil {
            return err
        }
        defer file.Close() // not called until readFiles returns
        // ...
    }
    return nil
}
```

**Correct** -- extract the body into a function so `defer` fires each iteration:
```go
func readFiles(ch <-chan string) error {
    for path := range ch {
        if err := readFile(path); err != nil {
            return err
        }
    }
    return nil
}

func readFile(path string) error {
    file, err := os.Open(path)
    if err != nil {
        return err
    }
    defer file.Close()
    // ...
    return nil
}
```

An anonymous closure also works:

```go
for path := range ch {
    if err := func() error {
        f, err := os.Open(path)
        if err != nil {
            return err
        }
        defer f.Close()
        // ...
        return nil
    }(); err != nil {
        return err
    }
}
```

Rules:
- Flag any `defer` that appears directly inside a `for`/`range` loop body. Wrap the loop body in a helper function or closure so `defer` fires per iteration.
- This applies to any resource cleanup (file handles, locks, DB connections, HTTP response bodies).
