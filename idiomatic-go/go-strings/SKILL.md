---
name: go-strings
description: >
  Guides the agent to write correct and efficient Go string code. Use when
  writing or reviewing Go code that iterates over strings, concatenates strings,
  trims strings, converts between string and []byte, or extracts substrings.
  Covers rune semantics, string iteration pitfalls, trim vs. suffix/prefix
  functions, Builder-based concatenation, avoiding useless string/byte
  conversions, and preventing memory leaks from substrings.
---

# Go Strings — Rules and Patterns

## 1. Runes, bytes, and `len`

- A Go `string` is an immutable sequence of **bytes**, not runes.
- `len(s)` returns the **byte count**, not the character/rune count.
- A `rune` is an alias for `int32` and represents a single Unicode code point.
- Under UTF-8 a code point may occupy 1-4 bytes.
- To count runes, use `utf8.RuneCountInString(s)`.

```go
s := "cafe\u0301" // "cafe" + combining accent = 5 runes, but check byte length
fmt.Println(len(s))                    // byte count (likely 6)
fmt.Println(utf8.RuneCountInString(s)) // rune count (5)
```

## 2. String iteration

### Prefer the range value variable for rune access

When ranging over a string, the index `i` is the **byte offset** of the rune, and the value `r` is the **rune itself**. Accessing `s[i]` gives a single byte, not the rune.

**Wrong:**

```go
for i := range s {
    fmt.Printf("%c", s[i]) // prints individual bytes, corrupts multi-byte runes
}
```

**Correct — iterate over runes:**

```go
for i, r := range s {
    fmt.Printf("position %d: %c\n", i, r) // i = byte offset, r = full rune
}
```

### Accessing the i-th rune

If you need the rune at a logical index (not byte offset), convert to `[]rune` first:

```go
r := []rune(s)[4]
```

This allocates a new slice (O(n)), so avoid it in hot loops. If the string is known to
be pure ASCII, `rune(s[i])` is safe and allocation-free.

## 3. Trim functions — `TrimRight`/`TrimLeft` vs. `TrimSuffix`/`TrimPrefix`

These are commonly confused. The semantics are fundamentally different:

| Function | Behaviour |
|---|---|
| `strings.TrimRight(s, cutset)` | Removes **all trailing runes** that appear anywhere in `cutset`, one by one, until a rune not in the set is found. |
| `strings.TrimSuffix(s, suffix)` | Removes the exact trailing `suffix` substring **once**. |
| `strings.TrimLeft(s, cutset)` | Same as TrimRight but from the left. |
| `strings.TrimPrefix(s, prefix)` | Same as TrimSuffix but from the left. |
| `strings.Trim(s, cutset)` | Applies both `TrimLeft` and `TrimRight`. |

```go
strings.TrimRight("123oxo", "xo")   // "123"   (strips o, x, o individually)
strings.TrimSuffix("123oxo", "xo")  // "123o"  (strips the suffix "xo" once)
```

**Rule:** When you want to remove a known fixed string from the start/end, use
`TrimPrefix` / `TrimSuffix`. When you want to strip a *set of characters*, use
`TrimLeft` / `TrimRight` / `Trim`.

## 4. String concatenation

### Avoid `+=` in loops

Strings are immutable. Every `+=` allocates a new string and copies all previous
bytes. This is O(n^2) for n concatenations.

**Wrong:**

```go
func concat(values []string) string {
    s := ""
    for _, v := range values {
        s += v // new allocation every iteration
    }
    return s
}
```

### Use `strings.Builder` in loops

```go
func concat(values []string) string {
    var sb strings.Builder
    for _, v := range values {
        sb.WriteString(v)
    }
    return sb.String()
}
```

### Pre-grow the builder when total size is known or estimable

Computing the total byte length first and calling `Grow` avoids internal slice
re-allocations. Benchmarks show ~78% speedup over a non-pre-allocated Builder.

```go
func concat(values []string) string {
    total := 0
    for _, v := range values {
        total += len(v)
    }
    var sb strings.Builder
    sb.Grow(total)
    for _, v := range values {
        sb.WriteString(v)
    }
    return sb.String()
}
```

### When `+=` is fine

For a small, fixed number of concatenations (roughly <= 5) or one-off formatting,
`+=`, `fmt.Sprintf`, or `+` are acceptable and more readable.

### Safety note

`strings.Builder` is **not** safe for concurrent use.

## 5. Avoid useless `string` <-> `[]byte` conversions

Each conversion between `string` and `[]byte` allocates and copies because strings
are immutable.

**Rule:** If input arrives as `[]byte` (from `io.Reader`, `io.ReadAll`, etc.) and the
result is also `[]byte`, keep the entire pipeline in `[]byte`. The `bytes` package
mirrors almost every function in `strings`:

| `strings` function | `bytes` equivalent |
|---|---|
| `strings.TrimSpace` | `bytes.TrimSpace` |
| `strings.Split` | `bytes.Split` |
| `strings.Contains` | `bytes.Contains` |
| `strings.Index` | `bytes.Index` |
| `strings.Count` | `bytes.Count` |

**Wrong — double conversion:**

```go
func getBytes(reader io.Reader) ([]byte, error) {
    b, err := io.ReadAll(reader)
    if err != nil {
        return nil, err
    }
    return []byte(strings.TrimSpace(string(b))), nil // 2 extra allocs
}
```

**Correct — stay in `[]byte`:**

```go
func getBytes(reader io.Reader) ([]byte, error) {
    b, err := io.ReadAll(reader)
    if err != nil {
        return nil, err
    }
    return bytes.TrimSpace(b), nil // zero extra allocs
}
```

**Guideline:** Before reaching for the `strings` package, check whether the whole
workflow can use `bytes` instead.

## 6. Substrings and memory leaks

Substring expressions like `s[a:b]` produce a string that **shares the same backing
array** as the original. If the original string is large (e.g., a log line of thousands
of bytes) and you store only a small substring, the entire original backing array
stays in memory and cannot be garbage-collected.

**Leaky:**

```go
uuid := log[:36]  // uuid's backing array still holds the full log string
s.store(uuid)
```

### Fix: copy the substring

**Go >= 1.18 — use `strings.Clone`:**

```go
uuid := strings.Clone(log[:36]) // fresh 36-byte allocation
```

**Pre-1.18 — manual deep copy:**

```go
uuid := string([]byte(log[:36])) // forces a new backing array
```

Note: some linters flag `string([]byte(...))` as a "redundant conversion" — this
warning is incorrect in this context because the round-trip deliberately breaks
backing-array sharing.

### Substring indexing caveat

`s[a:b]` operates on **byte** indices, not rune indices. For multi-byte runes,
convert to `[]rune` first:

```go
s := "Hêllo, World!"
sub := string([]rune(s)[:5]) // "Hêllo" — rune-safe
```

## Quick-reference checklist

- [ ] `len(s)` used only when byte count is intended; `utf8.RuneCountInString` for rune count.
- [ ] String range loops use the value variable (`r`), not `s[i]`, for rune access.
- [ ] `TrimRight`/`TrimLeft` not confused with `TrimSuffix`/`TrimPrefix`.
- [ ] No `+=` concatenation inside loops; `strings.Builder` with `Grow` preferred.
- [ ] No unnecessary `string` <-> `[]byte` round-trips; `bytes` package used when possible.
- [ ] Substrings of large strings copied via `strings.Clone` (or `string([]byte(...))`) before long-term storage.
