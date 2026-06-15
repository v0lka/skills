# Configuration & Dependencies — Code Patterns & Configs

Reference for sections 5 (Configuration) and 6 (Dependencies) of the secure-go skill.

## 5. Configuration

> OWASP: A05:2021 → A02:2025 — Security Misconfiguration

### Production mode by default

```go
gin.SetMode(gin.ReleaseMode)
```

### Never leak internals to clients

```go
// Wrong:
c.JSON(500, gin.H{"error": err.Error()})

// Correct:
log.Error("internal error", "err", err, "request_id", requestID)
c.JSON(500, gin.H{"error": "internal error", "request_id": requestID})
```

### Security headers middleware

```go
func SecurityHeaders() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Header("Content-Security-Policy", "default-src 'self'")
        c.Header("X-Content-Type-Options", "nosniff")
        c.Header("X-Frame-Options", "DENY")
        c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
        c.Next()
    }
}

r := gin.New()
r.Use(SecurityHeaders())
```

### Disable directory listing

```go
// Wrong — raw http.Dir enables directory listing:
r.StaticFS("/uploads", http.Dir("./uploads"))

// Correct — Gin wrapper Dir(root, false) disables listing.
// r.Static does exactly this under the hood:
r.Static("/uploads", "./uploads")
// or explicitly:
r.StaticFS("/uploads", gin.Dir("./uploads", false))
```

### Validate uploaded file types by magic bytes

```go
func Upload(c *gin.Context) {
    file, header, err := c.Request.FormFile("file")
    if err != nil {
        c.JSON(400, gin.H{"error": "no file"})
        return
    }
    defer file.Close()

    // Check Content-Type by magic bytes.
    // Use io.ReadAtLeast — it doesn't treat short reads as fatal
    // (small files < 512 bytes are valid), while full io.EOF/other errors are caught explicitly.
    buf := make([]byte, 512)
    n, err := io.ReadAtLeast(file, buf, 1)
    if err != nil {
        c.JSON(400, gin.H{"error": "cannot read file"})
        return
    }
    contentType := http.DetectContentType(buf[:n])

    // IMPORTANT: after Read the pointer has advanced. If saving the file below —
    // seek back to the beginning, otherwise the first 512 bytes will be lost.
    if _, err := file.Seek(0, io.SeekStart); err != nil {
        c.JSON(500, gin.H{"error": "seek failed"})
        return
    }

    allowed := map[string]bool{"image/jpeg": true, "image/png": true, "image/gif": true}
    if !allowed[contentType] {
        c.JSON(400, gin.H{"error": "file type not allowed"})
        return
    }
    if header.Size > 10<<20 {
        c.JSON(400, gin.H{"error": "file too large"})
        return
    }
}
```

### Server timeouts and TLS

```go
srv := &http.Server{
    Addr:              ":8443",
    Handler:           handler,
    ReadHeaderTimeout: 5 * time.Second,  // critical — without this, vulnerable to Slowloris
    ReadTimeout:       30 * time.Second,
    WriteTimeout:      30 * time.Second,
    IdleTimeout:       120 * time.Second,
    TLSConfig: &tls.Config{
        MinVersion: tls.VersionTLS12, // minimum; prefer TLS 1.3 for new code
    },
}
log.Fatal(srv.ListenAndServeTLS(certFile, keyFile))
```

### Production Dockerfile

```dockerfile
# Multi-stage build: build in full image, run in minimal.
# In production, pin specific patch version + sha256 digest
# to prevent silently changed images on rebuild.
FROM golang:1.26.0-alpine@sha256:<digest> AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download && go mod verify
COPY . .
RUN CGO_ENABLED=0 go build -o /server ./cmd/server

# Final image — also with digest:
FROM gcr.io/distroless/static-debian12@sha256:<digest>
COPY --from=builder /server /server
USER nonroot:nonroot
ENTRYPOINT ["/server"]
```

### Production build flags

```dockerfile
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /server ./cmd/server
```

- `-trimpath` strips absolute paths from the binary; removes VCS info that would leak via `runtime/debug.BuildInfo`
- `-ldflags="-s -w"` strips symbol table and DWARF debug data
- `CGO_ENABLED=0` produces a static binary
- `USER nonroot` — never run containers as root

**Trade-off:** `-s -w` removes debug info, which shrinks the binary and removes internal identifiers from dumps, but breaks profilers, debuggers, and quality of stack traces in incident dumps. If production profiling (`pprof`) or an external tracer with symbolization is used, keep only `-trimpath` and apply `-s -w` selectively.

## 6. Dependencies

> OWASP: A06:2021 → A03:2025 — Software Supply Chain Failures

### govulncheck — install and run

```bash
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...
```

`govulncheck` builds a call-graph and checks whether a vulnerable function is actually reachable from your code — smarter than version-only scanners. Limitation: for cgo, reflection, plugins, and dynamic dispatch, it falls back to version comparison.

### CI/CD security scanning

```yaml
# .github/workflows/security.yml
name: Security
on: [push, pull_request]
jobs:
  govulncheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: golang/govulncheck-action@v1
```

### Version pinning and integrity verification

```bash
go get -u ./...
go mod tidy
go mod verify  # verifies checksums in go.sum match on-disk files
```

### Keep Go toolchain current

```dockerfile
# Wrong:
FROM golang:1.20-alpine
# Correct (as of June 2026):
FROM golang:1.26-alpine
```
