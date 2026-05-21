---
name: security-policy-generator
description: Analyze a project repository and generate a comprehensive SECURITY.md with threat model, security architecture, and secure coding guidelines. Use when the user asks to create a security policy, generate a threat model, fill in a SECURITY.md template, or assess project security posture.
---

# Security Policy Generator

Generate a project-specific SECURITY.md by analyzing the codebase, dependencies, configuration, and architecture. The output covers: supported versions, vulnerability reporting, threat model, security architecture, secure coding rules, and AI agent constraints.

## Workflow

Copy this checklist and track progress:

```
Task Progress:
- [ ] Step 1: Project reconnaissance
- [ ] Step 2: Identify assets and data flows
- [ ] Step 3: Map attack surface
- [ ] Step 4: Assess dependencies and supply chain
- [ ] Step 5: Document security controls in place
- [ ] Step 6: Derive secure coding rules
- [ ] Step 7: Generate SECURITY.md
- [ ] Step 8: Register SECURITY.md in AGENTS.md
- [ ] Step 9: Validate completeness
```

---

## Step 1: Project Reconnaissance

Gather foundational information about the project.

**Automated discovery** — run the reconnaissance script first, then supplement with manual checks:

```bash
# Run the bundled reconnaissance script from the skill directory
bash scripts/recon.sh
```

This script automatically detects:

- Language & framework (package files, source extensions)
- Build tools & deployment indicators
- Security configuration files
- Dependency counts
- Web frameworks, ORMs, auth libraries
- Template engines, serialization libraries, HTTP clients
- GraphQL libraries, cloud SDKs, CMS frameworks
- Test frameworks
- Dangerous code patterns (command execution, eval, deserialization, XXE)
- Version/release information

**Supplement the script output by checking:**

| What to find       | Where to look                                                               |
| ------------------ | --------------------------------------------------------------------------- |
| API surface        | OpenAPI specs, route definitions, gRPC proto files, GraphQL schemas         |
| Auth mechanism     | Auth middleware, OAuth config, JWT libraries, session stores                |
| Data stores        | DB drivers, ORM config, migration files, cache clients (Redis, Memcached)   |
| Agent instructions | `AGENTS.md`, `.github/copilot-instructions.md`, `.cursorrules`, `CLAUDE.md` |

**Key questions to clarify with user** (use AskUserQuestion if available):

1. What type of application is this? (web service / CLI tool / library / mobile app / desktop app)
2. What deployment environment? (cloud provider, on-prem, hybrid)
3. Who are the users? (internal employees / external customers / developers / public)
4. Is there an existing security contact or process?

---

## Step 2: Identify Assets and Data Flows

Determine what the project stores, processes, and transmits.

**Look for:**

- Database models / schemas / migrations → identify PII, credentials, financial data
- Environment variables and config files → identify secrets and sensitive config
- File upload handlers → identify user-supplied content
- API response shapes → identify what data leaves the system
- Logging statements → identify what might be inadvertently logged
- Cache keys → identify what's stored in shared memory

**Classify assets by sensitivity:**

| Sensitivity | Examples                                                             |
| ----------- | -------------------------------------------------------------------- |
| Critical    | Signing keys, DB master credentials, encryption keys, payment tokens |
| High        | User PII, session tokens, API keys, access logs with user context    |
| Medium      | Application config, internal IPs, non-sensitive business data        |
| Low         | Public content, marketing copy, open-source dependency list          |

---

## Step 3: Map Attack Surface

Identify every point where untrusted input enters the system.

**Checklist:**

- [ ] HTTP/gRPC/WebSocket endpoints (list all public routes)
- [ ] Authentication endpoints (login, register, password reset, OAuth callbacks)
- [ ] File upload endpoints
- [ ] Webhook receivers
- [ ] Message queue consumers
- [ ] CLI arguments and stdin
- [ ] Environment variables read at runtime
- [ ] DNS/network exposure (ports, protocols)
- [ ] CI/CD triggers (workflow_dispatch, PR events from forks)
- [ ] Admin/debug endpoints (check if properly gated)

**For each entry point, note:**

- Input validation present? (type, length, format)
- Authentication required?
- Authorization granularity?
- Rate limiting in place?

---

## Step 4: Assess Dependencies and Supply Chain

**Automated checks:**

```bash
# Node.js
npm audit --json 2>/dev/null || true
cat package-lock.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
pkgs = data.get('packages', {})
print(f'Total packages: {len(pkgs)}')
direct = [k for k in pkgs if k.count('/node_modules/') == 1]
print(f'Direct dependencies: {len(direct)}')
"

# Go
go list -m all 2>/dev/null | wc -l
govulncheck ./... 2>/dev/null || true

# Python
pip-audit 2>/dev/null || safety check 2>/dev/null || true

# Rust
cargo audit 2>/dev/null || true
```

**Assess:**

- Total dependency count (direct + transitive)
- Known vulnerabilities (critical/high/medium)
- Dependency freshness (last update dates of key deps)
- Pinning strategy (lockfile present? hash verification?)
- Whether security-critical functions use well-known libraries vs custom code

---

## Step 5: Document Security Controls in Place

Identify what security measures already exist. Look for:

| Category           | What to find                                                |
| ------------------ | ----------------------------------------------------------- |
| AuthN              | Middleware enforcing authentication, token validation logic |
| AuthZ              | Role checks, permission guards, policy engines              |
| Input validation   | Schema validation (zod, joi, pydantic), sanitization        |
| CSRF protection    | Token generation/validation middleware                      |
| Rate limiting      | Rate limiter middleware, API gateway config                 |
| Encryption         | TLS config, field-level encryption, at-rest encryption      |
| Secret management  | Vault integration, KMS usage, env-only secrets              |
| Logging & audit    | Structured logging setup, audit trail implementation        |
| Security headers   | Helmet.js, manual header setting, CSP                       |
| Container security | Non-root user, minimal base image, read-only FS             |

For each control found, note:

- Where it's implemented (file + line)
- Coverage (all routes? only some?)
- Any gaps or inconsistencies

---

## Step 6: Derive Secure Coding Rules

Based on the discovered tech stack, generate project-specific coding rules.

**Language-specific rule selection:**

| Stack              | Key rules to emphasize                                                         |
| ------------------ | ------------------------------------------------------------------------------ |
| Node.js/TypeScript | Prototype pollution, ReDoS, event loop blocking, npm supply chain              |
| Go                 | Integer overflow, goroutine leaks, unsafe package usage, TOCTOU in file ops    |
| Python             | Pickle deserialization, SSTI, subprocess injection, `yaml.safe_load`           |
| Rust               | `unsafe` block justification, FFI boundary validation                          |
| Java/Kotlin        | Deserialization (Jackson/Gson config), JNDI injection, XML external entities   |
| React/Frontend     | XSS via dangerouslySetInnerHTML, open redirects, token storage in localStorage |

**Framework-specific rules:**

- ORM: N+1 queries as DoS vector, mass assignment protection
- GraphQL: query depth/complexity limits, introspection in prod
- gRPC: message size limits, deadline propagation
- WebSocket: origin validation, message rate limiting

---

## Step 7: Generate SECURITY.md

Use the template from [template.md](template.md) and fill in each section with discovered data.

**Section-by-section guidance:**

| Section                       | Source                                                            |
| ----------------------------- | ----------------------------------------------------------------- |
| Supported Versions            | Git tags, CHANGELOG, CI release config                            |
| Reporting a Vulnerability     | User input (or infer from existing SECURITY.md / CONTRIBUTING.md) |
| Assets                        | Step 2 output                                                     |
| Threat Actors                 | Standard list, adjusted to project's exposure level               |
| Attack Surface                | Step 3 output                                                     |
| Trust Boundaries              | Infer from architecture (edge → app → data layer)                 |
| Known Risks                   | Findings from Steps 3-5 where no mitigation exists                |
| Security Architecture         | Step 5 output                                                     |
| Secure Coding Guidelines      | Step 6 output                                                     |
| Rules for AI Coding Agents    | Derived from stack + project-specific patterns                    |
| Security-Related Config Files | Files found in Step 1                                             |

**Writing rules:**

- Remove `{{ }}` placeholder markers from filled sections
- Keep `{{ }}` only for sections that could not be filled (note why)
- Be specific: reference actual file paths, library names, config values
- Include concrete examples from the codebase where helpful
- Mark assumptions explicitly: "Assumed based on [evidence]"

---

## Step 8: Register SECURITY.md in AGENTS.md

Ensure that AI coding agents working on the repository are aware of the security policy. Add or update a reference to `SECURITY.md` in the project's `AGENTS.md` file.

**If `AGENTS.md` exists** — add a section (or append to an existing "Security" / "Guidelines" section):

```markdown
## Security Policy

This project maintains a security policy in [SECURITY.md](./SECURITY.md).
All AI coding agents MUST read and follow SECURITY.md before making changes.
It contains:

- Threat model and trust boundaries
- Secure coding guidelines specific to this project's stack
- Hard constraints and forbidden patterns for AI agents
- Vulnerability reporting procedures

Any code contribution that violates the rules in SECURITY.md will be rejected.
```

**If `AGENTS.md` does not exist** — create it with at minimum the security reference above, plus a brief header:

```markdown
# Agent Guidelines

Instructions for AI coding agents (GitHub Copilot, Cursor, Qoder, etc.)
working on this repository.

## Security Policy

This project maintains a security policy in [SECURITY.md](./SECURITY.md).
All AI coding agents MUST read and follow SECURITY.md before making changes.
It contains:

- Threat model and trust boundaries
- Secure coding guidelines specific to this project's stack
- Hard constraints and forbidden patterns for AI agents
- Vulnerability reporting procedures

Any code contribution that violates the rules in SECURITY.md will be rejected.
```

**Important:** Do not duplicate the full security rules in AGENTS.md — reference SECURITY.md as the single source of truth. AGENTS.md should only contain a pointer and a brief summary of what agents will find there.

---

## Step 9: Validate Completeness

After generating, verify:

- [ ] Every section either filled or marked with reason for incompleteness
- [ ] No placeholder text left unmarked
- [ ] Asset sensitivity ratings are justified
- [ ] Attack surface entries match actual routes in codebase
- [ ] Dependency counts match actual lockfile
- [ ] Secure coding rules match the actual tech stack (no irrelevant rules)
- [ ] AI agent rules reference patterns actually present in the project
- [ ] No secrets or sensitive internal details exposed in the document
- [ ] Revision history has today's date
- [ ] AGENTS.md exists and references SECURITY.md
- [ ] AGENTS.md does NOT duplicate security rules (only references them)

---

## Output Location

Save the generated SECURITY.md to the project root directory. If one already exists, back it up first and present both versions for comparison.

## Tone and Audience

The document will be read by:

- Security researchers evaluating the project
- New contributors learning project security standards
- AI coding agents operating on the codebase
- Auditors reviewing security posture

Write in clear, imperative, technical language. Avoid marketing fluff. Prefer concrete over abstract.
