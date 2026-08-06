---
name: security-policy-generator
description: Analyze a project repository and generate a comprehensive SECURITY.md with threat model, security architecture, and secure coding guidelines — covering both classical security and the OWASP Top 10 for Agentic Applications 2026 (ASI01–ASI10). Use when the user asks to create a security policy, generate a threat model, fill in a SECURITY.md template, or assess project security posture.
---

# Security Policy Generator

Generate a project-specific SECURITY.md by analyzing the codebase, dependencies, configuration, and architecture. The output covers: supported versions, vulnerability reporting, threat model, security architecture, secure coding rules, and AI agent constraints.

This skill produces a policy that covers **two complementary risk domains**:

1. **Classical application security** — the OWASP Top 10 (Web/Cloud), injection, auth, crypto, supply chain, etc. Always applicable.
2. **Agentic application security** — the [OWASP Top 10 for Agentic Applications (2026)](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/), identifiers ASI01–ASI10. Applies whenever the project builds AI agents that plan, act, call tools, remember across sessions, or communicate with other agents on behalf of users.

The agentic section is **conditional**: a pure chatbot or RAG setup with no tool use and no multi-agent coordination needs only classical controls (and, where relevant, the OWASP Top 10 for LLM Applications). The moment the system takes actions on behalf of a user, the agentic threat model becomes mandatory. The reconnaissance script (`scripts/recon.sh`) auto-detects agentic indicators (LLM/agent SDKs, MCP, vector stores, prompt files, tool-calling patterns) and flags whether the agentic section should be generated.

## Workflow

Copy this checklist and track progress:

```
Task Progress:
- [ ] Step 1: Project reconnaissance (incl. agentic indicators)
- [ ] Step 2: Identify assets and data flows (incl. agent assets)
- [ ] Step 3: Map attack surface (incl. agentic entry points)
- [ ] Step 4: Assess dependencies and supply chain
- [ ] Step 5: Document security controls in place
- [ ] Step 6: Agentic risk assessment — OWASP ASI01–ASI10
- [ ] Step 7: Derive secure coding rules
- [ ] Step 8: Generate SECURITY.md
- [ ] Step 9: Register SECURITY.md in AGENTS.md
- [ ] Step 10: Validate completeness
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
| Agentic components | LLM/inference SDKs, agent frameworks (LangChain/LangGraph, CrewAI, AutoGen), MCP servers/config, vector stores, tool/function-calling definitions, system-prompt files |

The reconnaissance script reports an **"Agentic AI Indicators"** section with a summary flag. If `AGENTIC PROJECT DETECTED` appears, the OWASP Top 10 for Agentic Applications (ASI01–ASI10) section MUST be generated; otherwise it may be omitted (classical controls suffice). Verify the flag manually against the "Agentic components" row above.

**Key questions to clarify with user** (use AskUserQuestion if available):

1. What type of application is this? (web service / CLI tool / library / mobile app / desktop app)
2. What deployment environment? (cloud provider, on-prem, hybrid)
3. Who are the users? (internal employees / external customers / developers / public)
4. Is there an existing security contact or process?
5. **Does the application include AI agents that take actions on behalf of users** (call tools, write to systems, make decisions autonomously)? If yes, the agentic threat model (ASI01–ASI10) is required.

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

**When agentic components are present, also look for:**

- System / role prompts → identify embedded guardrails and business logic (extraction reveals the agent's rules)
- Agent credentials & tool secrets → the API keys/OAuth tokens the agent holds; their combined scope equals the blast radius (ASI03)
- Agent memory stores & vector DBs → long-term memory and conversation history that persist across sessions (ASI06)
- Tool & MCP definitions → schemas, descriptions, and permission mappings the agent trusts (ASI04)
- Agent-generated artifacts → code, plans, and API calls produced at runtime (ASI05)
- Training / embedding data → fine-tune datasets and embeddings (poisoning vectors)

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

**When agentic components are present, add these entry points:**

- [ ] Agent prompt inputs — user messages, RAG-retrieved documents, web pages, and tool outputs entering the model context (ASI01 indirect-injection vectors)
- [ ] Agent tool / function-calling surface — every tool the agent may invoke, especially side-effecting operations (ASI02)
- [ ] External tool & MCP registries — dynamically integrated tools, plugins, and schemas whose descriptions/permissions may be forged (ASI04)
- [ ] Agent-generated code / shell execution — sandboxed or unsandboxed environments running model output (ASI05)
- [ ] Agent memory stores — vector DBs, long-term memory, and conversation logs writable by the agent (ASI06)
- [ ] Inter-agent message channels — orchestration buses, delegation protocols between agents (ASI07)
- [ ] Human approval / HITL gates — review steps vulnerable to prompt-injection or approval-fatigue (ASI09)

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
- **Agentic supply chain (ASI04):** third-party tools, MCP servers, and plugin packages — are they pinned, vetted, provenance-verified? Are tool descriptions reviewed for deceptive language? Is dynamic tool discovery allowed?

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
| Agent guardrails (agentic) | Instruction/data separation, prompt-injection filtering, output classification |
| Tool-call governance (agentic) | Per-tool least privilege, allowlist, parameter validation, budget/loop caps |
| Code-exec sandboxing (agentic) | Isolated env, restricted FS/network, human-approval gates for model-generated code |
| Memory protection (agentic) | Write/read validation on vector stores & long-term memory, session isolation, TTL |
| Inter-agent security (agentic) | Authenticated/signed messages, delegation-depth limits, fail-closed delegation |
| Resilience (agentic) | Circuit breakers, bulkheads, kill-switch, behavioral-drift monitoring |

For each control found, note:

- Where it's implemented (file + line)
- Coverage (all routes? only some?)
- Any gaps or inconsistencies

---

## Step 6: Agentic Risk Assessment — OWASP Top 10 for Agentic Applications (ASI01–ASI10)

> **Conditional step.** Skip entirely if Step 1 did not detect agentic components (the recon script prints `No strong agentic indicators`). For a pure chatbot / RAG system with no tool use and no multi-agent coordination, classical controls and the OWASP Top 10 for LLM Applications suffice. The moment the system takes actions on behalf of a user, this step is **required**.

For each ASI category below, assess the project against the checklist. Use the existing agentic review conventions from [code-review/references/review-guide.md](../../development/code-review/references/review-guide.md) for consistency. Record findings as: **control present** (file + coverage), **gap** (→ Known Risks), or **not applicable** (justify).

The unifying principle is **least agency** — grant an agent only the minimum autonomy required for a safe, bounded task. Ask, for every agent: what is its reach (least privilege) AND what is its latitude within that reach (least agency)?

- [ ] **ASI01 — Agent Goal Hijacking.** Is all content entering the agent context (user input, tool outputs, external docs, web pages) treated as potentially hostile? Are trusted instructions delimited from untrusted data? Is there defense-in-depth (sanitization, output filtering, privilege separation)? Canary tokens / prompt-extraction detection?
- [ ] **ASI02 — Tool Misuse and Exploitation.** Are tools granted minimum permissions? Are call arguments validated (schemas, regex, allowlists)? Are dangerous operations (DELETE/DROP/EXEC) programmatically restricted regardless of agent request? Tool allowlist, budget/loop caps, human-approval gates?
- [ ] **ASI03 — Agent Identity and Privilege Abuse.** Does each agent use a verified identity? Is it scoped/rotated? Are confused-deputy attacks prevented? Is every action logged with the verified principal? Are delegation chains preserving the original caller?
- [ ] **ASI04 — Agentic Supply Chain Compromise.** Are third-party tools/MCP servers/plugins pinned and vetted? Are tool descriptions reviewed for deceptive language? Is provenance verified? Are new tools sandboxed before production?
- [ ] **ASI05 — Unexpected Code Execution.** Is agent-generated/shell code sandboxed (isolated FS, no network unless needed)? Human approval for high-risk execution? Argument scanning? Ephemeral cleanup? Resource limits?
- [ ] **ASI06 — Memory and Context Poisoning.** Is persistent memory (vector DB, long-term store) validated before write/read? Scanned for poisoning patterns? Can poisoned memories be purged? Is session context isolated? Retention/TTL?
- [ ] **ASI07 — Insecure Inter-Agent Communication.** Are agent-to-agent messages authenticated/integrity-protected? Delegation-depth limited/monitored? Impersonation resistance? Explicitly defined cross-agent permissions? Transport security (mTLS, signed tokens)?
- [ ] **ASI08 — Cascading Agent Failures.** Circuit breakers? Fail-closed when policy service unreachable? Bulkheads? Safe fallback per dependency? Monitoring for deny-rate spikes / cascades?
- [ ] **ASI09 — Human-Agent Trust Exploitation.** Do approval workflows show raw intent (not an agent summary)? Rate-limited against approval fatigue? AI-generated labeling? Policy-engine-generated justifications (not agent-generated)?
- [ ] **ASI10 — Rogue Agents.** Behavioral-drift monitoring? Full auditable receipt chain? Kill-switch / circuit-breaker? Periodic alignment checks? Bounds on autonomy (max steps, time-boxed sessions)?

---

## Step 7: Derive Secure Coding Rules

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

**Agentic-specific rules (when ASI01–ASI10 apply):**

- Prompt construction: strict instruction/data separation with delimiters; treat retrieved/tool-produced text as adversarial (ASI01)
- Tool integration: per-tool least privilege, validated parameter schemas, allowlist, budget/loop caps, irreversible-action gates (ASI02)
- Code execution: sandbox with restricted FS/network, ephemeral cleanup, argument scanning (ASI05)
- Memory: validate before write/read, scan for poisoning, isolate per session, enforce TTL (ASI06)
- Inter-agent messaging: authenticate and sign messages, limit delegation depth, fail-closed (ASI07)

---

## Step 8: Generate SECURITY.md

Use the template from [template.md](template.md) and fill in each section with discovered data.

**Section-by-section guidance:**

| Section                       | Source                                                            |
| ----------------------------- | ----------------------------------------------------------------- |
| Supported Versions            | Git tags, CHANGELOG, CI release config                            |
| Reporting a Vulnerability     | User input (or infer from existing SECURITY.md / CONTRIBUTING.md) |
| Assets                        | Step 2 output                                                     |
| Threat Actors                 | Standard list, adjusted to project's exposure level               |
| Attack Surface                | Step 3 output                                                     |
| Trust Boundaries              | Infer from architecture (edge → app → data layer); add agent trust boundaries if agentic |
| Known Risks                   | Findings from Steps 3-5 and Step 6 where no mitigation exists     |
| Security Architecture         | Step 5 output                                                     |
| Agentic Application Security  | Step 6 output (ASI01–ASI10) — include only if agentic indicators detected |
| Secure Coding Guidelines      | Step 7 output                                                     |
| Rules for AI Coding Agents    | Derived from stack + project-specific patterns + agentic constraints (ASI09/ASI10) |
| Security-Related Config Files | Files found in Step 1                                             |

**Writing rules:**

- Remove `{{ }}` placeholder markers from filled sections
- Keep `{{ }}` only for sections that could not be filled (note why)
- Be specific: reference actual file paths, library names, config values
- Include concrete examples from the codebase where helpful
- Mark assumptions explicitly: "Assumed based on [evidence]"

---

## Step 9: Register SECURITY.md in AGENTS.md

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
- Agentic security controls (OWASP Top 10 for Agentic Applications ASI01–ASI10), where applicable

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
- Agentic security controls (OWASP Top 10 for Agentic Applications ASI01–ASI10), where applicable

Any code contribution that violates the rules in SECURITY.md will be rejected.
```

**Important:** Do not duplicate the full security rules in AGENTS.md — reference SECURITY.md as the single source of truth. AGENTS.md should only contain a pointer and a brief summary of what agents will find there.

---

## Step 10: Validate Completeness

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
- [ ] If agentic indicators were detected: ASI01–ASI10 section present, each category assessed (control/gap/N/A), and gaps moved to Known Risks
- [ ] If no agentic indicators: the Agentic Application Security section is explicitly omitted with a one-line note (no stale placeholders)

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
