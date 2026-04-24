---
name: go-functions-methods
description: Enforces best practices for Go functions and methods including receiver type selection, named result parameters, nil receiver pitfalls, io.Reader over filenames, and defer argument evaluation. Use when writing, reviewing, or refactoring Go functions, methods, receivers, or defer statements.
---

# Go Functions & Methods

Rules for writing correct Go functions and methods, covering receiver types, named results, nil receivers, function inputs, and defer evaluation.

## Receiver Type Selection

### Must use pointer receiver when:

- The method mutates the receiver
- The receiver contains a non-copyable field (e.g., `sync.Mutex`, `sync.WaitGroup`)

```go
// Mutating a slice receiver requires a pointer
type slice []int

func (s *slice) add(element int) {
    *s = append(*s, element)
}
```

### Should use pointer receiver when:

- The receiver is a large struct (benchmark if unsure)

### Must use value receiver when:

- The receiver is a map, function, or channel (compiler error otherwise)
- You need to enforce immutability of the receiver

### Should use value receiver when:

- The receiver is a small, naturally value-like struct with no mutable fields (e.g., `time.Time`)
- The receiver is a slice that the method does not mutate
- The receiver is a basic type (`int`, `float64`, `string`)

### Default rule

Choose a value receiver unless there is a specific reason to use a pointer. When in doubt, prefer a pointer receiver.

### Mixing receiver types

Avoid mixing value and pointer receivers on the same type. Exception: when a value-semantic type must implement an interface that requires mutation (e.g., `time.Time` uses value receivers everywhere except `UnmarshalBinary` which requires a pointer to satisfy `encoding.TextUnmarshaler`).

### Indirect mutation through pointer fields

A value receiver can still mutate data reachable through pointer fields. For clarity, use a pointer receiver to signal that the type is mutable:

```go
type customer struct {
    data *data // pointer field
}

// Even though this compiles with a value receiver and mutates
// data.balance, prefer a pointer receiver for clarity:
func (c *customer) add(amount float64) {
    c.data.balance += amount
}
```

## Named Result Parameters

### When to use

- In interface definitions where multiple results of the same type would be ambiguous:

```go
// Bad - which float32 is latitude vs longitude?
type locator interface {
    getCoordinates(address string) (float32, float32, error)
}

// Good - self-documenting
type locator interface {
    getCoordinates(address string) (lat, lng float32, err error)
}
```

- In implementations where naming improves clarity for same-type returns
- When zero-value initialization makes the implementation shorter (e.g., `io.ReadFull` pattern)

### When NOT to use

- When the return type is already unambiguous (e.g., a single `error` return)

```go
// Unnecessary - naming err adds nothing
func StoreCustomer(customer Customer) (err error) { ... }

// Prefer
func StoreCustomer(customer Customer) error { ... }
```

### Naked returns

- Only acceptable in short functions
- Never mix naked returns and explicit returns within the same function
- Named result parameters do not require naked returns -- you can name them for clarity and still use explicit returns

## Unintended Side Effects with Named Result Parameters

Named result parameters are initialized to their zero value. This can silently produce nil errors.

```go
// BUG: if ctx.Err() != nil, this returns err which is still nil!
func (l loc) getCoordinates(ctx context.Context, address string) (
    lat, lng float32, err error) {
    isValid := l.validateAddress(address)
    if !isValid {
        return 0, 0, errors.New("invalid address")
    }
    if ctx.Err() != nil {
        return 0, 0, err // err is still nil here!
    }
    // ...
}
```

**Fix:** always assign to the named variable before returning it:

```go
if err = ctx.Err(); err != nil {
    return 0, 0, err
}
```

**Rule:** When reviewing code with named result parameters, verify that every return path either assigns the named variable or uses an explicit value. Watch for returns that reference a named error variable that was never assigned.

## Returning a Nil Receiver (nil Pointer vs nil Interface)

A nil pointer converted to an interface produces a **non-nil** interface value. The interface wrapper is non-nil even though the wrapped pointer is nil.

```go
type MultiError struct {
    errs []string
}

func (m *MultiError) Error() string {
    return strings.Join(m.errs, ";")
}

// BUG: always returns non-nil error even when valid
func (c Customer) Validate() error {
    var m *MultiError
    if c.Age < 0 {
        m = &MultiError{}
        m.Add(errors.New("age is negative"))
    }
    if c.Name == "" {
        if m == nil {
            m = &MultiError{}
        }
        m.Add(errors.New("name is nil"))
    }
    return m // m is a nil *MultiError, but wrapping it in error makes it non-nil!
}
```

**Fix:** return nil explicitly when there is no error:

```go
func (c Customer) Validate() error {
    var m *MultiError
    // ... same validation logic ...

    if m != nil {
        return m
    }
    return nil // explicit nil interface, not a nil pointer cast to interface
}
```

**Rule:** When a function returns an interface type and builds the concrete value conditionally, never return the concrete pointer variable directly at the end. Check for nil and return a `nil` literal. This applies to any interface, not just `error`.

## Accept io.Reader, Not Filenames

Functions that accept a filename to read from are a code smell. They are hard to test (require creating files) and not reusable across data sources.

```go
// Bad - tied to filesystem, hard to test
func countEmptyLines(filename string) (int, error) {
    file, err := os.Open(filename)
    // ...
}

// Good - works with files, HTTP bodies, strings, etc.
func countEmptyLines(reader io.Reader) (int, error) {
    scanner := bufio.NewScanner(reader)
    // ...
}
```

Testing becomes trivial:

```go
func TestCountEmptyLines(t *testing.T) {
    count, err := countEmptyLines(strings.NewReader("foo\n\nbar\n"))
    // ...
}
```

**Rule:** Accept `io.Reader` (or `io.Writer` for output) instead of filenames. Let the caller handle file opening. Exception: functions whose purpose is specifically to open files (e.g., `os.Open`).

## Defer Argument and Receiver Evaluation

### Arguments are evaluated immediately

```go
// BUG: status is captured as "" at defer time, not at return time
func f() error {
    var status string
    defer notify(status)           // status evaluated NOW (empty string)
    defer incrementCounter(status) // same - empty string

    if err := foo(); err != nil {
        status = StatusErrorFoo
        return err
    }
    status = StatusSuccess
    return nil
}
```

**Fix 1 -- pass a pointer:**

```go
func f() error {
    var status string
    defer notify(&status)          // address of status (constant)
    defer incrementCounter(&status)
    // ... status mutations are visible via pointer
}
```

**Fix 2 -- use a closure (preferred when you cannot change callee signatures):**

```go
func f() error {
    var status string
    defer func() {
        notify(status)           // status is a free variable, evaluated at execution
        incrementCounter(status)
    }()
    // ... status mutations are visible
}
```

**Key rule:** In a defer closure, function arguments are evaluated immediately but free variables (referenced from outer scope) are evaluated when the closure executes.

```go
i := 0
j := 0
defer func(i int) {
    fmt.Println(i, j) // prints "0 1": i is arg (immediate), j is free var (deferred)
}(i)
i++
j++
```

### Value vs pointer receivers with defer

- **Value receiver:** the receiver is copied at `defer` time. Later mutations are not visible.
- **Pointer receiver:** the pointer is copied at `defer` time, but mutations to the pointed-to struct are visible.

```go
s := Struct{id: "foo"}
defer s.print()  // if print() has value receiver: prints "foo"
s.id = "bar"     // mutation NOT visible to deferred call

s := &Struct{id: "foo"}
defer s.print()  // if print() has pointer receiver: prints "bar"
s.id = "bar"     // mutation IS visible to deferred call
```

**Rule:** When using `defer` on a method, consider whether the receiver is a value or pointer. If the receiver is a value and you mutate fields after the defer statement, the deferred call will see the old values. Use a pointer receiver or a closure to capture mutations.
