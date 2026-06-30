# Code Review — Detailed Methodology

This guide expands on each review category from the main skill file with concrete checklists, examples, and edge case guidance.

---

## Determining the Review Scope

The review scope depends on the input provided. Always clarify the scope before beginning the review.

### Scenario A: No Input — Review Uncommitted Changes

When no input is provided, review all changes in the working tree:

1. Retrieve the diff of unstaged modifications (changes not yet staged for commit).
2. Retrieve the diff of staged modifications (changes staged but not yet committed).
3. List all files with their status to identify untracked (new) files that have no diff but need full review.

### Scenario B: Commit Reference — Review a Specific Commit

When a commit identifier is provided (full hash, short hash, or other unique reference):

1. Retrieve the full content, metadata, and diff for that commit.
2. Review only the changes introduced by that commit.
3. Read the full files modified by the commit to understand context beyond the diff.

### Scenario C: Branch Name — Branch Comparison

When a branch name is provided:

1. Compute the diff between the specified branch and the current branch.
2. Review all differences between the two branches.
3. Pay attention to merge conflicts or overlapping changes if the branches have diverged significantly.

### Scenario D: Pull Request — Review a PR

When a pull request number, URL, or reference is provided:

1. Fetch the pull request metadata: title, description, linked issues, reviewer comments.
2. Fetch the full diff of all changes included in the pull request.
3. Review each file in the diff with full context.
4. Cross-reference the PR description with the actual changes — do they match?

---

## Gathering Context — In Depth

### Why Full Files Matter

A diff shows only the changed lines and a few surrounding lines. This limited view can hide:

- **Incorrect assumptions**: The changed code may assume a variable is never null, but the function above can return null.
- **Duplicate logic**: The change may reimplement something that already exists elsewhere in the file.
- **Broken patterns**: The change may break an established pattern that spans multiple functions within the same file.
- **Missing cleanup**: The change may allocate resources without matching cleanup that other code paths in the file perform.

### What to Look For in Full Files

When reading the full file:

1. **Entry and exit points**: How does execution reach the changed code? What happens after it?
2. **Variable lifecycle**: Where are variables declared, initialized, modified, and destroyed?
3. **Error propagation**: How do errors flow through the file? Does the change respect this flow?
4. **Defensive checks**: What guards exist elsewhere in the file that the changed code should mirror?
5. **Helper usage**: Are there helper functions or utilities in the file that the change should use but doesn't?

### Conventions Files

Before reviewing, check for project-specific guidance files. Common names include:

- `CONVENTIONS.md` — coding style and patterns
- `AGENTS.md` — agent-specific instructions (may contain review preferences)
- `.editorconfig` — editor formatting rules
- `CONTRIBUTING.md` — contribution guidelines
- `STYLE_GUIDE.md` — formal style guide
- `SECURITY.md` — project threat model and secure development rules
- Language-specific config files: `.eslintrc`, `.prettierrc`, `tsconfig.json`, `Cargo.toml` (lint settings), etc.

Apply these conventions when evaluating style and structure. If a convention file exists but the change violates it, reference the specific rule.

---

## Bug Detection — Detailed Checklist

### Logic Errors

- [ ] Are all conditional branches reachable? Check for impossible conditions (e.g., `if (x > 5 && x < 3)`).
- [ ] Are boolean conditions correct? Watch for inverted logic (`!flag` when `flag` was intended).
- [ ] Are comparisons using the correct operator? (`==` vs `===`, `>` vs `>=`, `!=` vs `!==`).
- [ ] Are off-by-one errors present in loops, array indexing, or range checks?
- [ ] Are `switch`/`match` statements exhaustive? Are `default`/`else` cases handled?
- [ ] Are short-circuit evaluations (`&&`, `||`, `??`) behaving as intended?
- [ ] Integer overflow or underflow — can arithmetic operations wrap around or produce incorrect results near type limits (e.g., `math.MaxInt + 1`)?
- [ ] Floating-point precision — are floating-point values compared with `==`? Can accumulation or rounding errors produce incorrect results?
- [ ] Mutation during iteration — is a collection being modified (add/delete/reorder) while it is being iterated?
- [ ] Type coercion — do implicit conversions (truthy/falsy checks, string-to-number, `==` vs `===`) produce unexpected behavior?

### Control Flow

- [ ] Are guard clauses present at the top of functions for invalid inputs?
- [ ] Is there unreachable code after `return`, `throw`, `break`, or `continue` statements?
- [ ] Are loops guaranteed to terminate? Check exit conditions.
- [ ] Are recursive functions protected against infinite recursion?
- [ ] Are `try-catch` blocks correctly scoped? Is cleanup (`finally`, `defer`) present?
- [ ] Are async/await patterns correct? Check for missing `await`, unhandled promise rejections.
- [ ] Missing deadlines/timeouts — can an I/O operation, lock acquisition, or external call block indefinitely without a timeout?
- [ ] Deadlocks — in concurrent code, can two or more goroutines/threads deadlock due to lock ordering, circular wait, or channel miscoordination?

### Edge Cases

- [ ] What happens when inputs are `null`, `undefined`, `None`, or empty?
- [ ] What happens with empty strings, zero values, or empty collections?
- [ ] What happens at boundary values (max/min integers, empty arrays, single-element lists)?
- [ ] What happens under concurrent access (if applicable)?
- [ ] What happens when external dependencies fail (network timeout, database error, file not found)?
- [ ] What happens with Unicode/special characters in string inputs?
- [ ] NaN and Infinity — do numeric computation paths guard against division by zero producing `Infinity`, or operations producing `NaN` that propagates silently?
- [ ] Negative or out-of-range values — for domain-constrained parameters (e.g., size, count, index), does the code handle negative values or values outside the valid range?

### Security — OWASP Top 10:2025 for Web Applications

The following checklist is organized by the [OWASP Top 10:2025](https://owasp.org/Top10/2025/) Web Application Security Risks categories. Each category includes actionable review checks. When reviewing, map findings to the relevant OWASP category to ensure comprehensive coverage.

#### A01 — Broken Access Control

- [ ] Are authentication/authorization checks performed before every protected operation?
- [ ] Are file paths validated to prevent directory traversal?
- [ ] Are there insecure direct object references (IDOR) — can a user access another user's resources by manipulating identifiers?
- [ ] Are role-based access controls enforced server-side (not just hidden in the UI)?
- [ ] Are CORS policies explicitly configured rather than using wildcards (`*`)?
- [ ] Are rate limits enforced on sensitive endpoints (login, password reset, API)?

#### A02 — Security Misconfiguration

- [ ] Are secrets, API keys, and tokens excluded from source code and configuration files?
- [ ] Are default credentials, default accounts, and unnecessary features disabled?
- [ ] Are security headers present (Content-Security-Policy, X-Content-Type-Options, HSTS, X-Frame-Options)?
- [ ] Are verbose error pages and debug modes disabled in production?
- [ ] Are cloud storage buckets, databases, and internal services not publicly exposed?
- [ ] Are directory listings disabled on the web server?

#### A03 — Software Supply Chain Failures

- [ ] Are all dependencies pinned to specific versions (no floating or wildcard version ranges)?
- [ ] Are dependencies regularly scanned for known vulnerabilities (CVEs)?
- [ ] Is the integrity of downloaded packages verified (checksums, signatures, lockfiles)?
- [ ] Are third-party SDKs and libraries sourced from official, trusted repositories?
- [ ] Is the provenance of build artifacts tracked and reproducible (SBOM, SLSA)?

#### A04 — Cryptographic Failures

- [ ] Are cryptographic operations using standard, well-audited libraries (not custom implementations)?
- [ ] Is sensitive data (passwords, tokens, API keys, PII) encrypted in transit (TLS 1.2+) and at rest?
- [ ] Are obsolete or broken algorithms avoided (MD5, SHA1, DES, RC4, ECB mode)?
- [ ] Are cryptographic keys managed securely (not hardcoded, proper rotation, key vault)?
- [ ] Are random values generated with cryptographically secure PRNGs (not `Math.random()`)?

#### A05 — Injection

- [ ] Is user input properly validated and sanitized before use?
- [ ] Are SQL, command, or code injection vulnerabilities prevented through parameterized queries or safe APIs?
- [ ] Is user input in OS commands escaped or avoided entirely (prefer library/API calls over shell execution)?
- [ ] Are LDAP, XPath, or XML injection risks prevented with proper encoding and parameterization?
- [ ] Are template engines configured to auto-escape output (XSS prevention)?

#### A06 — Insecure Design

- [ ] Are security requirements explicitly defined for the project (e.g., in SECURITY.md or a threat model)?
- [ ] Is the threat model documented, reviewed, and kept up to date?
- [ ] Are security controls designed in from the start, not added as an afterthought?
- [ ] Is input validation performed at the trust boundary, not deep in business logic?
- [ ] Are there enforced limits on resource consumption (request size, upload size, query complexity)?

#### A07 — Authentication Failures

- [ ] Are authentication mechanisms implemented using well-audited frameworks (no custom auth unless reviewed)?
- [ ] Are password policies enforced (minimum length, complexity, breach-list/compromised-password checking)?
- [ ] Is multi-factor authentication supported or enforced for sensitive operations?
- [ ] Are session tokens generated securely (CSPRNG) and invalidated on logout?
- [ ] Are credential recovery flows resistant to user enumeration attacks?
- [ ] Are brute-force protections in place (account lockout, rate limiting, CAPTCHA)?

#### A08 — Software or Data Integrity Failures

- [ ] Are CI/CD pipelines protected against unauthorized modifications?
- [ ] Is deserialization of untrusted data avoided or tightly sandboxed?
- [ ] Are integrity checks performed on critical configuration files and serialized data?
- [ ] Are auto-update mechanisms verified with digital signatures before applying?
- [ ] Is data integrity validated between components (checksums, HMACs, digital signatures)?

#### A09 — Security Logging and Alerting Failures

- [ ] Are authentication events (login, logout, password change, MFA setup) logged?
- [ ] Are access control failures and suspicious access patterns logged with sufficient context?
- [ ] Are logs free of sensitive data (passwords, tokens, PII, session IDs)?
- [ ] Are log entries structured and timestamped consistently (ISO 8601, JSON structured logs)?
- [ ] Are alerts configured for suspicious patterns (repeated failures, abnormal access, high-rate actions)?

#### A10 — Mishandling of Exceptional Conditions

- [ ] Does error handling avoid leaking stack traces, internal paths, or system information to users?
- [ ] Do unhandled exceptions return safe, generic responses (not raw error details)?
- [ ] Are timeout and retry policies defined, bounded, and tested?
- [ ] Does the system degrade gracefully under load or partial dependency failures?
- [ ] Are edge cases tested for robustness (null/empty inputs, boundary values, concurrent access)?

### OWASP Top 10 for Agentic Applications

If the project implements an agentic application (LLM integration, tool use, autonomous decision-making), also consider the following risks from the [OWASP Top 10 for Agentic Applications](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/). These checks apply when the code under review involves AI agents that plan, act, call tools, or communicate with other agents.

#### ASI01 — Agent Goal Hijacking

- [ ] Is all content that flows into the agent's context (user input, tool outputs, external documents, web pages) treated as potentially hostile?
- [ ] Are delimiter patterns used to separate trusted instructions from untrusted data within prompts?
- [ ] Is there defense-in-depth against prompt injection: input sanitization, output filtering, and privilege separation?
- [ ] Are canary tokens or detection mechanisms in place to identify prompt extraction attempts?

#### ASI02 — Tool Misuse

- [ ] Are tools granted only the minimum permissions needed for their intended purpose (principle of least privilege)?
- [ ] Are tool call arguments validated before execution (parameter schemas, regex constraints, allowlists)?
- [ ] Are dangerous tool operations (DELETE, DROP, EXEC) programmatically restricted regardless of what the agent requests?
- [ ] Is the agent's tool call against a declared allowlist rather than a denylist?

#### ASI03 — Identity and Privilege Abuse

- [ ] Does the agent operate with its own verified identity rather than claiming or inheriting arbitrary identities?
- [ ] Are confused deputy attacks prevented: can a low-privilege caller trick a high-privilege agent into acting on their behalf?
- [ ] Are agent credentials scoped to the minimum required for the task, and rotated regularly?
- [ ] Is every agent-bound action logged with the verified principal identity?

#### ASI04 — Supply Chain Vulnerabilities

- [ ] Are third-party agent tools, MCP servers, and plugin packages vetted and pinned to specific versions?
- [ ] Are tool descriptions from external packages reviewed for suspicious or manipulative language before integration?
- [ ] Is the provenance of agent frameworks, model files, and tool dependencies verified?
- [ ] Are new or updated tools tested in a sandbox before production deployment?

#### ASI05 — Unexpected Code Execution

- [ ] Is code execution by the agent sandboxed (isolated environment, restricted filesystem, no network access unless needed)?
- [ ] Does code execution require human approval (REVIEW gate) for high-risk operations?
- [ ] Are code execution tool arguments scanned for malicious patterns before execution?
- [ ] Is the code execution environment ephemeral and cleaned up after each invocation?

#### ASI06 — Memory and Context Poisoning

- [ ] Is the agent's persistent memory (long-term storage, vector databases) validated before storage and retrieval?
- [ ] Are values destined for persistent memory scanned for poisoning patterns (instruction overrides, false authorization claims)?
- [ ] Can poisoned memories be identified and purged? Is there monitoring for anomalous memory writes?
- [ ] Are session contexts isolated so one user's context cannot contaminate another's?

#### ASI07 — Insecure Inter-Agent Communication

- [ ] Are agent-to-agent messages authenticated and integrity-protected (signed, encrypted)?
- [ ] Is the delegation chain depth limited and monitored (how many hops can a task be forwarded)?
- [ ] Can a compromised agent impersonate another agent or the orchestrator?
- [ ] Are cross-agent permissions explicitly defined — does Agent B trust Agent A's request without verification?

#### ASI08 — Cascading Failures

- [ ] Does the system fail closed (deny actions) rather than fail open when the authorization or policy service is unreachable?
- [ ] Are there circuit breakers to prevent failure propagation across agents?
- [ ] Are there monitoring alerts for unusual deny-rate spikes or failure cascades?
- [ ] Does the agent have safe fallback behavior defined for each dependency failure?

#### ASI09 — Human-Agent Trust Exploitation

- [ ] Do human approval workflows show the raw, unmodified intent — not an agent-generated summary that may be deceptive?
- [ ] Are high-frequency approval requests rate-limited to prevent approval fatigue attacks?
- [ ] Is the agent's output labeled as AI-generated so human operators can calibrate trust appropriately?
- [ ] Are approval justifications generated by the policy engine, not by the agent itself?

#### ASI10 — Rogue Agents

- [ ] Is there behavioral drift monitoring to detect sustained shifts in agent behavior (action volume, deny rate, delegation depth)?
- [ ] Are agent actions auditable with a full receipt chain — can you reconstruct what happened and why?
- [ ] Are there kill-switch or circuit-breaker mechanisms to halt an agent exhibiting anomalous behavior?
- [ ] Are agent goals periodically verified against operator intent (alignment checks, evaluation benchmarks)?

### Error Handling

- [ ] Are errors silently caught and ignored without logging or propagation?
- [ ] Are exceptions thrown in contexts where callers don't expect them?
- [ ] Do error messages leak sensitive information?
- [ ] Are error types consistent with the project's error handling conventions?
- [ ] Is resource cleanup guaranteed in error paths (files, connections, locks)?
- [ ] Are retry policies appropriate for transient failures?
- [ ] Partial failure in batch operations — when processing a batch, does the code define whether partial success is acceptable, and are callers informed which items succeeded and which failed?
- [ ] Error cause preservation — when wrapping or translating errors, is the original error cause preserved (e.g., `fmt.Errorf("...: %w", err)` or `cause` chain) so callers can inspect the root cause?

---

## Structure Review — Detailed Checklist

### Pattern Adherence

- [ ] Does the change follow the same naming conventions as surrounding code?
- [ ] Does it use the same architectural patterns (MVC, repository, dependency injection)?
- [ ] Are function/module boundaries consistent with the project's organization?
- [ ] Does it reuse existing abstractions rather than reimplementing them?
- [ ] Are imports/dependencies organized consistently with the project's conventions?
- [ ] Circular dependencies — does the change introduce import cycles between packages/modules, or tighten coupling that will make future refactoring difficult?

### Abstraction Usage

- [ ] Is there an existing utility, helper, or service that could replace new code?
- [ ] Is the change introducing a new abstraction that overlaps with an existing one?
- [ ] Are new abstractions properly named and documented?
- [ ] Is the level of abstraction appropriate? (Not too high-level that it hides important detail, not too low-level that it duplicates boilerplate.)

### Nesting and Complexity

- [ ] Can deeply nested conditionals be flattened with early returns or guard clauses?
- [ ] Can complex expressions be broken into named intermediate variables?
- [ ] Can a long function be split into smaller, well-named helper functions?
- [ ] Are there more than 3-4 levels of indentation? Each level beyond 3 is a red flag.
- [ ] Is the cyclomatic complexity reasonable for the domain? (Many branches may be unavoidable in business logic.)

### Duplication

- [ ] Does this change duplicate logic that exists elsewhere in the codebase?
- [ ] Could a shared helper function or utility eliminate the duplication?
- [ ] Is the duplication intentional (e.g., decoupling two modules that should evolve independently)?

---

## Performance — When to Flag

Performance issues should only be flagged when they are **obviously problematic** — not when they are merely suboptimal. A clear performance problem means:

### Clear Performance Problems

- **O(n²) or worse on unbounded data**: A nested loop over user-provided data of unknown size. If `n` is guaranteed to be small (e.g., the number of days in a week), it's not a problem.
- **N+1 queries**: Fetching related data one-by-one inside a loop instead of using a batch or joined query. Look for database calls, API calls, or file reads inside loops.
- **Blocking I/O on hot paths**: Synchronous file, network, or database operations in request handlers, UI rendering, or tight computational loops.
- **Unnecessary allocations**: Creating large objects or arrays inside tight loops or frequently called functions when a single allocation could be reused.
- **Missing caching**: Expensive computations repeated with identical inputs in quick succession.
- **Memory leaks**: Are caches unbounded (no eviction policy)? Are resources (files, connections, event listeners, timers) closed/removed in all paths? Do closures retain references to large objects unnecessarily?
- **Unbounded concurrency**: Are goroutines, threads, or async tasks launched without bounds (e.g., inside a loop over unbounded data), potentially exhausting system resources?

### What NOT to Flag

- Micro-optimizations that have no measurable impact.
- Theoretical performance problems without evidence that the data size will grow.
- Premature optimization concerns — correctness and clarity come first.
- Using a "slower" data structure when the collection size is trivially small.

---

## Behavior Changes — Detection Guide

Behavior changes are modifications that alter what the code *does* beyond fixing bugs. They can be intentional (a new feature) or unintentional (a side effect). Always raise behavioral changes so the author can confirm intent.

### Common Behavioral Changes

| Category | Examples |
|---|---|
| **Defaults** | Changed default parameter values, configuration defaults, or fallback values. |
| **Signatures** | Modified function signatures (added/removed/reordered parameters), changed return types. |
| **Error semantics** | Changed error messages, error codes, HTTP status codes, or exception types. |
| **API contracts** | Changed JSON field names, serialization formats, API endpoint behaviors, or protocol compatibility. |
| **Side effects** | Added, removed, or reordered side effects (logging, metrics, notifications, state mutations). |
| **Ordering** | Changed iteration order, sort order, or execution order of dependent operations. |
| **Validation** | Relaxed or tightened input validation that changes what inputs are accepted. |
| **Timing** | Added delays, timeouts, or async behavior that changes the operational characteristics. |

### How to Identify Unintentional Behavior Changes

1. Compare the old and new behavior for the same inputs — are the outputs identical?
2. Check whether error conditions are handled the same way.
3. Look for removed side effects that other code might depend on.
4. Verify that serialization formats are backward-compatible if the change modifies data structures.
5. Check whether the change affects any public API (function, endpoint, event, or protocol).

---

## The Certainty Principle — In Depth

The most common review mistake is flagging something that isn't actually a problem. Before raising an issue, apply these checks:

### Is It Actually a Bug?

- **Reproduce it mentally**: Walk through the code with concrete inputs. Does it produce the wrong result?
- **Check the context**: Read the caller and callee. Does the surrounding code prevent the bug from manifesting?
- **Check the tests**: Are there tests that would catch this? If tests pass, is your analysis wrong?

### Is It a Realistic Scenario?

- Don't flag "this could be null" if the function is only called after a null check in every caller.
- Don't flag "this could overflow" if the input is validated to a safe range upstream.
- Do flag realistic edge cases with concrete examples: "If `user.email` is empty (which happens when OAuth doesn't return email scope), this will throw on line 42."

### When You're Unsure

- **Say you're unsure**: "I'm not confident about X — could you confirm?" is better than a false positive.
- **Ask for clarification**: If the code's intent is unclear, ask what it's supposed to do before assuming it's wrong.
- **Investigate more**: Search the codebase for similar patterns, consult library or API documentation, or research best practices before flagging.

### The Pre-Existing Code Rule

Only review the changes introduced by the commit, PR, or branch — **not** pre-existing code that wasn't modified. If you spot a bug in unchanged code that is **directly affected** by the change (e.g., the change introduces a caller to a buggy function), you may mention it as context. Otherwise, leave it for a separate review.

---

## Issue Format

Every issue in the review report must follow this structure. For each finding, provide:

1. **Issue number** — a sequential number (1, 2, 3…) that uniquely identifies the finding in the report.
2. **Severity tag** — exactly one of `MUST FIX`, `SHOULD FIX`, or `CONSIDER`:
   - **MUST FIX**: critical bugs, security issues, data loss risks — blocking issues.
   - **SHOULD FIX**: design problems, maintainability issues, likely future bugs — important but not blocking.
   - **CONSIDER**: style nits, minor optimizations, subjective improvements — optional.
3. **One-line summary** — a concise description of the issue.
4. **File path and line reference** — e.g., `src/auth/login.ts#L42`.
5. **Why it is a problem** — state the realistic scenario or input that triggers the issue.
6. **Suggested fix** — one or more concrete fix options labeled with Latin letters (a, b, c…), giving the author actionable alternatives.

---

## Output Examples

### Example: Bug with Severity

> **#1 MUST FIX** — SQL injection in user lookup
>
> The `user_id` parameter is passed directly into the SQL query on line 47 via string interpolation. This allows SQL injection if `user_id` comes from user input.
>
> **Why it is a problem:** The function is called from the `/api/users/:id` endpoint where `:id` is user-controlled. An attacker can inject arbitrary SQL, potentially extracting, modifying, or deleting data.
>
> **Suggested fix:**
> a) Use parameterized queries with the database driver's placeholder syntax (`db.query('SELECT * FROM users WHERE id = ?', [user_id])`).
> b) Use the ORM's safe binding methods if available (e.g., `User.where('id', user_id)`).

### Example: Structural Issue

> **#2 SHOULD FIX** — Database access pattern inconsistency
>
> This function introduces a new pattern for database access (raw queries in the controller) while the rest of the codebase uses the repository layer (`src/repositories/`).
>
> **Why it is a problem:** Mixing data access patterns makes the codebase harder to maintain and test. Future developers won't know which pattern to follow, leading to inconsistent code.
>
> **Suggested fix:**
> a) Move the query to a repository method in `src/repositories/user.js` to maintain consistency with the existing pattern.
> b) If the existing `UserRepository.findById()` already covers this case, reuse it directly instead of writing a new query.

### Example: Performance Concern

> **#3 SHOULD FIX** — N+1 database queries in order processing loop
>
> The loop on line 82-95 makes a database query inside the loop body for each item in `orders`.
>
> **Why it is a problem:** If a user has 100 orders, this results in 100 sequential database round-trips. For 1,000 orders, the page load time becomes unacceptable. This is a classic N+1 pattern.
>
> **Suggested fix:**
> a) Fetch all required data in a single batch query using `WHERE id IN (...)` or a JOIN.
> b) Use the ORM's eager loading or batch loading mechanism to prefetch related data.

### Example: Being Unsure

> **#4 CONSIDER** — Error silently replaced with defaults
>
> The error from `parseConfig()` on line 34 is caught but only logged — the function continues with a default config.
>
> **Why it is a problem:** The caller on line 12 assumes the config is always valid, which would break if a malformed config is silently replaced with defaults that don't match the expected schema.
>
> **Suggested fix:**
> a) Re-throw the error after logging so the caller can handle the failure explicitly.
> b) Return a `Result` type or error value so the caller is forced to check whether parsing succeeded.
> c) If the current behavior is intentional, add a comment explaining why silent fallback is acceptable here.

### Example: Behavior Change

> **#5 MUST FIX** — Breaking change to formatCurrency() signature
>
> The third parameter of `formatCurrency()` was changed from `locale` (string) to `options` (object) on line 128. This is a breaking change for any caller passing a locale string.
>
> **Why it is a problem:** The codebase has 4 callers in `src/billing/` that still pass a locale string — those will now receive incorrect formatting, potentially causing financial display errors in customer invoices.
>
> **Suggested fix:**
> a) Add an overloaded signature that accepts both `locale` (string) and `options` (object) so existing callers continue to work.
> b) Update all 4 callers in `src/billing/` to pass an options object instead of a locale string before merging this change.

---

## Review Workflow Summary

1. **Determine scope**: Identify what to review based on input (uncommitted changes, commit, branch, PR).
2. **Gather the diff**: Retrieve the set of changes.
3. **List affected files**: Identify all modified, added, and deleted files.
4. **Read full files**: For each modified file, read the entire file for context.
5. **Check conventions**: Locate and apply any project-specific conventions files.
6. **Review systematically**: Go through Bugs → Structure → Performance → Behavior Changes for each file.
7. **Apply certainty checks**: Verify every finding before including it in the output.
8. **Format output**: Follow output guidelines for clarity, severity, and tone.
