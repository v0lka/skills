# Authentication & Error Handling — Code Patterns

Reference for sections 7 (Authentication) and 8 (Error Handling) of the secure-go skill.

## 7. Authentication

> OWASP: A07:2021 → A07:2025 — Authentication Failures

Delegate at the highest possible level: identity platform > OIDC client > JWT library.

### JWT — mandatory algorithm check and expiry

```go
import "github.com/golang-jwt/jwt/v5"

func GenerateToken(userID int64, role string) (string, error) {
    claims := jwt.MapClaims{
        "user_id": userID,
        "role":    role,
        "exp":     time.Now().Add(24 * time.Hour).Unix(),
        "iat":     time.Now().Unix(),
    }
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString(jwtSecret)
}

func ParseToken(tokenString string) (*jwt.Token, error) {
    return jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
        // Mandatory algorithm check
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
        }
        return jwtSecret, nil
    })
}
```

For new systems, prefer asymmetric algorithms (`EdDSA`, `RS256`) — the public key can be safely distributed to verifiers.

### Per-IP rate limiter for authentication

```go
import "golang.org/x/time/rate"

type IPRateLimiter struct {
    mu       sync.Mutex
    limiters map[string]*rate.Limiter
}

func (l *IPRateLimiter) GetLimiter(ip string) *rate.Limiter {
    l.mu.Lock()
    defer l.mu.Unlock()
    limiter, exists := l.limiters[ip]
    if !exists {
        limiter = rate.NewLimiter(rate.Every(time.Second), 5)
        l.limiters[ip] = limiter
    }
    return limiter
}
```

**Production note:** use TTL/eviction (e.g., `golang-lru`) or `ulule/limiter` with Redis to prevent unbounded map growth.

### Check passwords against breach databases (k-anonymity)

```go
import "github.com/mattevans/pwned-passwords"

func ValidatePassword(password string) error {
    if len(password) < 8 {
        return errors.New("password must be at least 8 characters")
    }
    client := pwned.NewClient()
    compromised, err := client.Compromised(password)
    if err == nil && compromised {
        return errors.New("password found in known data breaches, choose another")
    }
    return nil
}
```

Only the first 5 characters of the password hash are sent to the external service.

### Uniform error responses — no user enumeration

```go
func (h *AuthHandler) ForgotPassword(c *gin.Context) {
    var req ForgotPasswordRequest
    // Suppress parse error intentionally: even on invalid JSON
    // the response must be the same — otherwise a side-channel for email enumeration appears.
    _ = c.BindJSON(&req)

    user, err := h.users.GetByEmail(c, req.Email)
    if err == nil {
        token, _ := generateResetToken()
        h.users.SetResetToken(c, user.ID, token)
        h.mailer.SendResetEmail(user.Email, token)
    }
    // Always the same response — no way to probe which emails exist
    c.JSON(200, gin.H{"message": "If this email exists, a reset link has been sent"})
}
```

### Full session invalidation on logout

"Logout" must mean the presented token/session ID no longer works on any node. For server-side sessions — delete the record; for JWT-like stateless schemes — denylist by `jti` or short `exp` + refresh token rotation with revocation:

```go
// Server-side session (gorilla/sessions, Redis-backed):
func (h *AuthHandler) Logout(c *gin.Context) {
    session, _ := h.store.Get(c.Request, "session")
    session.Options.MaxAge = -1 // Set-Cookie with expired date
    _ = session.Save(c.Request, c.Writer)
    _ = h.sessionRepo.Delete(c, sessionIDFrom(session)) // delete server record
}

// JWT with jti-based denylist:
func (h *AuthHandler) LogoutJWT(c *gin.Context, claims jwt.MapClaims) {
    jti, _ := claims["jti"].(string)
    exp, _ := claims["exp"].(float64)
    // Remember jti until its natural exp — then it can be cleaned up.
    _ = h.revoked.Add(c, jti, time.Until(time.Unix(int64(exp), 0)))
}
```

Without the invalidation step, "logout" only removes the cookie from the user, but a stolen token continues to work until its `exp`.

## 8. Error Handling

> OWASP: A10:2025 — Mishandling of Exceptional Conditions (new in 2025)

### Every goroutine gets its own recover

Framework recovery middleware (Gin, Echo, Fiber) only protects the HTTP request goroutine. For background workers, queues, and periodic jobs — put `defer recover()` at the isolation boundary. Silencing panics in every ordinary one-off goroutine is an anti-pattern: software bugs should crash loudly and be visible in tests.

```go
// Wrong — panic in goroutine kills the entire process:
go func() {
    result := processPayment(amount)
}()

// Correct — recover at the boundary of a long-lived worker:
go func() {
    defer func() {
        if r := recover(); r != nil {
            log.Error("payment worker panic", "recovered", r)
        }
    }()
    for job := range paymentJobs {
        process(job)
    }
}()
```

### Multi-step operations in transactions

```go
func (s *CheckoutService) Process(ctx context.Context, req CheckoutRequest) error {
    tx, err := s.db.BeginTx(ctx, nil)
    if err != nil {
        return fmt.Errorf("begin tx: %w", err)
    }
    defer tx.Rollback() // safe: no-op if already committed

    if err := s.capturePayment(ctx, tx, req); err != nil {
        return fmt.Errorf("capture payment: %w", err)
    }
    if err := s.createOrder(ctx, tx, req); err != nil {
        return fmt.Errorf("create order: %w", err) // Rollback via defer
    }
    return tx.Commit()
}
```

### Don't leak internals in recovery

```go
// Wrong — custom recovery dumping everything:
defer func() {
    if err := recover(); err != nil {
        c.JSON(500, gin.H{
            "error": fmt.Sprintf("%v", err),
            "stack": string(debug.Stack()),
            "env":   os.Environ(),
        })
    }
}()

// Correct — standard recovery:
r := gin.New()
r.Use(gin.Recovery()) // logs to stderr, client gets generic 500
```

### Resource cleanup with committed-flag pattern

```go
func (h *UploadHandler) Process(c *gin.Context) {
    path, err := h.saveFile(c)
    if err != nil {
        c.JSON(400, gin.H{"error": "upload failed"})
        return
    }
    var committed bool
    defer func() {
        if !committed {
            _ = os.Remove(path)
        }
    }()

    if err := h.processImage(path); err != nil {
        c.JSON(500, gin.H{"error": "processing failed"})
        return
    }
    committed = true
}
```

### Coordinated goroutines with errgroup

```go
import "golang.org/x/sync/errgroup"

func ProcessOrder(ctx context.Context, order Order) error {
    g, ctx := errgroup.WithContext(ctx)

    g.Go(func() error {
        return validateInventory(ctx, order.Items)
    })
    g.Go(func() error {
        return chargePayment(ctx, order.PaymentInfo)
    })

    // If any goroutine returns an error, the other is canceled via ctx
    return g.Wait()
}
```
