# Architecture Review

A standalone [Agent Skill](https://agentskills.io/specification) for evidence-based architecture reviews. It reconstructs the *real* architecture of a codebase from code and evaluates it for structural health: layering, dependency direction, module boundaries, coupling balance (integration strength, distance, volatility), resilience, observability, and security-by-design.

## When to use

| Situation                                                                     | Use this skill |
| ----------------------------------------------------------------------------- | -------------- |
| Assess the architecture of a whole project (the default when no input is given) | ✅             |
| Review a subsystem (directory, package, module) plus its boundary relationships | ✅             |
| Review the architectural impact of uncommitted changes                         | ✅             |
| Review the architectural impact of a specific commit                           | ✅             |
| Review the architectural impact of a branch or pull request                    | ✅             |
| Planning a refactor or migration and need a structural baseline                | ✅             |
| Onboarding into an unfamiliar codebase                                         | ✅             |
| Line-by-line bug or vulnerability hunting (use `code-review` / `security-review` instead) | ❌ |

## How it works

```
Determine scope  ──►  Explore with evidence  ──►  Evaluate  ──►  Report
```

1. **Determine scope** — based on input: no input → whole project; a path → that subsystem plus its dependencies; a commit/branch/PR/uncommitted changes → the architectural impact of the change.
2. **Explore with evidence** — map the tree first, cover every significant module before judging, trace real dependency directions from imports. Every claim must cite files actually read; unconfirmed checks are reported as *Not confirmed*, never guessed.
3. **Evaluate** — against five check catalogs (see below), loading each reference on demand.
4. **Report** — a self-contained Markdown report: architecture summary, layer/module map with dependency directions, the coupling balance assessment, severity-ordered findings with evidence (`path:lines`), prioritized recommendations, and coverage notes.

### Review areas

| Area                                                     | Focus                                                                                                                                     |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **Structure & boundaries**                               | Layering violations, cyclic dependencies, dependency direction, bounded contexts, god modules, SRP/DIP, global state, error/config boundaries |
| **Coupling & modularization**                            | Balanced coupling: integration strength (intrusive/functional/model/contract) × distance × volatility; connascence catalog; CBO and instability metrics |
| **Operational qualities**                                | Timeouts, retries, circuit breakers, bulkheads, rate limiting; structured logging, correlation IDs, metrics, tracing                        |
| **Security architecture**                                | Trust boundaries, endpoint authn/authz, fail-closed defaults, least privilege, secrets management, cryptography choices                     |
| **Governance**                                           | Architectural Decision Records: presence, completeness, currency                                                                            |

Findings are severity-graded (CRITICAL / HIGH / MEDIUM / LOW) and must state a concrete consequence, not just the smell.

## Bundled resources

| File                                       | Purpose                                                                    |
| ------------------------------------------ | --------------------------------------------------------------------------- |
| `SKILL.md`                                 | Scope determination, exploration workflow, evidence rules, report format    |
| `references/structure-and-boundaries.md`   | Layer rules, cycles, bounded contexts, SRP/DIP, cross-cutting smells        |
| `references/coupling-modularization.md`    | Balanced Coupling Model: strength × distance × volatility, connascence catalog, metrics, refactoring strategies |
| `references/observability-and-resilience.md` | Observability standards and the five resilience patterns with config baselines |
| `references/security-architecture.md`      | Trust boundaries, access control, secure defaults, least privilege, secrets, crypto |
| `references/decision-records.md`           | ADR checks, template, starter set, severity guidance                        |

## Compatibility

The skill is agent-agnostic. It requires read access to a codebase (directory listing, file reading, content search); git is required for change-based scopes (commits, branches, pull requests).

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## Authors

Created by [Vladimir Kochetkov](https://github.com/v0lka). Co-authored with Radda Yureva.

## License

MIT
