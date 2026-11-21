# Generation Templates

Skeletons for the files the Generate Phase produces. Angle-bracket
placeholders (`<like-this>`) are filled from the Clarify-Phase answers —
never leave a placeholder in delivered output. Adapt structure to the
target repository's existing sibling skills when the user names one.

## Description formula

> `<Action verb in third person>` + `<what the skill produces/does>` +
> `<scope boundary>` + "Use when the user asks to <trigger phrasing 1>,
> <trigger phrasing 2>, or <trigger phrasing 3>." + "Do not use for
> <near-miss case>."

Rules: third person; concrete keywords users actually type; one explicit
negative trigger; keep total length well under 1,024 characters; quote or
block-scalar the value if it contains `:`.

## SKILL.md skeleton

```markdown
---
name: <skill-name>
description: >-
  <Description built from the formula above.>
---

# <Skill Title>

<One paragraph: what this skill does and the outcome it produces.>

## When NOT to Use This Skill

- <Near-miss case 1 and why>
- <Near-miss case 2 and why>

## <Phase 1 Name>

<Steps. Prescriptive exact commands only for fragile/deterministic
operations; elsewhere state the intent and the reason.>

If <condition>, <do X>. Otherwise continue to <Phase 2 Name>.

## <Phase 2 Name>

<Steps, referencing resources at their point of use.>

Read [references/<topic>.md](references/<topic>.md) <load condition —
"when the input is X">.

## Key Principles

- <Correction-grade gotchas and calibration rules>
```

Variations are allowed — a short skill may be a single procedure section —
but every delivered `SKILL.md` has: frontmatter per the formula, a title,
a purpose paragraph, a when-not section or equivalent negative guidance,
and a procedural body with explicit decision points.

## Reference file pattern

One topic per file, small enough to read in one sitting, self-contained
(no chains that require opening a second file to understand the first).
Open with one line stating when the runtime agent should read it.

```markdown
# <Topic>

Read this file <load condition>.

<Focused material: rules, tables, worked examples from the user's
real context.>
```

Typical splits: one file per sub-domain of a broad procedure; one file for
a large checklist the body only summarizes; one file per output format the
skill may produce.

## Script pattern (only when the design requires it)

Tiny single-purpose command-line tools for logic that is deterministic or
fragile when improvised. No long-lived library code.

- Clear single responsibility; exits non-zero with a descriptive message
  on failure so the runtime agent can self-correct.
- Dependencies stated in the skill body, not discovered at runtime.
- Language chosen from the user's confirmed environment, never by default.

## Asset pattern (only when the design requires it)

Fixed artifacts the skill fills in or hands through: templates, forms,
starter files. Static content only — anything the agent must reason about
belongs in `references/` or the body.

## Optional frontmatter additions

Add only when a concrete need was established during Clarify:

```yaml
license: <license name>
compatibility: >-
  <Environment requirements, ≤ 500 chars; omit when none.>
metadata:
  <key>: <value>
```

## Naming reminders

- Name = directory name; derive from the capability, lowercase, hyphens
  only, no doubled/leading/trailing hyphens, ≤ 64 chars.
- Prefer two words that name the outcome (`invoice-parse`, `release-notes`)
  over abstract nouns (`utils`, `helpers`, `tools`).
