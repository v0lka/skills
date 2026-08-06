# Humanize RU

A standalone [Agent Skill](https://agentskills.io/specification) for text transformation and post-editing of AI-generated content. It removes signs of machine generation from Russian-language AI text while preserving its original register and communicative purpose — scientific text stays scientific, business text stays business, conversational stays conversational. Only the "AI smell" is removed.

## When to use

| Situation                                                                                       | Use this skill |
| ----------------------------------------------------------------------------------------------- | -------------- |
| Text from an LLM (ChatGPT, Claude, Gemini, …) needs to be published under human authorship      | ✅             |
| A client or instructor checks the text with an AI detector                                      | ✅             |
| Machine output sounds dry, formulaic, or unnatural for its genre                                | ✅             |
| AI output needs to be adapted to a specific tone of voice in Russian                            | ✅             |

## How it works

The skill follows a four-step procedure built around one core principle: **not "make the text conversational", but "remove AI markers, keeping the register appropriate for the context."**

```
Step 0            Step 1             Step 2              Step 3
Determine   ──►   Diagnose     ──►   Transform     ──►   Verify
the register      AI markers         (respecting          (overcorrection
                                     the register)        test)
```

### Step 0 — Determine the register

The appropriate transformations depend entirely on the functional style:

| Register                  | Genre examples                                           |
| ------------------------- | -------------------------------------------------------- |
| **Разговорный**           | Telegram post, personal letter, comment                  |
| **Публицистический**      | Blog, media article, column, longread                    |
| **Научный**               | Scientific article, dissertation, textbook, report       |
| **Официально-деловой**    | Order, contract, business letter, instruction            |
| **Художественный**        | Story, novel, essay, literary sketch                     |

**Register is law.** Never lower the register without an explicit reason — a scientific text "humanized" to conversational level is a ruined scientific text.

### Steps 1–3 — Diagnose, transform, verify

1. **Diagnose** — explicitly list every AI marker found. Transformation does not begin until the markers are enumerated.
2. **Transform** — apply techniques *selectively*, based on which markers were found and which register was determined. Transformations must not change the register.
3. **Verify** — apply the **mandatory overcorrection test**: "Could this text have been written by a human in this genre?" If a scientific article sounds like a TikTok post, roll back.

## Key principles

- **Do not harm meaning.** Style is secondary to content.
- **Register is law.** Do not lower the register.
- **Do not overdo it.** Conversational elements work on contrast: ≤1 particle per paragraph in publicist text, 0 in scientific and business.
- **Verify facts.** Better to leave a general formulation than invent a number.
- **Organic unevenness > mechanical evenness.**

## Bundled resources

| File                            | Purpose                                                              |
| ------------------------------- | -------------------------------------------------------------------- |
| `SKILL.md`                      | Skill definition, the four-step procedure, and universal rules       |
| `references/ai-markers.md`      | Full catalog of AI markers with examples and explanations            |
| `references/transformations.md` | Transformation techniques with dosage tables per register            |
| `references/checklist.md`       | Verification checklist with register-dependent criteria              |

## Compatibility

The skill is agent-agnostic. It describes **what** to do, not which specific tools to call, so it works with any AI agent that can read and write text. No external services are required.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
