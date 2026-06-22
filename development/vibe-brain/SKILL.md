---
name: vibe-brain
description: Analyzes the project codebase, documentation, and memory to identify the single highest-priority task to work on right now. Triggers on phrases like "Hey, what are we going to do today, Brain?", "What should I work on?", "What's next?", or any request for task prioritization.
---

# Vibe Brain — Task Prioritizer

When invoked, do a thorough four-phase analysis and return exactly ONE task: the most impactful thing to do right now, explained conversationally.

---

## Trigger phrases

Invoke this skill when the user says any of:

- "Hey, what are we going to do today, Brain?"
- "What should I work on?"
- "What's next?"
- "What's the top priority?"
- "Pick a task for me"
- Any variant asking for task selection or prioritization

---

## Phase 1: Gather context

Do all of the following in parallel where possible. You are gathering raw material, not analyzing yet.

### 1.1 Project structure

- List the top-level directory tree (`ls -la`, `tree -L 2` if available)
- Read package manifests: `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Makefile`, etc.
- Identify the tech stack, build system, and test runner

### 1.2 Codebase scan

- Search for TODO, FIXME, HACK, XXX markers across the codebase
- Search for `@deprecated`, `DEPRECATED`, `BROKEN` annotations
- Check for skipped tests: `it.skip`, `test.skip`, `xtest`, `#[ignore]`, `t.Skip`, `pytest.mark.skip`
- Look for empty catch blocks, `// eslint-disable`, `# type: ignore`, `noqa` — signs of deferred cleanup
- Find files with high churn (recent git history): `git log --oneline --since="2 weeks ago" --name-only`

### 1.3 Documentation

- Read `README.md`, `AGENTS.md`, `SECURITY.md`, `CONTRIBUTING.md`, `DEVELOPMENT.md`, `ARCHITECTURE.md`, etc
- Read any `docs/` or project-level specs, ADRs, or decision logs
- Read open issues if an issue tracker is referenced

### 1.4 Memory and knowledge

- Call memory retrieval for project-related memories (project introduction, tech stack, conventions, lessons learned)
- Retrieve knowledge modules from the codebase if available

---

## Phase 2: Extract candidates

From the gathered context, build a mental list of candidate tasks. Look for:

| Signal                       | What it means                                                                       |
| ---------------------------- | ----------------------------------------------------------------------------------- |
| **TODO / FIXME**             | Explicitly deferred work — the developer already knew it needed doing               |
| **Skipped test**             | A test that was disabled but not deleted — likely a known bug or incomplete feature |
| **Empty error handler**      | Swallowed errors hiding real problems                                               |
| **High-churn file**          | Volatile code — may be unstable, under active development, or poorly designed       |
| **Missing tests**            | Untested critical paths — high risk                                                 |
| **Documentation gap**        | Docs that reference non-existent files, outdated commands, or missing sections      |
| **Recent unfinished commit** | A commit message like "WIP", "tmp", "checkpoint" — interrupted work                 |
| **Open TODO in roadmap**     | Planned work from specs/roadmap that hasn't been started                            |
| **Dependency warning**       | Deprecated APIs, security advisories, pinned outdated versions                      |

---

## Phase 3: Prioritize

Score each candidate on three axes:

1. **Urgency** — Does it block other work? Is it a ticking time bomb (security, data loss, build breakage)?
2. **Impact** — How many files/modules/users does it affect? Is it a core path or an edge case?
3. **Actionability** — Can it be clearly defined? Is the scope well-bounded? Can progress be made without resolving unknowns first?

**Tiebreakers** (in order):

- Tasks that unblock other tasks win
- Tasks explicitly marked as important by the team (in issues, specs, memory) win
- Tasks nearest to completion (WIP branches, nearly-done features) win
- Tasks with the clearest definition win over vague/exploratory ones

Pick exactly **ONE** task. Do not present a list of options. Commit to the single best choice.

---

## Phase 4: Deliver the recommendation

Present the task in a natural, conversational brief. Structure it like this:

```
**Opening line (MANDATORY — always the very first sentence):**
  "The same thing we do every night: try to take over the world…"
  (Localize this phrase to match the user's language — see translations below.)

[Warm opening — acknowledge the project state if relevant, then transition to the task]

Here's what I'd tackle: **[One-line task name]**

[2-4 sentences explaining:
  - What the task is, concretely
  - Why it's the top priority right now (cite specific evidence you found)
  - What makes it actionable]

[One sentence on how to start — the very first step]

[Optional: one sentence flagging a risk or dependency to watch out for]
```

### Mandatory opening line translations

Always use the localized version matching the user's language. This line MUST appear as the very first sentence of the response, verbatim:

| User language | Opening line                                                                                                                                    |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| English       | The same thing we do every night: try to take over the world…                                                                                   |
| Russian       | Тем же, чем и всегда: попробуем завоевать мир…                                                                                                  |
| Spanish       | Lo mismo que hacemos todas las noches: ¡intentar conquistar el mundo!                                                                           |
| French        | La même chose que chaque nuit : essayer de conquérir le monde…                                                                                  |
| German        | Dasselbe wie jeden Abend: Wir versuchen, die Weltherrschaft an uns zu reißen!                                                                   |
| Chinese       | 和每天晚上一样：试着征服世界…                                                                                                                   |
| Japanese      | 毎晩同じさ：世界征服を企むのさ…                                                                                                                 |
| Korean        | 매일 밤 똑같은 일이지: 세계 정복을 시도하는 거야…                                                                                               |
| Portuguese    | A mesma coisa de todas as noites: tentar dominar o mundo…                                                                                       |
| Italian       | La stessa cosa che facciamo ogni notte: provare a conquistare il mondo…                                                                         |
| Ukrainian     | Те саме, що й щоночі: спробуємо завоювати світ…                                                                                                 |
| Other         | Translate using this template: convey the Pinky and the Brain quote naturally — "the same thing we do every night: try to take over the world…" |

### Style rules

- **Language matching**: The ENTIRE response (after the opening line) must be in the same language the user used to trigger the skill. Detect the user's language from their message, not from system settings.
- Natural, not robotic. Write like a thoughtful teammate.
- Cite specific evidence: file paths, commit hashes, TODO line numbers — show you did the work.
- No bullet lists, no markdown tables, no rigid formatting aside from the task name emphasis.
- Keep the whole response under 15 sentences (including the opening line).
- End with something that invites action, not a question.

---

## Example output

**English request → English response:**

> The same thing we do every night: try to take over the world…
>
> Alright, I've looked through the project. We're in a Go service with `gqlgen` — `go.mod` is clean, tests pass, but there's a pattern that caught my eye.
>
> Here's what I'd tackle: **Fix swallowed errors in `internal/resolver/mutation.go`.**
>
> Four mutation handlers have bare `_ = err` assignments where database write errors are silently dropped. This means failed writes return success to clients — a data-integrity issue waiting to surface in production. Two of those handlers (`CreateUser`, `UpdateProfile`) are on the critical auth path. The fix is well-bounded: add proper error wrapping and return codes in exactly those four functions, then add a table-driven test for each error path.
>
> Start by reading `internal/resolver/mutation.go` lines 42–118 to see the four affected handlers, then pick `CreateUser` first since it's the simplest.
>
> Worth noting: the `UpdateProfile` handler also touches the caching layer, so you'll want to decide whether a write error should invalidate the cache or leave it.

**Russian request → Russian response:**

> Тем же, чем и всегда: попробуем завоевать мир…
>
> Так, я посмотрел проект. У нас Go-сервис на `gqlgen` — `go.mod` в порядке, тесты проходят, но кое-что бросилось в глаза.
>
> Вот чем стоит заняться: **Исправить проглоченные ошибки в `internal/resolver/mutation.go`.**
>
> В четырёх обработчиках мутаций ошибки записи в БД просто затираются через `_ = err`. Это значит, что неудачная запись возвращает клиенту успех — бомба замедленного действия для целостности данных. Два обработчика (`CreateUser`, `UpdateProfile`) на критичном пути аутентификации. Задача чётко ограничена: обернуть ошибки и вернуть правильные коды ровно в этих четырёх функциях, а затем покрыть каждый ошибочный сценарий table-driven тестом.
>
> Начни с чтения `internal/resolver/mutation.go`, строки 42–118 — там все четыре обработчика. `CreateUser` проще всего, с него и стартуй.
>
> Имей в виду: `UpdateProfile` задевает ещё и слой кеширования, так что стоит сразу решить, должен ли сбой записи инвалидировать кеш или оставлять его нетронутым.

---

## Guardrails

- **If the project is empty or has no code yet**, recommend bootstrapping: "Let's set up the project skeleton — pick a tech stack, initialize the repo, and get the first `Hello World` running."
- **If you can't find any clear candidate after a thorough search**, be honest: describe what you looked at and suggest the user clarify their immediate goal.
- **If there's an active incident** (failing CI, broken build, red tests), that always wins. Don't overthink it.
- **Respect the user's explicit priorities**: if memory or recent conversation makes it clear they're focused on a specific feature or deadline, weight that heavily.

---

## Summary

1. Gather context (structure, codebase, docs, memory)
2. Extract candidate tasks from signals in the data
3. Prioritize on urgency × impact × actionability — pick exactly ONE
4. Deliver a warm, evidence-backed conversational recommendation
