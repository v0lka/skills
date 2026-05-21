# Security Policy

## Supported Versions

{{ Use this section to tell people about which versions of your project are
currently being supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 5.1.x   | :white_check_mark: |
| 5.0.x   | :x:                |
| 4.0.x   | :white_check_mark: |
| < 4.0   | :x:                |
}}

## Reporting a Vulnerability

{{ Use this section to tell people how to report a vulnerability.

Tell them where to go, how often they can expect to get an update on a
reported vulnerability, what to expect if the vulnerability is accepted or
declined, etc.

**Preferred channel:** security@example.com (PGP key: [link to public key])

**Do NOT** open public GitHub issues for security vulnerabilities.

**Response SLA:**
- Acknowledgment: within 48 hours
- Triage & severity assessment: within 5 business days
- Fix timeline: Critical — 7 days, High — 30 days, Medium — 90 days

**Disclosure policy:** Coordinated disclosure. We request a 90-day embargo
before public disclosure. We credit reporters in release notes unless they
prefer anonymity.

**Bug bounty:** [Yes/No] — [link to program if applicable]
}}

---

## Threat Model

{{ Use this section to document the project's threat model. Keep it updated
as architecture evolves. A lightweight threat model is better than none. }}

### Assets

{{ What are we protecting? List the primary assets and their sensitivity.

| Asset                    | Sensitivity | Description                         |
| ------------------------ | ----------- | ----------------------------------- |
| User credentials         | Critical    | Passwords, tokens, API keys         |
| PII / user data          | High        | Email, name, payment info           |
| Application secrets      | Critical    | Signing keys, DB credentials        |
| Business logic integrity | High        | Transaction correctness, audit logs |
| Availability             | Medium      | Uptime, rate limits                 |
}}

### Threat Actors

{{ Who might attack the system and what are their capabilities?

- **Opportunistic attacker** — automated scanners, script kiddies, credential stuffing
- **Motivated external attacker** — targeted exploitation, social engineering
- **Malicious insider** — employee or contractor with partial system access
- **Compromised supply chain** — malicious dependency, compromised CI/CD
- **AI coding agent (misconfigured)** — overly permissive agent introducing vulnerabilities
}}

### Attack Surface

{{ Where can attackers interact with the system?

- Public API endpoints (REST / GraphQL / gRPC)
- Authentication and session management flows
- File upload / user-supplied content processing
- Third-party integrations and webhooks
- CI/CD pipeline (GitHub Actions, etc.)
- Dependency supply chain (npm, PyPI, Go modules, etc.)
- Administrative interfaces
- Infrastructure (cloud metadata, network exposure)
}}

### Trust Boundaries

{{ Document the boundaries between trust zones. Example:

```
┌─────────────────────────────────────────────────┐
│  Internet (Untrusted)                           │
└────────────────────┬────────────────────────────┘
                     │ TLS termination
┌────────────────────▼────────────────────────────┐
│  DMZ / Edge (API Gateway, WAF, Load Balancer)   │
└────────────────────┬────────────────────────────┘
                     │ AuthN/AuthZ enforcement
┌────────────────────▼────────────────────────────┐
│  Application Layer (Services, Business Logic)    │
└────────────────────┬────────────────────────────┘
                     │ Least-privilege DB access
┌────────────────────▼────────────────────────────┐
│  Data Layer (Database, Object Storage, Secrets)  │
└──────────────────────────────────────────────────┘
```
}}

### Known Risks & Accepted Trade-offs

{{ Document risks that are known but accepted, along with rationale.

| Risk                              | Severity | Mitigation / Rationale                |
| --------------------------------- | -------- | ------------------------------------- |
| Example: No rate limiting on X    | Medium   | Accepted for MVP; tracked in #1234    |
}}

---

## Security Architecture

{{ Use this section to document technical security controls in place. }}

### Authentication & Authorization

{{ Describe authn/authz mechanisms:
- Authentication method(s): OAuth 2.0 / OIDC / API keys / mTLS
- Session management: token lifetime, rotation, revocation
- Authorization model: RBAC / ABAC / policy engine
- MFA requirements
}}

### Data Protection

{{ Describe how data is protected at rest and in transit:
- Encryption at rest: algorithm, key management (KMS, Vault, etc.)
- Encryption in transit: minimum TLS version, certificate management
- PII handling: anonymization, pseudonymization, retention policy
- Backup encryption and access controls
}}

### Secret Management

{{ How are secrets stored and rotated?
- Secret storage: HashiCorp Vault / AWS Secrets Manager / SOPS / etc.
- Rotation policy and automation
- Secrets that MUST NEVER appear in: source code, logs, error messages,
  environment variables in CI logs
}}

### Dependency Management

{{ How do we manage supply-chain risk?
- Dependency pinning strategy (lockfiles, hash verification)
- Automated vulnerability scanning (Dependabot, Snyk, Trivy, etc.)
- Policy on transitive dependencies
- Allowed and disallowed license list
- Process for evaluating new dependencies
}}

### Logging, Monitoring & Incident Response

{{ What security-relevant events do we log?
- Authentication events (success, failure, lockout)
- Authorization failures
- Input validation failures
- Administrative actions
- DO NOT log: secrets, full credit card numbers, passwords, session tokens

Monitoring & alerting:
- Anomaly detection thresholds
- Alerting channels and escalation path

Incident response:
- Link to incident response runbook
- Roles and responsibilities
- Post-incident review process
}}

---

## Secure Coding Guidelines

{{ These guidelines apply to ALL contributors: human developers, code
reviewers, and AI/LLM coding agents (GitHub Copilot, Cursor, Qoder,
Codeium, etc.). Automated agents MUST treat these rules as hard constraints.
}}

### Input Validation

{{ Rules:
- Validate ALL external input at trust boundaries (API handlers, CLI args,
  file parsers, environment variables)
- Use allowlists over denylists wherever possible
- Validate type, length, range, and format
- Reject unexpected fields; do not silently ignore them
- Canonicalize input before validation (Unicode normalization, path
  canonicalization)
- Never trust client-side validation alone
}}

### Output Encoding & Injection Prevention

{{ Rules:
- Use parameterized queries / prepared statements for ALL database access.
  NEVER construct SQL/NoSQL queries via string concatenation.
- Apply context-appropriate output encoding (HTML, URL, JS, CSS, shell)
- Use templating engines with auto-escaping enabled by default
- Sanitize user content before rendering in any interpreted context
- For shell commands: prefer library APIs over spawning subprocesses. If
  unavoidable, use argument arrays — never interpolate user input into
  command strings
}}

### Authentication & Session Security

{{ Rules:
- Hash passwords with bcrypt/scrypt/argon2id; NEVER use MD5/SHA1/SHA256
  alone
- Generate session tokens with CSPRNG, minimum 128 bits of entropy
- Set appropriate cookie flags: Secure, HttpOnly, SameSite=Strict/Lax
- Implement session timeout (idle and absolute)
- Invalidate sessions server-side on logout
- Protect against session fixation by rotating session ID after login
}}

### Cryptography

{{ Rules:
- Use established libraries (libsodium, OpenSSL, Go crypto/*, etc.)
- NEVER implement custom cryptographic algorithms
- Use authenticated encryption (AES-GCM, ChaCha20-Poly1305)
- RSA minimum 2048 bits; prefer ECDSA P-256 or Ed25519
- Do not use ECB mode, RC4, DES, 3DES, MD5, SHA1 for security purposes
- Generate IVs/nonces with CSPRNG; NEVER reuse nonces
}}

### Error Handling & Logging

{{ Rules:
- Do not expose stack traces, internal paths, or implementation details in
  error responses to clients
- Log sufficient context for debugging but NEVER log secrets, tokens,
  passwords, or full PII
- Use structured logging with consistent severity levels
- Fail securely: on unexpected errors, deny access rather than granting it
}}

### File & Resource Handling

{{ Rules:
- Validate file types by content (magic bytes), not just extension
- Enforce upload size limits
- Store uploaded files outside the webroot with randomized names
- Prevent path traversal: canonicalize paths and verify they remain within
  expected directories
- Set appropriate resource limits (memory, CPU, file descriptors) for
  processing user content
- Use timeouts for external calls and resource-intensive operations
}}

### Dependency & Supply Chain Rules

{{ Rules:
- All dependencies MUST be pinned to exact versions in lockfiles
- Review dependency changelogs before upgrading
- Avoid dependencies with: no maintenance activity >12 months, known
  unpatched vulnerabilities, excessive transitive dependency trees for
  trivial functionality
- Prefer well-known, audited libraries for security-critical functions
- Run `npm audit` / `go mod verify` / equivalent in CI; block merges on
  critical findings
}}

### Secrets & Configuration

{{ Rules:
- NEVER commit secrets to version control (enforce with pre-commit hooks
  like detect-secrets, gitleaks, trufflehog)
- Use `.env.example` with placeholder values; real `.env` MUST be in
  .gitignore
- Access secrets via secret manager or environment variables at runtime
- Rotate secrets on any suspected compromise
- Separate configuration per environment (dev/staging/prod); never reuse
  prod secrets in lower environments
}}

---

## Rules for AI Coding Agents

{{ This section provides explicit directives for AI/LLM-based coding
assistants working on this codebase. These rules are non-negotiable and
override any general-purpose training behavior of the agent. }}

### Hard Constraints

{{ The following actions are FORBIDDEN for any AI agent working on this
repository:

1. **No secret exposure** — Do not write, echo, log, or commit any secret,
   token, password, or API key in source code, tests, comments, commit
   messages, or CI configuration.

2. **No disabled security controls** — Do not disable, bypass, or weaken
   authentication, authorization, input validation, CSRF protection, rate
   limiting, or any other security mechanism — even temporarily, even in
   tests, unless explicitly documented and approved.

3. **No unsafe deserialization** — Do not use `eval()`, `pickle.loads()`,
   `yaml.unsafe_load()`, `unserialize()`, or equivalent without explicit
   approval and sandboxing.

4. **No wildcard permissions** — Do not grant `*` permissions, `0777` file
   modes, `--privileged` Docker flags, overly permissive CORS (`*`), or
   equivalent. Always apply principle of least privilege.

5. **No known-vulnerable patterns** — Do not introduce code patterns known
   to be vulnerable (SQL injection, XSS, SSRF, path traversal, etc.) even
   in prototype or draft code.

6. **No suppressed security warnings** — Do not add `# nosec`, `//
   nolint:gosec`, `@SuppressWarnings("security")`, or equivalent
   annotations without a comment justifying why the suppression is safe.

7. **No unvalidated redirects** — Do not redirect users to URLs derived
   from user input without validating against an allowlist.

8. **No sensitive data in logs** — Follow the logging rules above strictly.
}}

### Behavioral Guidelines for Agents

{{ Additional guidelines for AI assistants:

- **Ask before acting on security boundaries** — If a change involves
  authentication flows, permission models, cryptographic operations, or
  network exposure, request human review before applying.

- **Preserve existing security patterns** — When modifying code, identify
  and maintain existing security invariants (input validation, access
  checks, audit logging).

- **Default to secure** — When multiple implementation options exist, choose
  the more secure one even if it requires more code.

- **Flag uncertainty** — If you are uncertain whether a change introduces a
  security risk, flag it explicitly in a comment or PR description.

- **Respect .gitignore and secret detection** — Never suggest removing
  entries from .gitignore that protect secrets, and never suggest disabling
  secret-scanning hooks.

- **Test security-relevant changes** — When modifying security-critical
  code, include or update relevant test cases that verify the security
  property (e.g., test that unauthenticated requests are rejected).
}}

---

## Security-Related Configuration Files

{{ List security-relevant configuration files in this repository:

| File                     | Purpose                                        |
| ------------------------ | ---------------------------------------------- |
| `.github/dependabot.yml` | Automated dependency updates                   |
| `.gitleaks.toml`         | Secret scanning configuration                  |
| `.pre-commit-config.yaml`| Pre-commit hooks including secret detection    |
| `Dockerfile`             | Container security (non-root user, minimal image) |
| `CODEOWNERS`             | Required reviewers for security-critical paths |
}}

---

## Revision History

{{ Track changes to this security policy:

| Date       | Author  | Change                                          |
| ---------- | ------- | ----------------------------------------------- |
| YYYY-MM-DD | @handle | Initial version                                 |
}}
