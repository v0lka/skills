# Security Checklist

Comprehensive checklist for secure Go development, organized by OWASP Top 10 categories.

## Access Control (A01:2021 / A01:2025)

- [ ] Access to all non-public resources denied by default
- [ ] Every operation checks data ownership for the current user
- [ ] Authorization logic centralized in middleware, reused across routes
- [ ] Access rules covered by tests

## Data Protection (A02:2021 → A04:2025)

- [ ] Sensitive data identified and classified
- [ ] Unnecessary sensitive data not stored
- [ ] Passwords stored via bcrypt/Argon2 (`golang.org/x/crypto`)
- [ ] Data transmitted over TLS
- [ ] No secrets in the repository (verified by gitleaks)
- [ ] Tokens and keys generated via `crypto/rand`

## Input & Output (A03:2021 → A05:2025)

- [ ] SQL — only parameterized queries (or sqlc/ORM)
- [ ] OS commands — `exec.Command` without `sh -c`
- [ ] HTML — `html/template`, not `text/template`
- [ ] Input validated on the server (validator/ozzo-validation)
- [ ] Output sanitized context-dependently

## Architecture (A04:2021 → A06:2025)

- [ ] Every feature defines allowed actions and limits
- [ ] Constraints validated on the server
- [ ] Resource consumption limits in place
- [ ] Each component gets minimal permissions
- [ ] Concurrent operations protected by transactions (`FOR UPDATE`)

## Configuration (A05:2021 → A02:2025)

- [ ] Production mode by default (`GIN_MODE=release`)
- [ ] Stack traces and `err.Error()` not returned to clients
- [ ] Security headers configured (CSP, X-Frame-Options, HSTS, nosniff)
- [ ] Dockerfile: minimal image with pinned sha256 digest, non-root, nothing unnecessary
- [ ] File uploads: type check + size limit
- [ ] Build flags: `-trimpath` (strips paths); `-s -w` only if profiling/pprof is not needed

## Dependencies (A06:2021 → A03:2025 — Software Supply Chain Failures; expanded beyond outdated deps to include typosquatting, compromised maintainers, registry substitution)

- [ ] govulncheck in CI
- [ ] `go mod tidy` — no unused dependencies
- [ ] `go mod verify` — module integrity verified
- [ ] Versions pinned, updated regularly
- [ ] Go toolchain current

## Authentication (A07:2021 / A07:2025)

- [ ] Authentication via ready-made library (golang-jwt/v5, go-oidc) or identity platform (Kratos, SuperTokens, ZITADEL)
- [ ] JWT: `exp` + algorithm check (EdDSA/RS256 preferred for new systems)
- [ ] Rate limiting on login by IP + by account
- [ ] Uniform error responses (no user enumeration)
- [ ] Session invalidated on logout (denylist or server record deletion)

## Error Handling (A10:2025, new in 2025)

- [ ] Long-lived workers — `defer recover()` at isolation boundary
- [ ] Multi-step business operations — in transactions with `defer tx.Rollback()`
- [ ] Recovery middleware doesn't leak internals
- [ ] Resources cleaned up on errors (`defer`)

## Integrity (A08:2021 / A08:2025; in 2025 partially redistributed: supply chain → A03, data integrity remained as A08)

- [ ] Client data not deserialized via gob without signature
- [ ] Cookies signed (gorilla/securecookie or HMAC)
- [ ] CSRF protection (Go 1.25+ `http.CrossOriginProtection` or gorilla/csrf)
- [ ] `go mod verify` in CI
- [ ] CDN resources with SRI

## Logging & Alerting (A09:2021 / A09:2025; emphasis shifted to alerting in 2025)

- [ ] Significant events logged (login, logout, auth errors)
- [ ] Sensitive data not in logs
- [ ] Structured logging (slog/zerolog/zap)
- [ ] Alerting on anomalies

## External Objects (cross-cutting: A04/A06 + A03/A05)

- [ ] File paths — `filepath.Abs` + prefix check
- [ ] Data updates — typed structs (not `map[string]interface{}`)
- [ ] Redirect URLs — relative only or whitelist
- [ ] External data — full validation

## External Requests (A10:2021 SSRF → A01:2025)

- [ ] Server-side request URLs — whitelist
- [ ] Private IPs blocked
- [ ] Raw responses not returned to clients
- [ ] HTTP client with timeout and redirect validation

## AI-Assisted Development (OWASP LLM Top 10 2025)

- [ ] `AGENTS.md`/`SECURITY.md` pin security invariants of the project
- [ ] Agent skills connected: secure-go, idiomatic-go, sdd, security-policy-generator
- [ ] Spec-Driven Development: spec and tests — before code generation
- [ ] Agent works in a sandbox; production secrets inaccessible
- [ ] Tool permissions granted minimally
- [ ] AI-PRs pass all the same CI gates: vet/lint/govulncheck/race
- [ ] Sensitive changes (auth/crypto/access) undergo manual review
- [ ] Agent tool-calls are logged as audit events
