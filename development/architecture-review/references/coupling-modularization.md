# Coupling and Modularization

Detailed checks for coupling quality using the Balanced Coupling Model (Vlad Khononov, *Balancing Coupling in Software Design*). The premise: **coupling is not inherently bad — misdesigned coupling is bad.** The goal is balanced coupling, not zero coupling. This reference complements [structure and boundaries](structure-and-boundaries.md): that file checks *where things live and which direction dependencies point*; this one classifies *the quality of each dependency* — how much knowledge it shares, across what distance, between components of what volatility — and what to do when the balance is wrong.

The governing formula:

```
MODULARITY = (STRENGTH XOR DISTANCE) OR NOT VOLATILITY
```

High integration strength belongs close together (same module/service); low integration strength may live far apart (separate services); low volatility tolerates a strength/distance mismatch.

**Reporting requirements for this area:** every balance verdict and connascence finding must cite the dependency it describes — the module pair plus the import, call, or code that evidences it. Volatility claims require evidence (git change history, domain documentation); when neither is available, report volatility as **Not confirmed** and judge strength × distance alone — never guess a subdomain classification.

## The three dimensions of coupling

Classify every significant cross-boundary dependency (module→module, context→context, service→service) along three dimensions before judging it.

### 1. Integration strength — what knowledge is shared

From strongest (worst) to weakest (best):

| Level | Type | Shared knowledge | Typical evidence |
| ----- | ---- | ---------------- | ---------------- |
| 1 | **Intrusive** | Non-public internals | ORM query against another service's tables; reflection into private fields; importing another module's `_internal`/`models` package |
| 2 | **Functional** | Business logic and rules | The same validation or calculation implemented in two modules; one module's correctness depends on *how* another does its work |
| 3 | **Model** | Domain models | The identical entity/DTO definition reused across contexts or services |
| 4 | **Contract** | Explicit interfaces only | Public APIs, owner-side DTOs, protocols, published events |

### 2. Distance — how far knowledge travels

From closest to most distant:

1. Methods within the same class
2. Classes in the same file
3. Classes in the same package/namespace
4. Modules in different namespaces/packages
5. Separate services
6. Services owned by different teams
7. Different systems/organizations

### 3. Volatility — how often the coupled knowledge changes

Classify each component by DDD subdomain type:

- **Core subdomain** — competitive advantage, changes frequently (high volatility).
- **Supporting subdomain** — necessary but not differentiating (low volatility).
- **Generic subdomain** — solved problems: authentication libraries, date handling, logging (low volatility).

Evidence for volatility: change frequency per module from git history (`git log --format= --name-only` grouped by directory), stated change plans in docs/roadmaps, domain knowledge supplied by the team. Without any of these, volatility is **Not confirmed** — see the reporting requirements above.

## The balance matrix

| Integration strength | Distance | Verdict |
| -------------------- | -------- | ------- |
| High (1–2) | High (5–7) | ❌ Complexity — distributed monolith |
| Low (3–4) | Low (1–3) | ❌ Complexity — unnecessary abstraction |
| High (1–2) | Low (1–3) | ✅ Modularity — related things together |
| Low (3–4) | High (5–7) | ✅ Modularity — independent things apart |

**Exception:** when the volatility of the coupled knowledge is LOW, a strength/distance mismatch is acceptable — stable knowledge does not punish strong long-distance coupling. Verify the exception before flagging, and state it in the report when it applies.

Review procedure:

1. List the significant cross-boundary dependency pairs from the layer/module map.
2. For each pair, classify strength (using the evidence column above), distance, and volatility.
3. Mark ❌ pairs; check the volatility exception before confirming any of them as findings.
4. Prioritize by degree — how many edges share the mismatch — and by the intrusiveness of the strongest edge.

## Integration-strength violations

### Intrusive coupling (strongest — finding candidates)

What to check:

- One service reading or writing another service's database or tables directly.
- Code reaching past another module's public API: imports of `internal`, `models`, `db` packages, or `_`-prefixed/private symbols of another module.
- Reflection or metadata hacks used to read another component's private state.
- Synchronized deployments: two services that cannot be released independently (shared release steps, tests asserting another service's internal behavior).

Detection heuristics:

- Import paths that skip a public API: `from ordering import inventory._internal.models`, `require('../inventory/db/client')`.
- SQL or ORM code in one context naming another context's tables.
- Reflection near cross-module boundaries: `getattr(obj, "_cache")`, Java `setAccessible(true)`.

Remediation — Intrusive → Contract:

1. Identify what the consumer actually needs from the internals.
2. Define an explicit contract (interface, DTO, or event) owned by the exposing side.
3. Implement a public API or adapter on the exposing side.
4. Route all access through the contract and make internals non-importable (package visibility, boundary enforcement via tooling).

### Functional coupling

What to check:

- The same business rule implemented in two modules — duplicate validation, duplicate price or status calculation. They *will* drift. This overlaps with "Duplicated domain concepts" in structure-and-boundaries.md; here the question is who should *own* the rule.
- A module whose correctness depends on *how* another performs its work, not just on what it returns (order-dependent operations, replicated rounding or encoding logic).

Detection heuristics:

- Rule names, constants, and status strings duplicated across modules; similarly named functions with near-identical bodies in different packages.

Remediation — Functional → Model coupling: extract the rule to a single owner and consume it via an explicit dependency. When ownership spans contexts, prefer publishing the rule's *outcome* as data (events, contract fields) over sharing the code.

### Model coupling

What to check:

- Identical entity/domain classes defined or shared across contexts or services, with drifting fields.
- A shared `models`/`types` package imported by every context.
- Database tables with no single owner, written by several contexts.

Detection heuristics:

- The same class or table name in multiple contexts; diff the fields — drift is the evidence that the copies have already diverged.

Remediation — Model → Contract coupling: integration-specific DTOs mapped at the boundaries; each context keeps its internal model private; contracts are versioned independently of models. See the Extract Contract pattern below.

## Connascence catalog

Connascence names the *specific* knowledge two components must agree on — the unit of coupling to minimize. Static forms are visible in source; dynamic forms appear only at runtime and are harder to detect and fix.

| # | Type | Components must agree on | Search for | Convert to |
| - | ---- | ------------------------ | ---------- | ---------- |
| 1 | Name (CoN) | Entity names | ordinary identifier references | — (weakest) |
| 2 | Type (CoT) | Entity types | rigid type annotations where a protocol would do | CoN — duck typing / protocols |
| 3 | Meaning (CoM) | Meaning of values | magic numbers/strings across modules (`if role == 0`) | CoN — named constants/enums |
| 4 | Position (CoP) | Order of values | long positional parameter lists; positional tuples crossing modules | CoN — parameter objects, named args, builders |
| 5 | Algorithm (CoA) | The same algorithm | duplicated hashing/encoding/calculation logic | CoN — a single algorithm home |
| 6 | Execution (CoE) | Call order | setter sequences; `init()` required before use | explicit constructors/builders/state machines |
| 7 | Timing (CoTm) | Timing of execution | sleeps synchronizing modules; expiry-window assumptions | explicit async/synchronization primitives |
| 8 | Value (CoV) | Several values together | redundant stored state (`area` stored beside `width`/`height`) | computed derived values, invariant-preserving methods |
| 9 | Identity (CoI) | The same instance | module-level singletons shared implicitly | explicit DI wiring at the composition root |

The highest-impact forms, violation vs compliant:

```python
# CoA — Violation: the hashing algorithm lives in two places and must stay in sync
class AuthService:
    def verify_password(self, password, stored_hash):
        return hashlib.sha256(password.encode()).hexdigest() == stored_hash

# CoA — Compliant: one algorithm home; consumers reference it by name
class PasswordHasher:
    @staticmethod
    def hash(value: str) -> str:
        return hashlib.sha256(value.encode()).hexdigest()

class AuthService:
    def verify_password(self, password, stored_hash):
        return PasswordHasher.hash(password) == stored_hash
```

```python
# CoM — Violation: every consumer must know that 0 means admin
if get_user_role(user) == 0:
    grant_access()

# CoM — Compliant: meaning reduced to a name
if get_user_role(user) == Role.ADMIN:
    grant_access()
```

```python
# CoE — Violation: set_subject after send() is silently lost; order is implicit
email = Email()
email.set_recipient(addr); email.send(); email.set_subject(s)

# CoE — Compliant: the builder makes a half-built email unrepresentable
email = EmailBuilder().recipient(addr).subject(s).build()
email.send()
```

```python
# CoI — Violation: Subscriber silently depends on the Publisher's exact Queue instance
class Subscriber:
    def __init__(self, publisher):
        self._pub = publisher
    def consume(self):
        return self._pub.queue.get()

# CoI — Compliant: identity made explicit, wired once at the composition root
queue = Queue()
publisher = Publisher(queue)
subscriber = Subscriber(queue)
```

Connascence rules for review:

1. Minimize overall connascence.
2. Minimize connascence **crossing module boundaries**.
3. Maximize it **within** a boundary — internal CoN/CoT is cheap.
4. Convert stronger forms to weaker ones (the "Convert to" column above).
5. As distance grows, allowable connascence weakens: CoM/CoP/CoA across services are findings; the same forms inside one class usually are not.

Priority rule: flag first the **strongest connascence at the longest distance with the most participants** (high strength × low locality × high degree).

## Metrics and thresholds

Metrics are inspection triggers, not automatic findings — confirm by reading the code before reporting anything.

**CBO** (Coupling Between Objects — unique classes a class is coupled to via calls, fields, inheritance, parameter/return/exception types):

| Range | Assessment |
| ----- | ---------- |
| 0–8   | Healthy |
| 9–14  | Warning — inspect |
| >14   | Critical candidate — refactor |

**Afferent (Ca)** — how many classes depend *on* this one. High Ca suits stable infrastructure (logging, utils): changes there affect many, so the code must stay stable.

**Efferent (Ce)** — how many classes this one depends on. High Ce on a class that should be stable is suspect.

**Instability index** `I = Ce / (Ce + Ca)`: 0 = maximally stable, 1 = maximally unstable. **0.3–0.7 is the "zone of pain"** for frequently-changing modules. Stable Abstractions Principle: stable packages (I→0) should be abstract; unstable ones (I→1) concrete.

Quick assessment heuristics:

| Indicator | Threshold | Suggests |
| --------- | --------- | -------- |
| Method parameters | >5 | parameter object (CoP) |
| Import statements per class | >15 | split responsibilities |
| Class lines | >500 | extract classes |
| Public methods | >20 | split the interface |
| Inheritance depth | >4 | prefer composition |

Measurement tools: `import-linter`/`pydeps` (Python), `dependency-cruiser`/`madge` (JS/TS), ArchUnit/`ckjm` (Java), NDepend (.NET), `depguard`/`go-arch-lint` (Go), SonarQube (multi-language). If a tool ran, cite its numbers; if metrics are estimated from reading, say so.

## Refactoring strategies

By distance problem:

- **High strength + high distance (distributed monolith):** Option A — reduce distance, merge the modules/services. Option B — reduce strength, introduce contracts or async messaging. Choose using volatility: volatile (core) knowledge argues for owning the pair together or cutting the strength; stable knowledge can stay as it is.
- **Low strength + low distance (over-abstraction):** the formula fails in the other direction too — remove indirection layers, inline overly generic code, combine closely-related classes.

By connascence type — use the "Convert to" column of the catalog above.

Patterns for strength problems; DIP, dependency injection, facades, and composition roots are covered in [structure and boundaries](structure-and-boundaries.md) — the two remediation catalogs are meant to be combined:

```python
# Extract Contract (Model → Contract) — Violation: B imports A's domain model
from orders.models import Order            # cross-service model coupling

# Compliant: A publishes a DTO; B depends on the contract only
@dataclass
class OrderDTO:
    customer_id: str
    item_ids: list[str]
    status: str

class OrderService:                        # inside service A
    def get_order(self, order_id) -> OrderDTO:
        order = self._repository.find(order_id)
        return OrderDTO(
            customer_id=order.customer.id,
            item_ids=[i.id for i in order.items],
            status=self._map_status(order.internal_status),
        )
```

```python
# Event-driven decoupling (Functional → lower strength) — when the coupling is only causal
# Violation: synchronous knowledge of two downstream modules
def place_order(self, order):
    self._inventory.reserve(order.items)
    self._notifications.send(order.customer)

# Compliant: publish an event; subscribers own their reactions
def place_order(self, order):
    self._events.publish(OrderPlaced(order))
```

## Mapping findings to consequences

Severity follows the report-wide definitions; for this area specifically:

- **CRITICAL** — intrusive coupling across deployment boundaries: cross-service database access, one service writing another's tables, reflection into another service's state; coupled deployments that make independent releases impossible.
- **HIGH** — distributed-monolith shape: model coupling across services with observed field drift; functional coupling of core-subdomain rules across long distances; the strongest connascence (CoA/CoE/CoI) crossing module boundaries; critical-range metrics on frequently-changed modules.
- **MEDIUM** — contained mismatches: contract coupling that still leaks internals; CoM/CoP across modules within one service; warning-range metrics; over-abstraction in one area.
- **LOW** — hygiene: naming-level connascence worth converting, missing volatility evidence, metric drift without a confirmed consequence.

For every finding, name the failure it predicts: "a schema change in inventory breaks ordering silently", "every release of payments requires a matching release of notifications", "the duplicated rounding rule diverged — checkout and invoice prices differ". Where the low-volatility exception applies, say so and do not flag the pair.
