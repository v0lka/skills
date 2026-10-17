# Security Review

A standalone [Agent Skill](https://agentskills.io/specification) that performs security review of code changes and codebases. It hunts exploitable vulnerabilities across the OWASP Top 10 for Web Applications (2021 and 2025), the OWASP Top 10 for Agentic Applications (ASI01–ASI10), business-logic flaws, and data races / race conditions — proving every finding with a realistic attack scenario, mapping it to CWEs, and prioritizing the report by CVSS v4.0.

## When to use

| Situation                                                                          | Use this skill |
| ---------------------------------------------------------------------------------- | -------------- |
| Security review of uncommitted changes (the default when no input is given)         | ✅             |
| Security review of a specific commit, branch diff, or pull request                  | ✅             |
| Security audit of a file or directory                                              | ✅             |
| Triaging scanner output (govulncheck, npm audit, cargo audit, pip-audit, …)          | ✅             |
| Auditing a project against its `SECURITY.md` threat model and rules                | ✅             |
| General (non-security) code review — bugs, structure, performance                   | ❌ use `code-review` |
| Generating a SECURITY.md / threat model                                             | ❌ use `security-policy-generator` |

## How it works

```
Determine scope ──► Load policy context ──► Run scanners ──► Review domains ──► Prove, score, map ──► Report
```

1. **Determine scope** — no input → uncommitted changes; commit ref → that commit; branch name → branch diff; PR → pull request; path → full audit of that subtree.
2. **Load policy context** — `SECURITY.md` (threat model and secure coding rules), `REVIEW.md` (project review rules), project specifications (OpenAPI, specs, RFCs, ADRs). Violations of these documents are findings that cite the specific rule.
3. **Run scanners** — ecosystem dependency/SAST/secret/race tools appropriate to the stack (govulncheck, npm audit, cargo audit, pip-audit, semgrep, gitleaks, …), all read-only. Scanner output is a lead until verified.
4. **Review domains** — OWASP Top 10 Web 2021/2025; OWASP Top 10 Agentic ASI01–ASI10 (when agentic indicators are present); business-logic errors derived from spec-vs-code invariants; data races and race conditions.
5. **Prove, score, map** — every finding carries a four-part attack scenario (actor, entry point, steps, impact), a CWE mapping (primary + supporting), and a CVSS v4.0 vector string with score.
6. **Report** — findings sorted by CVSS score descending; the ordering is the prioritization.

### Review domains

| Domain                                             | Coverage                                                                                                    |
| -------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **OWASP Top 10:2025 / 2021 (Web)**                 | All ten categories, with 2021↔2025 correspondence and notable CWEs per category                              |
| **OWASP Top 10 Agentic (ASI01–ASI10)**             | Applied when the code implements or integrates AI agents (tool calling, MCP, agent memory, multi-agent flows) |
| **Business logic errors**                          | Spec-vs-code invariant violations: workflow bypass, replay, negative values, price tampering, fail-open      |
| **Data races / race conditions**                   | Unsynchronized access, check-then-act, TOCTOU, lock discipline, distributed and storage-level races          |

### Finding anatomy

Each finding includes: severity (CVSS 4.0 score + qualitative rating), the full `CVSS:4.0/…` vector with per-metric justification, CWE mapping with exact names, OWASP/ASI category, location, the attack scenario, evidence, concrete fix options, and a confidence level. The evidence standard is strict: **no attack scenario, no finding**.

## Bundled resources

| File                                    | Purpose                                                                       |
| --------------------------------------- | ----------------------------------------------------------------------------- |
| `SKILL.md`                              | Skill definition: workflow, evidence standard, scoring, CWE mapping, output format |
| `references/owasp-web.md`               | OWASP Top 10 Web 2021/2025 checklists, edition correspondence, notable CWEs   |
| `references/owasp-agentic.md`           | OWASP Agentic ASI01–ASI10 checklists with suggested CWE proxies               |
| `references/business-logic-and-races.md`| Business-logic invariants, abuse cases, race/TOCTOU taxonomy and proof format |
| `references/cvss-v4.md`                 | CVSS v4.0 metric guide, vector syntax, severity bands, scoring procedure      |
| `references/tooling.md`                 | Ecosystem scanner catalog (dependencies, SAST, secrets, race detectors)       |

## Compatibility

The skill is agent-agnostic. It requires read access to a version-controlled repository. Installed security scanners for the project's ecosystem (govulncheck, npm audit, cargo audit, pip-audit, semgrep, gitleaks, …) and network access for CVE/CWE/CVSS lookups are optional but recommended; the report records which tools ran, failed, or were unavailable.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
