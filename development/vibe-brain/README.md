# Vibe Brain — Task Prioritizer

A standalone [Agent Skill](https://agentskills.io/specification) that analyzes the project codebase, documentation, and memory to identify the single highest-priority task to work on right now. After a thorough four-phase analysis it returns exactly **one** task — the most impactful thing to do — explained conversationally.

## When to use

Triggered by phrases like *"Hey, what are we going to do today, Brain?"*, *"What should I work on?"*, *"What's next?"*, *"What's the top priority?"*, *"Pick a task for me"*, or any variant asking for task selection or prioritization.

| Situation                                                          | Use this skill |
| ------------------------------------------------------------------ | -------------- |
| You want to know what the single highest-leverage task is right now | ✅             |
| You need a data-driven task recommendation across the whole project  | ✅             |
| You already know exactly what to implement                          | ❌             |

## How it works

The skill runs a four-phase analysis and returns one task. Context gathering happens in parallel where possible:

```
Phase 1: Gather context   ──►   Phase 2: Analyze   ──►   Phase 3: Rank   ──►   Phase 4: Recommend ONE task
(project, code, docs, memory)
```

### Phase 1 — Gather context

| Source            | What it looks for                                                                              |
| ----------------- | ---------------------------------------------------------------------------------------------- |
| **Project structure** | Directory tree, package manifests, tech stack, build system, test runner                   |
| **Codebase scan**     | `TODO`/`FIXME`/`HACK` markers, `@deprecated`, skipped tests, empty catch blocks, suppressed linters, high-churn files |
| **Documentation**     | `README.md`, `AGENTS.md`, `SECURITY.md`, `CONTRIBUTING.md`, `docs/`, ADRs, decision logs    |
| **Memory & knowledge** | Project memories — introduction, tech stack, conventions, lessons learned                 |

### Phases 2–4 — Analyze, rank, recommend

The gathered material is analyzed, ranked by leverage and urgency, and condensed into a single conversational recommendation with the reasoning behind it.

## Bundled resources

| File        | Purpose                                                        |
| ----------- | ------------------------------------------------------------- |
| `SKILL.md`  | Skill definition, the four phases, and trigger phrases        |

## Compatibility

The skill is agent-agnostic. It requires access to the project's filesystem and benefits from memory retrieval capabilities. No external services are required.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
