# Deeper Research

A standalone [Agent Skill](https://agentskills.io/specification) that conducts thorough, multi-source research using a **Tree of Thoughts** methodology. Produces cited, multi-perspective syntheses with explicit confidence ratings, an evidentiary hierarchy, and transparent documentation of pruned branches.

## When to use

| Situation                                                                      | Use this skill |
| ----------------------------------------------------------------------------- | -------------- |
| You asked for research, analysis, investigation, or a deep dive               | ✅             |
| You need a literature review or structured reasoning on a complex topic        | ✅             |
| You need cited sources and a multi-perspective synthesis                       | ✅             |
| A simple factual lookup is sufficient                                          | ❌             |

## How it works

Instead of following a single chain of reasoning, the skill deliberately explores multiple reasoning paths at each stage, evaluates their promise, and backtracks from dead ends:

```
BRANCH    →  Generate 2–4 candidate approaches / hypotheses / interpretations
EVALUATE  →  Score each on evidence strength, relevance, novelty
SELECT    →  Pursue the top 1–2; mark the rest as fallback
DEEPEN    →  Develop the selected branches further
BACKTRACK →  Hit contradictory evidence or dead end? Return to the branching point
```

The research process applies the Tree of Thoughts cycle at each step:

1. **Clarify the research question** — restate, generate alternative framings, commit to the strongest, keep a fallback.
2. **Deconstruct the topic** — break into 3–6 subtopics, rate analytical lenses by yield.
3. **Gather and evaluate** — 5–15 web searches, multi-source verification.
4. **Synthesize** — separate established facts from emerging trends, hypotheses, and speculation; cite sources inline with numbered references.

Source reliability is categorized using the standard evidentiary hierarchy: *peer-reviewed > government reports > industry papers > preprints > press*.

## Bundled resources

| File        | Purpose                                                                          |
| ----------- | ------------------------------------------------------------------------------- |
| `SKILL.md`  | Skill definition, the ToT framework, behavioral constraints, and report format  |

## Compatibility

The skill is agent-agnostic. It requires network access for source gathering and verification. It never fabricates URLs or source references — only sources actually retrieved and verified are cited.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
