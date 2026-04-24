---
name: go-data-types
description: >
  Guides the agent to avoid common Go mistakes with basic data types, slices, and maps.
  Use when writing or reviewing Go code that involves integer literals, numeric overflow,
  floating-point arithmetic, slice initialization/slicing/appending/copying, map initialization,
  or value comparison. Covers mistakes #17-#29 from "100 Go Mistakes and How to Avoid Them."
---

# Go Data Types: Slices, Maps, and Numeric Pitfalls

## Octal Literals (#17)

- Integer literals starting with `0` are **octal** (base 8). `010 == 8`, not `10`.
- Always use the explicit `0o` prefix for octal numbers to prevent confusion:

```go
// Bad - readers may think this is decimal 644
file, err := os.OpenFile("foo", os.O_RDONLY, 0644)

// Good - explicitly octal
file, err := os.OpenFile("foo", os.O_RDONLY, 0o644)
```

- Other literal prefixes: `0b` (binary), `0x` (hex), `i` suffix (imaginary).
- Use `_` as a digit separator for readability: `1_000_000_000`.

## Integer Overflows (#18)

- Integer overflow and underflow are **silent** at runtime in Go. No panic occurs.
- Compile-time overflow (e.g., `var x int32 = math.MaxInt32 + 1`) is caught, but runtime overflow is not.
- When overflow matters (conversions, large numbers, constrained integer sizes), guard explicitly:

```go
// Increment
func Inc32(counter int32) int32 {
    if counter == math.MaxInt32 {
        panic("int32 overflow")
    }
    return counter + 1
}

// Addition
func AddInt(a, b int) int {
    if a > math.MaxInt-b {
        panic("int overflow")
    }
    return a + b
}

// Multiplication
func MultiplyInt(a, b int) int {
    if a == 0 || b == 0 {
        return 0
    }
    result := a * b
    if a == 1 || b == 1 {
        return result
    }
    if a == math.MinInt || b == math.MinInt {
        panic("integer overflow")
    }
    if result/b != a {
        panic("integer overflow")
    }
    return result
}
```

- Use `math/big` when `int64` is insufficient.

## Floating Points (#19)

- `float32` and `float64` are **approximations** (IEEE-754). They cannot represent all decimal values exactly.
- **Never compare floats with `==`**. Compare within a delta:

```go
// Bad
if f1 == f2 { ... }

// Good
const epsilon = 1e-9
if math.Abs(f1-f2) < epsilon { ... }
```

- Floating-point error accumulates across operations. To reduce it:
  - **Addition/subtraction**: group values of similar magnitude together.
  - **Mixed operations**: perform multiplication and division **before** addition and subtraction.

```go
// Better accuracy: add small values first, then add large value
result := 0.0
for i := 0; i < n; i++ {
    result += 1.0001
}
result += 10_000.0

// Better accuracy: multiply/divide before add/subtract
// Prefer: a*b + a*c  over  a*(b+c) when magnitudes differ
```

- Special values: `+Inf`, `-Inf`, `NaN`. Check with `math.IsInf`, `math.IsNaN`.
- NaN is the only float where `f != f` is true.

## Slice Length vs. Capacity (#20)

- **Length**: number of accessible elements. **Capacity**: size of backing array.
- `make([]int, 3, 6)` creates a slice with length 3, capacity 6.
- Accessing beyond length panics even if capacity allows it; use `append` to grow into capacity.
- When capacity is exhausted, `append` allocates a new backing array (doubles until 1024 elements, then grows ~25%).
- Slicing (`s1[1:3]`) shares the backing array. Mutations via one slice are visible through the other.
- After enough appends cause a new backing array, the slices decouple.

## Inefficient Slice Initialization (#21)

- If the output length is known, **always** preallocate:

```go
// Bad - causes repeated allocations and copies
bars := make([]Bar, 0)
for _, foo := range foos {
    bars = append(bars, fooToBar(foo))
}

// Good (fastest) - given length + direct index
bars := make([]Bar, len(foos))
for i, foo := range foos {
    bars[i] = fooToBar(foo)
}

// Good (slightly slower, sometimes more readable) - given capacity + append
bars := make([]Bar, 0, len(foos))
for _, foo := range foos {
    bars = append(bars, fooToBar(foo))
}
```

- Given-length is ~4% faster than given-capacity due to avoiding `append` overhead.
- Use given-capacity + `append` when index math would be complex (e.g., two appends per iteration).
- If exact length is unknown but an upper bound exists, prefer setting capacity to the upper bound.

## Nil vs. Empty Slices (#22)

- A **nil slice** (`var s []string`): `s == nil` is true, `len(s) == 0`.
- An **empty slice** (`s := []string{}` or `make([]string, 0)`): `s == nil` is false, `len(s) == 0`.
- **Nil slice requires zero allocation.** Prefer `var s []T` when the slice may remain empty.
- `append` works on nil slices. No need to defensively initialize to non-nil.
- **Do not return non-nil empty slices for defensive reasons.** Return nil slices instead.

```go
// Good - returns nil if nothing appended (zero allocation)
func f() []string {
    var s []string
    if foo() { s = append(s, "foo") }
    if bar() { s = append(s, "bar") }
    return s
}
```

- Avoid `[]string{}` without initial elements; it allocates unnecessarily.
- **Beware**: `encoding/json` marshals nil slices as `null` and empty slices as `[]`. `reflect.DeepEqual` distinguishes nil from empty. Know your downstream consumers.

Initialization cheat sheet:

| Form | Nil? | When to use |
|---|---|---|
| `var s []T` | yes | Default; final length unknown, may be empty |
| `[]T(nil)` | yes | Inline nil slice (e.g., `append([]int(nil), 42)`) |
| `make([]T, n)` | no | Known length |
| `make([]T, 0, n)` | no | Known capacity, use with append |
| `[]T{}` | no | Only when providing initial elements |

## Checking if a Slice is Empty (#23)

- **Always check `len(s) == 0`**, never `s == nil`.
- `len` works correctly for both nil and non-nil empty slices.
- Same rule applies to maps: check `len(m) == 0`, not `m == nil`.
- When designing APIs, do not distinguish between nil and empty slices.

## Slice Copy (#24)

- `copy(dst, src)` copies `min(len(dst), len(src))` elements. A zero-length dst copies nothing.

```go
// Bug - dst is zero-length, copies nothing
var dst []int
copy(dst, src)

// Correct
dst := make([]int, len(src))
copy(dst, src)
```

- Argument order: **destination first**, source second.
- Alternative one-liner: `dst := append([]int(nil), src...)`.

## Unexpected Side Effects with Append (#25)

- Appending to a sub-slice can mutate the original slice's backing array if capacity remains:

```go
s1 := []int{1, 2, 3}
s2 := s1[1:2]         // len=1, cap=2, shares backing array
s3 := append(s2, 10)  // overwrites s1[2]! s1 is now [1, 2, 10]
```

- **Fix option 1**: pass a copy of the sub-slice.
- **Fix option 2 (preferred)**: use a **full slice expression** to cap capacity:

```go
// s[:2:2] creates a slice with len=2, cap=2
// append will allocate a new backing array instead of mutating
f(s[:2:2])
```

- When passing sub-slices to functions that may append, always use the full slice expression `s[low:high:max]`.

## Slices and Memory Leaks (#26)

### Capacity leak

- Slicing a large slice (e.g., `msg[:5]` from a 1MB slice) retains the entire backing array.
- The GC cannot reclaim the unused portion. Full slice expressions (`msg[:5:5]`) do **not** help here.
- **Fix**: copy into a new slice:

```go
func getMessageType(msg []byte) []byte {
    msgType := make([]byte, 5)
    copy(msgType, msg)
    return msgType
}
```

### Pointer element leak

- When slicing a slice of pointers (or structs with pointer fields), the GC does not reclaim elements outside the new length but inside the original backing array.
- **Fix option 1**: copy the elements you need into a new slice.
- **Fix option 2**: nil out excluded elements before slicing:

```go
func keepFirstTwo(foos []Foo) []Foo {
    for i := 2; i < len(foos); i++ {
        foos[i].v = nil  // allow GC to collect backing data
    }
    return foos[:2]
}
```

- Choose based on proportion: if keeping few elements, copy; if discarding few, nil them out.

## Inefficient Map Initialization (#27)

- Go maps are backed by hash table buckets (8 elements each). Maps grow by doubling buckets, requiring rehashing all keys.
- If the number of entries is known, **always provide a size hint**:

```go
// Bad - causes repeated growth and rehashing
m := make(map[string]int)

// Good - preallocates buckets for ~1M entries
m := make(map[string]int, 1_000_000)
```

- Providing a size hint is ~60% faster for large maps vs. not providing one.
- The size is a hint, not a hard limit. You can still add more elements.
- Unlike slices, maps take only a single size argument to `make` (no separate capacity).

## Maps and Memory Leaks (#28)

- **Map buckets never shrink.** Deleting all entries does not free bucket memory.
- After adding 1M entries and deleting them all, the map retains its bucket structure.
- This matters for maps that experience high-water-mark spikes (e.g., caches during peak load).
- **Mitigation strategies**:
  1. Periodically re-create the map: build a new map, copy live entries, release the old one.
  2. Use pointer values (`map[K]*V` instead of `map[K]V`) to reduce per-bucket memory. Buckets still exist but each slot stores only a pointer (8 bytes) instead of the full value.
- Values or keys over 128 bytes are automatically stored as pointers by the runtime.

## Comparing Values (#29)

- `==` works on: booleans, numerics, strings, channels, interfaces, pointers, and structs/arrays composed entirely of comparable types.
- `==` does **not** work on slices, maps, or structs containing them. This is a compile error.
- Comparing `any`-typed values containing non-comparable types **panics at runtime**.

```go
var a any = customer{operations: []float64{1.0}}
var b any = customer{operations: []float64{1.0}}
fmt.Println(a == b) // PANIC at runtime
```

- **`reflect.DeepEqual`**: works for all types but is ~100x slower than `==`. Distinguishes nil from empty slices. Best for tests.
- **Custom `equal` method**: ~96x faster than `reflect.DeepEqual`. Preferred for runtime comparison of non-comparable structs.
- **`bytes.Compare`**: optimized for `[]byte` comparison. Check standard library before writing custom comparators.
- In tests, prefer `go-cmp` or `testify` over `reflect.DeepEqual` for better diffs and readability.
