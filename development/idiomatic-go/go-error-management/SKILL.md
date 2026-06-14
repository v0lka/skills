---
name: go-error-management
description: >
  Guides the agent to avoid common Go error management mistakes when writing or reviewing Go code.
  Covers panic usage, error wrapping vs transforming, checking error types and values correctly
  with errors.As/errors.Is, handling errors exactly once, explicitly ignoring errors, and
  handling defer errors. Use when writing, reviewing, or refactoring Go error handling code,
  or when working with sentinel errors, custom error types, wrapped errors, or defer cleanup.
---

# Go Error Management

Rules and patterns for idiomatic Go error handling based on common mistakes #48-#54.

---

## 1. Panicking (#48)

**Rule:** Reserve `panic` for truly unrecoverable conditions only. Never use panic as a substitute for returning errors.

**Acceptable uses of panic:**
- Programmer errors (invariant violations that indicate a bug)
- Failure to initialize a mandatory dependency during startup (e.g., `regexp.MustCompile` for a required regex)

**Never panic for:**
- User input validation
- Network/IO failures
- Any condition the caller could reasonably handle

```go
// GOOD: panic for programmer error (invalid invariant)
func MustCompileSchema(pattern string) *regexp.Regexp {
    re, err := regexp.Compile(pattern)
    if err != nil {
        panic(fmt.Sprintf("invalid regex pattern: %s", err))
    }
    return re
}

// BAD: panicking on a runtime error the caller should handle
func GetUser(id string) User {
    u, err := db.FindUser(id)
    if err != nil {
        panic(err) // DO NOT do this
    }
    return u
}
```

---

## 2. Error Wrapping vs Transforming (#49)

**Rule:** Choose deliberately between wrapping (`%w`), transforming (`%v`), and returning directly based on whether the caller should access the source error.

| Technique | Extra context | Source error available | Creates coupling |
|---|---|---|---|
| `return err` | No | Yes | No |
| `fmt.Errorf("...: %w", err)` | Yes | Yes (unwrappable) | Yes |
| `fmt.Errorf("...: %v", err)` | Yes | No | No |
| Custom error type wrapping | Yes | Yes | Yes |

**Guidelines:**
- **Wrap (`%w`)** when the caller legitimately needs to inspect the source error (e.g., checking for `sql.ErrNoRows`).
- **Transform (`%v`)** when the source error is an implementation detail the caller should not depend on.
- **Return directly** when no additional context is needed and the error is already descriptive.
- Default to `%w` within a package. Use `%v` at API boundaries where you want to hide internals.

```go
// Wrapping: caller can inspect the source error
return fmt.Errorf("failed to get transaction %s: %w", id, err)

// Transforming: hides implementation detail
return fmt.Errorf("failed to get transaction %s: %v", id, err)

// Direct return: error is already descriptive enough
return err
```

---

## 3. Checking Error Types with errors.As (#50)

**Rule:** Never use type assertion or type switch to check error types. Always use `errors.As`, which unwraps the error chain.

A type switch (`switch err.(type)`) only matches the outermost error. If the target error type is wrapped inside another error via `%w`, the match silently fails.

```go
// BAD: breaks if transientError is wrapped
switch err := err.(type) {
case transientError:
    // This won't match a wrapped transientError
}

// GOOD: works regardless of wrapping depth
var te transientError
if errors.As(err, &te) {
    // te is populated with the matched error
    http.Error(w, te.Error(), http.StatusServiceUnavailable)
} else {
    http.Error(w, err.Error(), http.StatusBadRequest)
}
```

**Important:** The second argument to `errors.As` must be a pointer to the target type. Passing a non-pointer compiles but panics at runtime.

---

## 4. Checking Error Values with errors.Is (#51)

**Rule:** Never use `==` to compare errors against sentinel values. Always use `errors.Is`, which traverses the entire wrapped error chain.

```go
// BAD: breaks if sql.ErrNoRows is wrapped
if err == sql.ErrNoRows {
    // ...
}

// GOOD: works through any wrapping depth
if errors.Is(err, sql.ErrNoRows) {
    // ...
}
```

**Design guideline for sentinel errors:**
- Expected errors (caller is meant to check for them) -> sentinel values: `var ErrNotFound = errors.New("not found")`
- Unexpected errors (structural/contextual info needed) -> custom error types: `type ValidationError struct{ ... }`

---

## 5. Handle an Error Exactly Once (#52)

**Rule:** An error must be handled exactly once. Logging an error counts as handling it. Returning an error counts as handling it. Never do both.

```go
// BAD: handles the error twice (logs AND returns)
func GetRoute(srcLat, srcLng, dstLat, dstLng float32) (Route, error) {
    err := validateCoordinates(srcLat, srcLng)
    if err != nil {
        log.Println("failed to validate source coordinates")
        return Route{}, err // logged AND returned
    }
    // ...
}

// GOOD: handles the error once (wraps and returns, no log)
func GetRoute(srcLat, srcLng, dstLat, dstLng float32) (Route, error) {
    err := validateCoordinates(srcLat, srcLng)
    if err != nil {
        return Route{}, fmt.Errorf("failed to validate source coords: %w", err)
    }
    // ...
}
```

**Consequences of double-handling:**
- Duplicate/interleaved log lines in concurrent code make debugging harder.
- Context is split across log and error message, neither is complete.

**Pattern:** Return errors with added context (`%w`); let the top-level caller (HTTP handler, main, etc.) log once.

---

## 6. Explicitly Ignore Errors (#53)

**Rule:** When intentionally ignoring an error, assign it to the blank identifier `_`. Never silently discard by omitting assignment.

```go
// BAD: unclear if the developer forgot to handle the error
notify()

// GOOD: explicit that error is intentionally ignored
_ = notify()

// BETTER: explain WHY the error is ignored
// At-most-once delivery; acceptable to miss some notifications on error.
_ = notify()
```

**Do not** add comments like `// Ignore the error` -- that just restates the code. Instead explain the **rationale** for ignoring.

---

## 7. Handling Defer Errors (#54)

**Rule:** Never silently discard errors from `defer` calls. At minimum, explicitly ignore them. Prefer logging or propagating.

### Option A: Log the defer error

```go
defer func() {
    if err := rows.Close(); err != nil {
        log.Printf("failed to close rows: %v", err)
    }
}()
```

### Option B: Propagate using named return parameters

When both the main body and the defer can fail, prioritize the original error:

```go
func getBalance(db *sql.DB, clientID string) (balance float32, err error) {
    rows, err := db.Query(query, clientID)
    if err != nil {
        return 0, err
    }
    defer func() {
        closeErr := rows.Close()
        if err != nil {
            // Body already failed; log the close error, keep the original.
            if closeErr != nil {
                log.Printf("failed to close rows: %v", closeErr)
            }
            return
        }
        // Body succeeded; surface the close error.
        err = closeErr
    }()

    if rows.Next() {
        if err := rows.Scan(&balance); err != nil {
            return 0, err
        }
        return balance, nil
    }
    // ...
}
```

### Option C: Explicitly ignore (when truly acceptable)

```go
defer func() { _ = rows.Close() }()
```

**Never** write bare `defer rows.Close()` when `Close()` returns an error -- it silently discards the error with no indication of intent.

---

## Quick Reference

| Mistake | Rule |
|---|---|
| #48 Panicking | Only for programmer errors or mandatory-dependency init failures |
| #49 Wrapping | `%w` = caller can unwrap; `%v` = opaque transform; choose intentionally |
| #50 Error type check | Use `errors.As`, never type switch/assertion |
| #51 Error value check | Use `errors.Is`, never `==` |
| #52 Double handling | Either log or return, never both; wrap with `%w` for context |
| #53 Ignoring errors | Assign to `_`; comment the rationale, not the action |
| #54 Defer errors | Log, propagate via named returns, or explicitly ignore -- never bare defer |
