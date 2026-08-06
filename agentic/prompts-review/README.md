# Prompts Review

A standalone [Agent Skill](https://agentskills.io/specification) for building and maintaining AI agent systems. It conducts a structured review of every prompt in a codebase — system prompts, tool descriptions, dynamically constructed injections, and string literals bound for an LLM — balancing output quality against token efficiency and producing a severity-ranked report with concrete fixes.

## When to use

| Situation                                                                                  | Use this skill |
| ----------------------------------------------------------------------------------------- | -------------- |
| You want to audit or optimize the prompts embedded in your LLM application                | ✅             |
| You shipped prompts that work but suspect they are verbose, redundant, or token-wasteful  | ✅             |
| You are about to change models and want to verify your prompts hold up across providers   | ✅             |
| A prompt already produces correct, reliable output and no issue was reported              | ❌             |
| The prompt is very small (<50 tokens) — micro-optimizations risk breaking behavior        | ❌             |

## How it works

The skill runs a three-phase review that produces a per-prompt report and an aggregate summary:

```
Discovery          →  Pre-evaluation gate  →  Evaluation
(all prompts)         (don't touch working     (checklist +
                       prompts)                severity ranking)
```

1. **Discovery** — locates *all* prompts: dedicated prompt files, string-literal constants (`*PROMPT*`, `*INSTRUCTION*`, `SYSTEM_*`), dynamically constructed prompts (f-strings, template literals, `fmt.Sprintf`), tool/function descriptions, and inline context injections.
2. **Pre-evaluation gate** — for each prompt, asks whether it currently produces correct, reliable output. If yes and the user did not request optimization, it is left untouched.
3. **Evaluation** — prompts that pass the gate are checked against a checklist, producing findings ranked by severity:

| Severity   | Meaning                                                                              |
| ---------- | ------------------------------------------------------------------------------------ |
| **High**   | Actively harms output quality, causes misbehavior, or wastes >30% of tokens          |
| **Medium** | Works but has clear optimization opportunities (10–30% token savings, clarity gains) |
| **Low**    | Minor style/structure improvements; functional as-is                                  |

The guiding principle is that **output quality takes priority over token savings**: context activates the model's knowledge, so a reminder that directs attention to the right domain is worth keeping.

## Bundled resources

| File          | Purpose                                                          |
| ------------- | ---------------------------------------------------------------- |
| `SKILL.md`    | Skill definition, discovery strategy, and report format           |
| `checklist.md`| The full evaluation checklist with the "Don't Touch" gate         |

## Compatibility

The skill is agent-agnostic. It describes **what** to review, not which specific tools to call, so it works with any AI agent that can search and read files. No external services are required beyond a filesystem.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
