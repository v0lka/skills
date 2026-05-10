# Specification Workflow

A reference guide for developers and AI agents on effective use of this project's specification system.

---

## 1. General Philosophy

Specifications are the **source of truth** about the intended behavior of the system. They are not generated from code; they are maintained manually. Key implications:

- A discrepancy between a spec and the code = a bug (in the code or in the spec — determine by context).
- Specs are optimized for **AI agents**: predictable structure, explicit cross-references, no filler prose.
- Organized by **domains** (conceptual areas), NOT by repository file structure.
- **Contracts** are a separate first-class entity for describing boundaries between layers.

---

## 2. Getting Started: Navigation

### Step 1: INDEX.md

Open `specs/INDEX.md`. It contains a "task → specs" table that maps common tasks to the spec files you should read.

### Step 2: Domain README

Every domain with multiple files has a `README.md` — the entry point. It contains:

- Purpose
- Key Files (key source files)
- Core Types (main types with code blocks)
- Flow (flow diagram)
- Invariants (what ALWAYS holds true)
- Extension Points (how to extend)

### Step 3: Detail Files

When you need details about a specific component — navigate to the corresponding domain file.

---

## 3. Document Formats

The system uses 5 strictly defined formats. Every new document MUST follow the corresponding template from `META.md`.

1. **Domain README** — `domains/*/README.md` or `domains/*.md` (9 required sections)
2. **Domain Detail** — `domains/*/<component>.md` (7 required sections)
3. **Contract** — `contracts/*.md` (7 required sections)
4. **Architecture** — `architecture/*.md` (4+ required sections)
5. **ADR** — `decisions/NNN-slug.md` (5 required sections)

---

## 4. Cross-References

Rules for linking between specs:

```markdown
<!-- To another spec (relative path from specs/) -->
[Event Catalog](contracts/event-catalog.md)

<!-- To a section within another spec -->
[Circuit Breaker](domains/orchestration/executor.md#circuit-breaker)

<!-- To source code (backticks, path from repo root) -->
`src/core/builder.go`
```

Rule: all links are **relative from `specs/`**. Section anchors — lowercase, hyphen-separated.

---

## 5. Update Protocol

### When to Update

- After any change that alters documented behavior
- After adding/removing/renaming interfaces from contracts
- After changing architectural boundaries or invariants
- After a new architectural decision → create an ADR

### How to Update

1. **Read** the current spec fully before modifying
2. **Preserve the format** — sections and their order are defined in META.md
3. **Update cross-references** if file paths changed
4. **Update INDEX.md** after adding or removing a spec file
5. **ADRs are immutable** — if `Status: Accepted`, create a new ADR with a `Superseded by` link

### Validation Checklist

After updating, verify:

- [ ] All sections from the template are present
- [ ] Cross-references point to existing files
- [ ] Paths in Key Files are accurate
- [ ] Invariants are stated affirmatively
- [ ] INDEX.md reflects the current file set

---

## 6. Workflow for Typical Tasks

### "Implement a new feature in an existing domain"

1. Read the domain README — understand invariants and extension points
2. Read the detail file for the component you're changing (if it exists)
3. Read the relevant contract (if your change crosses a boundary)
4. **After implementation**: update affected specs

### "Add a new component to a domain"

1. Read the domain README — understand where it fits
2. Read `META.md` — get the Domain Detail template
3. **After implementation**: create the detail spec + update domain README catalog

### "Make an architectural change"

1. Read `architecture/` specs — understand current rules
2. Check affected contracts in `contracts/`
3. **After implementation**: create a new ADR + update affected specs

### "Understand why X is designed a certain way"

1. Search in `decisions/` — there may already be an ADR
2. If not — look at the `## Invariants` section of the corresponding domain spec

---

## 7. Working with ADRs

### Creating a New ADR

1. Determine the next sequential number (check existing ones in `decisions/`)
2. Copy the template from `decisions/_template.md`
3. Fill in all sections
4. Add an entry to `INDEX.md`

### Superseding a Decision

1. Create a new ADR with the updated decision
2. In the old ADR, change `## Status` to `Superseded by [NNN](./NNN-slug.md)`
3. This is the only permissible edit to an accepted ADR

---

## 8. Content Formatting Principles

### Invariants — Affirmative Only

```markdown
<!-- Correct -->
- The router always returns exactly one decision per request.
- Tool policy resolution checks tool-level first, then workspace, then global.

<!-- Incorrect -->
- The router should not return multiple decisions.
- Don't skip tool-level policy check.
```

### Key Files — From Repository Root

```markdown
## Key Files

- `src/core/orchestrator.go` — top-level orchestrator
- `src/orchestration/dag.go` — DAG data structure
```

### Tables for Reference Information

Tables are the preferred format for: interface catalogs, tool registries, configuration mappings, decision tables.

### ASCII Diagrams

For flows and architecture — ASCII art (not Mermaid), to work without a renderer.

---

## 9. Anti-Patterns

| Anti-pattern | Why it's bad | What to do instead |
| --- | --- | --- |
| Mirror file structure in specs | One file may participate in multiple domains | Organize by domains |
| Generate specs from code | Loses the ability to detect discrepancies | Write manually, compare with code |
| Skip updating INDEX.md | Agent won't find the new spec | Always update when adding/removing |
| Edit an accepted ADR | Loses decision history | Create a new ADR with `Superseded by` |
| State invariants negatively | Harder to verify compliance | Use affirmative phrasing |
| Add filler and human-oriented explanations | Wastes the agent's context window | Only necessary and sufficient information |

---

## 10. Quick Start (TL;DR)

1. **Need to learn something** → `specs/INDEX.md` → find task → go to spec
2. **Need to change code** → read domain spec + contract → implement → update spec
3. **Need a new decision** → create ADR → update INDEX.md
4. **Need to add a spec** → take format from META.md → create file → update INDEX.md
5. **Formats, rules, templates** → `specs/META.md`
