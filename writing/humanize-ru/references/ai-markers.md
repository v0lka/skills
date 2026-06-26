# AI Marker Catalog for Russian Text

Full diagnostic catalog of AI-generation signs in Russian text. Load this when
executing Step 1 (Diagnosis) of the humanize-ru procedure.

---

## 1.1 Lexical Cliches and Stamps

Neural networks are statistically over-represented in academic and encyclopedic
texts, so they reproduce characteristic phrases even where inappropriate.

**High-frequency AI markers (3+ found = text almost certainly machine-generated):**

| Marker                                        | Why it reveals AI                                                       |
| --------------------------------------------- | ---------------------------------------------------------------------- |
| «В современном мире…»                         | Universal opener, neural net can't start without a contextual frame    |
| «В заключение следует отметить…»              | Template summary instead of a natural conclusion                       |
| «Важно отметить, что…»                        | Machine way to signal importance                                       |
| «Необходимо подчеркнуть…»                     | Calque from English "it is necessary to emphasize"                     |
| «Несомненно, …» / «Безусловно, …»             | Excessive confidence where a human would be softer                     |
| «В данной статье рассматривается…»            | Dissertation-abstract stamp, inappropriate outside academic contexts   |
| «Следует отметить…»                           | The most frequent AI-text marker in Russian                            |
| «Данная статья посвящена…»                    | Another dissertation-abstract stamp                                    |
| «В наше время…»                               | Outdated newspaper opener                                              |
| «Играет важную/ключевую роль…»                | Translated "plays an important role"                                   |
| «Представляет собой…»                         | Heavy construction instead of simple "это"                             |
| «В целом, …»                                  | Empty generalization                                                   |
| «Это особенно важно для…»                     | ChatGPT's calling card in Russian texts                                |
| «…, что + verb» (repeating construction)      | English "…, which + verb" calque                                       |
| «Является» as a copula                       | Calque from English "is", often omitted in natural Russian             |
| «В заключение хочется сказать…»               | Template ending                                                        |
| «На основании вышеизложенного…»               | Bureaucratic cliche, typical for AI                                    |
| «Хочется верить, что…»                        | Sentimental stamp in endings                                           |
| «Обеспечивает возможность…»                   | Heavy replacement for "позволяет"                                      |
| «Является одним из наиболее…»                 | Template superlative                                                   |
| «В рамках данной работы…»                     | Academic stamp                                                         |
| «Обусловлено тем, что…»                       | Bureaucratic cause-and-effect construction                             |

## 1.2 Structural Patterns

- **Uniform paragraph openings.** All paragraphs start with a nominative noun
  or verb in the same form. Humans vary.
  **Quantitative threshold:** if more than 50% of paragraphs start with a
  nominative noun — this is a structural AI marker. Count the ratio: paragraphs
  starting with nominative nouns divided by total paragraphs. The threshold also
  triggers for texts where all paragraphs start with a verb in the same form
  (e.g., all infinitives or all 3rd-person forms).
- **Predictable composition.** Introduction (general frame) → Main body
  (3–4 paragraphs) → Conclusion (summarizing paragraph with "таким образом" or
  "в заключение"). Natural text often breaks this scheme.
- **"Rule of three."** Neural nets love exactly three-item lists and
  three-part parallel constructions. Humans use 2, 3, 4, or asymmetric lists.
- **Uniform sentence length.** 15–20 words each — neural nets produce
  rhythmically monotonous text. Humans mix short (3–5 words) and long
  (30+ words) sentences.
- **Every paragraph is a mini-essay.** Thesis → elaboration → micro-conclusion.
  In natural text, paragraphs have varied structure: one-two sentences,
  a question, an example.
- **Template contrasts "not X, but Y."** Neural nets love constructions like
  "это не просто инструмент, а целая философия", "важно не количество,
  а качество", "не за счёт сокращения расходов, а за счёт роста выручки",
  "дело не в X, а в Y". This is a rhetorical crutch: instead of directly
  asserting Y, AI creates an artificial contrast with X. In natural Russian,
  this construction is a rare emphasis, not a structural template in every
  other paragraph. A human says "это философия" or "важно качество"
  without the dramatic negation.

## 1.3 Syntactic Features

- **Subject + predicate without variation.** Word order is too "correct" —
  no inversions, fronted adverbials, parceling.
- **Overuse of participial and adverbial phrases.** Especially in
  unnatural positions — a long chain of 2–3 phrases in a row.
- **Genitive chaining.** "Анализ особенностей формирования механизмов
  реализации…" — a classic AI pattern.
- **Excess "который."** Where a human would use a participial phrase, a dash,
  or split into two sentences — the neural net piles on "который".
- **Verbal nouns at sentence start.** "Формирование стратегии…",
  "Реализация подхода…" instead of "Формируем стратегию…" or
  "Чтобы реализовать подход…".
- **Excessive passive voice.** "Было установлено…", "Может быть
  рассмотрено…", "Является актуальным…" — legacy of training on
  scientific and bureaucratic texts.

## 1.4 Stylistic Signs

- **Absence of personality.** Text is faceless: no "я", "по моему опыту",
  "мне кажется", personal stories or assessments. If present — they sound fake.
- **Emotional neutrality.** Even, dispassionate tone without the slightest
  variation. Humans involuntarily add emotion through word order, particles,
  punctuation.
- **Encyclopedic style.** Text reads like a Wikipedia article, even if
  it's a Telegram post or a message to a colleague.
- **Excessive politeness.** Neural nets avoid sharp formulations, adding
  "возможно", "вероятно", "как представляется" everywhere.
- **Absence of conversational elements.** No particles "ну", "вот", "же",
  "ли", "-то", "ведь"; no colloquial words, contractions ("чё", "щас"
  not as illiteracy but as natural oral speech rendered in text).
- **Inappropriate metaphorical comparisons.** Neural nets often insert
  metaphors where unnecessary, and do so unnaturally: "подобно тому, как…",
  "словно…", "как маяк в бушующем море…", "это как строить дом без
  фундамента". Metaphors are either banal (worn-out images from the training
  corpus) or excessively poetic for the context (a post about accounting —
  but there's "подобно симфонии"). In natural Russian text, a metaphor is
  either fresh and precise or absent. A human does not illustrate every
  point with a comparison.

## 1.5 English Calques

Neural nets were predominantly trained on English and "translate" patterns:

- **"Это является…"** instead of "это…" (is → является).
- **"Делать" as a universal verb.** "Делает возможным" instead of
  "позволяет", "делает акцент" instead of "подчёркивает".
- **Mandatory subject.** "Они говорят, что…" instead of "Говорят, что…".
  Russian is a pro-drop language — AI forgets this.
- **"Иметь" instead of specific verbs.** "Имеет значение" instead of "важен",
  "имеет место" instead of "происходит".
- **Direct word order in subordinate clauses.** "Я думаю, что это хорошая
  идея" instead of "Хорошая идея, я думаю" or "Идея-то хорошая".

## 1.6 Content Signs

- **Superficial topic coverage.** General words without specifics: no numbers,
  dates, names, statistics. "Многие компании…" — which ones exactly?
- **Logical loops and repetitions.** The same thought restated in different
  words in adjacent paragraphs.
- **Absence of context.** Neural nets don't know what's happening right now —
  no references to current events, news, trends.
- **Hallucinations.** Fabricated sources, non-existent quotes, confused
  names and dates. Never publish AI text as-is without fact-checking.
- **Logical contradictions.** One paragraph asserts something, two paragraphs
  later — the opposite. Neural nets don't track contradictions.

## 1.7 Mandatory Diagnostic Output Format

**CRITICAL: do not proceed to transformation without listing found markers
explicitly.** "In-head" diagnosis is unreliable — markers get lost, go
uncounted, remain unnoticed.

Output the diagnostic result in this format:

```
### Diagnostic Result

**Lexical cliches:** [list of found markers or "none found"]
**Structural patterns:** [list: "rule of three", "not X, but Y", uniform paragraph openings, ...]
**Syntax:** [list: monotonous sentence length, genitive chaining, ...]
**Style:** [list: flat tone, explanatory intonation, absence of personality, ...]
**English calques:** [list or "none found"]
**Content signs:** [list: lack of specifics, logical loops, ...]

**Total markers:** N (3+ = text almost certainly machine-generated)
```

Only after explicitly listing the markers, proceed to Step 2.
