# Verification Checklist and Anti-Patterns

Load this when executing Step 3 (Final Verification) of the humanize-ru
procedure. Contains register-specific checklists, rhythm verification,
anti-overcorrection tests, and the full anti-pattern catalog.

---

## Formal Rhythm Check

For **conversational and publicist** registers only. For scientific and
official-business, rhythmic monotony is less critical and some criteria
directly contradict genre norms.

**For conversational and publicist:**

- [ ] **Sentence length spread:** minimum length ≤ 5 words, maximum ≥ 22 words.
      If all sentences fall within 12–18 words — rhythm is monotonous, fix it.
- [ ] **Varied sentence openings:** no more than 30% of sentences start with a
      nominative subject. Count the ratio — if higher, add inversions, fronted
      adverbials, questions.
- [ ] **No identical consecutive openings:** no two adjacent sentences start
      with the same word or the same part of speech in the same form.
- [ ] **Presence of ultra-short:** at least one sentence of 2–5 words per every
      500 characters of text.
- [ ] **Punctuation density:** at least one em-dash per 300–500 characters
      (Russian actively uses dashes where AI puts commas or "является").
- [ ] **No monotonous chains:** no three consecutive sentences have the same
      syntactic structure.

If at least 4 of 6 criteria are met — the text is rhythmically varied.

**For scientific and official-business:**

- [ ] Check only length spread and absence of monotonous chains.
- [ ] Do NOT require ultra-short sentences and dashes — in these registers,
      long sentences and minimal dashes are the norm.
- [ ] Do NOT require varied openings — in scientific text, subject-first
      word order is standard.

---

## Anti-Overcorrection: Final Naturalness Test

Before considering the work complete, check the text for signs of the opposite
problem — unnaturalness caused by excessive "humanizing":

- [ ] **Register test:** read the text and ask — "Could this text have been
      written by a human in this genre?" If a scientific article sounds like
      a TikTok post — the register is violated, roll back conversational edits.
- [ ] **Particle test:** if a scientific or business text contains «ну», «ведь»,
      «-то», «короче» — remove immediately.
- [ ] **Idiom test:** if a scientific text contains «палка о двух концах» or
      «брать быка за рога» — remove.
- [ ] **Forced «я» test:** if «я заметил» or «по моему опыту» was inserted
      into text where a personal voice is inappropriate — remove.
- [ ] **Parody test:** read the text in full. If it sounds like "look how
      human-like I'm writing!" — there are too many conversational elements.
      Remove half.
- [ ] **New monotony test:** if EVERY paragraph starts with a question, particle,
      or inversion — this is a new monotony. Return some paragraphs to neutral
      opening.

---

## AI Detector Check (Optional)

If formally passing a detector matters — run through a verification service
(GPTZero, Originality.ai, or Russian-language equivalents). Note that no
detector gives 100% accuracy. Rely on the cumulative weight of signs.

---

## Anti-Patterns

### Register Errors

- **Lowering the register.** Turning a scientific article into a conversational
  post. Scientific text stays scientific — remove only AI stamps.
- **Inserting «я» into formal text.** «Я заметил, что инфляция составляет 6%»
  — in a business report, sounds fake.
- **Spamming conversational words in any register.** Even in conversational
  text, «ну» and «ведь» in every sentence is a caricature.
- **Adding idioms to scientific and business text.** «Палка о двух концах»
  in an article about machine learning — destruction of scientific authority.

### Transformation Errors

- **Changing «является» to «это» everywhere indiscriminately.** In scientific
  and business style, «является» is the norm, not an AI marker.
- **Removing all bureaucratese.** In official-business text, «в соответствии с»,
  «на основании» are genre standards. Remove only AI stamps, not genre norms.
- **Adding profanity or coarse colloquialisms** without an explicit user request.
- **Changing structure where it is dictated by genre.** Legal document,
  technical specification, scientific article — structure is part of the content.
- **Inserting fabricated life examples.** «Я как-то раз…» always sounds fake.
  Hypothetical scenarios («представьте», «допустим») are permissible, but
  indicate their hypothetical nature.
- **Leaving AI text without hallucination check.**

### Overcorrection Errors

- **Creating "mechanical emotions."** Inserting «я считаю» and personal
  assessments where they carry no semantic weight. If the authorial position
  amounts to restating the same thing in different words — this is not a living
  voice, but a new AI pattern.
- **Turning every paragraph into a rhetorical question.** If five paragraphs
  in a row start with a question — this is a new monotony.
- **Creating a parody of conversational style.** «Ну, короче, проблема-то,
  ведь, палка о двух концах, но, как ни крути, берём быка за рога» — the text
  sounds like bad comedy, not living speech.
- **Replacing one uniformity with another.** If every sentence became short
  (parceling everywhere) or every paragraph starts with a particle — the
  rhythmic problem was not solved, but replaced with a new one.
