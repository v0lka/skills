# External Objects & External Requests — Code Patterns

Reference for sections 11 (External Objects) and 12 (External Requests / SSRF) of the secure-go skill.

## 11. External Objects

> OWASP: cross-cutting — Insecure Design (A04:2021/A06:2025) + Injection (A03:2021/A05:2025)

### Path traversal protection

```go
import "path/filepath"

func SafeFilePath(baseDir, userPath string) (string, error) {
    absBase, err := filepath.Abs(baseDir)
    if err != nil {
        return "", err
    }
    full := filepath.Join(absBase, filepath.Clean(userPath))
    absPath, err := filepath.Abs(full)
    if err != nil {
        return "", err
    }
    if !strings.HasPrefix(absPath, absBase+string(filepath.Separator)) {
        return "", errors.New("path traversal detected")
    }
    return absPath, nil
}
```

**Go 1.24+ alternative:** `os.Root` / `os.OpenRoot` — opens a root directory and prevents operations (`Open`, `Create`, `Stat`, `Remove`) from escaping it, even through symlinks. Preferred for new code.

### Mass assignment prevention — struct whitelisting

```go
// Wrong — accepting arbitrary fields:
var updates map[string]interface{}
json.NewDecoder(r.Body).Decode(&updates)
// updates may contain "role": "admin"!

// Correct — explicit struct whitelist:
type UpdateProfileRequest struct {
    FullName string `json:"full_name" validate:"omitempty,max=100"`
    Email    string `json:"email" validate:"omitempty,email"`
    // Role — absent, client cannot change
}
```

Struct-based binding (Gin `ShouldBindJSON`, Echo `Bind`, Fiber `BodyParser`) ignores fields not in the struct by default — whitelist without extra code:

```go
func UpdateProfile(c *gin.Context) {
    var req UpdateProfileRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": "invalid input"})
        return
    }
    // req.FullName and req.Email — the only fields available
}
```

### Open redirect prevention

```go
func SafeRedirect(inputURL string) string {
    u, err := url.Parse(inputURL)
    if err != nil || u.Host != "" {
        return "/" // absolute or invalid URL → home
    }
    return u.Path // relative paths only
}
```

### External data validation (API/webhook import)

```go
type ImportProduct struct {
    Name        string  `json:"name" validate:"required,max=200"`
    Price       float64 `json:"price" validate:"required,gt=0,lt=100000"`
    Description string  `json:"description" validate:"max=2000"`
}

func ImportFromExternal(ctx context.Context, data []byte) ([]ImportProduct, error) {
    var products []ImportProduct
    if err := json.Unmarshal(data, &products); err != nil {
        return nil, err
    }
    validate := validator.New()
    valid := products[:0]
    for i := range products {
        if err := validate.Struct(products[i]); err != nil {
            continue // discard invalid records
        }
        valid = append(valid, products[i])
    }
    return valid, nil
}
```

### Configuration — whitelist allowed settings keys

```go
// Wrong — accepting any configuration keys:
var settings map[string]interface{}
json.NewDecoder(r.Body).Decode(&settings)
for k, v := range settings {
    runtimeConfig[k] = v // someone could set "jwt_secret"
}

// Correct — whitelist:
var allowedSettings = map[string]bool{
    "site_title": true, "items_per_page": true, "maintenance_mode": true,
}

for k, v := range settings {
    if !allowedSettings[k] {
        continue
    }
    runtimeConfig[k] = v
}
```

## 12. External Requests (SSRF)

> OWASP: A10:2021 (SSRF) → consolidated into A01:2025

### URL/host whitelist

```go
var allowedHosts = map[string]bool{
    "api.partner.com":    true,
    "images.cdn.com":     true,
    "static.example.org": true,
}

func ValidateExternalURL(rawURL string) error {
    u, err := url.Parse(rawURL)
    if err != nil {
        return errors.New("invalid URL")
    }
    if u.Scheme != "https" {
        return errors.New("only HTTPS allowed")
    }
    if !allowedHosts[u.Host] {
        return errors.New("host not in allowlist")
    }
    return nil
}
```

### Block private/reserved IPs

```go
func isReservedIP(ip net.IP) bool {
    return ip == nil ||
        ip.IsPrivate() ||            // 10.x, 172.16-31.x, 192.168.x
        ip.IsLoopback() ||           // 127.x.x.x, ::1
        ip.IsLinkLocalUnicast() ||   // 169.254.x.x (AWS metadata!)
        ip.IsLinkLocalMulticast() || // 224.0.0.x
        ip.IsUnspecified()           // 0.0.0.0, ::
}

func IsPrivateOrReserved(host string) bool {
    if ip := net.ParseIP(host); ip != nil {
        return isReservedIP(ip)
    }
    // Domain passed — resolve and check EVERY returned address
    addrs, err := net.LookupHost(host)
    if err != nil || len(addrs) == 0 {
        return true // block on resolution failure
    }
    for _, addr := range addrs {
        if isReservedIP(net.ParseIP(addr)) {
            return true
        }
    }
    return false
}
```

### Safe HTTP client with timeouts and redirect checks

```go
func NewSafeHTTPClient() *http.Client {
    transport := &http.Transport{
        DialContext:           (&net.Dialer{Timeout: 5 * time.Second}).DialContext,
        TLSHandshakeTimeout:   5 * time.Second,
        ResponseHeaderTimeout: 5 * time.Second,
    }
    return &http.Client{
        Timeout:   10 * time.Second,
        Transport: transport,
        CheckRedirect: func(req *http.Request, via []*http.Request) error {
            if len(via) >= 3 {
                return errors.New("too many redirects")
            }
            if IsPrivateOrReserved(req.URL.Hostname()) {
                return errors.New("redirect to private IP blocked")
            }
            return nil
        },
    }
}
```

### DNS rebinding protection

Resolve DNS once, check all returned IPs, connect via verified IP with explicit `ServerName` for TLS:

```go
import (
    "crypto/tls"
    "net"
)

func SafeFetch(ctx context.Context, rawURL string) (*http.Response, error) {
    u, err := url.Parse(rawURL)
    if err != nil {
        return nil, err
    }

    // Resolve DNS upfront
    addrs, err := net.DefaultResolver.LookupHost(ctx, u.Hostname())
    if err != nil || len(addrs) == 0 {
        return nil, errors.New("DNS resolution failed")
    }

    // Verify every resolved IP
    for _, addr := range addrs {
        ip := net.ParseIP(addr)
        if ip == nil || ip.IsPrivate() || ip.IsLoopback() || ip.IsLinkLocalUnicast() {
            return nil, errors.New("resolved to private IP")
        }
    }

    // Determine port
    port := u.Port()
    if port == "" {
        if u.Scheme == "https" {
            port = "443"
        } else {
            port = "80"
        }
    }

    // Connect via verified IP, keep Host/SNI as domain for TLS
    dialer := &net.Dialer{Timeout: 5 * time.Second}
    transport := &http.Transport{
        DialContext: func(ctx context.Context, network, _ string) (net.Conn, error) {
            return dialer.DialContext(ctx, network, net.JoinHostPort(addrs[0], port))
        },
        TLSClientConfig: &tls.Config{
            ServerName: u.Hostname(), // critical — TLS cert must match domain
            MinVersion: tls.VersionTLS12,
        },
    }
    client := &http.Client{Transport: transport, Timeout: 10 * time.Second}
    return client.Get(rawURL)
}
```

**Production note:** the example above only uses `addrs[0]`. For production, implement a retry loop over all `addrs` — the first address may be unreachable.

### Don't proxy raw responses to clients

```go
// Wrong — proxy returning raw response:
resp, _ := http.Get(userURL)
io.Copy(c.Writer, resp.Body)

// Correct — extract only needed data, limit size:
resp, err := safeClient.Get(validatedURL)
if err != nil {
    c.JSON(502, gin.H{"error": "upstream unavailable"})
    return
}
defer resp.Body.Close()

var result ProductData
if err := json.NewDecoder(io.LimitReader(resp.Body, 1<<20)).Decode(&result); err != nil {
    c.JSON(502, gin.H{"error": "invalid upstream response"})
    return
}
c.JSON(200, result)
```
