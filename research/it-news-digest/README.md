# IT News Digest

A standalone [Agent Skill](https://agentskills.io/specification) that compiles a daily digest of major world IT news for a technical audience — developers, security engineers, and AI/ML practitioners. Each edition covers the previous calendar day, verifies every item against a primary source, scores candidates for significance, and is written in the language of the user's request.

## When to use

| Situation                                                                  | Use this skill |
| -------------------------------------------------------------------------- | -------------- |
| You asked for a news digest, a daily tech news roundup, or "what happened yesterday in tech" | ✅ |
| You want a curated IT / security / AI news summary for engineers            | ✅ |
| You need a dated news brief with verified primary sources                   | ✅ |
| You need general web research on a topic (use `deeper-research` instead)    | ❌ |
| You need evergreen analysis rather than a dated edition                     | ❌ |

## How it works

The skill runs a fixed editorial pipeline:

1. **Fix the window** — previous calendar day, 00:00–23:59, Moscow time by default (date and timezone are overridable).
2. **Collect candidates** — poll the mandatory source list, supplement with targeted web searches; build a pool of 30+ candidates.
3. **Verify** — resolve every candidate to a primary source (official blog → GitHub → academic venue → CVE/advisory → researcher report), enforce the publication window, merge duplicate coverage of one event.
4. **Score** — five axes (technical depth, practical relevance, novelty, source trustworthiness, impact scale), 0–5 each; inclusion threshold ≥ 15 of 25.
5. **Balance** — 12–15 items in descending significance, split roughly equally between AI, security, and developer tooling/infrastructure.
6. **Write** — a one-line trend overview, structured items (context → technical essence → security impact → takeaway → source URL) of 400–700 characters each, plus "Also worth noting" and "On the radar next week" sections.
7. **Save** — the digest is written to `digest-YYYY-MM-DD.md` and delivered in full.

Hard exclusions apply throughout: consumer products without engineering detail, finance/PR news, retellings of old stories, shallow listicles, and anything without a primary-source URL never make the edition. If fewer than 12 items clear the bar, the edition is published shorter rather than padded.

The digest and all artifacts are written in the language of the user's request (English fallback); internal working notes stay in English.

## Bundled resources

| File                     | Purpose                                                                     |
| ------------------------ | --------------------------------------------------------------------------- |
| `SKILL.md`               | Skill definition, behavioral constraints, editorial workflow, scoring rubric |
| `references/sources.md`  | Mandatory-review source list (~60 feeds) with a polling strategy             |
| `references/format.md`   | Edition skeleton, item anatomy, length limits, tone rules, heading localization |

## Compatibility

The skill is agent-agnostic. It requires network access for web search and page fetching, and an agent that knows the current date to compute the selection window. It never fabricates news, URLs, dates, or figures — only retrieved and verified sources are cited.

The skill follows the [Agent Skills specification](https://agentskills.io/specification).

## License

MIT
