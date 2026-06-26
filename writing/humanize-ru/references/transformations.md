# Transformation Techniques by Register

Full catalog of transformation techniques with register-specific permissions.
Load this when executing Step 2 (Transformation) of the humanize-ru procedure.

Symbols in tables: 🟢 = use freely, 🟡 = use moderately (1–2 per text), 🔴 = do not use.

---

## 2.1 Lexical Replacement

Replace AI stamps with natural Russian equivalents matching the text register.
The same AI marker is replaced differently across registers:

| AI stamp                      | Conversational/Publicist 🟢                     | Scientific 🟢                                      | Official-business 🟢          |
| ----------------------------- | ----------------------------------------------- | -------------------------------------------------- | ----------------------------- |
| В современном мире            | Сегодня / Сейчас / В 2026-м                     | В настоящее время                                  | По состоянию на [год]         |
| В заключение следует отметить | Главное — / Суть в том, что / Короче,           | Таким образом / Резюмируя,                         | В заключение отмечается / Итого |
| Важно отметить                | Важно: / Ключевой момент —                      | Следует отметить / Необходимо учесть               | Следует отметить              |
| В данной статье               | Здесь / В этом тексте / Ниже                    | В настоящей работе / Далее                         | В настоящем документе         |
| Следует отметить              | Заметим: / Обратите внимание:                   | Отметим, что                                       | Следует отметить              |
| Играет важную роль            | Важен тем, что / Критичен для / Без него не работает | Является значимым фактором / Существенно влияет на | Имеет существенное значение для |
| Представляет собой            | Это / По сути / Фактически                      | Представляет собой / Является (научная норма)      | Представляет собой            |
| Является + adjective          | Just the adjective: «важен»                     | Allowed in scientific style, but can be omitted    | Allowed                       |
| Обеспечивает возможность      | Позволяет / Даёт / Открывает                    | Обеспечивает / Позволяет                           | Обеспечивает                  |
| Несомненно / Безусловно       | Конечно / Ясно / Понятно                        | Очевидно / Не вызывает сомнений                    | Бесспорно                     |
| На основании вышеизложенного  | Поэтому / Вот почему / Из этого следует         | Таким образом / На основании изложенного           | На основании вышеизложенного  |
| В рамках                      | В / При / Для                                   | В рамках (norm) / В контексте                      | В рамках                      |
| Данный / Данная / Данное      | Этот / Эта / Это or remove                      | Этот / Данный (both allowed)                       | Данный (business style norm)  |

**Universal rule across all registers:**

- «Осуществить» → «сделать» (conv.), «провести» (sci.), «выполнить» (off.-bus.)
- «Произвести» → «сделать» (conv.), «выполнить» (sci.), «произвести» (off.-bus. — allowed)
- «Функционировать» → «работать» (all registers)
- «Обладать» → concrete verb by meaning («имеет», «отличается», «характеризуется»)

**IMPORTANT:** do not replace bureaucratese and scientific phrases if they are
the GENRE NORM of the register. «Представляет собой» in a scientific article is
normal. «Данный» in an official document is normal. Remove only what is an
AI stamp (unnaturally high frequency), not a genre norm.

## 2.2 Syntactic Variety

AI text is rhythmically monotonous: uniform openings, uniform length, uniform
structure. Introduce variety — but within limits appropriate to the register.

| Technique                                                            | Conv. | Publ. | Sci. | Off.-bus. | Lit. |
| -------------------------------------------------------------------- | ----- | ----- | ---- | --------- | ---- |
| **Break uniform length** — ultra-short (2–5 words) among long ones    | 🟢    | 🟢    | 🟡   | 🔴        | 🟢   |
| **Vary paragraph openings** — question, "А вот…", verb, example       | 🟢    | 🟢    | 🟡   | 🔴        | 🟢   |
| **Front adverbials** — "При условии X — работает"                     | 🟢    | 🟢    | 🟢   | 🟡        | 🟢   |
| **Parceling** — split a sentence into two or three                    | 🟢    | 🟢    | 🔴   | 🔴        | 🟢   |
| **Change voice** — passive → active                                   | 🟢    | 🟢    | 🟡   | 🔴        | 🟢   |
| **Rhetorical question** at paragraph start                            | 🟢    | 🟢    | 🔴   | 🔴        | 🟢   |
| **Inversion** — reverse word order                                    | 🟢    | 🟢    | 🟡   | 🔴        | 🟢   |
| **Start with conclusion** — invert "intro→body→conclusion"            | 🟢    | 🟢    | 🟡   | 🔴        | 🟢   |

**Explanations for restrictions:**

- **Scientific:** parceling and rhetorical questions destroy academic tone.
  Variety is achieved through varying sentence length and fronting adverbials,
  not through conversational techniques.
- **Official-business:** syntactic variety is minimal — this register is
  deliberately standardized. Remove AI stamps but don't break genre structure.
- **Literary:** maximum freedom, but preserve the authorial voice.
  Don't impose techniques not present in the original text.

## 2.3 Russian Idioms and Natural Constructions

**CRITICAL:** this section is the primary source of "humanized text sounds
unnatural" type errors. Conversational elements are appropriate ONLY in
conversational and publicist registers. In scientific and official-business,
they destroy the text.

**Particles and modal words — dosage by register:**

| Element   | Example                         | Conv. | Publ. | Sci. | Off.-bus. | Lit. |
| --------- | ------------------------------ | ----- | ----- | ---- | --------- | ---- |
| «ну»      | «Ну, давайте разберёмся»       | 🟢    | 🟡    | 🔴   | 🔴        | 🟡   |
| «вот»     | «Вот что из этого вышло»       | 🟢    | 🟢    | 🔴   | 🔴        | 🟢   |
| «ведь»    | «Ведь это же очевидно»         | 🟢    | 🟡    | 🔴   | 🔴        | 🟡   |
| «же»      | «Туда же относится и…»         | 🟢    | 🟢    | 🔴   | 🔴        | 🟢   |
| «-то»     | «Проблема-то не в этом»        | 🟢    | 🟡    | 🔴   | 🔴        | 🟡   |
| «ли»      | «Работает ли это на практике?» | 🟢    | 🟢    | 🟡   | 🔴        | 🟢   |
| «уж»      | «Не так уж и сложно»           | 🟢    | 🟡    | 🔴   | 🔴        | 🟡   |
| «хоть»    | «Хоть какой-то прогресс»       | 🟢    | 🟡    | 🔴   | 🔴        | 🟡   |

**Conversational phrases — dosage by register:**

| Phrase                                         | Conv. | Publ. | Sci. | Off.-bus. | Lit. |
| ---------------------------------------------- | ----- | ----- | ---- | --------- | ---- |
| «По сути», «на самом деле», «если честно»      | 🟢    | 🟢    | 🔴   | 🔴        | 🟡   |
| «Как ни крути», «мягко говоря», «само собой»   | 🟢    | 🟡    | 🔴   | 🔴        | 🟡   |
| «Далеко не», «вряд ли», «оно и понятно»        | 🟢    | 🟢    | 🟡   | 🔴        | 🟢   |

**Idioms and phraseological units:**

| Register            | Allowed?     | If yes — how many                         |
| ------------------- | ------------ | ----------------------------------------- |
| Conversational      | Yes          | ≤1 per 500 characters                     |
| Publicist           | Moderately   | ≤1 per 1000 characters                    |
| Scientific          | 🔴 No        | 0                                         |
| Official-business   | 🔴 No        | 0                                         |
| Literary            | By context   | Unlimited, if the author has a style      |

**Safe idiom usage rule:** if in doubt — do NOT insert. An idiom added "for
liveliness" to a scientific text turns it into parody. "Палка о двух концах"
in an article about quantum mechanics does not enliven the text — it destroys it.

**What to use instead of idioms in formal registers:**

- Instead of «палка о двух концах» → «имеет как преимущества, так и недостатки»
  (sci.) or «сопряжено с рисками» (off.-bus.)
- Instead of «шито белыми нитками» → «аргументация неубедительна» (sci.)
- Instead of «брать быка за рога» → «перейти к решающему этапу» (publ.)

## 2.4 Personal Dimension

**CRITICAL:** do not insert "я" and "мой опыт" into text where a personal voice
is inappropriate. A scientific article without "я" is normal, not a flaw.
A business letter without personal pronouns is standard, not a problem.

| Technique                                                                          | Conv. | Publ. | Sci. | Off.-bus. | Lit. |
| ---------------------------------------------------------------------------------- | ----- | ----- | ---- | --------- | ---- |
| **Authorial position** — «я заметил», «по моему опыту», «мне кажется»              | 🟢    | 🟢    | 🔴   | 🔴        | 🟡   |
| **Life example / hypothetical scenario** — «Представьте: вы запустили…»            | 🟢    | 🟢    | 🟡   | 🔴        | 🟢   |
| **Doubt and nuance** — «Хотя, если честно…», «Тут есть нюанс…»                    | 🟢    | 🟢    | 🔴   | 🔴        | 🟢   |
| **Reader address** — «Знакомо?», «Согласитесь,», «Вы наверняка замечали»           | 🟢    | 🟢    | 🔴   | 🔴        | 🟡   |

**For scientific register — alternatives to personal voice:**

- Instead of «я заметил» → «обращает на себя внимание», «следует отметить»
- Instead of «по моему опыту» → «как показывает практика», «экспериментальные
  данные свидетельствуют»
- Instead of «мне кажется важным» → «принципиально важным представляется»
- Authorial «мы» is allowed: «мы провели исследование», «нами было установлено»

**For official-business — no personal voice.** Even «мы» is used only in the
sense of the organization, not the author.

**For publicist — authorial position is desirable.** This is what distinguishes
a living column from an AI compilation. But it must be meaningful, not routine:
«я считаю» followed by a restatement of the same thing — this is mechanical
emotion, not a living voice. The author must either take a position on a
debatable issue, provide real experience, or express an unexpected observation.

## 2.5 Structural Transformations

AI text suffers from "mechanical evenness" — equal attention to all sections,
smooth transitions, perfect "intro→body→conclusion" structure, template
contrasts. Human text is "organically uneven." But the degree of permissible
transformation depends on the register.

| Technique                                                                          | Conv. | Publ. | Sci. | Off.-bus. | Lit. |
| ---------------------------------------------------------------------------------- | ----- | ----- | ---- | --------- | ---- |
| **Remove or mask "rule of three"**                                                 | 🟢    | 🟢    | 🟡   | 🟡        | 🟢   |
| **Start with conclusion** — invert composition                                     | 🟢    | 🟢    | 🟡   | 🔴        | 🟢   |
| **Ask a rhetorical question** instead of a thesis                                  | 🟢    | 🟢    | 🔴   | 🔴        | 🟢   |
| **Skip formal conclusion** — one sentence or an open question                      | 🟢    | 🟢    | 🔴   | 🔴        | 🟢   |
| **Straighten template contrasts "not X, but Y"**                                   | 🟢    | 🟢    | 🟢   | 🟢        | 🟢   |
| **Kill inappropriate metaphors** — remove banal ones, keep fresh ones               | 🟢    | 🟢    | 🟢   | 🟢        | 🟡   |
| **Vary depth** — detailed here, telegraphic there                                  | 🟢    | 🟢    | 🟡   | 🔴        | 🟢   |
| **Make a sharp transition** — without smoothing "кроме того", "также"               | 🟢    | 🟢    | 🔴   | 🔴        | 🟢   |

**Explanations:**

- **Straightening "not X, but Y" contrasts** — the only technique that works in
  ALL registers. This is a pure AI pattern; in natural Russian it is rare.
  Instead of «важно не количество, а качество» → «важно качество» (or
  «качество решает — количество тут ни при чём» for conversational).
- **Killing metaphors** — everywhere. A banal metaphor («как дом без фундамента»)
  reveals AI in any register. If an image is needed — invent a fresh one from the
  same domain. But in scientific and official-business, better without metaphors
  at all — precise formulation is more valuable than imagery.
- **Formal conclusion** — mandatory in scientific and official-business.
  In these, «таким образом» and «в заключение» are genre norms, not AI stamps.
  Remove only in conversational and publicist.

## 2.6 Concreteness

Adding specifics (numbers, names, dates, titles) is a UNIVERSAL technique that
works in all registers. AI text speaks in general terms: «многие компании»,
«исследователи полагают», «в последнее время». A human writing on any topic
with understanding provides details.

- **Numbers.** Instead of «многие компании» → «73% опрошенных компаний из
  рейтинга Forbes Top-100» (publ.) or «по данным опроса N = 1200» (sci.).
- **Names.** Instead of «исследователи полагают» → «Группа Иванова из МФТИ
  показала…» (sci.) or «Как отмечает Иванов в своём блоге…» (publ.).
- **Dates.** Instead of «в последнее время» → «с января по июнь 2026».
- **Real product names.** Instead of «инструмент позволяет» → «Тот же Notion
  позволяет» or «Обычный Google Docs позволяет».

**Important:** if exact data is unavailable — do not invent. Better to leave
a general formulation than to hallucinate. In the scientific register, the
absence of specific references where expected is itself an AI marker. Either
add real ones, or restructure the sentence so it doesn't promise a reference.
