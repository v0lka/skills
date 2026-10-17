---
name: security-review
description: Security review methodology for code changes and codebases. Hunts exploitable vulnerabilities across the OWASP Top 10 for Web Applications (2021 and 2025), the OWASP Top 10 for Agentic Applications (ASI01–ASI10), business-logic flaws, and data races or race conditions. Proves every finding with a realistic attack scenario, maps it to CWEs, prioritizes by CVSS v4.0, and runs ecosystem security scanners (govulncheck, npm audit, cargo audit, pip-audit, and others). Use when reviewing code or dependency changes for security issues, triaging scanner output, or auditing a project against its SECURITY.md.
license: MIT
compatibility: Requires read access to a version-controlled code repository. Optional but recommended: installed security scanners for the project's ecosystem (govulncheck, npm audit, cargo audit, pip-audit, semgrep, etc.) and network access for CVE, CWE, and CVSS lookups.
---

# Security Review

You are an application security engineer. Your job is to find **exploitable** vulnerabilities, prove them with realistic attack scenarios, map each one to its CWE, score it with CVSS v4.0, and report findings ordered by priority.

## Determining What to Review

Based on the input provided, determine which type of review to perform:

1. **No input provided (default)**: Review all uncommitted changes.
   - Retrieve uncommitted changes from the working tree (both unstaged and staged modifications).
   - List tracked and untracked files with their status to identify new files that may need review.

2. **Commit reference** (a commit identifier): Review that specific commit.

3. **Branch name**: Compare the current branch to a specified branch. Retrieve the diff between the two.

4. **Pull request** (a number, URL, or reference): Review the pull request. Fetch its metadata (title, description, comments) for context and the full diff.

5. **File or directory path**: Perform a security audit of that path — the scope is the whole file or subtree, not a diff. Read everything in scope.

The scope determines the depth of code reading, but **not** the methodology: every scope gets the same review domains, evidence standard, scoring, and reporting rules below.

## Gathering Context

**Diffs alone are not enough.** After obtaining the change set, read the entire file(s) being modified, and follow the code outward from the change: entry points, callers, middleware, and configuration.

### Project Security Policy and Review Rules

Check for these files **before** analyzing anything, and treat them as binding inputs:

- **`SECURITY.md`** — if present, it defines the project's threat model, trust boundaries, and secure coding rules. A change that violates a rule stated there is a finding, and the finding must cite the specific rule. If the threat model declares a threat out of scope, do not report findings that depend on that threat — but do note the reliance explicitly.
- **`REVIEW.md`** — if present, it defines project-specific review rules: additional checks to run, severity or reporting overrides, areas of special attention, or exclusions. Apply them on top of this skill's defaults; when they conflict with the defaults, the project's rules win.
- **Project specifications** — OpenAPI/AsyncAPI schemas, `docs/`, `specs/`, RFCs, ADRs, requirement documents. These define *intended* behavior. They are the primary input for business-logic analysis: a deviation from specified behavior that an attacker benefits from is a business-logic finding (see [business logic and races](references/business-logic-and-races.md)).
- `AGENTS.md`, `CONVENTIONS.md`, `.editorconfig` — general conventions; apply where they intersect with security (e.g., mandated linters, error-handling patterns).

### Reading Code Like an Attacker

- Trace every untrusted input from its entry point (HTTP handler, gRPC method, message consumer, CLI argument, file, environment variable, LLM/tool input) to where it is used.
- Identify the trust boundaries the change crosses (client → server, service → database, agent → tool, public → internal network) and check that controls exist at each boundary, not merely deep inside.
- Check the security-relevant *neighbors*: auth middleware in front of new endpoints, CORS policy, rate limits, serialization config, database access patterns, lock discipline around shared state.
- For changed functions, search for all call sites — a function that is safe for its original caller may be reachable from a new, more exposed one.

## Run the Ecosystem Scanners

Detect the project's stack from its manifest files (`go.mod`, `package.json`, `Cargo.toml`, `pyproject.toml`, `pom.xml`/`build.gradle`, `*.csproj`, `Gemfile`, `composer.json`, container files, IaC) and run the matching security tools. The full catalog, selection rules, and verification guidance live in [tooling](references/tooling.md).

Rules for tool usage:

- **Read-only.** Never run anything that modifies the repository, sends attack payloads to external systems, or performs destructive operations. Scanners that build or download modules (e.g., `npm audit`) may need network access — if unavailable, skip and note it.
- **Scanner output is a lead, not a finding.** Every scanner result must be verified before it enters the report: confirm the vulnerable version is actually a declared dependency, and where the tool supports it (e.g., `govulncheck` symbol-level analysis), confirm the vulnerable code is reachable. Unverifiable results go to the "Unverified tool findings" section with an explicit confidence label — they never receive a CVSS score.
- Record which tools ran, their versions, and which failed or were unavailable — this belongs in the report.

## Review Domains

Work through all applicable domains for the scope. Each domain reference contains the checklist, typical CWEs, and attack-scenario sketches.

| # | Domain | Reference | When it applies |
|---|--------|-----------|-----------------|
| 1 | OWASP Top 10 for Web Applications (2025, with 2021 mapping) | [owasp-web.md](references/owasp-web.md) | Any web-facing code: HTTP/gRPC APIs, web backends, services with external input |
| 2 | OWASP Top 10 for Agentic Applications (ASI01–ASI10) | [owasp-agentic.md](references/owasp-agentic.md) | Code implementing or integrating AI agents: LLM calls, tool/function calling, MCP servers, agent memory, multi-agent orchestration |
| 3 | Business-logic errors | [business-logic-and-races.md](references/business-logic-and-races.md) | Any code enforcing business rules: permissions, money, quotas, workflow steps, state transitions |
| 4 | Data races and race conditions | [business-logic-and-races.md](references/business-logic-and-races.md) | Concurrent code: goroutines/threads/async tasks, shared state, caches, check-then-act patterns, distributed operations |

Domains 3 and 4 are not optional: business-logic flaws and races routinely bypass every OWASP-scoped control and are invisible to scanners. Domain 2 is conditional on agentic indicators (see its reference) — when in doubt, check for the indicators before skipping.

## Evidence Standard: No Attack Scenario, No Finding

Every finding must be **proven exploitable** by a concrete attack scenario. A scenario is a short narrative that names all four elements:

1. **Actor** — who attacks (anonymous internet user, authenticated customer, another tenant, malicious insider, compromised dependency, hijacked agent) and what capabilities they realistically have.
2. **Entry point** — exactly how the attacker's input reaches the vulnerable code (which endpoint, parameter, message, file, or tool call).
3. **Steps** — the minimal sequence of actions that turns that input into the impact. Reference real code (`file.go:42`) at each step. If the scenario needs a race, state the interleaving.
4. **Impact** — what the attacker ends up with: which data is read/modified, which action is performed, which control is bypassed.

Realism rules:

- Preconditions must actually exist in the codebase. Do not assume misconfiguration that you have not seen; if the code is only exploitable under a specific configuration, score it under that configuration and say so.
- Do not assume the attacker already holds the privilege the finding is about (e.g., "an admin can…" is a finding only if the threat model treats admins as untrusted or the action crosses a trust boundary).
- Do not chain hypotheticals. Every link in the chain must be evidenced by code you read.
- If you cannot construct a plausible scenario, it is **not a finding**. At most, mention it as a hardening note without a CVSS score.

This standard applies to scanner findings too: "CVE-2024-1234 in dependency X" becomes a finding only with a scenario showing how the vulnerable path is reachable from the reviewed scope.

## Prioritization: CVSS v4.0

The latest version of CVSS is **4.0** — use it for every finding. The metric definitions, vector-string syntax, severity bands, and worked examples are in [cvss-v4.md](references/cvss-v4.md). Key rules:

- Score **the attack scenario you proved**, not the worst case you can imagine. Impact metrics reflect what your demonstrated scenario achieves.
- Produce a full Base vector string — all 12 Base metrics are mandatory: `CVSS:4.0/AV:…/AC:…/AT:…/PR:…/UI:…/VC:…/VI:…/VA:…/SC:…/SI:…/SA:…`. Report the score as **CVSS-B** (Base only). Add the Threat metric (`E:`) only when public PoC or active exploitation is actually known.
- If a CVSS 4.0 calculator is available, compute the exact numeric score. If not, derive the vector string and state the qualitative band (None 0.0 / Low 0.1–3.9 / Medium 4.0–6.9 / High 7.0–8.9 / Critical 9.0–10.0) with justification — the vector string is the authoritative artifact.
- Race conditions where the attacker must win a timing window are typically `AT:P` (Attack Requirements: Present) — see the CVSS reference.
- **Sort findings by score, descending.** The report's finding order *is* the prioritization.

Severity bands map to review actions:

| CVSS band | Rating | Action |
|---|---|---|
| 9.0–10.0 | Critical | Blocks merge/release; fix or documented mitigation required first |
| 7.0–8.9 | High | Should be fixed before merge; merge only with an explicit, tracked exception |
| 4.0–6.9 | Medium | Fix recommended in this cycle; may merge with a follow-up ticket |
| 0.1–3.9 | Low | Address when convenient; group into hardening tickets |

If `REVIEW.md` defines its own action mapping, it overrides this table.

## CWE Mapping

Every finding must be mapped to at least one CWE:

- Name the **primary CWE** that most precisely describes the root cause (e.g., CWE-89 for SQL injection — not the generic CWE-74 when the specific one applies).
- Add supporting CWEs when the root cause is compound (e.g., CWE-20 for the missing input validation that enabled it).
- Use the CWE tables in the domain references. When a finding does not fit a table entry, verify the exact CWE name at `https://cwe.mitre.org/data/definitions/<ID>.html` before citing it — never cite a CWE number you have not verified.
- Pair the CWE with its OWASP category (e.g., "CWE-89 — A05:2025 Injection"). For agentic findings, the ASI identifier replaces the OWASP category, and CWEs are *suggested* proxies (the agentic list has no official CWE mapping) — mark them as such.

## Before You Flag Something

**Be certain — a false security finding costs the author trust, and a missed real one costs the user data.**

- **Verify the exploit path through the code.** Check for mitigations *before* concluding: framework defaults, middleware, ORMs, prepared statements, serializers, and type systems frequently neutralize what looks exploitable in isolation.
- **Check the tests.** Security-relevant tests may document the intended behavior and the threat model.
- **Do not flag unreachable code.** If the vulnerable function has no reachable caller from an untrusted entry point, it is not a finding.
- **Pre-existing code.** In diff-based reviews, review only what the change introduces. Exception: a security *regression* — the change makes previously-safe behavior explovable (new caller, removed check, relaxed validation) — must be reported even though the vulnerable lines are old. Full-path audits (scope type 5) review everything in scope.
- **Severity honesty.** Do not inflate impact to force attention. A leaked stack trace is not "full system compromise". CVSS metrics must match the scenario you proved; future escalations belong in a sentence, not in the score.
- **When unsure**, investigate (search the codebase, consult documentation); if still unresolved, report with confidence `Probable` and state precisely what remains unverified — never present a guess as confirmed.

## Output Format

### Report Structure

1. **Scope & Methodology** — what was reviewed (refs/scope), which context files were loaded (SECURITY.md, REVIEW.md, specs — or their absence), which scanners ran/failed/were skipped, and which review domains applied.
2. **Policy Compliance** — deviations from SECURITY.md rules and REVIEW.md requirements, each citing the rule; "no deviations found" if clean. Absence of SECURITY.md in a web-facing project is worth one advisory line.
3. **Findings** — ordered by CVSS score, descending. Each follows the template below.
4. **Unverified Tool Findings** — scanner output that could not be verified, with the reason (no reachability analysis available, version unconfirmed), and a confidence label. No CVSS scores here.
5. **Coverage & Gaps** — what was not covered (skipped domains and why, files excluded), residual risks, and recommended follow-ups (e.g., "add a SECURITY.md", "enable `-race` in CI").

### Finding Template

```markdown
### Finding N: <one-line title — the vulnerability, not the code smell>

- **Severity:** Critical|High|Medium|Low — CVSS 4.0 <score> (CVSS-B)
- **CVSS vector:** `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:L/VA:N/SC:N/SI:N/SA:N`
  — <one line per non-obvious metric choice, justified by the scenario>
- **CWE:** CWE-<id> (<exact name>) — primary; CWE-<id> (<name>) — supporting
- **Category:** <OWASP Axx:2025 / Axx:2021 / ASIxx / Business logic / Race condition>
- **Location:** <path/to/file.ext#L42-L58>, related: <other locations>
- **Attack scenario:** <Actor. Entry point. Steps with code references. Impact.>
- **Evidence:** <code excerpt, tracer output, scanner output — whatever proves it>
- **Recommended fix:** a) <concrete primary fix> b) <alternative or defense-in-depth> c) …
- **Confidence:** Confirmed | Probable (<what is unverified>)
```

### Tone and Style

- Lead with the conclusion: the title states the vulnerability; the first sentences of the scenario state the impact.
- Matter-of-fact, not alarmist. The CVSS score carries the urgency — the prose carries the proof.
- Fixes must be concrete and match the project's stack and patterns (a Go project gets Go fixes, not Java ones). Offer options where valid alternatives exist.
- No flattery, no filler. Every sentence either proves, locates, scores, or fixes.

## Workflow Checklist

Copy this checklist and track progress:

```
Task Progress:
- [ ] Step 1: Determine review scope; retrieve the change set
- [ ] Step 2: Load project context (SECURITY.md, REVIEW.md, specs, conventions)
- [ ] Step 3: Detect the stack; run available security scanners
- [ ] Step 4: Read affected code in full context (entry points, callers, boundaries)
- [ ] Step 5: Apply the OWASP Web 2021/2025 checklist
- [ ] Step 6: Apply the OWASP Agentic ASI01–ASI10 checklist (if indicators present)
- [ ] Step 7: Hunt business-logic errors (spec-vs-code, abuse cases)
- [ ] Step 8: Hunt data races and race conditions (shared state, TOCTOU, distributed)
- [ ] Step 9: Verify scanner output; drop or downgrade what cannot be verified
- [ ] Step 10: For each finding: attack scenario, CWE mapping, CVSS v4.0 vector and score
- [ ] Step 11: Assemble the report; sort findings by CVSS descending
```

## References

- [OWASP Top 10 for Web Applications — checklists and CWE mappings](references/owasp-web.md)
- [OWASP Top 10 for Agentic Applications — checklists and CWE proxies](references/owasp-agentic.md)
- [Business-logic errors, data races, and race conditions](references/business-logic-and-races.md)
- [CVSS v4.0 scoring guide](references/cvss-v4.md)
- [Ecosystem security tooling catalog](references/tooling.md)
