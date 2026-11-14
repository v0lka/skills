# Security Architecture

Security checks for an architecture review — focused on *where security controls live in the structure*: trust boundaries, defaults, privileges, secrets, and cryptography choices. This complements (and defers line-level detail to) a dedicated code security review: here you verify that the architecture gives every trust boundary a validator, every protected route an authorizer, and every secret a manager.

**Reporting requirements for this area:** each finding must include the file path plus line numbers or the function name. If a control's presence cannot be confirmed, report it as **Not confirmed** and list the files or configuration that would need inspection — do not assume a control exists because a framework is imported.

## Trust boundaries and input validation

Every place untrusted data enters — HTTP endpoints, message consumers, file uploads, CLI arguments, third-party webhooks — is a trust boundary and must validate input before it reaches internal logic.

What to check:

- Validation happens *at the boundary* (schema validation middleware, typed DTOs), not scattered through business logic — or absent until a crash.
- Allowlist validation (known types, ranges, formats, lengths), not blocklist guessing.
- File uploads constrained: type, size, content checked; stored outside the web root.
- Error responses at boundaries do not echo internals (stack traces, SQL, internals of exception messages) — that is information disclosure.
- Client-side validation is never the only validation.

Detection heuristics:

- Handlers reading raw request data straight into queries or business calls (`request.json` fields used without a schema; `req.body` destructured and passed on).
- SQL built with string concatenation, `%`/`format()`, or f-strings instead of parameterized queries / prepared statements / ORM parameter binding:

```python
# Violation: unvalidated input straight into a query
query = f"SELECT * FROM users WHERE id = {user_id}"
cursor.execute(query)

# Compliant: validated input, parameterized query
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))
```

## Authentication and authorization on endpoints

Authentication answers "who is calling"; authorization answers "may they do this". Both must be enforced server-side, on every protected endpoint — via centralized middleware/decorators, not per-handler improvisation.

What to check:

- Protected routes are behind auth middleware; enumerate routes and look for protected-looking ones (admin, user data, deletions) lacking it.
- Admin/sensitive endpoints enforce *roles or permissions*, not just authentication (a logged-in user is not necessarily an admin).
- Object-level access control (ownership/tenant checks) on every route taking an ID — otherwise IDOR: any authenticated user reads/deletes any record by guessing IDs.
- Authorization decisions centralized (policy service, RBAC/ABAC module), not re-implemented per handler with drifting rules.
- On control failure the system fails *closed* (deny), never open.

Framework-specific smells:

- Flask: routes under `/admin/...` without `@login_required`/`@admin_required`; `@login_required` present but no ownership check on object access.
- Spring: controller methods without `@PreAuthorize` on admin paths.
- Express: handlers registered without `authenticateToken`/`requireRole` middleware in the chain.
- Go: `http.HandlerFunc`s with no auth wrapper in the mux registration.

```python
# Violation: authenticated but not authorized, and no ownership check
@app.route("/api/orders/<int:order_id>", methods=["DELETE"])
@login_required
def delete_order(order_id):
    db.delete(Order.query.get(order_id))     # any user deletes any order

# Compliant: role + ownership enforced
@app.route("/api/orders/<int:order_id>", methods=["DELETE"])
@login_required
def delete_order(order_id):
    order = Order.query.get_or_404(order_id)
    if order.owner_id != current_user.id and not current_user.has_role("admin"):
        abort(403)
    db.session.delete(order)
```

## Secure defaults and fail-closed behavior

The system must be safe as shipped: deny by default, fail closed, no permissive factory settings.

What to check:

- Auth/permission checks that fail open on exception (catch → allow) — a CRITICAL finding.
- CORS configured as a whitelist; `origin: "*"` (especially with credentials) is a finding.
- Debug modes, verbose error pages, and test flags off by default, driven by environment.
- Security headers applied globally by middleware (CSP, HSTS, `X-Content-Type-Options`, frame protection) rather than per-route.
- Session cookies: `Secure`, `HttpOnly`, sensible `SameSite`, bounded lifetime.
- Rate limiting present on authentication and other abuse-prone endpoints.

```python
# Violation: fails open
def check_permission(user, resource):
    try:
        return permission_service.has_access(user, resource)
    except Exception:
        return True                      # control failure → access granted

# Compliant: fails closed
def check_permission(user, resource):
    try:
        return permission_service.has_access(user, resource)
    except Exception:
        logger.exception("permission check failed")
        return False
```

## Least privilege

Every component — service account, database user, container, IAM role — runs with the minimum permissions it needs.

What to check:

- Database grants scoped per service and per operation class: read-only services get `SELECT` only; write services get exactly their tables — not `GRANT ALL ON *.*`.
- Distinct credentials per service (not one shared superuser), per environment.
- IAM roles / container permissions narrowed to specific actions and resources.
- No `sudo` or world-writable paths (`chmod 777`) inside application runtime.
- Endpoints do not demand broader roles than their logic needs (admin-only read endpoints fragment the privilege model).

```sql
-- Violation
GRANT ALL PRIVILEGES ON *.* TO 'app_user'@'%';
-- Compliant
GRANT SELECT, INSERT, UPDATE ON app_db.orders TO 'order_service'@'%';
```

## Secrets management

What to check:

- No credentials, API keys, tokens, or private keys in source or committed config. Search for assignment patterns around `password`, `secret`, `token`, `api_key`, and connection strings embedding passwords (`scheme://user:password@host`).
- Secrets come from the environment or a secret manager (Vault, AWS/GCP secret stores); their absence at startup fails fast with a clear error.
- `.env` files git-ignored; pre-commit secret scanning configured.
- Secrets kept out of logs, error messages, and client-facing responses.

```python
# Violation
API_KEY = "sk-1234567890abcdef"
# Compliant
API_KEY = os.environ["API_KEY"]          # fails fast if missing
```

## Cryptography

What to check:

- No deprecated primitives: MD5, SHA-1 (for security purposes), DES, RC4, 3DES.
- Passwords hashed with a purpose-built KDF (bcrypt, scrypt, Argon2, or PBKDF2 with per-user salt) — never a bare fast hash, never unsalted.
- Randomness for security purposes from a CSPRNG (`secrets` in Python, `crypto.randomBytes` in Node) — never `random.random()`/`Math.random()`.
- Keys generated per environment and stored as secrets, not hardcoded; IVs/nonces never fixed constants.
- TLS: minimum 1.2, prefer 1.3, modern ciphersuites; internal service calls not silently downgraded to plaintext.

```javascript
// Violation: weak randomness for a token
const token = Math.random().toString(36).slice(2);
// Compliant
const token = crypto.randomBytes(32).toString("hex");
```

## Mapping findings to consequences

For each confirmed issue, name the realistic attack or failure path in **Why it matters** — e.g. "any authenticated user can delete arbitrary orders by iterating IDs", "auth outage turns into an open system", "committed API key leaks via repository access". Where applicable, reference the CWE (e.g. CWE-798 hardcoded credentials, CWE-862 missing authorization, CWE-16 configuration) — but the concrete scenario matters more than the number.
