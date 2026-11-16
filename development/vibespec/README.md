# Specification-Driven Development (vibespec)

A set of [Agent Skills](https://agentskills.io/specification) that implement a **Specification-Driven Development** workflow for AI agents. The skillset is named **vibespec**; its skills carry the `vibespec-` prefix.

The skills cover the whole span of project specifications — from bootstrapping a spec system for an existing codebase to keeping specs aligned with code as it evolves.

All artifacts are plain Markdown files in a `specs/` directory. No wiki engine, database, or external service is required.

## How the skills map to the workflow

The skillset splits on **how often a skill runs**:

- **Lifecycle** — runs once per scope, with a defined start and a defined end. `vibespec-init` runs once per project, `vibespec-explore` once per task whose requirements are unclear.
- **Continuous** — has no stage of its own: a trigger fires, the skill runs, the trigger fires again later. `vibespec-consult` and `vibespec-update` sit inside every development loop; `vibespec-create` and `vibespec-check` are on-demand and can be invoked at any point during development.

```
  Lifecycle skills (once per scope)     Continuous skills (repeatedly, at any point)
  ─────────────────────────────────     ────────────────────────────────────────────
  vibespec-init     (project)           vibespec-consult  before a structural change
  vibespec-explore  (task)              vibespec-update   after a code change
                                        vibespec-create   when a document is missing
                                        vibespec-check    when drift is suspected
```

`vibespec-explore` is the on-ramp for work whose requirements are not yet clear; every other skill assumes the change is already known. Writing and checking documents are not stages of their own — that is why `vibespec-create` and `vibespec-check` belong with the continuous skills, next to `vibespec-update`.

| Skill              | Group                             | Purpose                                                                                              |
| ------------------ | --------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `vibespec-init`    | Lifecycle — once per project      | Bootstrap a complete spec system: analyze the codebase, identify layers/domains/boundaries, and generate META.md, INDEX.md, architecture specs, domain specs, contracts, the ADR template and initial ADRs. |
| `vibespec-explore` | Lifecycle — once per unclear task | Spec-aware thinking partner: grounds exploration in the project's spec system, turns crystallized ideas into a roadmap (What / How / Where / Spec footprint / Acceptance criteria) for user approval, then implements it while syncing specs via `vibespec-update` / `vibespec-create`. |
| `vibespec-consult` | Continuous — before changes       | Load the relevant specs before making structural changes. Extracts invariants, extension points, anti-patterns, and breaking-change checklists so the agent respects constraints during implementation. |
| `vibespec-update`  | Continuous — after changes        | Update existing specs after code changes that alter documented behavior, interfaces, or invariants. Preserves format, maintains cross-reference integrity, and respects ADR immutability. |
| `vibespec-create`  | Continuous — on demand            | Create a single new spec document (domain, contract, architecture, or ADR) following templates and naming conventions. Ensures correct format, placement, cross-references, and INDEX.md registration. |
| `vibespec-check`   | Continuous — on demand            | Detect discrepancies between specs and actual code. Categorizes drift, asks the user to resolve each finding, and routes the fixes to `vibespec-update`. |

## Spec system structure

The `vibespec-init` skill creates and the other skills maintain a standard directory tree:

```
specs/
├── META.md                           <- format rules, templates, conventions
├── INDEX.md                          <- task-to-spec navigation table
├── WORKFLOW.md                       <- how to use the spec system (conditional,
│                                       see Phase 1 below)
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

### Phase 1 — Initialization (`vibespec-init`, once per project)

```
vibespec-init
```

Run once on an existing codebase that has no spec system. The agent:

1. Confirms scope and location with the user (`specs/` by default) and aborts if a spec system already exists and the user does not confirm overwrite
2. Analyzes the codebase (layers, domains, boundaries, decisions, configuration)
3. Proposes a spec directory structure for approval
4. Generates META.md, INDEX.md, architecture specs, domain specs, contracts, the ADR template, and initial ADRs that pass the ADR bar
5. Generates WORKFLOW.md **only** when the host has no documented spec-system entry point — an existing `AGENTS.md` pointer, META.md, or comparable document already tells agents how to work with specs, and a second "how to use" surface would drift from it
6. Adds a `## Specifications` pointer to `AGENTS.md` when the project has one — this pointer is the entry point agents follow, so no other workflow/usage document is created
7. Validates templates, cross-references, `Key Files` paths, INDEX.md coverage, and ASCII rendering

### Phase 2 — Work whose requirements are unclear (`vibespec-explore`)

```
vibespec-explore  ->  [approved roadmap]  ->  vibespec-consult -> implement -> vibespec-update
```

Use `vibespec-explore` at the start of any task whose requirements are not yet clear. It runs three modes:

1. **Explore** — a thinking partner that starts from `specs/`, not the codebase. Read-only: it reads specs and code, notes drift, and never writes code or edits specs. Areas no spec covers are flagged `UNDOCUMENTED`.
2. **Plan** — produces a roadmap whose tasks each carry a **Spec footprint** (the spec work they own) plus an **Invariants & Constraints** section cited from the specs. The roadmap is presented for approval and is a hard gate: no implementation before approval.
3. **Implementation** — executes the approved roadmap task by task, running `vibespec-consult` → change → sync specs (`vibespec-update` / `vibespec-create`) per each task's Spec footprint.

The skill reads specs and delegates every spec edit to `vibespec-update` or `vibespec-create`. Without a `specs/` directory it degenerates to plain code exploration rather than inventing a spec system.

### Phase 3 — Daily development (two orderings of one loop)

Daily work is a short loop — consult the specs, make the change, reconcile them — and its two middle steps can run in either order. The order decides what is the source of truth at any moment: the code or the specs. Both alternatives below drive the same skills; they differ in **when specs are written** and in **what a spec/code mismatch means**.

#### Alternative A — Code-first (the default)

```
vibespec-consult  ->  [implement]  ->  vibespec-update
      ^                                       |
      └───────────────────────────────────────┘
```

1. **Consult** (`vibespec-consult`) — before making structural changes, load relevant specs via INDEX.md. Extract invariants, extension points, anti-patterns, and breaking-change checklists.
2. **Implement** — proceed with the code change, respecting the extracted constraints.
3. **Update** (`vibespec-update`) — after implementation, bring every affected spec to the new reality. Maintain format, cross-references, and ADR immutability.

Specs describe code that already exists: the shape of the change is discovered by writing it, and the documents are reconciled afterwards. A spec/code mismatch therefore means the spec is stale. This is the ordering `vibespec-update` is written for — it states explicitly that updating a spec before the code is finished risks a mismatch if the implementation changes shape.

`vibespec-create` attaches to this loop when the change needs a document that does not exist yet: a new domain, contract, or architecture topic, or a decision passing the ADR bar.

#### Alternative B — Spec-first (specs as the contract)

```
vibespec-consult  ->  [write specs]  ->  [implement]  ->  vibespec-check
      ^                                                          |
      └──────────────────────────────────────────────────────────┘
```

1. **Consult** (`vibespec-consult`) — the same opening step: load the specs that govern the area and extract their constraints.
2. **Write the specs** — bring *every* document the change touches to its target state before writing any code: `vibespec-update` for existing documents, `vibespec-create` for the missing ones (new domain, contract, architecture topic), and `vibespec-create` (ADR type) for a decision that passes the ADR bar. The spec delta *is* the design.
3. **Implement** — write the code the specs describe, starting where the specs start: the contract at the boundary, then the components behind it.
4. **Verify** (`vibespec-check`) — compare the finished code against the freshly written specs, resolving findings with **trust spec** as the default: a deviation is a code bug, and the skill reports the fix without applying it.

Here specs are written ahead of the code they describe, so until implementation lands they are a **proposal**, not a description. Three consequences are accepted knowingly:

- **A documented rule is inverted.** The skill map above and `vibespec-update` itself both place the spec update *after* the code change; spec-first uses that skill for design instead. The mismatch the rule warns about does not disappear — it moves to step 4, where `vibespec-check` catches it.
- **`Key Files` may point at paths that do not exist yet.** The validation step that checks those paths therefore fails until the code lands. That failure is expected and must not be "fixed" by deleting the entries.
- **"Traceable to source" holds only at the end.** While the work is in flight the spec is the reference and the code is what gets made to match it; the content principle holds once step 4 comes back clean.

#### Choosing between them

| Aspect            | Code-first (default)                        | Spec-first                                        |
| ----------------- | ------------------------------------------- | ------------------------------------------------- |
| Source of truth   | Code — specs describe what exists           | Specs — code is written to satisfy them           |
| A mismatch means  | The spec is stale (`trust code`)            | The code is wrong (`trust spec`)                  |
| Specs are written | After implementation                        | Before implementation                             |
| Strong fit        | Exploratory work, small fixes, refactors    | Contracts, multi-component changes, parallel work |
| Cost              | Drift grows between the change and the sync | A wrong spec surfaces late, at verification       |

A spec-first task is a code-first task with two steps swapped, so `vibespec-explore` covers both: its roadmap already gives every task a **Spec footprint**, and spec-first discharges that footprint before the implementation step instead of after it.

Under either alternative the on-demand skills stay on-demand: `vibespec-create` whenever a document is missing, `vibespec-check` as periodic maintenance (Phase 4). What changes is only which resolution is the sensible first answer — `trust code` after a code-first change, `trust spec` after a spec-first one.

### Phase 4 — Drift detection (`vibespec-check`)

```
vibespec-check  ->  [user decisions]  ->  vibespec-update / code fixes
```

When specs may have drifted from code:

1. The agent takes a scope — single spec, domain, contracts, or the full `specs/` tree
2. It systematically compares specs against source code and categorizes each discrepancy
3. For each finding it asks the user: **trust code** (update the spec), **trust spec** (flag the code fix, never apply it here), **trust neither** (record an open question), or **ignore**
4. It applies the resolutions — spec updates go through `vibespec-update`, code fixes are only reported

Drift categories: `PATH_MISSING`, `TYPE_MISMATCH`, `INTERFACE_DRIFT`, `BEHAVIOR_DRIFT`, `CONFIG_DRIFT`, `INVARIANT_VIOLATED`, `CROSS_REF_BROKEN`, `UNDOCUMENTED`, `STALE_CONTENT`, `DUPLICATE_ADR_NUMBER`.

## Spec document types

The system recognizes five document types, each with a dedicated template:

| Type              | Purpose                                                                      | Location                                |
| ----------------- | ---------------------------------------------------------------------------- | --------------------------------------- |
| **Domain README** | Overview of a conceptual domain (key files, types, flow, invariants)         | `specs/domains/<domain>/README.md`      |
| **Domain Detail** | Detailed behavior of a specific component within a domain                    | `specs/domains/<domain>/<component>.md` |
| **Contract**      | Boundary definition between layers/modules (interfaces, wiring, error rules) | `specs/contracts/<a>-<b>.md`            |
| **Architecture**  | System-level concerns (layer hierarchy, data flow, security)                 | `specs/architecture/<topic>.md`         |
| **ADR**           | Architecture Decision Record                                                 | `specs/decisions/NNN-slug.md`           |

## ADR rules

An ADR is created only when the decision passes the **ADR bar**:

1. It constrains work beyond the immediate change — cross-domain, cross-cutting, or hard to reverse — **and** had real alternatives considered and rejected; **or**
2. It contradicts or supersedes an existing ADR or a documented invariant.

`Alternatives Considered` is the bar: if that section cannot be filled honestly, the decision belongs in a domain or architecture spec instead. Implementation details, local reversible choices, and restatements of existing specs are never ADRs.

Numbering and locking follow these rules:

- The next number is the highest `NNN` in `specs/decisions/` (superseded ADRs included) plus one; numbers are never reused
- A number allocated on an unmerged branch is provisional — if two ADRs land with the same number, the second-landed one is renumbered and every reference to it is updated (filename, heading, supersede links, INDEX.md, cross-references)
- `Status: Accepted` locks an ADR only once its content is **committed**. An uncommitted accepted ADR is still a draft and may be rewritten in place
- To change a committed decision, create a new superseding ADR and edit only the old record's `## Status` line

## Content principles

Specs generated and maintained by these skills follow strict rules:

- **Agent-optimized** — predictable structure, explicit cross-references, no filler prose
- **Invariants are affirmative** — "X always does Y" (not "X never does Z")
- **Derived from code** — every claim is traceable to actual source; discrepancy = bug
- **Key Files use repo-root paths** — `src/core/scheduler.go`, not `./scheduler.go`
- **ASCII for diagrams** — must render in any terminal, no Mermaid dependencies
- **Tables for catalogs** — interfaces, configs, tool registries, decision tables
- **Updated in place** — no changelog entries or "Updated:" prefixes inside a spec; git history tracks change

## Artifact ownership

Each skill owns specific files and respects boundaries:

| Skill              | Creates                                                                                              | Updates                                                                                              |
| ------------------ | ---------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `vibespec-init`    | Entire `specs/` tree (META.md, INDEX.md, architecture, domains, contracts, ADR template, initial ADRs, WORKFLOW.md when required) | `AGENTS.md` (adds the specs pointer)                                                                 |
| `vibespec-explore` | — (presents a roadmap in-conversation)                                                               | — (read-only on `specs/`; delegates every edit to `vibespec-update` / `vibespec-create`)             |
| `vibespec-consult` | —                                                                                                    | — (read-only; may invoke `vibespec-update` / `vibespec-create` afterwards)                           |
| `vibespec-update`  | —                                                                                                    | Any existing spec; `INDEX.md` when files are added, renamed, or removed                              |
| `vibespec-create`  | One new spec file of any type                                                                        | `INDEX.md` (navigation table + directory listing)                                                    |
| `vibespec-check`   | —                                                                                                    | — (read-only on spec content; routes fixes to `vibespec-update` and ADR renumbering follows the `vibespec-create` protocol) |

When one change touches several specs, `vibespec-update` applies them in dependency order: contracts → domain details → domain READMEs → architecture → INDEX.md.

## Skill interconnections

```
vibespec-init (once per project)
      │
      ▼
vibespec-explore ──► vibespec-consult ──► [implementation] ──► vibespec-update ──► vibespec-check
   ▲                                                                                   │
   └───────────────────────────────────────────────────────────────────────────────────┘
                     drift, or new work, re-enters the loop

vibespec-create ◄── a document is missing: UNDOCUMENTED area, new domain or contract,
                    or a decision passing the ADR bar (registers itself in INDEX.md)
```

The diagram draws the code-first ordering. In the spec-first alternative (Phase 3) the two middle arrows swap: `vibespec-consult` is followed by the spec write (`vibespec-update` / `vibespec-create`), then by implementation, and `vibespec-check` closes the loop.

The typical invocation patterns:

- **New project**: `vibespec-init` (once)
- **Unclear task**: `vibespec-explore -> vibespec-consult -> implement -> vibespec-update`
- **Daily work, code-first**: `vibespec-consult -> implement -> vibespec-update`
- **Daily work, spec-first**: `vibespec-consult -> vibespec-update / vibespec-create -> implement -> vibespec-check`
- **New component**: `vibespec-consult -> implement -> vibespec-create + vibespec-update`
- **Maintenance**: `vibespec-check -> vibespec-update` (spec fixes) or `vibespec-check -> vibespec-create` (uncovered areas)
- **Decision passing the ADR bar**: `vibespec-create` (ADR type)

## Bundled resources

| File                                             | Contents                                                                                             |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| `vibespec-init/assets/meta-template.md`          | META.md template — file organization, spec templates, format rules                                   |
| `vibespec-init/assets/workflow-template.md`      | WORKFLOW.md template — used only when the host documents no spec-system entry point                  |
| `vibespec-init/assets/adr-template.md`           | ADR template written to `specs/decisions/_template.md`                                               |
| `vibespec-explore/references/roadmap-format.md`  | Full roadmap template (What / How / Where / Spec footprint / Acceptance criteria) with guidance on acceptance criteria and the Spec footprint |
| `vibespec-explore/references/entry-points.md`    | How to handle common entry points — vague idea, specific problem, stuck implementation, options comparison — with spec-aware variants |
| `vibespec-explore/references/example-session.md` | A full spec-aware session: explore → plan (with Spec footprint) → implement (with spec sync)         |

## Compatibility

The skills are agent-agnostic. They describe **what** to do, not which specific tools to call, so they work with any AI agent that can read, write, and search files. No external services, APIs, or runtime dependencies are required beyond a filesystem.

All skills follow the [Agent Skills specification v1](https://agentskills.io/specification) and have been validated for frontmatter correctness, naming conventions, cross-references, and body size limits.

## License

MIT
