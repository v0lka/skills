---
name: go-standard-library
description: >
  Guides the agent to avoid common Go standard library mistakes when writing or reviewing Go code.
  Covers time.Duration misuse, time.After memory leaks, JSON handling pitfalls (type embedding,
  monotonic clock, map of any), SQL mistakes (sql.Open, connection pooling, prepared statements,
  null values, row iteration errors), closing transient resources (HTTP body, sql.Rows, os.File),
  missing return after HTTP error replies, and using default HTTP client/server without timeouts.
  Use when writing, reviewing, or refactoring code that uses the time, encoding/json, database/sql,
  net/http, or os packages.
---

# Go Standard Library

Rules and patterns for correct use of Go's standard library based on common mistakes #75-#81.

---

## 1. Time Duration (#75)

**Rule:** Never pass a bare integer to functions accepting `time.Duration`. Always use the `time` API constants.

`time.Duration` is nanoseconds as `int64`. Passing `1000` means 1000 nanoseconds (1 microsecond), not 1 second.

```go
// BAD: 1000 nanoseconds, not 1 second
ticker := time.NewTicker(1000)

// GOOD: explicit duration units
ticker := time.NewTicker(time.Second)
ticker := time.NewTicker(1000 * time.Millisecond)
```

This applies to all functions/methods accepting `time.Duration`: `time.NewTicker`, `time.NewTimer`, `time.Sleep`, `time.After`, `context.WithTimeout`, etc.

---

## 2. time.After Memory Leaks (#76)

**Rule:** Never use `time.After` inside a loop or any repeatedly-called function (HTTP handler, Kafka consumer, etc.). Use `time.NewTimer` with `Reset` instead.

Each `time.After` call allocates ~200 bytes that cannot be freed until the timer expires. In a hot loop, this causes unbounded memory growth.

```go
// BAD: leaks memory -- each iteration allocates a timer that lives for 1 hour
func consumer(ch <-chan Event) {
    for {
        select {
        case event := <-ch:
            handle(event)
        case <-time.After(time.Hour):
            log.Println("warning: no messages received")
        }
    }
}

// GOOD: reuse a single timer
func consumer(ch <-chan Event) {
    timerDuration := time.Hour
    timer := time.NewTimer(timerDuration)
    defer timer.Stop()
    for {
        timer.Reset(timerDuration)
        select {
        case event := <-ch:
            handle(event)
        case <-timer.C:
            log.Println("warning: no messages received")
        }
    }
}
```

`time.After` is fine for one-shot use outside loops.

---

## 3. JSON Handling (#77)

### 3.1 Type Embedding Hijacks Marshaling

**Rule:** If an embedded type implements `json.Marshaler` or `json.Unmarshaler`, the parent struct silently inherits that behavior, overriding the default field-by-field marshaling.

`time.Time` implements `json.Marshaler`. Embedding it causes the entire struct to marshal as just the time value, dropping all other fields.

```go
// BAD: marshals as "2021-05-18T21:15:08Z" -- ID is silently lost
type Event struct {
    ID int
    time.Time
}

// GOOD: use a named field
type Event struct {
    ID   int
    Time time.Time
}
```

**When reviewing:** flag any embedded type that implements `json.Marshaler`/`json.Unmarshaler` (e.g., `time.Time`, `encoding.TextMarshaler` implementors). Prefer named fields unless the embedding is intentional and a custom `MarshalJSON` is defined on the parent.

### 3.2 Monotonic Clock Breaks Equality

**Rule:** `time.Now()` includes a monotonic clock reading. JSON marshal/unmarshal strips it. Comparing the original and unmarshaled structs with `==` returns `false`.

```go
t := time.Now()
event1 := Event{Time: t}
b, _ := json.Marshal(event1)
var event2 Event
_ = json.Unmarshal(b, &event2)

event1 == event2 // false -- monotonic component differs
```

**Fixes:**

- Compare time fields with `time.Time.Equal()` (ignores monotonic component).
- Strip monotonic before storing: `t.Truncate(0)` or `t.Round(0)`.
- For tests, use `t.UTC().Truncate(0)` to normalize both timezone and monotonic.

### 3.3 Map of any: Numerics Are float64

**Rule:** When unmarshaling JSON into `map[string]any`, all numeric values become `float64` -- even integers. Incorrect type assertions (e.g., to `int`) cause panics.

```go
var m map[string]any
json.Unmarshal([]byte(`{"id": 32}`), &m)
// m["id"] is float64(32), NOT int

// BAD: panics at runtime
id := m["id"].(int)

// GOOD: assert to float64, then convert
id := int(m["id"].(float64))
```

Prefer unmarshaling into a concrete struct when the schema is known.

---

## 4. SQL Mistakes (#78)

### 4.1 sql.Open Does Not Connect

**Rule:** `sql.Open` may only validate arguments without establishing a connection. Always follow it with `db.Ping()` or `db.PingContext()` to verify the database is reachable.

```go
db, err := sql.Open("mysql", dsn)
if err != nil {
    return err
}
if err := db.PingContext(ctx); err != nil {
    return err
}
```

### 4.2 Connection Pool Configuration

**Rule:** `*sql.DB` is a connection pool, not a single connection. For production, always configure these parameters:

| Method | Default | Guidance |
|---|---|---|
| `SetMaxOpenConns` | Unlimited | **Must set.** Match what the DB can handle. |
| `SetMaxIdleConns` | 2 | Increase for high-concurrency workloads to avoid frequent reconnects. |
| `SetConnMaxIdleTime` | Unlimited | Set to release connections after traffic bursts. |
| `SetConnMaxLifetime` | Unlimited | Set when connecting through a load balancer. |

```go
db.SetMaxOpenConns(25)
db.SetMaxIdleConns(25)
db.SetConnMaxIdleTime(5 * time.Minute)
db.SetConnMaxLifetime(1 * time.Hour)
```

### 4.3 Use Prepared Statements

**Rule:** Use `db.Prepare` / `db.PrepareContext` for repeated queries and any query built from untrusted input (SQL injection defense).

```go
stmt, err := db.PrepareContext(ctx, "SELECT * FROM orders WHERE id = ?")
if err != nil {
    return err
}
defer stmt.Close()

rows, err := stmt.QueryContext(ctx, id)
```

### 4.4 Null Values

**Rule:** Scanning a SQL `NULL` into a non-pointer Go type fails at runtime. Use a pointer or `sql.NullXXX` type for nullable columns.

```go
// Option A: pointer
var department *string
err := rows.Scan(&department, &age) // department is nil if NULL

// Option B: sql.NullString (preferred -- clearer intent)
var department sql.NullString
err := rows.Scan(&department, &age)
if department.Valid {
    fmt.Println(department.String)
}
```

Available null types: `sql.NullString`, `sql.NullBool`, `sql.NullInt32`, `sql.NullInt64`, `sql.NullFloat64`, `sql.NullTime`.

### 4.5 Check rows.Err After Iteration

**Rule:** `rows.Next()` can return `false` either because all rows were consumed OR because an error occurred preparing the next row. Always check `rows.Err()` after the loop.

```go
for rows.Next() {
    if err := rows.Scan(&department, &age); err != nil {
        return err
    }
}
if err := rows.Err(); err != nil {
    return err
}
```

---

## 5. Closing Transient Resources (#79)

**Rule:** Any struct implementing `io.Closer` must be closed. Use `defer` immediately after the creation/error-check.

### 5.1 HTTP Response Body

- Always close `resp.Body` when `err == nil`, even if you don't read it.
- Closing without reading may prevent TCP connection reuse. To preserve keep-alive, drain the body first.

```go
resp, err := client.Get(url)
if err != nil {
    return err
}
defer resp.Body.Close()

// If you don't need the body but want keep-alive:
_, _ = io.Copy(io.Discard, resp.Body)
```

**Note:** On the server side, the request body is closed automatically. No action needed.

### 5.2 sql.Rows

Forgetting to close `sql.Rows` leaks a database connection back to the pool.

```go
rows, err := db.QueryContext(ctx, query)
if err != nil {
    return err
}
defer rows.Close()
```

### 5.3 os.File

Not closing `os.File` delays release until GC. For writable files, the close error may surface a buffered write failure -- propagate it.

```go
// Read-only: log close errors
f, err := os.Open(filename)
if err != nil {
    return err
}
defer func() {
    if err := f.Close(); err != nil {
        log.Printf("failed to close file: %v", err)
    }
}()

// Writable: propagate close errors via named return
func writeToFile(filename string, content []byte) (err error) {
    f, err := os.Create(filename)
    if err != nil {
        return err
    }
    defer func() {
        closeErr := f.Close()
        if err == nil {
            err = closeErr
        }
    }()
    _, err = f.Write(content)
    return
}
```

If durability matters, call `f.Sync()` before close. Then close errors can be safely ignored.

---

## 6. Return After HTTP Error Reply (#80)

**Rule:** `http.Error` does NOT stop handler execution. Always `return` immediately after it.

```go
// BAD: execution continues after error reply
func handler(w http.ResponseWriter, req *http.Request) {
    err := foo(req)
    if err != nil {
        http.Error(w, "foo", http.StatusInternalServerError)
    }
    // This runs even on error -- may panic on nil pointer, or write duplicate response
    result := bar(req)
    w.Write(result)
}

// GOOD: return after error reply
func handler(w http.ResponseWriter, req *http.Request) {
    err := foo(req)
    if err != nil {
        http.Error(w, "foo", http.StatusInternalServerError)
        return
    }
    result := bar(req)
    w.Write(result)
}
```

This applies to any function that writes an HTTP error: `http.Error`, `w.WriteHeader`, `json.NewEncoder(w).Encode`, etc. Missing return causes duplicate writes and a superfluous `WriteHeader` warning.

---

## 7. Default HTTP Client and Server (#81)

### 7.1 HTTP Client

**Rule:** Never use `http.DefaultClient`, `http.Get()`, `http.Post()`, or `&http.Client{}` in production. They have no timeouts -- requests can hang forever.

```go
// GOOD: production HTTP client
client := &http.Client{
    Timeout: 5 * time.Second,
    Transport: &http.Transport{
        DialContext: (&net.Dialer{
            Timeout: time.Second,
        }).DialContext,
        TLSHandshakeTimeout:   time.Second,
        ResponseHeaderTimeout:  time.Second,
        MaxIdleConnsPerHost:    100,
        IdleConnTimeout:        90 * time.Second,
    },
}
```

**Key timeouts:**

| Timeout | Covers |
|---|---|
| `net.Dialer.Timeout` | TCP dial |
| `Transport.TLSHandshakeTimeout` | TLS handshake |
| `Transport.ResponseHeaderTimeout` | Waiting for response headers |
| `Client.Timeout` | Entire request (dial through body read) |

**Connection pooling:** Default `MaxIdleConnsPerHost` is 2. For high-throughput to a single host, increase it to avoid constant reconnection overhead.

### 7.2 HTTP Server

**Rule:** Never use `&http.Server{}`, `http.ListenAndServe()`, or `http.Serve()` without timeouts in production. Clients can exploit missing timeouts to exhaust resources.

```go
// GOOD: production HTTP server
srv := &http.Server{
    Addr:              ":8080",
    ReadHeaderTimeout: 500 * time.Millisecond,
    ReadTimeout:       time.Second,
    IdleTimeout:       time.Second,
    Handler:           http.TimeoutHandler(handler, 5*time.Second, "request timeout"),
}
```

**Key timeouts:**

| Timeout | Covers |
|---|---|
| `ReadHeaderTimeout` | Reading request headers. **Must set** to prevent Slowloris attacks. |
| `ReadTimeout` | Reading entire request (headers + body). |
| `http.TimeoutHandler` | Handler execution time. Returns 503 on timeout and cancels the handler's context. |
| `IdleTimeout` | Keep-alive idle time. Falls back to `ReadTimeout` if unset. |

**Prefer `http.TimeoutHandler`** over the older `WriteTimeout` field: it returns a proper 503 status, cancels the handler context, and has consistent behavior regardless of TLS.

---

## Quick Reference

| Mistake | Rule |
|---|---|
| #75 Time duration | Never pass bare integers; use `time.Second`, `time.Millisecond`, etc. |
| #76 time.After leak | Use `time.NewTimer` + `Reset` in loops/repeated code paths |
| #77a Embedded JSON | Embedded types can hijack marshal/unmarshal; prefer named fields |
| #77b Monotonic clock | Use `Equal()` or `Truncate(0)` for time comparison after JSON round-trip |
| #77c Map of any | All JSON numbers become `float64`; assert correctly or use a struct |
| #78a sql.Open | Follow with `Ping`/`PingContext` to verify connectivity |
| #78b Connection pool | Set `MaxOpenConns`, `MaxIdleConns`, `ConnMaxIdleTime`, `ConnMaxLifetime` |
| #78c Prepared stmts | Use `Prepare` for repeated queries and untrusted input |
| #78d Null values | Use `*T` or `sql.NullXXX` for nullable columns |
| #78e Row iteration | Always check `rows.Err()` after the `rows.Next()` loop |
| #79 Close resources | `defer Close()` for `resp.Body`, `sql.Rows`, `os.File`, and all `io.Closer` |
| #80 Return after error | `http.Error` does not stop execution; always `return` after it |
| #81a HTTP client | Set dial, TLS, header, and overall timeouts; tune `MaxIdleConnsPerHost` |
| #81b HTTP server | Set `ReadHeaderTimeout`; use `http.TimeoutHandler`; set `IdleTimeout` |
