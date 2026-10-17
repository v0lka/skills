# Business-Logic Errors, Data Races, and Race Conditions — Review Reference

Two domains that scanners cannot find and OWASP categories only partially cover. Both are mandatory review domains for every scope.

---

## Part 1 — Business-Logic Errors

A business-logic vulnerability is a flaw in the *application of business rules* — the code does exactly what it was written to do, but what it does is exploitable. The code is "correct"; the behavior is wrong. That is why the primary evidence source is the **specification** (OpenAPI schemas, `docs/`, `specs/`, RFCs, ADRs, SECURITY.md threat model), and the method is **differential testing of intent vs implementation**: derive the invariants the spec implies, then try to violate each one through the code.

**CWEs:** CWE-840 (Business Logic Errors) — primary; CWE-841 (Improper Handling of Inconsistent Data Structures); CWE-670 (Always-Incorrect Control Flow Implementation); CWE-691 (Insufficient Control Flow Management); CWE-223 / CWE-284 when the flaw is an authorization decision. OWASP: A06:2025 Insecure Design (business-logic flaws are named there explicitly); older reports may say A04:2021.

### Deriving Invariants from the Spec

For every operation in scope, write down the invariants the spec implies, e.g.:

- "A refund never exceeds the original payment amount."
- "An order transitions PAID → SHIPPED → DELIVERED, never backwards, never skipping."
- "One coupon per order, single use, expires at T."
- "Only the account owner or support role with reason can view PII."
- "Withdrawals require balance ≥ amount at execution time, not at request time."

Then hunt for code paths that violate each invariant. Where there is no spec, derive the invariant from the domain (money, permissions, quotas, workflow) and say in the finding that the invariant was inferred, not specified.

### Checklist

- [ ] **Client-trusted values:** prices, totals, discounts, currencies, roles, flags arriving from the client and used without server-side recomputation (tamper → pay 0.01 for a 999 item).
- [ ] **Negative and boundary quantities:** qty = −1 flips totals; qty = 0 in division; integer overflow/underflow in money math (`int32` cents overflowing at ~21.5M units).
- [ ] **Order of operations:** can step N run before step N−1? (Ship before pay; use coupon before validating cart; upload before checking quota.)
- [ ] **Skipped steps:** direct API access to a later workflow step bypasses earlier validations; state machine transitions not guarded server-side.
- [ ] **Duplicate / replay:** same request replayed (idempotency keys missing or client-controlled), double redemption of one-time codes/coupons/points, retry storms crediting twice.
- [ ] **Timing windows in business flows:** price/quote valid indefinitely? rate quoted at request time honored at execution after market move? (pairs with TOCTOU below).
- [ ] **Time manipulation:** expiry checked against client-supplied time or unvalidated `exp`; "trial ends" logic trusting local dates.
- [ ] **Multi-tenant boundary in logic:** does the business rule hold per-tenant, or can resources of tenant A satisfy constraints for tenant B?
- [ ] **Error-path business impact:** what does the system do when the rule engine / fraud check / policy service fails? Failing open is a business-logic finding (CWE-636), not just an availability one.
- [ ] **Asymmetry between create and update:** strict validation on create, lax on update (or PATCH partials) — set fields the create path would reject.
- [ ] **Consistency across replicas:** values derived from two sources (cache + DB, two services) that can disagree and be arbitrated in the attacker's favor.

### Scenario Requirements

A business-logic finding stands on the invariant it violates. State it as:

> **Invariant (from spec/ADR X):** refunds ≤ payment. **Violation:** `refund.Amount` validated only client-side; `POST /refunds` accepts `amount > payment.total`. **Scenario:** attacker refunds 10,000 against a 10.00 payment. **Impact:** direct financial loss.

Score honestly: most business-logic findings are AV:N (API-reachable), PR:L (authenticated customer), and their impact metrics reflect the concrete loss (VI:H for money; VC:H for cross-tenant data reads). Where the violation requires an insider or unusual product state, say so — it changes PR and AT.

---

## Part 2 — Data Races and Race Conditions

Three related but distinct defects — name which one you found:

1. **Data race** (CWE-366, "Race Condition within a Thread" family; language-level): two concurrent accesses to the same memory location, at least one a write, with no synchronization → undefined behavior (torn reads, corrupted structures, crashes). The bug is *unsynchronized access*.
2. **Race condition** (CWE-362, "Concurrent Execution using Shared Resource with Improper Synchronization"): the logic assumes interleaving that isn't guaranteed — check-then-act (TOCTOU is its file-system twin, CWE-367), read-modify-write, lazy init. Memory may be perfectly synchronized per-operation; the *sequence* still isn't atomic.
3. **TOCTOU** (CWE-367, "Time-of-check Time-of-use"): the classic check-act gap on external state — files, cache entries, DB rows, external APIs. Also CWE-667 (Improper Locking) for lock-discipline defects (missing locks, wrong lock, lock scope too small).

Security-relevant races are not "just crashes": the canonical exploit is **check-then-act on an authorization or quota** — balance check and withdrawal as two steps, coupon validation and redemption as two steps, uniqueness check and insert as two steps. The attacker wins the interleaving and gets the forbidden outcome. This is a security finding even though nothing "crashes".

### Checklist — Local Concurrency

- [ ] Shared mutable state (maps, slices, counters, caches, singletons, config) accessed from concurrent goroutines/threads/async tasks without a mutex/atomic/channel — check the language's escape routes (Go maps are not concurrent-safe; JS `async` interleaves at every `await`; Python `asyncio` interleaves but threads need locks).
- [ ] Lazy initialization / singleton creation without `sync.Once`/double-checked locking done correctly.
- [ ] Read-modify-write sequences (balance -= x, counter++, cache stampede fills) not atomic — use atomic ops, transactions, or `UPDATE … WHERE` in SQL.
- [ ] Lock discipline: every write path locked? the *same* lock/mutex instance (per-key vs global)? lock scope covers the whole invariant, not just the field? no double-unlock / unlock-on-nil? (CWE-667)
- [ ] Deadlock potential: multiple locks acquired in inconsistent order; channel waits without timeouts; goroutine leaks blocking future runs (availability impact).
- [ ] Context/cancellation: shared state mutated after request cancellation; `errgroup`/`WaitGroup` misuse letting writes continue post-response.
- [ ] Unbounded goroutine/async-task spawning on user-triggered paths (DoS amplifier).

### Checklist — Distributed / Storage-Level Races

- [ ] Check-then-act against the database in two queries instead of one conditional statement (`SELECT` then `INSERT` without a unique constraint or transaction isolation; fix: unique index + handle conflict, or `UPDATE … WHERE balance >= ?`).
- [ ] Cache-aside races: concurrent misses both compute and write; stale-cache-after-write windows used to resurrect revoked permissions/roles.
- [ ] Idempotency: retry-safe endpoints? Idempotency keys unique-constrained and stored with the result? (replay → double charge / double action).
- [ ] Cross-service sequences (reserve stock → charge → confirm) without compensation/locking — partial failure leaves exploitable intermediate states.
- [ ] Webhooks/callbacks arriving concurrently with the state they mutate; ordering assumptions without sequence numbers.
- [ ] Session/token revocation racing active request handling — "revoked but the in-flight check already passed" windows.

### Proving a Race Finding

The scenario must state the **interleaving** — who runs what between the check and the act:

> **Invariant:** a promo code is single-use. **Code:** `valid := repo.Get(code)` → `repo.MarkUsed(code)` — two statements, no transaction/unique constraint. **Interleaving:** attacker fires N parallel `POST /redeem`; at t1 all N read `valid=true`; at t2 all N call MarkUsed (no-op on 2nd+); at t3 all N credits applied. **Evidence:** no unique constraint on `promo_redemptions(code)`; handler uses the shared `*sql.DB` without transaction. **Impact:** unlimited redemptions.

For data races, name the exact shared variable, the unsynchronized writer/reader pair, and the realistic trigger (concurrent requests to the same handler, cache refresh, shutdown). If a race detector can demonstrate it (`go test -race`, TSan, Loom), say so and run it if feasible — read-only runs only.

### CVSS Notes for Races

- `AT:P` (Attack Requirements: Present) fits races the attacker must *win* — CVSS 4.0 explicitly names "a race condition must be won" under AT:Present. If the window is trivially wide (two user-controlled sequential requests), `AT:N` with a justification is defensible; if winning needs precise timing, `AT:P`.
- Data races with only crash impact score VA (availability); check-then-act authorization races score VC/VI per what the stolen interleaving yields.
- Concurrent-abuse DoS (unbounded spawning) scores VA on the vulnerable system; scale honestly.

### Detectors (see [tooling](tooling.md) for invocation)

`go test -race` / `go run -race` (Go), ThreadSanitizer (C/C++/Rust/Swift `-fsanitize=thread`), Loom & Miri (Rust), `jcstress` (JVM). For .NET there is no mainstream race detector — code reading against the checklist above is the primary instrument. A clean detector run does **not** prove absence: coverage of concurrent paths decides, so report the run scope (which packages/tests executed).

---

## Output Mapping

| Defect | Primary CWE | Supporting CWEs | OWASP category |
|---|---|---|---|
| Business-rule violation | CWE-840 | CWE-670, CWE-691, CWE-841 | A06:2025 Insecure Design (A04:2021) |
| Check-then-act / logic race | CWE-362 | CWE-367, CWE-840 | A06:2025; report as Race condition |
| TOCTOU on files/external state | CWE-367 | CWE-362, CWE-59 (link following) | A01:2025 (path/permission TOCTOU) |
| Unsynchronized memory access | CWE-366 | CWE-362 | A10:2025 when it crashes |
| Lock-discipline defect | CWE-667 | CWE-362, CWE-366 | A10:2025 when mishandled condition results |
| Fail-open policy/error path | CWE-636 | CWE-840 | A10:2025 Mishandling of Exceptional Conditions |
