# Input Handling & Secure Design — Code Patterns

Reference for sections 3 (Input Handling) and 4 (Secure Design) of the secure-go skill.

## 3. Input Handling

> OWASP: A03:2021 → A05:2025 — Injection

### SQL — always parameterized

```go
// Wrong — fmt.Sprintf + concatenation:
query := fmt.Sprintf("SELECT * FROM products WHERE name LIKE '%%%s%%'", userInput)

// Correct — parameterization:
rows, err := db.QueryContext(ctx,
    "SELECT * FROM products WHERE name LIKE $1",
    "%"+userInput+"%",
)
```

### sqlc — injection structurally impossible

```sql
-- queries.sql
-- name: SearchProducts :many
SELECT id, name, price FROM products WHERE name LIKE $1 OR description LIKE $1;
```

Generated Go code:

```go
// sqlc output — parameters already typed:
func (q *Queries) SearchProducts(ctx context.Context, pattern string) ([]Product, error) {
    rows, err := q.db.QueryContext(ctx, searchProducts, pattern)
    // ... parameterization guaranteed at generation time
}

// Usage — simple function call:
products, err := queries.SearchProducts(ctx, "%"+userInput+"%")
```

### ORM raw queries — the trap

```go
// GORM — safe (parameterized by default):
db.Where("name LIKE ?", "%"+input+"%").Find(&products)

// GORM — DANGEROUS (raw query with concatenation):
db.Raw(fmt.Sprintf("SELECT * FROM products WHERE name LIKE '%%%s%%'", input)).Scan(&products)

// GORM — safe raw query:
db.Raw("SELECT * FROM products WHERE name LIKE ?", "%"+input+"%").Scan(&products)
```

### OS commands — no shell

```go
// Wrong — through shell:
cmd := exec.Command("sh", "-c", fmt.Sprintf("convert %s -resize 300x300 %s", input, output))

// Correct — direct exec, args as separate strings:
cmd := exec.Command("convert", input, "-resize", "300x300", output)
```

### HTML — html/template, not text/template

```go
import "html/template"

tmpl := template.Must(template.ParseFiles("receipt.html"))
tmpl.Execute(w, data) // context-aware auto-escaping
```

**Critical trap:** wrapping data in `template.HTML`, `template.JS`, `template.URL`, or `template.CSS` disables auto-escaping. Use only for pre-sanitized content (e.g., through bluemonday).

### Server-side validation with go-playground/validator

```go
import "github.com/go-playground/validator/v10"

type CreateProductRequest struct {
    Name     string  `json:"name" validate:"required,min=1,max=200"`
    Price    float64 `json:"price" validate:"required,gt=0,lt=100000"`
    Category string  `json:"category" validate:"required,oneof=electronics clothing food"`
}

validate := validator.New()
if err := validate.Struct(req); err != nil {
    // return 400
}
```

## 4. Secure Design

> OWASP: A04:2021 → A06:2025 — Insecure Design

### Server-side business logic — never trust client prices

```go
// Wrong — accepting price from client:
type CheckoutItem struct {
    ProductID int64   `json:"product_id"`
    Price     float64 `json:"price"` // client can set 0.01
}

// Correct — price fetched from database:
func (s *CheckoutService) CalculateTotal(ctx context.Context, items []CartItem) (float64, error) {
    var total float64
    for _, item := range items {
        product, err := s.products.GetByID(ctx, item.ProductID)
        if err != nil {
            return 0, err
        }
        if item.Quantity <= 0 {
            return 0, errors.New("quantity must be positive")
        }
        total += product.Price * float64(item.Quantity)
    }
    return total, nil
}
```

### Race-condition protection with transactions

```go
func (s *CouponService) Apply(ctx context.Context, code string) (float64, error) {
    tx, err := s.db.BeginTx(ctx, nil)
    if err != nil {
        return 0, err
    }
    defer tx.Rollback()

    var usedCount, maxUses int
    var discount float64
    err = tx.QueryRowContext(ctx,
        "SELECT used_count, max_uses, discount FROM coupons WHERE code = $1 FOR UPDATE",
        code,
    ).Scan(&usedCount, &maxUses, &discount)
    if err != nil {
        return 0, err
    }
    if usedCount >= maxUses {
        return 0, ErrCouponExhausted
    }
    _, err = tx.ExecContext(ctx,
        "UPDATE coupons SET used_count = used_count + 1 WHERE code = $1", code,
    )
    if err != nil {
        return 0, err
    }
    return discount, tx.Commit()
}
```

### Resource limits at business-logic level

```go
const (
    MaxCartItems    = 100
    MaxFileSize     = 10 << 20 // 10 MB
    MaxRequestsRate = 100      // per second
)
```

Note: Go's race detector (`-race`) detects data races but does NOT help with race conditions — bugs where the **order** of goroutine execution is the problem, regardless of which data they access.

### Rate limiting with golang.org/x/time/rate

```go
import "golang.org/x/time/rate"

limiter := rate.NewLimiter(rate.Every(time.Second), 100) // 100 req/sec, burst 100

func handler(w http.ResponseWriter, r *http.Request) {
    if !limiter.Allow() {
        http.Error(w, "rate limit exceeded", http.StatusTooManyRequests)
        return
    }
    // process request
}
```

### Design habit questions

For every feature, ask:
- "What if someone does this 100,000 times?"
- "What if they substitute someone else's ID?"
- "What if they pass a negative quantity?"
