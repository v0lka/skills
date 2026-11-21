# Architectural Decision Records

Architecture governance checks: are the project's important structural decisions written down, current, and discoverable? Undocumented architecture forces every newcomer (human or agent) to re-derive intent from code — and re-litigate settled decisions.

## What to check

- An ADR directory exists (`docs/adr/`, `docs/decisions/`, or similar) and is populated — not just a template.
- Each ADR is complete: status, context, decision, consequences, and alternatives considered.
- Status is current: ADRs still marked *Accepted* that the code has clearly moved away from are drift; superseding ADRs should link back (`Superseded by ADR-NNN`).
- Major decisions visible in the code have an ADR: the framework choice, the database and schema approach, the module structure, API versioning strategy, deployment topology, adoption of messaging, authentication mechanism.
- ADRs are referenced where relevant (README, contributing guide, architecture docs), not orphaned files.

## Decisions that deserve an ADR

During review, treat the following as ADR-worthy when no record exists:

- Introducing or replacing a foundational dependency (database, message broker, framework, cloud provider).
- Choosing or changing the module decomposition or layering scheme.
- API style and versioning policy (REST vs GraphQL vs gRPC; breaking-change policy).
- Cross-context integration approach (sync calls vs events; anti-corruption layers).
- Security architecture choices (auth mechanism, tenancy isolation model).
- Anything a new team member would ask "why is it like this?" about — and the answer is non-obvious from the code.

Textual cue worth searching in docs and commit messages: "chose/decided/selected/adopted … because …" — a decision was made; check that it was recorded.

## Template

A minimal, standard ADR:

```markdown
# ADR-NNNN: Short title of the decision

## Status
Proposed | Accepted | Deprecated | Superseded by [ADR-YYYY]

## Context
What is the problem or force we are addressing?

## Decision
What we are doing about it.

## Consequences
What becomes easier or harder because of this change.

## Alternatives considered
- Alternative 1 — why rejected
- Alternative 2 — why rejected

## Date
YYYY-MM-DD
```

Conventions: sequential numbering (`0001-`, `0002-`), one decision per record, never edit an accepted ADR's decision — supersede it with a new record that links back.

## Starter set for a project with no ADRs

If the project has none, recommend bootstrapping with:

1. `0001-record-architecture-decisions` — the meta-ADR establishing the ADR process itself.
2. `0002-project-structure` — module organization and layering rules.
3. `0003-database-selection` — storage technology and schema approach.
4. `0004-api-guidelines` — API design and versioning strategy.
5. `0005-deployment-architecture` — deployment topology and infrastructure.

## Severity guidance

- Missing ADR for a decision that is still contested or actively being re-made: MEDIUM.
- Missing ADR for a settled, well-entrenched decision: LOW (hygiene).
- Accepted ADRs that contradict the code as built: MEDIUM-HIGH — either the docs or the code is wrong, and both mislead.
