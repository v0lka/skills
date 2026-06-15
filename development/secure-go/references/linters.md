# Security Linter Configuration

Reference for the Linters section of the secure-go skill.

## Recommended `.golangci.yml`

```yaml
linters:
  enable:
    # Security
    - gosec           # vulnerability patterns (SQL injection, hardcoded secrets, weak crypto)
    - bodyclose       # unclosed resp.Body = connection leak
    - noctx           # HTTP requests without context = no timeout, no cancellation
    - rowserrcheck    # unchecked rows.Err() after iteration
    - sqlclosecheck   # unclosed sql.Rows, sql.Stmt
    - contextcheck    # using non-inherited context in call chain
    - makezero        # make([]T, n) with non-zero length + append = common bug
    - nilnil          # return nil, nil — caller can't distinguish success from error

    # Code correctness
    - govet           # standard vet (printf, structtag, unusedresult)
    - staticcheck     # most powerful static analyzer for Go
    - errcheck        # unchecked errors
    - ineffassign     # assignments that are never used
    - unused          # unused code
    - gocritic        # 100+ checks for bugs, performance, and style
    - errorlint       # errors in working with wrapped errors (errors.Is/As)
    - exhaustive      # incomplete switch on enum types

    # Style that affects security
    - revive          # golint replacement with configurable rules
    - unconvert       # redundant type conversions (noise that distracts review)
    - sloglint        # consistent log/slog usage (relevant to section 10)

linters-settings:
  gosec:
    excludes:
      - G104    # unchecked error — duplicates errcheck, which is more flexible
    config:
      G101:
        # Entropy threshold for hardcoded secret detection.
        # Default value depends on gosec version — check actual docs:
        # https://github.com/securego/gosec#available-rules.
        # Empirically, 100.0 gives minimum false positives and catches
        # only obvious cases like "password = qwerty123".
        entropy_threshold: "100.0"
      G301:
        mode: "0750"                # max directory permissions
      G302:
        mode: "0640"                # max file permissions
      G306:
        mode: "0640"

  gocritic:
    enabled-checks:
      - appendAssign       # append without assigning result
      - badCall            # incorrect arguments to fmt/log
      - filepathJoin       # filepath.Join with unsafe user input
      - sloppyReassign     # reassigning err in a block, losing original error
      - weakCond           # conditions that are always true/false
      - unnecessaryBlock   # unnecessary blocks complicating reading
      - octalLiteral       # 0777 without explicit 0o-prefix (Go 1.13+)

  staticcheck:
    checks:
      - all
      - "-SA1019"   # deprecated — noisy on transitive deps, better checked separately

  errcheck:
    check-type-assertions: true     # unchecked type assertions = runtime panic
    check-blank: false              # _ = fn() — intentional choice, don't complain

  exhaustive:
    default-signifies-exhaustive: true  # default in switch counts as covering all cases

  sloglint:
    # kv-only forbids positional pairs and Sprintf; alternative — attr-only,
    # which requires slog.Attr style (slog.Int, slog.String). Choose for your code.
    kv-only: true   # forbid slog.Info(fmt.Sprintf(...)) — logs must be structured

  noctx:
    # No settings — just catches http.Get() / http.Post() without context

issues:
  exclude-rules:
    - path: _test\.go
      linters:
        - gosec         # test hardcoded values aren't secrets
        - errcheck      # assert covers errors in tests
        - bodyclose     # httptest doesn't require closing

  max-issues-per-linter: 0
  max-same-issues: 0
```

## What each security linter catches

| Linter | Catches |
|--------|---------|
| **gosec** | SQL injection via `fmt.Sprintf` (G201/G202), `text/template` instead of `html/template` (G203), OS command injection (G204), hardcoded secrets (G101), weak crypto (G401), unsafe TLS config (G402), `math/rand` instead of `crypto/rand` (G404), path traversal through user input (G304/G305), file permission issues (G301/G302/G306), HTTP requests with user-supplied URL (G107) |
| **bodyclose** | `resp, _ := http.Get(url)` without `defer resp.Body.Close()` — TCP connection leaks. Under load, the service hits the file descriptor limit and stops responding |
| **noctx** | `http.Get(url)` instead of `http.NewRequestWithContext(ctx, ...)` — no timeout, no cancellation. In server code, this leads to goroutine leaks |
| **sqlclosecheck** + **rowserrcheck** | Unclosed `sql.Rows` (pool connection leak) + unchecked `rows.Err()` after `rows.Next()` loop (silent data loss on error) |
| **contextcheck** | Using a non-inherited context deeper in the call chain (e.g., creating `context.Background()` on the spot). Breaks the entire cancellation and timeout chain |
| **exhaustive** | Incomplete switch on enum types — silent fallthrough to default when new values are added |
| **makezero** | `make([]T, n)` with non-zero length + `append` — a common bug: `[0,0,0,0,0,x]` instead of `[x]` |

### gosec rule reference

- **G1xx** (general): hardcoded secrets (G101), bind to 0.0.0.0 (G102), unsafe usage (G103), HTTP requests with user-supplied URL (G107)
- **G2xx** (injection): SQL construction via fmt.Sprintf (G201/G202), text/template vs html/template (G203), OS command construction from input (G204)
- **G3xx** (files): over-permissive file creation permissions (G301/G302), path traversal through user input (G304/G305)
- **G4xx** (crypto): weak algorithms MD5/SHA1 for hashing (G401), insecure TLS config (G402), math/rand instead of crypto/rand (G404)
- **G5xx** (imports): blocked package imports (net/http/cgi, crypto/md5 directly)

## Running

```bash
# Install
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Locally — check only changed files
golangci-lint run --new-from-rev=HEAD~1

# In CI — full check
golangci-lint run ./...
```

## CI/CD integration

```yaml
# .github/workflows/lint.yml
name: Lint
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.26'
      # Current major version of the action: https://github.com/golangci/golangci-lint-action/releases
      - uses: golangci/golangci-lint-action@v9
        with:
          version: latest
```

## Adoption strategy

1. Start with `golangci-lint run --new-from-rev=main` — checks only new code
2. Add linters one at a time, starting with gosec and errcheck
3. Fix warnings in the current PR, don't accumulate technical debt
4. If a linter is noisy on legitimate code, add `//nolint:lintername // reason` with an explanation — don't disable globally
