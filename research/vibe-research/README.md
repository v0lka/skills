# Vibe Research Copilot

A standalone [Agent Skill](https://agentskills.io/specification) for iterative "vibe research." It progressively sharpens a broad topic into a sharp, high-value line of inquiry through multiple research loops — each turn more specific, more relevant, and more actionable than the previous one.

## When to use

| Situation                                                                | Use this skill |
| ------------------------------------------------------------------------ | -------------- |
| You have a broad topic and want to converge on a high-value question     | ✅             |
| You want open-ended research and brainstorming of research directions    | ✅             |
| You said "vibe research"                                                 | ✅             |
| You need a one-shot factual answer                                       | ❌             |

## How it works

The skill runs a core loop that converges over multiple turns:

```
broad topic ──► search web ──► structured brief ──► clarifying questions
       ▲                                                        │
       │                                            user answers │
       └──────────────────────────────────────────────────────────┘
              (each iteration is sharper than the last)
```

Every iteration returns a **structured research brief** with five sections:

| Section               | Content                                                             |
| --------------------- | ------------------------------------------------------------------ |
| **A. Current Snapshot**   | Concise synthesis of the latest relevant context                   |
| **B. What Stands Out**    | Important observations, patterns, contradictions, opportunities   |
| **C. Relevant References** | Links, papers, products, projects, people worth examining next   |
| **D. Suggested Directions** | 2–5 concrete ways to narrow, reframe, or deepen the topic        |
| **E. Clarifying Questions** | A grouped block of targeted questions (never one at a time)     |

**Key behaviors:** distinguish established facts from promising leads and hype; surface unexpected adjacent angles; be transparent about uncertainty; always respond in the user's language.

## Bundled resources

| File        | Purpose                                                          |
| ----------- | --------------------------------------------------------------- |
| `SKILL.md`  | Skill definition, the core loop, and the response format        |

## Compatibility

The skill is agent-agnostic. It benefits from network access for source gathering. No external services are required beyond a filesystem.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
