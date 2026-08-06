# SCAMPER Ideas Transformer

A standalone [Agent Skill](https://agentskills.io/specification) that transforms an existing idea (product, service, process, policy, or content concept) into multiple improved or differentiated variants using the full **SCAMPER** method. It runs as a continuous dialogue and enriches its "idea model" with information gathered from the public web.

## When to use

| Situation                                                                      | Use this skill |
| ----------------------------------------------------------------------------- | -------------- |
| You have a baseline idea to improve, differentiate, or repurpose              | ✅             |
| You want to redesign a process (reduce steps, cost, time, defects)            | ✅             |
| A concept is "stuck" and needs systematic variation                           | ✅             |
| Purely exploratory ideation with no starting subject                           | ❌             |
| Primarily verifying facts (use a research skill instead)                      | ❌             |

## How it works

The skill applies seven transformation lenses to a baseline idea:

| Letter | Transformation                            |
| ------ | ----------------------------------------- |
| **S**  | Substitute — swap a component or material |
| **C**  | Combine — merge two ideas or features     |
| **A**  | Adapt — borrow from another domain        |
| **M**  | Modify / Magnify / Minify                 |
| **P**  | Put to another use                        |
| **E**  | Eliminate — remove a part or step         |
| **R**  | Reverse / Rearrange                       |

The skill maintains a running **idea model** and iteratively enriches it with web context (benchmarks, analogs, constraints, technical options, user pain points, pricing patterns, regulations). Each transformation is grounded in real-world data rather than pure brainstorming.

### Inputs and outputs

| Required inputs | Optional inputs |
| --------------- | --------------- |
| **Subject** — what is being transformed | Audience / user segment |
| **Objective** — what "better" means | Current design or workflow steps |
| **Constraints** — must-haves and must-not-do | Known blockers, risks, assumptions |
| | Success metrics and target ranges |

**Output:** a set of labeled idea variants mapped to SCAMPER letters and prompts, plus a short-list (typically 3–7) of best candidates with rationale.

## Bundled resources

| File        | Purpose                                                        |
| ----------- | ------------------------------------------------------------- |
| `SKILL.md`  | Skill definition, the SCAMPER lenses, and the dialogue flow   |

## Compatibility

The skill is agent-agnostic. It benefits from network access to enrich the idea model with current domain facts. No external services are required beyond a filesystem.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
