# Structure and Boundaries

Detailed check catalog for the structural half of an architecture review: layering, dependency direction, bounded contexts, responsibility sizing, and coupling. Each section lists what to check, how to detect violations, and how to remediate them.

## Layering and dependency direction

The canonical layer rules (adapt naming to the project's style — the *direction* is what matters):

| Layer | May depend on | Contains |
| ----- | ------------- | -------- |
| Domain (core) | Nothing | Business logic, domain models, repository/driver interfaces |
| Application | Domain | Use cases, orchestration of domain objects |
| Infrastructure | Domain (implements its interfaces) | Databases, external service clients, messaging, frameworks |
| Presentation | Application | HTTP/GraphQL/CLI transports, controllers, views |

Common violations:

- Domain code importing infrastructure packages (ORMs, drivers, HTTP clients, cloud SDKs).
- Infrastructure importing application services instead of implementing domain interfaces.
- Presentation calling repositories or the database directly, bypassing the application layer.
- Business logic living in controllers or in framework base classes.

Detection heuristics:

- Trace imports layer-to-layer: for each module in the domain, search for imports of `infra`, `db`, `database`, `storage`, `http`, `sqlalchemy`, `gorm`, `mongoose`, `redis`, cloud SDKs. Any hit inside domain code is a direction violation.
- In Python/TypeScript, relative imports climbing out of the package (`from ..infra import ...`, `require('../../db/client')`) crossing a layer boundary are suspect.
- In Go, check `internal/` package trees: domain packages should not import `infrastructure` or transport packages.
- In Java/Spring, domain or application packages importing `org.springframework.web` or `javax.persistence` directly.

Remediation:

1. Introduce an interface in the domain layer and implement it in infrastructure (dependency inversion, below).
2. Move infrastructure concerns out of domain code.
3. Enforce direction with tooling so violations cannot return: `import-linter` (Python), `dependency-cruiser`/`madge` (JS/TS), ArchUnit (Java), NDepend or dependency-validation analyzers (.NET), `depguard`/`go-arch-lint` (Go).

## Cyclic dependencies

Cycles between modules make the modules impossible to understand, test, or deploy separately, and eventually freeze the design.

What to check:

- Package- or module-level import cycles (A imports B, B imports A — directly or transitively).
- Cycles across bounded contexts (order-management importing inventory internals and vice versa).
- "Utility" packages that import domain code (a hidden cycle: domain → utils → domain).

Detection:

- Static tools: `madge --circular` (JS/TS), `pydeps` or `import-linter` (Python), `go list -deps` plus a graph check or `godepgraph` (Go), ArchUnit (Java).
- Manual: pick the two most central modules, follow their imports outward two hops, and look for a path back.

Remediation:

- Extract the shared concept into a third module both depend on.
- Invert one direction with an interface (the dependent side defines it).
- Replace a synchronous call with an event where the coupling is only causal.

## Bounded contexts and module boundaries

Check that the codebase's module boundaries match its domain boundaries.

What to check:

- One bounded context per module/package (or a deliberate, documented grouping).
- Shared models, DTOs, or database tables between contexts — ambiguous ownership.
- Direct dependencies between contexts (order-management calling inventory's repository instead of its public API).
- Inconsistent models of the same concept across contexts (two different `User` classes with drifting fields).
- A `shared`/`common` kernel that has grown into a dumping ground.

Detection heuristics:

- Same class or table name referenced from multiple contexts (`UserModel` in both `billing` and `identity`).
- Cross-context imports that skip a public API: `from ordering import inventory.models`.
- Database migrations for one table appearing in two contexts' migration directories.

Integration patterns to recommend:

- Cross-context communication through published APIs or events, not shared internals.
- Anti-corruption layers when integrating with an external or legacy model.
- Context map documented (Shared Kernel, Customer/Supplier, Conformist, Open Host Service, etc.) — the point is that the relationship is *chosen*, not accidental.

Reference structure of a well-bounded modular monolith:

```
src/
├── order-management/     # bounded context
│   ├── domain/           # no outward dependencies
│   ├── application/      # depends on domain
│   └── infrastructure/   # implements domain interfaces
├── inventory/            # another bounded context, same shape
└── shared/               # deliberate, small shared kernel only
```

## Single responsibility and module size

One module — one reason to change. Check for god classes and oversized services.

What to check:

- Classes/modules handling validation + persistence + notification + reporting at once.
- "Manager", "Processor", "Handler", "Utils", "Helper" names — often responsibility dumps.
- Methods with "and"/"or" in the name (`processAndNotify`) — two responsibilities.
- Size guidelines: classes over ~200 lines and methods over ~20 lines deserve a look — not automatic findings, but inspection triggers.
- Many imports or mixed levels of abstraction inside one unit.

Detection heuristics:

- Count public methods per class; count distinct import domains (db + smtp + http + pdf in one class is four responsibilities).
- A class that changes in every sprint for unrelated reasons (visible in git history for change-based scopes).

Remediation moves:

- Extract Class / Extract Method; Move Method to the module that owns the data.
- Separate business logic from infrastructure (persistence, transport, notification each get their own unit).
- Replace conditional dispatch over "types" with polymorphism.
- A coordinating service that only sequences collaborators is acceptable — coordination is its single responsibility.

When NOT to split (say so, don't flag):

- DTOs and value objects (data containers, no behavior).
- Framework base-class obligations.
- Performance-critical code where the abstraction cost is unacceptable and demonstrable.

## Dependency inversion and coupling

High-level modules must not depend on low-level details; both depend on abstractions.

What to check:

- Direct instantiation of concrete infrastructure inside business logic (`new MySQLConnection(...)` inside a domain service; `redis.Redis(...)` in a constructor).
- Business logic importing concrete drivers (`mysql.connector`, `sqlalchemy`, `mongoose`, cloud SDKs) instead of interfaces.
- Hard-coded connection details (hosts, DSNs) in constructors.
- Code that cannot be unit-tested without a real database, SMTP server, or network.

Violation (condensed from the source rules):

```python
import mysql.connector, smtplib, redis

class UserService:                       # business logic...
    def __init__(self):
        self.db = mysql.connector.connect(host="localhost", user="root")   # ...welded to infrastructure
        self.email = smtplib.SMTP("smtp.gmail.com", 587)
        self.cache = redis.Redis(host="localhost", port=6379)
```

Compliant shape:

```python
class UserRepository(ABC):
    @abstractmethod
    def save(self, user): ...

class UserService:
    def __init__(self, repo: UserRepository):   # depends on abstraction
        self.repo = repo

# composition root (application entry point) wires concretes:
container = {UserRepository: MySQLUserRepository(conn)}
```

Remediation:

1. Extract an interface for each external dependency, defined on the consuming (high-level) side.
2. Inject dependencies via constructor (or the framework's DI mechanism); keep one composition root where concretes are wired.
3. Keep configuration (DSNs, hosts, credentials) in the configuration layer, injected as values — never read from arbitrary layers.
4. Verify testability: each business-logic unit should be testable with fakes for its interfaces.

## Cross-cutting structural smells

Quick checks for the remaining structural smells — each is a finding only with concrete evidence:

- **Temporal coupling**: constructors or module-level `init()` that must be called in a specific undocumented order; objects unusable until a second setup step.
- **Global state**: singletons and module-level mutable state shared across requests; hidden side effects at import time (connections opened, threads started).
- **Inconsistent error boundaries**: some modules returning error codes, others raising, others swallowing; errors from infrastructure surfacing raw in API responses.
- **Configuration leakage**: modules reading environment variables or config files directly instead of receiving configuration; secrets mixed into code constants.
- **Framework-driven design**: domain types inheriting framework base classes; domain logic expressed in framework configuration (routes/handlers) rather than called from it.
- **Poor API design of internal modules**: modules exposing all internals (`__all__` absent, everything public, no stable surface); consumers reaching into internals of other modules.
- **Duplicated domain concepts**: the same business rule implemented in two modules (validation, price calculation, status transitions) — they will drift.
