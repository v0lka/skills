# TRIZ Inventive Problem Solver

A standalone [Agent Skill](https://agentskills.io/specification) that solves inventive engineering, product, process, or system-design problems using **TRIZ** methodology. It combines classical TRIZ reasoning with targeted web research so that each iteration is informed by both abstract invention patterns and current domain facts. The goal is to progressively transform a vague problem into a well-structured contradiction model, generate non-obvious solution concepts, and converge on practical next steps.

## When to use

| Situation                                                                       | Use this skill |
| ------------------------------------------------------------------------------ | -------------- |
| A design trade-off that keeps forcing compromise                               | ✅             |
| You need to improve one parameter without worsening another                     | ✅             |
| A system element needs opposite properties at the same time                     | ✅             |
| You want breakthrough concepts, not incremental optimization                    | ✅             |
| You need to simplify a system or use existing resources more effectively        | ✅             |
| You only need a simple factual answer                                           | ❌             |
| The request is primarily legal, medical, or financial advice                    | ❌             |

Typical examples: improve cooling without increasing energy use; make a device stronger without adding weight; reduce manufacturing cost without reducing reliability; eliminate a harmful interaction between two components.

## How it works

The skill stays in continuous dialogue and treats the interaction as an ongoing problem-solving session, not a one-shot lecture:

```
vague problem ──► structure the contradiction ──► TRIZ inventive principles
                                                              │
                                                              ▼
                                               non-obvious solution concepts
                                                              │
                                                              ▼
                                                    practical next steps
```

It draws on the classical TRIZ toolkit — the 40 inventive principles, contradiction matrix, ideal final result, and the separation and resource-utilization patterns — and validates each generated concept against current domain facts gathered via web research.

## Bundled resources

| File        | Purpose                                                            |
| ----------- | ----------------------------------------------------------------- |
| `SKILL.md`  | Skill definition, TRIZ methodology, and the dialogue principles   |

## Compatibility

The skill is agent-agnostic. It benefits from network access to search for scientific effects, mechanisms, patents, materials, and analogous solutions in other industries. No external services are required beyond a filesystem.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
