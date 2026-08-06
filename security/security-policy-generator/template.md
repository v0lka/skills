# Security Policy

> **This is a security *policy*, not an audit report.** It defines the project's threat model and the secure coding rules every contributor and coding agent must follow. It does **not** record whether the current codebase complies with these rules — compliance verification belongs in code review, audits, or the issue tracker, never in this file.

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
| Agent system prompts     | High        | System/role prompts — extraction reveals guardrails & logic |
| Agent credentials & tool secrets | Critical | API keys/OAuth tokens the agent holds; scope = blast radius |
| Agent memory & context   | High/Critical | Long-term memory, vector DB contents, conversation history |
| Tool & MCP definitions   | Medium/High  | Tool schemas, descriptions, permission mappings |
| Agent-generated artifacts | Medium      | Code, plans, API calls produced by agent execution |
| Training / embedding data | High        | Fine-tune datasets, embeddings (poisoning vector) |
}}

### Threat Actors

{{ Who might attack the system and what are their capabilities?

- **Opportunistic attacker** — automated scanners, script kiddies, credential stuffing
- **Motivated external attacker** — targeted exploitation, social engineering
- **Malicious insider** — employee or contractor with partial system access
- **Compromised supply chain** — malicious dependency, compromised CI/CD
- **AI coding agent (misconfigured)** — overly permissive agent introducing vulnerabilities
- **Prompt-injection adversary (ASI01/ASI06)** — plants hostile instructions in documents, web pages, tool outputs, or memory that the agent reads and follows
- **Malicious tool / plugin author (ASI04)** — publishes a compromised tool, MCP server, or schema with deceptive descriptions to exploit dynamic integration
- **Compromised agent identity (ASI03/ASI07)** — forges or inherits agent credentials to act with delegated authority or impersonate another agent
- **Trust exploitation target (ASI09)** — the human operator who over-trusts confident agent output and skips verification
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
- **Agent prompt inputs** — user messages, RAG-retrieved documents, web pages, and tool outputs that enter the model context (ASI01 indirect injection)
- **Agent tool / function-calling surface** — every tool the agent may invoke, including side-effecting operations (ASI02)
- **External tool & MCP registries** — dynamically integrated tools, plugins, and schemas whose descriptions and permissions may be forged (ASI04)
- **Agent-generated code / shell execution** — sandboxed or unsandboxed environments running model output (ASI05)
- **Agent memory stores** — vector DBs, long-term memory, and conversation logs writable by the agent (ASI06)
- **Inter-agent message channels** — orchestration buses, delegation protocols, and message queues between agents (ASI07)
- **Human approval / HITL gates** — review steps where prompt-injection or approval-fatigue attacks exploit operator trust (ASI09)
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

{{ If the project includes agentic components (agents that plan, act, call tools,
or communicate with other agents), add the agent trust boundaries. The most
important boundary is the one between **trusted developer instructions** and
**untrusted content the agent reads at runtime**, because both arrive as natural
language the model treats identically (root cause of ASI01).

```
┌──────────────────────────────────────────────────────┐
│  Developer / Operator zone (trusted instructions)    │
│  System prompts, tool definitions, guardrails        │
└───────────────────┬──────────────────────────────────┘
                    │ instruction/data separation
┌───────────────────▼──────────────────────────────────┐
│  Agent reasoning zone (semi-trusted, boundary scope) │
│  Model context, plans, tool-call decisions           │
└─────────────────┬─┬──────────────────────────────────┘
    untrusted     │ │  least-agency enforcement
    content in ───┘ └──→ side-effecting tools
┌──────────────────────────────────────────────────────┐
│  Untrusted content sources (ASI01 vectors)           │
│  User input, RAG docs, web pages, tool outputs       │
└──────────────────────────────────────────────────────┘
                    │ per-agent identity + authZ
┌───────────────────▼──────────────────────────────────┐
│  Execution / Action zone (tools, APIs, shells, DBs)  │
│  Memory stores, inter-agent channels (ASI06/ASI07)   │
└──────────────────────────────────────────────────────┘
```
}}

### Known Risks & Accepted Trade-offs

{{ List inherent architectural risks that the design knowingly accepts as a
trade-off — NOT findings about what the current code is missing versus this
policy. A known risk here is a design-level decision (e.g., "MVP runs all
services behind a single shared database user to reduce operational overhead"),
not a compliance gap ("input validation not yet implemented on endpoint Y").
Compliance gaps belong in code review or the issue tracker, never in this file.

| Risk                              | Severity | Mitigation / Rationale                |
| --------------------------------- | -------- | ------------------------------------- |
| Example: Single shared DB user for MVP | Medium   | Accepted to reduce ops overhead; tracked in #1234 |
}}

---

## Security Architecture

{{ Use this section to describe the security domains this architecture involves
and what the policy requires of each. Frame each subsection around what
contributors and agents MUST do (the rules and expectations), not an inventory
of what the code currently implements or lacks. }}

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

## Agentic Application Security

{{ This section applies to projects that build AI agents — systems that
plan, act, call tools, remember across sessions, or communicate with other
agents on behalf of users. It follows the OWASP Top 10 for Agentic
Applications (2026), identifiers ASI01–ASI10.

If the project is a pure chatbot or RAG setup with NO tool use and NO
multi-agent coordination, classical controls and the OWASP Top 10 for LLM
Applications suffice; this section may be omitted. The moment the system
takes actions on behalf of a user, this section is REQUIRED.

A single core principle runs through every category below: **least agency** —
grant an agent only the minimum autonomy required to complete a safe, bounded
task, the agentic counterpart of least privilege. One that passes the least
privilege test (correct reach) can still fail the least agency test (excessive
latitude within that reach). Ask both about every agent you deploy.

Fill each subsection with the **rules and requirements** this project imposes for that category — what contributors and agents MUST do. Do NOT turn this into a checklist of whether the current code passes each category; that is an audit and does not belong in SECURITY.md. }}

### ASI01 — Agent Goal Hijacking

{{ An attacker redirects what the agent is trying to accomplish, usually through
text the agent reads. Agents represent plans in natural language, so a trusted
instruction from the user and a hostile instruction hidden inside a retrieved
document look identical to the model.

Patterns: direct goal manipulation, indirect instruction injection (via RAG
docs / tool outputs / web pages / emails), recursive hijacking (a modified goal
propagates through the agent's own reasoning chain), cross-context injection.

Document:
- Instruction/data separation — how trusted system instructions are delimited from untrusted retrieved content
- Input/output filtering — sanitization and classification of content entering context
- Privilege separation between user instructions and data
- Canary tokens / prompt-extraction detection
- Whether outputs of untrusted sources are treated as data, never as commands
}}

### ASI02 — Tool Misuse and Exploitation

{{ The agent abuses tools it is legitimately permitted to use, through loops,
unsafe chaining, or runaway volume. Traditional access control has no answer,
because every individual action is allowed.

Patterns: recursive tool calls that loop until resources are exhausted, unsafe
tool composition (individually harmless tools become dangerous in sequence),
tool budget exhaustion from sheer invocation volume, cross-tool state leakage.

Document:
- Per-tool permission scoping (least privilege for each tool)
- Parameter schemas validated before execution (type, range, allowlists)
- Dangerous operations (DELETE, DROP, EXEC, send payment) programmatically restricted regardless of agent request
- Tool-call allowlist (not denylist), rate/budget limits, loop-depth caps
- Human-approval gates for irreversible or high-impact actions
}}

### ASI03 — Agent Identity and Privilege Abuse

{{ Delegated authority or unclear agent identity leads to actions nobody
authorized. An orchestration agent holding credentials for five downstream
agents is a single point of compromise with the combined permissions of all six.

Patterns: agent impersonation, cross-agent trust abuse, identity inheritance
(privileges assumed through a chain), role bypass, confused-deputy attacks.

Document:
- Whether each agent operates with its own verified identity
- Agent credential scoping (minimum required, rotated regularly)
- Confused-deputy prevention — can a low-privilege caller trick a high-privilege agent?
- Audit logging with the verified principal identity on every action
- Whether delegation chains preserve and record the original caller
}}

### ASI04 — Agentic Supply Chain Compromise

{{ External agents, tools, schemas, or prompts that the agent trusts and imports
are themselves compromised. Unlike classical software supply chain, composition
happens at runtime — the agent may discover and integrate tools dynamically.

Patterns: schema manipulation, description deception (a tool's own description
misleads the agent), permission misrepresentation, registry poisoning.

Document:
- Third-party tools, MCP servers, and plugins vetted and pinned to specific versions
- Tool descriptions reviewed for manipulative language before integration
- Provenance verification for frameworks, model files, and dependencies
- Sandbox testing of new/updated tools before production
- Whether dynamic tool discovery is allowed and how it is constrained
}}

### ASI05 — Unexpected Code Execution

{{ Code the agent generates or triggers runs without adequate validation or
isolation. This is the most familiar risk to appsec teams, which cuts both ways
— familiarity tempts teams to assume existing controls cover paths a developer
never approved.

Patterns: agent-generated code run without validation, direct shell command
invocation, unsafe evaluation of dynamic expressions, command injection through
agent output.

Document:
- Sandbox isolation for code execution (restricted FS, no network unless needed)
- Human approval (REVIEW gate) for high-risk execution
- Scanning of execution arguments for malicious patterns
- Ephemeral, cleaned-up execution environments
- Resource limits (CPU, memory, time) on executed code
}}

### ASI06 — Memory and Context Poisoning

{{ Injected or leaked memory shapes reasoning and actions long after the
injection happened. Persistence makes this worse than goal hijack — clean up the
poisoned source and the poison may still sit in the agent's memory store,
influencing decisions weeks later.

Patterns: long-term memory store corruption, malicious context insertion,
reasoning-state alteration across sessions, sensitive memory-content leak.

Document:
- Validation of persistent memory (vector DB, long-term store) before write and read
- Scanning of memory-destined values for poisoning patterns (instruction overrides, false authorization claims)
- Ability to identify and purge poisoned memories; monitoring for anomalous writes
- Session/context isolation so one user's context cannot contaminate another's
- Retention/TTL policy on agent memory
}}

### ASI07 — Insecure Inter-Agent Communication

{{ Messages between agents, planners, and executors get intercepted, forged, or
modified. Multi-agent systems build message buses without consistently applying
the authentication, encryption, and integrity checks any other bus requires.

Patterns: agent-in-the-middle interception, message injection, message spoofing
(a forged message appears to come from a trusted agent).

Document:
- Whether agent-to-agent messages are authenticated and integrity-protected (signed/encrypted)
- Delegation chain depth limited and monitored
- Impersonation resistance — can a compromised agent forge another agent or the orchestrator?
- Explicitly defined cross-agent permissions — does Agent B trust Agent A without verification?
- Transport security on the message channel (mTLS, signed tokens)
}}

### ASI08 — Cascading Agent Failures

{{ A small failure propagates through connected tools, dependencies, and trust
chains. The agentic twist: agents route around failures creatively — a blocked
tool may trigger an improvised, unvalidated alternative, turning a clean failure
into an unpredictable one.

Patterns: tool-chain failures, agent-dependency failures, resource-exhaustion
cascades, broken trust chains.

Document:
- Circuit breakers to prevent failure propagation across agents
- Fail-closed behavior (deny actions) when authorization/policy service is unreachable
- Bulkhead / failure-isolation between agent groups
- Safe fallback behavior defined per dependency failure
- Monitoring/alerting for deny-rate spikes and failure cascades
}}

### ASI09 — Human-Agent Trust Exploitation

{{ People over-trust confident-sounding agent output and skip verification.
Agents write fluently and never sound unsure; humans reliably read fluency as
competence, and the times the agent is wrong look exactly like the times it is
right. The vulnerable component is a person.

Patterns: authority misrepresentation, misleading (plausible, wrong)
explanations, overconfidence projection, responsibility diffusion.

Document:
- Whether human approval workflows show raw, unmodified intent (not an agent-generated summary that may deceive)
- Rate-limiting of high-frequency approval requests (anti-approval-fatigue)
- AI-generated labeling so operators can calibrate trust
- Approval justifications generated by the policy engine, not by the agent itself
- Operator training on "distrust the answer that sounds certain"
}}

### ASI10 — Rogue Agents

{{ Agents operate outside intended objectives through goal drift, collusion, or
emergent behavior — without anyone necessarily attacking anything.

Patterns: goal drift (gradual wander from the original objective), agent
collusion (several agents coordinate toward something unintended), reward
hacking (optimizing a proxy metric instead of the real goal), runaway autonomy
(exceeding designed boundaries).

Document:
- Behavioral-drift monitoring (action volume, deny rate, delegation depth)
- Full auditable receipt chain — can you reconstruct what happened and why?
- Kill-switch / circuit-breaker mechanisms to halt anomalous agents
- Periodic alignment checks (goals verified against operator intent, eval benchmarks)
- Bounds on autonomy (max steps, max scope, time-boxed sessions)
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

9. **No mixing trusted instructions with untrusted data (ASI01)** — When
   building agent prompts, NEVER concatenate untrusted content (user input,
   RAG results, tool outputs, web pages) into the instruction stream without
   delimiters and clear data/instruction separation. Treat all retrieved or
   tool-produced text as potentially containing adversarial instructions.

10. **No unbounded tool autonomy (ASI02/ASI05)** — Do not wire an agent to
    invoke side-effecting tools (DB writes, shell, payments, deletions) without
    a tool-call allowlist, parameter validation, loop/budget caps, and a
    human-approval gate for irreversible operations.

11. **No unsandboxed agent-generated code execution (ASI05)** — Do not run
    model-generated code or shell commands outside a sandbox with network
    restrictions, resource limits, and ephemeral cleanup.

12. **No implicit cross-agent trust (ASI03/ASI07)** — Do not implement
    agent-to-agent delegation or identity inheritance without per-agent
    verified identities, scoped credentials, message authentication, and
    delegation-depth limits.
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

{{ Additional guidelines when the project includes AGENTIC components —
apply the least-agency principle alongside the rules above:

- **Apply least agency (ASI02/ASI10)** — Grant the agent only the minimum
  autonomy needed for a bounded task: restrict tool sets, cap loop depth
  and step counts, and scope credentials per-agent rather than per-process.

- **Separate instructions from data (ASI01/ASI06)** — When constructing or
  editing agent prompts, use explicit delimiters between trusted developer
  instructions and any untrusted content (retrieved docs, tool output, user
  text). Assume retrieved text can contain hostile instructions.

- **Prefer fail-closed delegation (ASI07/ASI08)** — When wiring inter-agent
  communication, default to denying a delegation if the source agent cannot
  be authenticated or the policy service is unreachable; do not let agents
  improvise unvalidated fallbacks around a blocked tool.

- **Make agent actions auditable (ASI03/ASI10)** — Ensure every agent action
  is logged with the verified principal identity, the tool invoked, the
  arguments, and a reconstructable receipt chain — so a post-incident review
  can answer "who/what decided this?".

- **Do not auto-approve confident output (ASI09)** — When a change adds or
  modifies a human-approval gate, ensure the operator sees the raw intended
  action, not an agent-generated summary; rate-limit repeated approvals to
  prevent fatigue attacks.
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
