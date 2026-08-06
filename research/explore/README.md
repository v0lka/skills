# Explore → Plan → Implement

A standalone [Agent Skill](https://agentskills.io/specification) that acts as a thinking partner for exploring ideas and clarifying requirements, then transitions into a structured roadmap for approval, then implements the approved plan — all within a single self-contained workflow.

## When to use

| Situation                                                                       | Use this skill |
| ------------------------------------------------------------------------------- | -------------- |
| Requirements are unclear, or you want to think something through before a change | ✅             |
| You are discussing architecture and design decisions                            | ✅             |
| You want a structured roadmap (What / How / Where / Acceptance criteria)        | ✅             |
| You need raw implementation with no exploration or planning                     | ❌             |

## How it works

The skill is a three-mode workflow. **Mode transitions are driven by the skill itself** — it announces each transition explicitly and follows mode-appropriate rules:

```
     ┌───────────┐  ideas      ┌───────────┐  approve     ┌──────────────┐
     │  Explore  │ crystallize │   Plan    │─────────────▶│Implementation│
     │   Mode    │────────────▶│   Mode    │              │    Mode      │
     │           │             │           │              │              │
     │ thinking, │             │ roadmap   │              │ execute      │
     │ no code   │             │ spec      │              │ tasks        │
     └─────┬─────┘             └─────┬─────┘              └──────┬───────┘
           ▲                         │                           │
           │   unknowns              │ revise                    │ plan
           │   emerge                │                           │ broken
           └─────────────────────────┘                           │
                                     ◀───────────────────────────┘
```

1. **Explore mode** — a curious, patient thinking partner. You may read files, search code, and investigate, but **never write code**. Open multiple threads, follow what resonates, use ASCII diagrams liberally.
2. **Plan mode** — crystallized ideas become a structured roadmap: tasks specified in **What / How / Where / Acceptance criteria** format, presented for user approval.
3. **Implementation mode** — the approved plan is executed task by task. If the plan breaks, control returns to Plan mode.

## Bundled resources

| File        | Purpose                                              |
| ----------- | --------------------------------------------------- |
| `SKILL.md`  | Skill definition, the three modes, and their rules  |

## Compatibility

The skill is agent-agnostic. It describes **what** to do, not which specific tools to call, so it works with any AI agent that can read, write, and search files.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
