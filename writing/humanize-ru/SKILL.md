---
name: humanize-ru
description: >
  Removes signs of machine generation from Russian-language AI text, preserving
  its original register and communicative purpose. Does not turn everything into conversational
  style — scientific text remains scientific, business text remains business, and conversational
  remains conversational. Use when you need to remove AI markers from text for
  publication, bypass AI detectors, or adapt machine output to
  natural Russian speech in the required register.
---

# Humanize RU — removing AI markers from Russian text

Remove signs of machine generation from the text, preserving its original register
and communicative purpose.

**Core principle:** not "make the text conversational", but "remove AI markers,
keeping the register appropriate for the context."

## When to use

- Text from ChatGPT, Claude, Gemini, or another LLM needs to be published
  under human authorship.
- A client or instructor checks the text with an AI detector.
- Machine text sounds dry, formulaic, unnatural for its genre.
- AI output needs to be adapted to a specific tone of voice.

## Procedure

### Step 0 — Determine the text register

FIRST, determine the functional style (register) of the source text.
The appropriate transformations — and the ones that would ruin the text — depend on this.

**Five registers and their key features:**

| Register                | Lexical features                                                          | Syntax                                                              | "I" allowed?                          | Genre examples                                           |
| ---------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------- | ------------------------------------- | --------------------------------------------------------- |
| **Разговорный**        | Conversational vocabulary, particles, contractions, ellipsis              | Short sentences, parcellation, inversions                           | Yes, freely                           | Пост в Telegram, личное письмо, комментарий               |
| **Публицистический**   | Common vocabulary + expressive elements, rhetorical devices               | Varied: alternating short and long, questions, exclamations         | Yes, author's position                | Блог, статья в СМИ, колонка, лонгрид                      |
| **Научный**            | Terms, abstract vocabulary, verbal nouns                                  | Complex syntax, passive voice, clear logical structure              | Only "мы" (author's) in methodology   | Научная статья, диссертация, учебник, аналитический отчёт |
| **Официально-деловой** | Bureaucratic formulas, business clichés, standardized phrasing            | Cumbersome, clipped, unemotional, strict word order                 | No                                    | Приказ, договор, деловое письмо, инструкция, отчёт        |
| **Художественный**     | Figurative vocabulary, metaphors, individual-authorial words              | Free, subordinated to artistic purpose                              | Depends on narrator                   | Рассказ, роман, эссе, художественный очерк                |

**How to determine the register** (check in order, first match is the answer):

1. **Formal marker?** Приказ, договор, инструкция, официальное письмо → Официально-деловой.
2. **Scientific vocabulary?** Terms, citations, methodology, abstract concepts as subjects → Научный.
3. **Literary devices?** Plot, characters, explicit imagery, metaphors as foundation → Художественный.
4. **Personal voice + expression?** "Я", rhetorical questions, value judgments, calls to action — without rigid scientific structure → Публицистический.
5. **Short, informal, with particles?** "Ну", "вот", "короче", ellipsis, emoji → Разговорный.

**If unsure — default to Публицистический.** This is the neutral register, from
which you can shift in any direction at the user's request.

**NEVER lower the register without an explicit reason.** A scientific text
"humanized" down to a conversational level is a ruined scientific text.

### Step 1 — Diagnosis: find AI markers

Find and explicitly list all signs of machine origin in the text. The full
marker catalog with examples and explanations is in
[references/ai-markers.md](references/ai-markers.md). Load this file
before starting diagnosis.

Brief overview of marker categories:

- **Lexical clichés** — formulaic phrases: "в современном мире", "следует
  отметить", "играет важную роль", "представляет собой" and others.
- **Structural patterns** — uniform paragraph openings, "rule of three",
  identical sentence length, template contrasts "не X, а Y".
- **Syntax** — monotonous word order, genitive chaining,
  overuse of "который", excessive passive voice.
- **Style** — facelessness, emotional neutrality, encyclopedic
  style, absence of conversational elements, inappropriate metaphors.
- **English calques** — "является" instead of zero copula, "делать" as a
  universal verb, mandatory subject, "иметь" instead of specific
  verbs.
- **Content signs** — lack of specifics, logical loops,
  absence of context, hallucinations.

**CRITICAL: do not proceed to transformation without listing the found markers
explicitly.** Output the result in the following format:

```
### Diagnostic Result

**Lexical clichés:** [list of found markers or "none found"]
**Structural patterns:** [list: "rule of three", "не X, а Y", uniform paragraph openings, ...]
**Syntax:** [list: monotonous sentence length, genitive chaining, ...]
**Style:** [list: flat tone, explanatory intonation, absence of personality, ...]
**English calques:** [list or "none found"]
**Content signs:** [list: lack of specifics, logical loops, ...]

**Total markers:** N (3+ = text almost certainly machine-generated)
```

### Step 2 — Transformation: removing AI markers while respecting the register

Apply techniques SELECTIVELY: which markers were found + which register was determined.

**Key rule:** transformation must NOT change the register. Scientific text
remains scientific, conversational remains conversational. Remove only the unnaturalness
of AI generation, not the genre traits of the register.

The full catalog of techniques with dosage tables by register is in
[references/transformations.md](references/transformations.md). Load this
file before transformation. Below are the critically important rules that must
not be violated:

**Universal rules (all registers):**

- "Осуществить" → "сделать" (conv.), "провести" (sci.), "выполнить" (off.-bus.)
- "Функционировать" → "работать" (all registers)
- "Обладать" → a concrete verb based on meaning
- **Straighten "не X, а Y"** — the only technique that works in ALL
  registers. This is a pure AI pattern. "Важно не количество, а качество" →
  "Важно качество".
- **Kill banal metaphors** everywhere. "Как дом без фундамента" reveals AI
  in any register.
- **Add specifics** (numbers, names, dates, titles) — a universal
  technique. But do not invent: if exact data is unavailable, leave the general formulation.

**Critical restrictions by register:**

- **Научный:** NO parcellation, rhetorical questions, particles ("ну",
  "вот", "ведь", "-то"), idioms, personal "я". Passive voice and "является" are
  normal. Authorial "мы" is allowed.
- **Официально-деловой:** NO conversational elements of any kind, personal
  voice, rhetorical questions, parcellation. Genre clichés ("в соответствии
  с", "на основании") MUST BE PRESERVED — these are not AI stamps.
- **Разговорный/Публицистический:** particles, idioms, personal voice allowed —
  but dosed (≤1 particle per paragraph, ≤1 idiom per 500–1000 characters).

### Step 3 — Final verification

After editing, run through the checklist. The full list with register-dependent
criteria and anti-patterns is in
[references/checklist.md](references/checklist.md). Load this file
before verification.

**Universal criteria (all registers):**

- [ ] The text contains none of the markers from the lexical cliché catalog
- [ ] Template contrasts "не X, а Y" have been removed
- [ ] Banal metaphors have been removed or replaced
- [ ] The meaning of the source text is preserved
- [ ] No fabricated facts — all added specifics are real
- [ ] English calques are eliminated
- [ ] AI bureaucratese removed: "является" as a copula (except Научный and Официально-деловой),
      "представляет собой" (except Научный and Официально-деловой)

**Mandatory overcorrection test:**
read the text and ask — "Could this text have been written by a human in this
genre?" If a scientific article sounds like a TikTok post — the register is violated,
roll back conversational edits. If a scientific or business text contains "ну",
"ведь", "-то", idioms, or an inserted "я" — remove immediately.

## Key principles

1. **Do not harm meaning.** Style is secondary to content.
2. **Register is law.** Do NOT lower the register. A scientific text must not
   become conversational.
3. **Do not overdo it.** Conversational elements work on contrast:
   ≤1 particle per paragraph in publicist text, 0 in scientific and business.
4. **Verify facts.** Better to leave a general formulation than to invent a number.
5. **Imitate the author, not the "average speaker."** Lively Russian in a scientific
   article is not the same as in a Telegram chat.
6. **Organic unevenness > mechanical evenness.** Human
   text is characterized by uneven depth and stylistic variation,
   not a collection of "human-like" wordlets.
7. **If in doubt — don't change.** Conservative editing is better than aggressive
   transformation.

## Anti-patterns (what not to do)

Full catalog is in [references/checklist.md](references/checklist.md).

**In brief:**

- ❌ Lowering the register (Научный → Разговорный).
- ❌ Inserting "я" into formal text.
- ❌ Spamming conversational words in any register.
- ❌ Adding idioms to scientific and business text.
- ❌ Changing "является" to "это" in scientific and business style (it's normal there).
- ❌ Removing genre-specific bureaucratese in Официально-деловой text.
- ❌ Creating "mechanical emotions" — inserting "я считаю" without semantic
  weight.
- ❌ Turning every paragraph into a rhetorical question.
- ❌ Replacing one uniformity with another (all sentences became short
  or all paragraphs start with a particle).
