# Skill Create

A standalone [Agent Skill](https://agentskills.io/specification) for building and maintaining AI agent systems. It turns a user-provided description of a capability into a validated Agent Skill directory — a spec-compliant `SKILL.md` plus optional `references/`, `scripts/`, and `assets/` — asking targeted clarifying questions whenever the description is underspecified and refusing to deliver until its authoring checklist passes.

## When to use

| Situation                                                                                     | Use this skill |
| --------------------------------------------------------------------------------------------- | -------------- |
| You want a new agent skill created from a plain-language description of a capability          | ✅             |
| You have a rough idea ("a skill that reviews our release notes") and expect the agent to ask the right follow-up questions | ✅ |
| You want a generated skill checked against the Agent Skills specification before delivery     | ✅             |
| You want to improve or refactor a skill that already exists                                   | ❌             |
| You need a one-off prompt or instruction sheet for a single conversation, not a reusable skill | ❌             |

## How it works

The skill runs a five-phase pipeline where clarification and validation are mandatory gates, not optional steps:

```
Intake  →  Clarify  →  Design  →  Generate  →  Validate
(raw         (targeted      (structure,   (files from     (checklist re-run
request)      questions      budgets,      templates)      until zero
              when vague)    naming)                       failures)
```

1. **Intake** — captures the raw description: the intended outcome, whether the scope is one coherent capability (an "and" between two independent actions is flagged as probably two skills), and the target location, learning from sibling skills if a conventions-following repository is named.
2. **Clarify** — *mandatory*: when the description is underspecified, batches targeted questions (trigger situations, anti-triggers, capability boundary, ground-truth expertise, environment needs, output format) with a default proposed for each. Unanswered questions become recorded defaults, never silent assumptions.
3. **Design** — picks the name (must equal the directory name), the frontmatter fields, and the file layout under progressive-disclosure budgets: body under 500 lines, detail pushed to `references/`, fixed artifacts to `assets/`, fragile deterministic logic to tiny `scripts/` tools.
4. **Generate** — writes the files from the bundled templates: a routing-optimized third-person description with positive and negative triggers, an imperative procedural body with explicit decision points, gotchas kept in the body, and point-of-use load conditions for every reference file.
5. **Validate** — *mandatory*: walks the full authoring checklist (spec compliance, routing quality, scope and body quality, portability, traceability), fixes failures, and re-runs from the top until zero failures before reporting the result.

Design principles: the description is the router; one skill is one capability; ask, don't assume; specifics beat generality; every sentence must earn its context cost.

## Bundled resources

| File                                      | Purpose                                                                        |
| ----------------------------------------- | ------------------------------------------------------------------------------ |
| `SKILL.md`                                | The five-phase procedure, mandatory gates, and key principles                  |
| `references/spec-digest.md`               | Normative digest of the Agent Skills specification (fields, limits, tiers)     |
| `references/authoring-checklist.md`       | The validation checklist run in full after every generation                    |
| `references/templates.md`                 | Description formula, SKILL.md skeleton, and reference/script/asset patterns    |

## Compatibility

The skill is agent-agnostic. It describes *what* to produce and *how to decide*, never which agent product's tools to call, and it generates skills with no baked-in programming-language or runtime assumptions — languages appear only when the user's context justifies them. It requires an agent that can read and write files and ask the user questions through its environment's native mechanism.

The generated skills follow the [Agent Skills specification](https://agentskills.io/specification).

## License

MIT
