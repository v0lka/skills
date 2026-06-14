# Specification-Driven Development Skills

A set of five [Agent Skills](https://agentskills.io/specification) that implement a **Specification-Driven Development** workflow for AI agents. The skills manage the complete lifecycle of project specifications — from bootstrapping a spec system for an existing codebase to keeping specs aligned with code as it evolves.

All artifacts are plain Markdown files in a `specs/` directory. No wiki engine, database, or external service is required.

## How the skills map to the workflow

The skills are split into **lifecycle** (invoked at distinct stages) and **continuous** (invoked repeatedly during development):

```
  Lifecycle skills                    Continuous skills
  ────────────────                    ─────────────────
  vibespec-init                       vibespec-consult
  vibespec-create                     vibespec-update
                                      vibespec-check
```

| Skill              | Purpose                                                                                                                                                                                                          |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `vibespec-init`    | Bootstrap a complete spec system for a project: analyze the codebase, identify layers/domains/boundaries, and generate META.md, WORKFLOW.md, INDEX.md, domain specs, contracts, architecture docs, ADR template. |
| `vibespec-create`  | Create a single new spec document (domain, contract, architecture, or ADR) following templates and naming conventions. Ensures correct format, placement, cross-references, and INDEX.md registration.           |
| `vibespec-update`  | Update existing specs after code changes that alter documented behavior, interfaces, or invariants. Preserves format, maintains cross-reference integrity, and respects ADR immutability.                        |
| `vibespec-check`   | Detect discrepancies between specs and actual code. Categorizes drift (path missing, type mismatch, behavior drift, etc.) and interactively asks the user how to resolve each finding.                           |
| `vibespec-consult` | Proactively load relevant specs before making structural changes. Extracts invariants, anti-patterns, and breaking-change checklists so the agent respects constraints during implementation.                    |

## Spec system structure

The `vibespec-init` skill creates and the other skills maintain a standard directory tree:

```
specs/
├── META.md                           <- format rules, templates, conventions
├── INDEX.md                          <- task-to-spec navigation table
├── WORKFLOW.md                       <- how to use the spec system
│
├── architecture/
│   └── <topic>.md                    <- system-level concerns (layers, security, data flow)
│
├── domains/
│   ├── <domain-a>/
│   │   ├── README.md                 <- domain overview, invariants, extension points
│   │   └── <component>.md            <- detail spec for a specific component
│   └── <domain-b>.md                 <- simple single-file domain
│
├── contracts/
│   └── <layer-a>-<layer-b>.md        <- boundary definition between layers
│
└── decisions/
    ├── _template.md                  <- ADR template
    └── NNN-slug.md                   <- Architecture Decision Records
```

The spec system lives alongside the codebase. META.md is the foundational document — all templates, naming rules, and format requirements are defined there.

## Recommended workflow

### Phase 1 — Initialization

```
vibespec-init
```

Run once on an existing codebase that has no spec system. The agent:

1. Confirms scope and location with the user
2. Analyzes the codebase (layers, domains, boundaries, decisions)
3. Proposes a spec directory structure for approval
4. Generates all files: META.md, INDEX.md, WORKFLOW.md, architecture specs, domain specs, contracts, and ADR template
5. Validates cross-references and path accuracy

### Phase 2 — Daily development (the spec-aware loop)

```
vibespec-consult  ->  [implement]  ->  vibespec-update
      ^                                       |
      └───────────────────────────────────────┘
```

This is the core loop for spec-aware development:

1. **Consult** (`vibespec-consult`) — before making structural changes, load relevant specs via INDEX.md. Extract invariants, extension points, anti-patterns, and breaking-change checklists.
2. **Implement** — proceed with the code change, respecting extracted constraints.
3. **Update** (`vibespec-update`) — after implementation, update any specs affected by the change. Maintain format, cross-references, and ADR immutability.

Two skills can be invoked **at any point** during development:

- `vibespec-create` — when you need a new spec document (new domain, new contract, new ADR).
- `vibespec-check` — when you suspect drift, after major refactoring, or as periodic maintenance.

### Phase 3 — Drift detection

```
vibespec-check  ->  [user decisions]  ->  vibespec-update / code fixes
```

When specs may have drifted from code:

1. The agent systematically compares specs against source code
2. Categorizes each discrepancy (path missing, type mismatch, behavior drift, etc.)
3. For each finding, asks the user: trust code, trust spec, trust neither, or ignore
4. Applies resolutions — updating specs or flagging code fixes as needed

## Spec document types

The system recognizes five document types, each with a dedicated template:

| Type              | Purpose                                                                      | Location                                |
| ----------------- | ---------------------------------------------------------------------------- | --------------------------------------- |
| **Domain README** | Overview of a conceptual domain (key files, types, flow, invariants)         | `specs/domains/<domain>/README.md`      |
| **Domain Detail** | Detailed behavior of a specific component within a domain                    | `specs/domains/<domain>/<component>.md` |
| **Contract**      | Boundary definition between layers/modules (interfaces, wiring, error rules) | `specs/contracts/<a>-<b>.md`            |
| **Architecture**  | System-level concerns (layer hierarchy, data flow, security)                 | `specs/architecture/<topic>.md`         |
| **ADR**           | Architecture Decision Record (immutable once accepted)                       | `specs/decisions/NNN-slug.md`           |

## Content principles

Specs generated and maintained by these skills follow strict rules:

- **Agent-optimized** — predictable structure, explicit cross-references, no filler prose
- **Invariants are affirmative** — "X always does Y" (not "X never does Z")
- **Derived from code** — every claim is traceable to actual source; discrepancy = bug
- **Key Files use repo-root paths** — `src/core/scheduler.go`, not `./scheduler.go`
- **ASCII for diagrams** — must render in any terminal, no Mermaid dependencies
- **Tables for catalogs** — interfaces, configs, tool registries, decision tables

## Artifact ownership

Each skill owns specific files and respects boundaries:

| Skill              | Creates                          | Updates                                             |
| ------------------ | -------------------------------- | --------------------------------------------------- |
| `vibespec-init`    | Entire `specs/` tree (all files) | `AGENTS.md` (adds pointer to specs)                 |
| `vibespec-create`  | One new spec file of any type    | `INDEX.md` (adds entry)                             |
| `vibespec-update`  | —                                | Any existing spec; `INDEX.md` if files renamed      |
| `vibespec-check`   | —                                | — (read-only; delegates fixes to `vibespec-update`) |
| `vibespec-consult` | —                                | — (read-only; may trigger `vibespec-update` after)  |

## Skill interconnections

```
vibespec-init ──────────────────────────────────────────────────┐
      │                                                         │
      ▼                                                         ▼
vibespec-consult ──► [implementation] ──► vibespec-update ──► vibespec-check
      ▲                                        │                    │
      │                                        │                    │
      └────────────────────────────────────────┘                    │
                                                                    │
vibespec-create ◄──────────────────────────────────────────────────┘
      │                   (creates new spec when UNDOCUMENTED found)
      ▼
vibespec-update (INDEX.md registration)
```

The typical invocation patterns:

- **New project**: `init` (once)
- **Daily work**: `consult -> implement -> update`
- **New component**: `consult -> implement -> create + update`
- **Maintenance**: `check -> update / create`
- **New architectural decision**: `create` (ADR type)

## Compatibility

The skills are agent-agnostic. They describe **what** to do, not which specific tools to call, so they work with any AI agent that can read, write, and search files. No external services, APIs, or runtime dependencies are required beyond a filesystem.

All skills follow the [Agent Skills specification v1](https://agentskills.io/specification) and have been validated for frontmatter correctness, naming conventions, cross-references, and body size limits.

## License

MIT
