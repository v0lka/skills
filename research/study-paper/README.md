# Study Paper

A standalone [Agent Skill](https://agentskills.io/specification) for **studying research papers**. It turns a vague "look at this paper" request into accurate, structured understanding — across six intents: understand, skim/triage, critically appraise, reproduce/implement, compare, and teach.

The skill keeps a hard line between what a paper **claims** and what it **actually demonstrates**, so appraisals stay honest and reproducible.

## What it does

Given a paper — as a PDF, an arXiv ID or URL, a DOI, a citation, or a pasted abstract — the skill produces a structured reading: motivation, problem statement, core method, experiments, results, and limitations. It adapts to the depth the user needs, from a one-paragraph triage skim to a reproduce-and-teach deep dive.

Every specific claim is attributed to the paper (section / figure / equation), and the skill explicitly separates:
- what the paper states,
- what the analyst infers, and
- what remains unknown.

## When to use

| Situation                                                                   | Use this skill |
| --------------------------------------------------------------------------- | -------------- |
| Understand or explain a paper ("what does this paper do?")                  | ✅             |
| Skim / triage a paper to decide whether a full read is worth it             | ✅             |
| Critically appraise a paper's methodology, evidence, and claims             | ✅             |
| Reproduce or re-implement a paper's method                                  | ✅             |
| Compare two or more papers on the same problem                              | ✅             |
| Teach or explain a paper at a chosen depth (beginner / practitioner / expert)| ✅             |
| A simple factual lookup that needs no paper                                 | ❌             |

## How it works

The skill infers the intended depth, confirms it in one line, and enters one of six modes:

```
Skim      → map + contributions + TL;DR + ≤3 red flags + reading decision
Deep      → complete read + a claim→evidence check on every load-bearing claim
Survey    → the paper's place among a set + a cross-paper comparison
Review    → full appraisal + statistics / reproducibility audit
Implement → method decomposition + equations + hyperparameters + data + gotchas
Teach     → multi-level explanation + glossary + Socratic questions + flashcards
```

Every mode passes through the same mandatory critical layer: a claim→evidence
check on the load-bearing claims, at most three ranked red flags, and explicit
uncertainty flags.

Output conventions: lead with the answer at the requested depth, cite the paper precisely for specific claims (section / figure / equation anchors), and mark clearly what is stated vs. inferred vs. unknown.

Guardrails: never fabricate results, numbers, citations, or methods; never overstate evidence; if a source cannot be retrieved or parsed, say so plainly.

## Bundled resources

| File        | Purpose                                                                       |
| ----------- | ----------------------------------------------------------------------------- |
| `SKILL.md`  | Skill definition: role, the six reading modes, the critical layer, and guardrails |
| `scripts/fetch_paper.py` | *optional*: resolve an identifier, DOI, or URL to metadata and an open-access PDF |
| `scripts/literature.py`  | *optional*: fetch predecessors, citing works, and contradictions |

## Compatibility

The core workflow is **dependency-free** — it needs only an agent that can read, search, and fetch.

Optional capabilities add environment requirements:

| Capability                         | Requirement                                                        |
| ---------------------------------- | ----------------------------------------------------------------- |
| PDF → Markdown conversion          | a host-managed document converter on `PATH` (e.g. `markitdown`) — optional; the workflow runs without it |
| Literature lookup by arXiv / DOI   | Python 3 (stdlib-only scripts) and network access                 |

The skill is agent-agnostic and describes **what** to do rather than naming specific operations to call.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
