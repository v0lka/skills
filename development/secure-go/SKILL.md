---
name: secure-go
description: >
  Write secure Go applications through everyday development practices — no AppSec expertise required.
  Covers the 12 OWASP Top 10 categories (2021 & 2025) with idiomatic Go patterns, standard library
  defaults, recommended libraries, and a security-focused linter setup. Use when writing or reviewing
  Go backend code, designing Go APIs, configuring production deployments, setting up CI/CD security
  checks, or hardening existing Go services.
---

# Secure Go Development

Write secure Go applications through idiomatic Go — explicit error handling, strict typing, a strong
standard library, and built-in tooling (`go vet`, `go test -race`, `govulncheck`). Vulnerability is
just a bug: code doing something the spec didn't ask for.

Go provides a strong starting position: no buffer overflows (GC, bounds-checked slices), strict static
typing (no silent coercions), explicit error handling (no swallowed exceptions), a single static binary
(smaller attack surface), and `go.sum` + checksum database guaranteeing dependency integrity out of
the box. Go cryptographic packages passed an independent [Trail of Bits audit](https://github.com/trailofbits/publications)
in 2025 (commissioned by Google): 1 low-severity finding (fixed in Go 1.24), 5 informational.

Structure follows OWASP Top 10 2021 with 2025 mappings noted in each section.

---

## 1. Access Control — don't give more than needed

> OWASP: A01:2021 / A01:2025 — Broken Access Control. SSRF (A10:2021) consolidated here.

Every data operation checks that the current user has the right to that operation on that data.

**Code examples:** [references/access-and-data.md](references/access-and-data.md#1-access-control)

### Rules

- Deny access to all non-public resources by default.
- Authorization logic lives in middleware, reused across routes.
- Data is bound to its owner; ownership checked on every access (`WHERE user_id = $1`).
- Access rules covered by tests — they are business logic.

### Recommended libraries

- **[Casbin](https://github.com/casbin/casbin)** — RBAC/ABAC as configuration. Adapters for Gin, Echo, Fiber, Chi.
- **[Oso](https://github.com/osohq/oso)** — policy engine with declarative language Polar. For rules more complex than roles.

---

## 2. Data Protection — protect what shouldn't be public

> OWASP: A02:2021 → A04:2025 — Cryptographic Failures.

**Code examples:** [references/access-and-data.md](references/access-and-data.md#2-data-protection) — bcrypt/Argon2 hashing, env secrets, `crypto/rand`, API response structs.

### Rules

- Don't store what you don't need. Delete or anonymize data once it served its purpose.
- Passwords: hash only (bcrypt/Argon2), never MD5/SHA-256 without salt.
- TLS everywhere data traverses between components.
- Secrets never live in source code or git.
- Tokens, keys, salt: only `crypto/rand`.

### Recommended libraries & tools

- **`golang.org/x/crypto/bcrypt`** & **`golang.org/x/crypto/argon2`** — password hashing. bcrypt simpler (manages salt and packs parameters into string), Argon2id adjustable in memory, preferred for new systems; bcrypt with cost 12+ remains acceptable per OWASP. Practical guidance from OWASP Password Storage Cheat Sheet: baseline profile m=19 MiB, t=2, p=1, keyLen=32 (minimum sufficient); heavier profile m=64 MiB, t=1, p=4 if hardware allows. Target ~0.5–1 second CPU per hash.
- **`crypto/rand`** — random values (salt, tokens, keys).
- **`crypto/subtle`** — `ConstantTimeCompare` for timing-safe hash comparisons.
- **[golang-jwt/jwt/v5](https://github.com/golang-jwt/jwt)** — JWT with mandatory algorithm verification.
- **[koanf](https://github.com/knadh/koanf)** — typed config from env, files, flags, Consul, etcd.
- **[env](https://github.com/caarlos0/env)** — minimal env→struct mapping via tags.
- **[viper](https://github.com/spf13/viper)** — full-featured config combiner (env + yaml + consul + remote).
- **[SOPS](https://github.com/getsops/sops)** — encrypt secrets in yaml/json config files (AWS KMS, GCP KMS, age, PGP). Safe in git.
- **[Vault](https://www.vaultproject.io/)** — dynamic secret generation, rotation, access audit. Go client: `hashicorp/vault/api`.
- **[gitleaks](https://github.com/gitleaks/gitleaks)** — pre-commit hook scanning diffs for secret patterns.

---

## 3. Input Handling — trust only what is explicitly allowed

> OWASP: A03:2021 → A05:2025 — Injection (XSS included in 2025).

Two universal rules: (1) never construct executable strings from raw user input; (2) validate on input, sanitize on output.

**Code examples:** [references/input-and-design.md](references/input-and-design.md#3-input-handling) — parameterized SQL, sqlc, ORM raw queries, OS commands, `html/template`, validation.

### Rules

- SQL — only through placeholders. `fmt.Sprintf` for SQL is a bug.
- OS commands — `exec.Command` with individual args, no `sh -c`.
- HTML — `html/template`, not `text/template`. Never wrap user data in `template.HTML` without sanitization.
- Validate on the server side, by whitelist (allowed chars, length, format).
- Sanitize context-dependently on output (HTML, URL, SQL — different contexts).

### Recommended libraries & tools

- **`database/sql`** — parameterized queries out of the box.
- **[sqlc](https://github.com/sqlc-dev/sqlc)** — typed Go from SQL. Injection structurally impossible.
- **[sqlx](https://github.com/jmoiron/sqlx)** — `database/sql` extension with named queries.
- **[ent](https://entgo.io/)** & **[GORM](https://gorm.io/)** — ORMs with parameterization by default. Raw queries still need `?` placeholders.
- **`html/template`** — stdlib, context-dependent auto-escaping.
- **[go-playground/validator](https://github.com/go-playground/validator)** — declarative validation via struct tags.
- **[ozzo-validation](https://github.com/go-ozzo/ozzo-validation)** — code-based validation (no tags).
- **[bluemonday](https://github.com/microcosm-cc/bluemonday)** — HTML sanitization on a whitelist approach.

---

## 4. Secure Design — trust boundaries at design time

> OWASP: A04:2021 → A06:2025 — Insecure Design.

Problems that can't be fixed at implementation because they're baked into the architecture.

**Code examples:** [references/input-and-design.md](references/input-and-design.md#4-secure-design) — server-side business logic, race-condition protection, resource limits, rate limiting.

### Rules

- For every feature, define who can do what and with what limits.
- Don't trust the client. Validate constraints on the server. Prices, discounts — server-side only.
- Resource consumption limits at the business-logic level.
- Each component gets exactly the permissions it needs.
- Use ready-made solutions for standard tasks (auth, hashing, sessions).
- Design habit: ask "What if someone does this 100,000 times? Substitutes someone else's ID? Passes a negative quantity?"

### Recommended libraries & tools

- **`database/sql` transactions** — `BeginTx` + `SELECT ... FOR UPDATE` for atomic business operations.
- **[golang.org/x/time/rate](https://pkg.go.dev/golang.org/x/time/rate)** — rate limiter from Go extended library.
- **Go race detector** (`go test -race`) — built-in.

---

## 5. Configuration — secure by default

> OWASP: A05:2021 → A02:2025 — Security Misconfiguration. Moved to A02 in 2025.

**Code examples:** [references/config-and-deps.md](references/config-and-deps.md#5-configuration) — production mode, error responses, security headers, file upload validation, server timeouts, Dockerfile.

### Rules

- Default accounts/passwords — not in production.
- Detailed errors — only in dev. Client gets generic message + `request_id`.
- Strip everything unnecessary from distribution: test pages, framework docs, debug endpoints.
- Security headers configured once in middleware.
- `http.Server` always has `ReadHeaderTimeout`/`ReadTimeout`/`WriteTimeout`. TLS ≥ 1.2.
- Environment configuration is automated and reproducible (Dockerfile, docker-compose, Terraform).
- Docker: multi-stage builds, distroless runtime, non-root user (`USER nonroot`). Pin specific patch version + sha256 digest in production builds to prevent silently changed images on rebuild.
- Build flags: `-trimpath` strips paths; `-ldflags="-s -w"` strips debug info; `CGO_ENABLED=0` for static binaries. Trade-off: `-s -w` removes symbol table and DWARF data — this shrinks binary and removes internal identifiers from dumps, but breaks profilers, debuggers, and symbolic stack traces. For production profiling (`pprof`), use only `-trimpath`.

### Recommended libraries & tools

- **[secure](https://github.com/unrolled/secure)** — security headers middleware for Gin, Echo, Chi, net/http. One line: `r.Use(secure.New(secure.Options{...}).Handler)`.
- **Echo `Secure` middleware** — built into `github.com/labstack/echo/v4/middleware`. Covers CSP, HSTS, X-Frame-Options, XSS-Protection, content-type-nosniff.
- **`http.DetectContentType`** — stdlib, MIME detection from first 512 bytes. Use `io.ReadAtLeast` (not `io.ReadFull`) — small files < 512 bytes are valid.

---

## 6. Dependencies — manage what you use

> OWASP: A06:2021 → A03:2025 — Software Supply Chain Failures. Category expanded: beyond outdated dependencies, now explicitly covers supply chain risks — typosquatting, compromised maintainer accounts, registry package substitution.

**Code examples & CI config:** [references/config-and-deps.md](references/config-and-deps.md#6-dependencies) — govulncheck, CI workflow, version pinning, toolchain updates.

### Rules

- Track dependencies (including transitive): `go mod graph`.
- govulncheck in CI — 5 lines in the workflow. Builds call-graph, checks reachability.
- `go mod tidy` — no unused dependencies.
- `go mod verify` — checksum integrity.
- Update dependencies regularly, but let new versions "settle."
- Use proven modules with active maintenance.
- Never run containers as root. `USER nonroot` in Dockerfile.
- Keep Go toolchain current (1.26 as of mid-2026).

### Recommended libraries & tools

- **[govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck)** — official vulnerability checker from the Go team. Must-have.
- **[nancy](https://github.com/sonatype-nexus-community/nancy)** — alternative scanner from Sonatype.
- **[Dependabot](https://docs.github.com/en/code-security/dependabot)** / **[Renovate](https://github.com/renovatebot/renovate)** — automated dependency update PRs.
- **Go module proxy + checksum database** (`sum.golang.org`) — built-in. `go get` verifies hashes transparently.

---

## 7. Authentication — ready-made solutions, correctly configured

> OWASP: A07:2021 → A07:2025 — Authentication Failures.

Delegate at the highest possible level: identity platform > OIDC client > JWT library.

**Code examples:** [references/auth-and-errors.md](references/auth-and-errors.md#7-authentication) — JWT generation/parsing, per-IP rate limiter, breach password check, uniform error responses.

### Rules

- Use ready-made libraries. Don't write your own authentication.
- JWT: always with `exp`, always with algorithm check. Prefer EdDSA/RS256 for new systems.
- Passwords: minimum length enforced.
- Session IDs: only `crypto/rand`.
- On logout: full session invalidation. For server-side sessions — delete the record. For JWT — denylist by `jti` or short `exp` + refresh token rotation with revocation. Without invalidation, "logout" only removes the cookie, but a stolen token keeps working until expiry.
- Rate limiting on login: by IP + by account.
- Uniform error responses on authentication failures. No user enumeration.

### Recommended libraries & tools

- **[golang-jwt/jwt/v5](https://github.com/golang-jwt/jwt)** — JWT library (signing/parsing only). Always v5 with algorithm verification.
- **[coreos/go-oidc](https://github.com/coreos/go-oidc)** — OpenID Connect client. Delegate to Google, GitHub, Keycloak, Auth0.
- **[Ory Kratos](https://github.com/ory/kratos)**, **[SuperTokens](https://github.com/supertokens/supertokens-core)**, **[ZITADEL](https://github.com/zitadel/zitadel)** — full identity platforms (login flow, MFA, password reset, audit log).
- **[golang.org/x/time/rate](https://pkg.go.dev/golang.org/x/time/rate)** — per-IP rate limiting.
- **[ulule/limiter](https://github.com/ulule/limiter)** — rate limiter with Redis. Middleware for Gin, Echo, Chi.
- **[gorilla/sessions](https://github.com/gorilla/sessions)** — server-side sessions (cookie, Redis, PostgreSQL, filesystem).
- **[mattevans/pwned-passwords](https://github.com/mattevans/pwned-passwords)** — breach check via k-anonymity.

---

## 8. Error Handling — exceptions must not become holes

> OWASP: A10:2025 — Mishandling of Exceptional Conditions (new in 2025).

**Code examples:** [references/auth-and-errors.md](references/auth-and-errors.md#8-error-handling) — per-goroutine recover, transactional multi-step ops, recovery middleware, committed-flag cleanup, errgroup.

### Rules

- Long-lived goroutines (background workers, queues): `defer recover()` at the isolation boundary. One-off goroutines don't need silencing — software bugs should crash loudly and be visible in tests.
- Multi-step business operations: transactions with `defer tx.Rollback()`.
- Recovery middleware: standard for request goroutines, custom for own workers. Never leak stack traces to clients.
- Resources (files, connections): cleanup on errors via `defer`.
- `panic` — for unrecoverable situations only. Not for normal errors.

### Recommended libraries & tools

- **`gin.Recovery()`** / **`echo.Recover()`** / **`fiber.Recover()`** — built-in recovery middleware for HTTP request goroutines.
- **[errgroup](https://pkg.go.dev/golang.org/x/sync/errgroup)** — goroutine coordination. One fails → others canceled via context.
- **`database/sql` transactions** — `defer tx.Rollback()` idiom.
- **`defer`** — resource cleanup on errors.

---

## 9. Data & Software Integrity — verify what you receive

> OWASP: A08:2021 → A08:2025 — Software or Data Integrity Failures. In 2025 partially redistributed: supply chain moved to A03:2025, data/signature integrity verification remained as A08.

**Code examples:** [references/integrity-and-logging.md](references/integrity-and-logging.md#9-data--software-integrity) — HMAC signing, signed cookies, CSRF, CI integrity pipeline, SRI.

### Rules

- Checksums when receiving external components (`go mod verify`).
- `encoding/gob` for client data — no. JSON + signature or server-side storage.
- CI/CD: access control and mandatory review.
- CSRF: Go 1.25+ `http.CrossOriginProtection` (checks `Origin`/`Referer`, no tokens needed) or gorilla/csrf.
- Everything stored client-side is signed.

### Recommended libraries & tools

- **`crypto/hmac`** & **`crypto/sha256`** — data signing (stdlib).
- **[gorilla/securecookie](https://github.com/gorilla/securecookie)** — signed & encrypted cookies. One call to `Encode`/`Decode`.
- **[gorilla/csrf](https://github.com/gorilla/csrf)** — CSRF protection via signed tokens. Middleware.
- **Go 1.25+ `http.CrossOriginProtection`** — built-in CSRF protection in stdlib.
- **`go mod verify`** — checks module integrity.

---

## 10. Logging & Alerting — record what helps investigation

> OWASP: A09:2021 → A09:2025 — Security Logging & Alerting Failures. "Alerting" explicitly added to the name in 2025 — emphasis shifted to alerting, not just log collection.

**Code examples:** [references/integrity-and-logging.md](references/integrity-and-logging.md#10-logging--alerting) — `log/slog` setup, sensitive data avoidance (passwords, tokens, card numbers, reset tokens), audit middleware, Prometheus metrics.

### Rules

- Log significant events: login/logout, failed attempts, permission changes, critical operations.
- Sensitive data never in logs. Passwords, tokens, card numbers.
- Structured logging: data as fields, not string concatenation. `JSONHandler` escapes values — injection impossible.
- Format suitable for automated analysis (JSON).
- Alert on anomalies: ">50 auth errors in 5 minutes", "spike in 5xx".

### Recommended libraries & tools

- **`log/slog`** (Go 1.21+) — structured logging in stdlib. Preferred since 2024.
- **[zerolog](https://github.com/rs/zerolog)** — zero-allocation, JSON. For high-throughput (>100k req/s).
- **[zap](https://go.uber.org/zap)** — fast structured logger from Uber.
- **[sloggin](https://github.com/samber/slog-gin)** / **[slog-echo](https://github.com/samber/slog-echo)** — slog integration with frameworks.
- **[Prometheus](https://prometheus.io/)** + **[client_golang](https://github.com/prometheus/client_golang)** — metrics and alerting.
- **Alerting pipeline** — JSON logs → [Vector](https://vector.dev/) or Promtail → Loki/Elasticsearch → Grafana.

---

## 11. External Objects — foreign data must not control logic

> OWASP: cross-cutting — Insecure Design (A04/A06) + Injection (A03/A05).

**Code examples:** [references/external-safety.md](references/external-safety.md#11-external-objects) — path traversal, mass assignment, open redirect, external data validation, config whitelist.

### Rules

- File paths: `filepath.Abs` + prefix check. Never `filepath.Join` with raw input alone. Go 1.24+ prefer `os.Root`/`os.OpenRoot`.
- Data updates: typed structs with field whitelist, not `map[string]interface{}`. Struct-based binding (Gin/Echo/Fiber) is whitelist by default.
- Redirect URL: relative paths only or domain whitelist.
- External API/webhook data: full validation before use.
- Configuration: whitelist of allowed keys.

### Recommended libraries & tools

- **`path/filepath`** — `filepath.Clean`, `filepath.Abs`. Always verify with `strings.HasPrefix`.
- **`os.Root` / `os.OpenRoot`** (Go 1.24+) — prevents escaping root directory, even through symlinks.
- **`net/url`** — URL parsing and validation.
- **[go-playground/validator](https://github.com/go-playground/validator)** — dozens of built-in rules.
- **Struct-based binding** (Gin/Echo/Fiber) — JSON→struct ignores undeclared fields.

---

## 12. External Requests — limit server-side request destinations

> OWASP: A10:2021 (SSRF) → consolidated into A01:2025.

**Code examples:** [references/external-safety.md](references/external-safety.md#12-external-requests-ssrf) — URL/host whitelist, private IP blocking, safe HTTP client, DNS rebinding protection, response proxying.

### Rules

- Server-side request URLs: whitelist of protocols, hosts, ports.
- Block requests to internal addresses (localhost, 169.254.x.x, private subnets). Check ALL resolved IPs.
- Never return raw external service responses to clients. Extract only needed data, limit size with `io.LimitReader`.
- If business logic allows, don't let users specify arbitrary URLs. Offer a choice.
- HTTP client: always with timeout, always with redirect validation, always check redirect targets for private IPs.

### Recommended libraries & tools

- **`net`** — IP checking (`net.ParseIP`, `net.ParseCIDR`, `net.IP.IsPrivate` since Go 1.17).
- **`net/http`** — `http.Client` with `Timeout` and `CheckRedirect`. Default client has no timeout — always create your own.
- **`io.LimitReader`** — limit response body size. Without it, an attacker forces the server to download a gigabyte response.
- **DNS rebinding protection** — resolve once, check all IPs, connect via verified IP with explicit `ServerName` in `tls.Config`. For production, implement a retry loop over all resolved addresses — the first address may be unreachable.

---
---

## 13. AI-Assisted Development — process and code in the age of agents

> OWASP: intersects with OWASP Top 10 for LLM Applications 2025 (LLM01 Prompt Injection, LLM02 Insecure Output Handling, LLM05 Improper Output Handling, LLM08 Excessive Agency) and all twelve sections above — because agent-written code falls into the same vulnerability categories as human-written code.

As of mid-2026, "ask an agent to write a handler" is as routine as searching Stack Overflow was a decade ago. One thing changed: the agent edits files, runs commands, reads dependencies and issues, sometimes deploys. This introduces two new risk classes:

1. **Generated code quality.** Models are trained on public repos — full of `fmt.Sprintf` in SQL, `math/rand` for tokens, `text/template` for HTML, and middleware with swallowed errors.
2. **Process security.** The agent reads external data (issue comments, READMEs of dependencies, web pages, MCP server responses) — any of these strings can contain instructions the model treats as commands (prompt injection, including indirect injection through repo file content).

### Rules

- Agent context is pinned in the repository (`AGENTS.md`/`SECURITY.md`/skills), documenting security invariants.
- Specifications and tests are written before code generation; the agent implements them.
- Agent tools run in a sandbox without access to production secrets; tool permissions are granted minimally.
- AI-PRs pass the same CI gates as human ones: `go vet`, `golangci-lint`, `govulncheck`, `go test -race`. No exemptions for generated code.
- Sensitive changes (auth, crypto, data access, external requests) require mandatory human review.
- Agent tool-calls are logged at production audit-log level: `tool`, `args`, `result`, `initiator`.

### Recommended libraries & tools

- **`AGENTS.md` / `SECURITY.md`** in the repo root — minimal but measurably effective way to set agent context.
- **OWASP Top 10 for LLM Applications 2025** ([genai.owasp.org](https://genai.owasp.org/llm-top-10/)) — separate risk list for LLM systems: Prompt Injection, Insecure Output Handling, Sensitive Information Disclosure, Excessive Agency.
- **Sandboxing for the agent**: dev containers, Docker-based runners, gVisor/Firecracker for strict isolation. Minimum: `docker run --network=none --read-only` for test execution.
- **Tool-call logging**: same `slog` JSON logs as in production, plus full prompt-input/output storage in a protected store — for post-incident prompt injection analysis.
- **`govulncheck` and `gosec`** on every AI-PR, mandatory (see sections 6 and Linters).
- **Secret scanners in pre-commit**: `gitleaks`, `trufflehog`. If the agent accidentally placed `.env` in a diff, the gate must be before push, not after.
- **Prompt injection scanner for code and skills**: [ipi-check](https://github.com/v0lka/ipi-check) — scan everything fed to a coding agent.

---
## Linters — automate what you shouldn't have to remember

`go vet` is necessary hygiene but not a full security suite. **[golangci-lint](https://golangci-lint.run/)** unifies 150+ linters.

**Full configuration and CI setup:** [references/linters.md](references/linters.md) — `.golangci.yml`, linter reference table, gosec rules, CI/CD workflow, adoption strategy.

### Key security linters

| Linter | Primary concern |
|--------|----------------|
| **gosec** | SQL injection, hardcoded secrets, weak crypto, path traversal, file permissions |
| **bodyclose** | Unclosed HTTP response bodies — TCP connection leaks |
| **noctx** | HTTP requests without context — goroutine leaks |
| **sqlclosecheck + rowserrcheck** | Unclosed DB resources + unchecked iteration errors |
| **contextcheck** | Broken context propagation chains |
| **exhaustive** | Missing enum values in switch |
| **makezero** | Slice initialization + append bugs |

### Running

```bash
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
golangci-lint run --new-from-rev=HEAD~1   # changed files only
golangci-lint run ./...                   # full check (CI)
```

### Adoption strategy

1. Start with `golangci-lint run --new-from-rev=main` — checks only new code.
2. Add linters one at a time, starting with gosec and errcheck.
3. Fix warnings in the current PR, don't accumulate technical debt.
4. If noisy on legitimate code, use `//nolint:lintername // reason` — don't disable globally.

---

## Checklist

The full 60+ item checklist is in [references/checklist.md](references/checklist.md), organized by OWASP category.
