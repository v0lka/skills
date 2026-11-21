# Digest Format and Style Guide

The digest is written in the language of the user's request (fallback: English). The structure below is canonical; section headings localize per the table at the end of this file.

## Edition skeleton

```markdown
# IT News Digest — YYYY-MM-DD

_Window: YYYY-MM-DD 00:00:00 – YYYY-MM-DD 23:59:59 <timezone>_

**Yesterday:** trend one; trend two; trend three; trend four; trend five. (5-7 key trends, each compressed to one clause.)

## 1. <Headline-thesis — one line>

...item body (see anatomy below)...

## 2. <Headline-thesis>
...

## Also worth noting

- <one-line essence> — <URL>
- ... (5-7 items, each with a mandatory URL)

## On the radar next week

- YYYY-MM-DD — <event> — <URL>
- ... (5-7 confirmed events, each with date and source URL)
```

Order the main items by descending significance (Step 4 total score, then judgment).

## Main item anatomy

Each of the 12-15 main items follows this shape:

```markdown
## N. <Headline-thesis — a single line stating the conclusion>

**Context:** why this matters now — 1-2 sentences.

**Technical essence:** architecture, mechanism, figures, limitations,
affected versions, code details, benchmark results, practical consequences.

**Security impact:** 1-2 sentences on risks, exploitation scenarios,
mitigations, or threat-model implications. Include ONLY when the item
is security-relevant.

**Takeaway:** what to check, try, update, read, disable, test, or reconsider.

Source: <primary URL>

Additional source: <URL>   (optional, only when genuinely additive)
```

Writing rules for the body fields:

- **Headline-thesis** states the finding itself ("OpenSSL 3.5 ships post-quantum KEM defaults"), never a teaser ("OpenSSL has news for you").
- **Context** answers "why today": what changed, what triggered it, what it displaces.
- **Technical essence** is a condensed retelling with the load-bearing specifics: mechanism, numbers, affected versions, benchmark results, limitations. If the item is a vulnerability: root cause, affected versions, fixed version, exploitability preconditions.
- **Security impact** is mandatory for vulnerabilities, attack classes, and infrastructure security items; optional elsewhere. Do not stretch non-security news into a security note.
- **Takeaway** is a concrete action for engineers, phrased as an instruction ("upgrade to 2.4.62 before Friday", "benchmark your RAG pipeline against MTEB-v2 before trusting vendor numbers").

## Length limits

- One main item: 400-700 characters excluding URLs (counting all body fields together).
- Headline: one line.
- No long introductions; the overview line is the whole preamble.
- No generic musings without technical value.

## Tone and style

Style: rigorous journalism — technical, alive.

Allowed:

- Skepticism and critical assessment.
- Pointing out limitations and trade-offs.
- Counterarguments for contested stories.

Forbidden:

- Advertising tone.
- Exaggerated or unsubstantiated claims.
- Bureaucratic officialese.
- Retelling a press release.
- Metaphorical comparisons and template contrasts: "this is not X, but Y", "what matters is not X, but Y", "achieved not through X, but through Y".
- Negation constructions where an affirmative phrasing works.

## Secondary sections

### Also worth noting

5-7 items that are fresh and relevant but fall below the main-edition bar on technical depth, scale, or source trustworthiness. Each entry: one-line essence — `<URL>`. The URL is mandatory. If no qualifying items exist, omit the section.

### On the radar next week

5-7 upcoming events, only if announced in advance and confirmed by sources: releases, conferences, deadlines, planned launches, end-of-support dates, vulnerability disclosure dates, expected benchmark or standard publications. Each entry: date — event — source URL. Never invent expected events; publish fewer entries (or omit the section) if few are confirmed.

## Heading localization

| Section (canonical English) | Russian |
|---|---|
| `Yesterday:` | `Вчера:` |
| Item field `Source:` | `Источник:` |
| Item field `Additional source:` | `Дополнительный источник:` |
| Item field `Context:` | `Краткий контекст:` |
| Item field `Technical essence:` | `Техническая суть:` |
| Item field `Security impact:` | `Значение для безопасности:` |
| Item field `Takeaway:` | `Практический вывод:` |
| Also worth noting | Что ещё стоит отметить |
| On the radar next week | На что обратить внимание на следующей неделе |

For other request languages, translate the canonical headings faithfully; keep the structure and field order identical.

## Pre-delivery self-check

Run the nine checks from SKILL.md Step 8. If all pass, deliver silently. If one cannot be met, add one line at the end of the digest stating the limitation.
