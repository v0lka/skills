# Prompts Review

A standalone [Agent Skill](https://agentskills.io/specification) for building and maintaining AI agent systems. It conducts a structured review of every prompt in a codebase — system prompts, tool descriptions, dynamically constructed injections, and string literals bound for an LLM — and reports prioritized, actionable findings without rewriting anything. Fixes (before → after rewrites with improvement points, and explicit questions when the context needed for a correct rewrite is missing) are applied only on a separate user request — or in one pass when the user supplies a single prompt to improve: a task prompt, system message, or agent-instruction document.

## When to use

| Situation                                                                                  | Use this skill |
| ------------------------------------------------------------------------------------------ | -------------- |
| You want to audit the prompts embedded in your LLM application and get a prioritized report | ✅             |
| You shipped prompts that work but suspect they are verbose, redundant, or token-wasteful   | ✅             |
| A review flagged issues and you now want specific findings fixed or a prompt rewritten     | ✅             |
| You are about to change models and want to verify your prompts hold up across providers    | ✅             |
| You wrote a prompt (task prompt, system message, AGENTS.md-style doc) that feels vague or unreliable and want it improved or rewritten | ✅ |
| A prompt already produces correct, reliable output and no issue was reported              | ❌             |
| The prompt is very small (<50 tokens) — micro-optimizations risk breaking behavior        | ❌             |

## How it works

The default mode is review-only: a four-phase pass that produces a per-prompt report and an aggregate summary, both prioritized by severity. No prompts are rewritten. A separate Improvement Mode runs only on explicit request — when the user picks findings from the report and asks to fix them, or supplies one prompt to improve (direct mode starts at the gate and rewrites in the same pass):

```
Discovery          →  Pre-evaluation gate  →  Evaluation           →  Findings Report
(all prompts)         (don't touch working     (checklist +           (prioritized by
                       prompts)                 finding format)        severity)

Improvement Mode (on request) — Gate → Evaluation → Rewrite
```

1. **Discovery** — locates *all* prompts: dedicated prompt files, string-literal constants (`*PROMPT*`, `*INSTRUCTION*`, `SYSTEM_*`), dynamically constructed prompts (f-strings, template literals, `fmt.Sprintf`), tool/function descriptions, and inline context injections.
2. **Pre-evaluation gate** — for each prompt, asks whether it currently produces correct, reliable output. If yes and the user did not request optimization, it is left untouched.
3. **Evaluation** — prompts that pass the gate are checked against a checklist, producing numbered findings in a structured template (root cause, why it is a problem, how to verify, letter-labeled fix options) with a severity tag:

| Severity      | Meaning                                                                                      |
| ------------- | ---------------------------------------------------------------------------------------------- |
| **MUST FIX**  | Actively harms output quality or causes misbehavior (conflicting instructions, missing untrusted-content separation, unverifiable criteria on high-risk tasks) |
| **SHOULD FIX** | Works but has clear, realistic improvements (missing context or verification path, ambiguous deliverable, meaningful token waste) |
| **CONSIDER**  | Minor style/structure improvements; functional as-is                                            |

Token waste alone never sets the severity — it is quantified inside the finding; the behavioral consequence decides the tag.

4. **Improvement Mode (on request)** — the user supplies a prompt to improve, or picks findings from the report. Rewrites use the playbook: each revision is shown as before → after with improvement points, guarded by hard rules (safety constraints survive verbatim, activating context stays, no silent guessing — missing information becomes explicit questions).

The guiding principle is that **output quality takes priority over token savings**: context activates the model's knowledge, so a reminder that directs attention to the right domain is worth keeping — and a rewrite is never a reason to guess.

## Bundled resources

| File           | Purpose                                                                          |
| -------------- | -------------------------------------------------------------------------------- |
| `SKILL.md`     | Skill definition: input modes, discovery strategy, finding format, severity scale, Improvement Mode |
| `checklist.md` | The full evaluation checklist — "Don't Touch" gate, 9 categories, anti-pattern quick map |
| `rewrites.md`  | The rewrite playbook, used in Improvement Mode only: hard rules, before → after transformations, task-type calibration, fill-in templates |

## Compatibility

The skill is agent-agnostic. It describes **what** to review and **how** to rewrite, not which specific tools to call, so it works with any AI agent that can search and read files. No external services are required beyond a filesystem. Where the source material for the playbook shipped agent-specific addenda, it was deliberately generalized into tool-neutral guidance.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
