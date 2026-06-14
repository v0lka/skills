---
name: go-code-organization
description: >
  Guides the agent to write well-organized Go code and projects. Use when
  writing or reviewing Go code involving variable scoping, nested control flow,
  init functions, getters/setters, interfaces, generics, type embedding,
  functional options, package structure, utility packages, package naming,
  code documentation, or linter configuration. Covers the 16 most common
  code and project organization mistakes in Go.
---

# Go Code and Project Organization — Rules and Patterns

## 1. Variable shadowing

A variable declared with `:=` in an inner block shadows the outer variable of the same name. The outer variable remains unchanged, which is almost always a bug.

**Wrong:**

```go
var client *http.Client
if tracing {
    client, err := createClientWithTracing() // shadows outer client
    if err != nil {
        return err
    }
    log.Println(client)
} else {
    client, err := createDefaultClient() // shadows outer client
    if err != nil {
        return err
    }
    log.Println(client)
}
// client is still nil here
```

**Fix — pre-declare `err`, use `=` instead of `:=`:**

```go
var client *http.Client
var err error
if tracing {
    client, err = createClientWithTracing()
} else {
    client, err = createDefaultClient()
}
if err != nil {
    return err
}
```

Alternative: assign `:=` to a temporary variable (`c`), then `client = c` after the error check.

**Detection:** Run `go vet -vettool=$(which shadow)` (install with `golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow`).

## 2. Unnecessary nesting

Keep the happy path left-aligned. Reduce nesting by returning early on errors and flipping conditions.

**Rules:**
- When an `if` block returns, omit the `else`.
- If the non-happy path is in the `else`, flip the condition.
- Aim for a maximum of two indent levels inside a function body.

**Wrong:**

```go
if s != "" {
    // ... long happy path
} else {
    return errors.New("empty string")
}
```

**Correct:**

```go
if s == "" {
    return errors.New("empty string")
}
// ... happy path at top level
```

Apply this recursively: replace every `if ... { return } else { ... }` chain with guard clauses that return early, keeping the happy path at the lowest indent level.

## 3. init functions

**Avoid `init` when:**
- The initialization can fail — `init` cannot return errors, so the only signal is `log.Fatal`/`panic`, removing the caller's ability to retry or fall back.
- It sets global mutable state — makes testing harder and any function in the package can alter the global.
- The side effect is not needed by every test in the file.

**Acceptable uses of `init`:**
- Registering static, infallible configuration (e.g., `http.HandleFunc` with non-nil handlers).
- Side-effect imports (`_ "image/png"`) for codec registration.

**Wrong — DB connection in init:**

```go
var db *sql.DB

func init() {
    d, err := sql.Open("mysql", os.Getenv("DSN"))
    if err != nil {
        log.Panic(err) // caller can't handle this
    }
    db = d
}
```

**Correct — explicit constructor:**

```go
func NewDB(dsn string) (*sql.DB, error) {
    db, err := sql.Open("mysql", dsn)
    if err != nil {
        return nil, err
    }
    if err = db.Ping(); err != nil {
        return nil, err
    }
    return db, nil
}
```

## 4. Getters and setters

Go does not require getters and setters. Do not add them unless they provide value (validation, computed values, mutex wrapping, debugging interception, or forward compatibility).

**Naming convention when used:**
- Getter: `Balance()` (not `GetBalance()`)
- Setter: `SetBalance(v int)`

```go
currentBalance := customer.Balance()
if currentBalance < 0 {
    customer.SetBalance(0)
}
```

The standard library exposes struct fields directly when appropriate (e.g., `time.Timer.C`). Follow the same pragmatism.

## 5. Interface pollution

**Core principle:** Abstractions should be discovered, not created. Do not define an interface until you have a concrete need.

**Valid reasons to create an interface:**
1. **Common behavior** — multiple types share the same method set (e.g., `sort.Interface`).
2. **Decoupling** — swap implementations for testing or Liskov substitution.
3. **Restricting behavior** — expose only a subset of a type's methods (e.g., read-only config getter from a read-write config struct).

**Do not** create interfaces preemptively "in case we need them later." If it is unclear how an interface improves the code, remove it.

**Keep interfaces small.** "The bigger the interface, the weaker the abstraction." (Rob Pike)

## 6. Interface on the consumer side

Interfaces should live in the package that **uses** them, not in the package that **implements** them.

- The producer exports the concrete struct.
- Each consumer defines only the interface it needs (possibly a single-method interface), keeping it unexported.

**Wrong — producer-side interface:**

```go
// package store
type CustomerStorage interface {  // forces all consumers into this abstraction
    StoreCustomer(Customer) error
    GetCustomer(id string) (Customer, error)
    // ... 4 more methods
}
```

**Correct — consumer-side interface:**

```go
// package client
type customersGetter interface {          // unexported, minimal
    GetAllCustomers() ([]store.Customer, error)
}
```

**Exception:** An interface on the producer side is acceptable when you **know** (not foresee) it will be used by many consumers (e.g., `encoding.BinaryMarshaler`). Keep it as small as possible.

## 7. Returning interfaces

Functions should return concrete types, not interfaces. Returning an interface:
- Creates a dependency from the implementation package to the client package.
- Forces every consumer into the same abstraction level.

**Guideline (Postel's law applied to Go):**
- Accept interfaces.
- Return structs.

**Exceptions:** The `error` interface (ubiquitous), and up-front abstractions proven to be universally useful (e.g., `io.LimitReader` returns `io.Reader`).

## 8. `any` says nothing

`any` (`interface{}`) discards all type information. Avoid it unless you genuinely need to accept every possible type.

**Wrong:**

```go
func (s *Store) Get(id string) (any, error) { ... }
func (s *Store) Set(id string, v any) error { ... }
```

**Correct — explicit per-type methods:**

```go
func (s *Store) GetContract(id string) (Contract, error) { ... }
func (s *Store) SetContract(id string, c Contract) error  { ... }
func (s *Store) GetCustomer(id string) (Customer, error)  { ... }
func (s *Store) SetCustomer(id string, c Customer) error  { ... }
```

**Legitimate uses of `any`:** `json.Marshal(v any)`, `fmt.Println(a ...any)`, `db.QueryContext(ctx, query, args ...any)` — where any possible type is truly expected.

## 9. Generics

### When to use

- **Data structures** — binary trees, linked lists, heaps parameterized by element type.
- **Functions on slices/maps/channels of any type** — e.g., `merge[T any](ch1, ch2 <-chan T) <-chan T`.
- **Factoring out behaviors** — e.g., a generic `SliceFn[T]` that implements `sort.Interface`.

### When NOT to use

- **Calling a method of the type argument** — if the body calls `w.Write(b)`, just accept `io.Writer` directly.
- **When it makes code harder to read** — generics are never mandatory. If the generic version is not clearly simpler, keep the concrete version.

**Rule of thumb:** Do not use type parameters preemptively. Wait until you are about to write boilerplate code to consider generics.

### Constraints

- Use `comparable` for map keys or equality checks.
- Use `~int | ~string` (union with `~`) to allow custom types whose underlying type matches.
- Type parameters work on functions and type receivers, **not** on individual methods:

```go
// Compile error:
func (Foo) bar[T any](t T) {} // methods cannot have type parameters

// OK — use a type-parameterized receiver:
type Foo[T any] struct{ val T }
func (f Foo[T]) Bar() T { return f.val }
```

## 10. Type embedding

Embedding promotes all fields and methods of the inner type. Use it only when promotion is desirable.

**Do NOT embed when:**
- It only saves typing (`Foo.Baz()` vs. `Foo.Bar.Baz()`) with no semantic benefit.
- It promotes fields or methods that should be private (e.g., `sync.Mutex` — clients should not call `Lock`/`Unlock`).

**Wrong — mutex embedded:**

```go
type InMem struct {
    sync.Mutex           // Lock/Unlock are now public
    m map[string]int
}
// m := inmem.New(); m.Lock() — exposed to external callers
```

**Correct — mutex as a named field:**

```go
type InMem struct {
    mu sync.Mutex        // unexported, invisible to clients
    m  map[string]int
}
```

**Good use of embedding — forwarding methods intentionally:**

```go
type Logger struct {
    io.WriteCloser       // promotes Write and Close deliberately
}
```

**Remember:** Embedding is composition, not inheritance. The embedded type remains the method receiver.

## 11. Functional options pattern

Use this pattern when a constructor has optional configuration. It is the idiomatic Go approach and avoids the downsides of config structs (zero-value ambiguity) and builder patterns (empty struct boilerplate).

```go
type options struct {
    port    *int
    timeout time.Duration
}

type Option func(*options) error

func WithPort(port int) Option {
    return func(o *options) error {
        if port < 0 {
            return errors.New("port should be positive")
        }
        o.port = &port
        return nil
    }
}

func WithTimeout(t time.Duration) Option {
    return func(o *options) error {
        o.timeout = t
        return nil
    }
}

func NewServer(addr string, opts ...Option) (*http.Server, error) {
    var o options
    for _, opt := range opts {
        if err := opt(&o); err != nil {
            return nil, err
        }
    }
    // use o.port, o.timeout with defaults ...
}
```

**Caller usage:**

```go
srv, err := httplib.NewServer("localhost",
    httplib.WithPort(8080),
    httplib.WithTimeout(time.Second),
)
// Default config — no extra args needed:
srv, err := httplib.NewServer("localhost")
```

**Conventions:**
- Option functions start with `With` prefix.
- The options struct is unexported.
- Validation happens inside each `With*` function, not deferred to `Build`.

## 12. Project structure

There is no official Go project structure standard. When choosing a layout:
- `/cmd` — main entry points (`/cmd/foo/main.go`).
- `/internal` — private packages that cannot be imported externally.
- `/pkg` — public library code (optional; some teams skip this).
- `/test` — integration and public API tests.
- No `/src` directory.

**Package organization rules:**
- Avoid premature packaging. Start simple, split when boundaries become clear.
- Avoid nano packages (1-2 files with no cohesion) and monolith packages.
- Name packages after what they **provide**, not what they **contain**.
- Package names: short, single lowercase word, concise.
- Minimize exports. When unsure, keep it unexported; export later if needed.
- Organize by context (domain) or by layer (hexagonal), but be **consistent**.

## 13. No utility packages

Do not create packages named `utils`, `common`, `shared`, or `base`. These names carry no meaning about what the package provides.

**Wrong:**

```go
package util

func NewStringSet(...string) map[string]struct{} { ... }
func SortStringSet(map[string]struct{}) []string { ... }
```

```go
set := util.NewStringSet("c", "a", "b")
fmt.Println(util.SortStringSet(set))
```

**Correct — name after what it provides:**

```go
package stringset

type Set map[string]struct{}
func New(...string) Set { ... }
func (s Set) Sort() []string { ... }
```

```go
set := stringset.New("c", "a", "b")
fmt.Println(set.Sort())
```

If common types are shared between a client and server package, consider merging them into one package rather than creating a `common` package.

## 14. Package name collisions

Do not use a variable name that shadows an imported package name. It makes the package inaccessible within the variable's scope and confuses readers.

**Wrong:**

```go
redis := redis.NewClient()  // redis package is now shadowed
v, err := redis.Get("foo")  // is this the package or the variable?
```

**Fix A — different variable name:**

```go
redisClient := redis.NewClient()
```

**Fix B — import alias:**

```go
import redisapi "mylib/redis"

redis := redisapi.NewClient()
```

Also avoid shadowing built-in function names (`copy`, `len`, `cap`, `new`, `make`, `close`, `delete`, `append`, etc.).

## 15. Code documentation

- Every **exported** element (type, function, method, constant, variable) must have a doc comment.
- Comments start with the element name: `// Customer is a customer representation.`
- Each comment is a complete sentence ending with punctuation.
- Document **what** a function does and **why**, not **how**.
- Package comments: `// Package math provides basic constants and mathematical functions.`
- Place package comments in the relevant file or a dedicated `doc.go`.
- Deprecate with `// Deprecated: Use X instead.`
- A blank line between a copyright header and the package comment keeps the copyright out of godoc.

```go
// DefaultPermission is the default permission used by the store engine.
const DefaultPermission = 0o644 // Need read and write accesses.
```

## 16. Linters

Always use linters. At minimum:
- `go vet` — standard Go analyzer.
- `shadow` — detects variable shadowing.
- `errcheck` — catches unchecked errors.
- `gocyclo` — flags high cyclomatic complexity.
- `goconst` — finds repeated string constants.

Formatters: `gofmt`, `goimports`.

**Use `golangci-lint`** as a single entry point — it wraps many linters, runs them in parallel, and is configurable via `.golangci.yml`. Automate linting in CI or Git pre-commit hooks.

## Quick-reference checklist

- [ ] No unintended variable shadowing (`:=` in inner blocks re-checked).
- [ ] Happy path left-aligned; no unnecessary `else` after `return`.
- [ ] `init` only used for infallible static setup; fallible init done in explicit constructors.
- [ ] Getters named `Field()`, not `GetField()`; only present when they add value.
- [ ] Interfaces discovered from need, not created speculatively.
- [ ] Interfaces defined on the consumer side, not the producer side.
- [ ] Functions return concrete types, not interfaces (except `error` and proven up-front abstractions).
- [ ] `any` only used when truly any type is valid; signatures are explicit otherwise.
- [ ] Generics used for data structures and collection utilities, not when a plain interface suffices.
- [ ] Embedded types only when promotion of all fields/methods is intended; `sync.Mutex` never embedded.
- [ ] Functional options pattern used for optional constructor config.
- [ ] No `utils`/`common`/`base` packages; packages named after what they provide.
- [ ] No variable names colliding with package names or built-in functions.
- [ ] All exported elements have doc comments starting with the element name.
- [ ] `golangci-lint` (or equivalent) integrated in CI.
