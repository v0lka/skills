# Access Control & Data Protection — Code Patterns

Reference for sections 1 (Access Control) and 2 (Data Protection) of the secure-go skill.

## 1. Access Control

> OWASP: A01:2021 / A01:2025 — Broken Access Control

### Deny-by-default middleware

```go
func RequireRole(role string) gin.HandlerFunc {
    return func(c *gin.Context) {
        user := auth.UserFromContext(c)
        if user == nil {
            c.AbortWithStatus(http.StatusUnauthorized)
            return
        }
        if user.Role != role {
            c.AbortWithStatus(http.StatusForbidden)
            return
        }
        c.Next()
    }
}
admin := r.Group("/api/admin", authMiddleware, RequireRole("admin"))
```

### net/http middleware (no framework)

```go
func RequireAuth(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        user := auth.UserFromRequest(r)
        if user == nil {
            http.Error(w, "unauthorized", http.StatusUnauthorized)
            return
        }
        next.ServeHTTP(w, r)
    })
}

mux := http.NewServeMux()
mux.Handle("GET /api/orders", RequireAuth(http.HandlerFunc(getOrders)))
```

### Owner-bound data queries

```go
func (r *OrderRepo) GetByID(ctx context.Context, orderID, userID int64) (*Order, error) {
    row := r.db.QueryRowContext(ctx,
        "SELECT id, total, status FROM orders WHERE id = $1 AND user_id = $2",
        orderID, userID,
    )
    // ...
}
```

### Access rule tests

```go
func TestGetOrder_BelongsToOtherUser(t *testing.T) {
    resp := asUser(userA).GET("/api/orders/" + orderOfUserB.ID)
    assert.Equal(t, http.StatusNotFound, resp.Code)
}
```

## 2. Data Protection

> OWASP: A02:2021 → A04:2025 — Cryptographic Failures

### bcrypt password hashing

```go
import "golang.org/x/crypto/bcrypt"

func HashPassword(password string) (string, error) {
    hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    return string(hash), err
}

func CheckPassword(hash, password string) bool {
    return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
}
```

### Argon2id password hashing

```go
import (
    "crypto/rand"
    "crypto/subtle"
    "golang.org/x/crypto/argon2"
)

func HashPasswordArgon2(password string) (hash, salt []byte, err error) {
    // Generate random salt — always through crypto/rand
    salt = make([]byte, 16)
    if _, err := rand.Read(salt); err != nil {
        return nil, nil, err
    }
    // Practical guidance from OWASP Password Storage Cheat Sheet:
    // baseline profile — m=19 MiB, t=2, p=1, keyLen=32 (minimum sufficient).
    // Heavier profile from the same cheat sheet, if hardware allows:
    // m=64 MiB, t=1, p=4 — extra memory-hardness margin.
    // Tune for target hardware — target ~0.5–1 second CPU per hash.
    hash = argon2.IDKey([]byte(password), salt, 1, 64*1024, 4, 32)
    return hash, salt, nil
}

func VerifyPasswordArgon2(password string, hash, salt []byte) bool {
    candidate := argon2.IDKey([]byte(password), salt, 1, 64*1024, 4, 32)
    // subtle.ConstantTimeCompare protects against timing attacks
    return subtle.ConstantTimeCompare(candidate, hash) == 1
}
```

### Secrets from environment

```go
// Variant 1 — os.Getenv (sufficient for most cases):
var jwtSecret = []byte(os.Getenv("JWT_SECRET"))

// Variant 2 — koanf (typed config from multiple sources):
import "github.com/knadh/koanf/v2"

// Never:
var jwtSecret = []byte("my-secret-key-2024")    // secret in code — bug

// Also never — secret in config.yaml committed to git:
// database:
//   password: "supersecret123"
```

For more complex setups, [koanf](https://github.com/knadh/koanf) reads from env, files, flags simultaneously:

```go
import "github.com/knadh/koanf/v2"
import "github.com/knadh/koanf/providers/env"

var k = koanf.New(".")

func LoadConfig() {
    k.Load(env.Provider("APP_", ".", func(s string) string {
        return strings.ToLower(strings.TrimPrefix(s, "APP_"))
    }), nil)
}

jwtSecret := k.String("jwt_secret") // from APP_JWT_SECRET
dbURL := k.String("database_url")   // from APP_DATABASE_URL
```

### Cryptographic randomness (crypto/rand, never math/rand)

```go
import "crypto/rand"

func GenerateToken() (string, error) {
    b := make([]byte, 32)
    _, err := rand.Read(b)
    return hex.EncodeToString(b), err
}
```

### API response structs — only what the client needs

```go
type UserResponse struct {
    ID       int64  `json:"id"`
    Email    string `json:"email"`
    FullName string `json:"full_name"`
    // password_hash, reset_token — absent from the struct, never serialized
}
```
