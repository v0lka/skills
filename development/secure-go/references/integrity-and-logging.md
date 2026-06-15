# Integrity & Logging — Code Patterns & Configs

Reference for sections 9 (Integrity) and 10 (Logging & Alerting) of the secure-go skill.

## 9. Data & Software Integrity

> OWASP: A08:2021 → A08:2025 — Software or Data Integrity Failures. In 2025 partially redistributed: supply chain moved to A03:2025, data/signature integrity verification remained as A08.

### Sign client-side data with HMAC

```go
import (
    "crypto/hmac"
    "crypto/sha256"
)

func SignData(data []byte, secret []byte) []byte {
    mac := hmac.New(sha256.New, secret)
    mac.Write(data)
    return mac.Sum(nil)
}

func VerifyData(data, signature, secret []byte) bool {
    expected := SignData(data, secret)
    return hmac.Equal(signature, expected)
}
```

### Never deserialize gob from clients

```go
// Wrong — gob-encoded cookie without signature:
var cart Cart
gob.NewDecoder(bytes.NewReader(cookieData)).Decode(&cart)

// Correct — server-side storage:
cart, err := s.cartRepo.GetBySessionID(ctx, sessionID)
```

### Signed and encrypted cookies with gorilla/securecookie

```go
import "github.com/gorilla/securecookie"

var s = securecookie.New(
    securecookie.GenerateRandomKey(64), // HMAC key
    securecookie.GenerateRandomKey(32), // AES encryption key
)

// Write signed cookie:
encoded, _ := s.Encode("cart", cartData)
http.SetCookie(w, &http.Cookie{Name: "cart", Value: encoded, HttpOnly: true})

// Read and verify:
var cart CartData
cookie, _ := r.Cookie("cart")
s.Decode("cart", cookie.Value, &cart) // error if signature invalid
```

### CSRF protection — Go 1.25+ built-in

```go
// Go 1.25+ built-in CSRF protection — checks Origin & Referer, no tokens needed:
mux := http.NewServeMux()
mux.HandleFunc("POST /api/orders", createOrder)

// Wrap the mux — all state-changing requests are protected:
handler := http.CrossOriginProtection(mux)
http.ListenAndServe(":8080", handler)
```

### CI/CD integrity pipeline

```yaml
# .github/workflows/integrity.yml
name: Integrity Check
on: [push, pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.26'
      - run: go mod verify        # dependency integrity
      - run: go vet ./...          # static analysis
      - run: govulncheck ./...     # known vulnerabilities
      - run: go test -race ./...   # tests + race detector

# + repository settings: branch protection rules
# → Require pull request review before merging
# → Require status checks to pass
```

### Subresource Integrity for CDN assets

```html
<script src="https://cdn.example.com/lib.js"
        integrity="sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxy9rx7HNQlGYl1kPzQho1wx4JwY8wC"
        crossorigin="anonymous"></script>
```

Generate hash:

```bash
# macOS (BSD base64)
shasum -b -a 384 lib.js | awk '{ print $1 }' | xxd -r -p | base64

# Linux (GNU base64) — use -w 0 to avoid line wraps
shasum -b -a 384 lib.js | awk '{ print $1 }' | xxd -r -p | base64 -w 0
```

## 10. Logging & Alerting

> OWASP: A09:2021 → A09:2025 — Security Logging & Alerting Failures. "Alerting" explicitly added to the name in 2025 — emphasis shifted to alerting, not just log collection.

### Structured logging with log/slog (Go 1.21+)

```go
import "log/slog"

logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelInfo,
}))
slog.SetDefault(logger)

// Data as separate fields — safe against log injection:
slog.Info("order created",
    "user_id", userID,
    "order_id", orderID,
    "total", total,
)

// Wrong — concatenating user input into log message:
slog.Info(fmt.Sprintf("search: %s", userQuery))
// If userQuery = "test\nERROR: admin password reset" — indistinguishable from real log entry

// Correct — data as fields (JSONHandler escapes values via encoding/json):
slog.Info("search performed", "query", userQuery)
```

### Never log sensitive data

```go
// Wrong:
slog.Info("login failed", "password", req.Password)
slog.Info("payment", "cc_number", req.CCNumber)
slog.Info("reset token generated", "token", resetToken)

// Correct:
slog.Warn("login failed", "email", req.Email)
slog.Info("payment processed", "order_id", orderID, "last4", ccLast4)
slog.Info("reset token generated", "email", user.Email)
```

### Audit middleware

```go
func AuditMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        wrapped := &statusWriter{ResponseWriter: w}
        next.ServeHTTP(wrapped, r)

        slog.Info("request",
            "method", r.Method,
            "path", r.URL.Path,
            "status", wrapped.status,
            "duration_ms", time.Since(start).Milliseconds(),
            "user_id", auth.UserIDFromContext(r.Context()),
            "ip", r.RemoteAddr,
        )
    })
}
```

### Metrics-based alerting with Prometheus

```go
import "github.com/prometheus/client_golang/prometheus"

var authFailures = prometheus.NewCounterVec(
    prometheus.CounterOpts{
        Name: "auth_failures_total",
        Help: "Total number of failed authentication attempts",
    },
    []string{"reason"}, // "bad_password", "user_not_found", "rate_limited"
)

// In handler:
authFailures.WithLabelValues("bad_password").Inc()
// Alert rule in Prometheus: rate(auth_failures_total[5m]) > 50
```

### Recommended alerting pipeline

JSON logs → [Vector](https://vector.dev/) or Promtail → Loki/Elasticsearch → Grafana alerts.

Example alert rules:
- `rate(auth_failures_total[5m]) > 50` — brute force detection
- `rate(http_requests_total{status=~"5.."}[5m]) > 10` — spike in server errors
