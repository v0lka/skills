# Prompt Rewrite Playbook

Read this file in Improvement Mode — when the user supplied a prompt and
asked for an improved rewrite, or picked findings from a review report and
asked to fix them. The default review pass never uses this playbook: it
reports prioritized findings with fix options only. Each transformation
below targets specific checklist categories; apply only the ones addressing
actual findings — a rewrite that touches nothing flagged shouldn't happen.

## Hard Rules (apply to every rewrite)

1. **Safety constraints survive verbatim.** Never shorten, soften, or drop
   negative safety constraints to save tokens (Category 1).
2. **Keep deliberate repetition.** Critical constraints repeated on purpose
   stay repeated.
3. **Keep activating context.** If a detail directs the model's attention to
   the right domain of its knowledge, it earns its tokens even when it looks
   like teaching.
4. **Preserve the target model's conventions.** XML-tag formatting, markdown
   structure, role fields, tool-schema shapes — do not "generalize" them
   away.
5. **Ask, don't invent.** If a correct rewrite needs missing information,
   output explicit questions and record any default you would have assumed —
   never silently guess.
6. **No drive-by changes.** Transform only what the evaluation flagged;
   re-check the result against those categories before delivering.

## Transformations

### 1. Add verifiability
Fixes: no verification method or success criteria (Category 3).

```
Before: "implement a function that validates email addresses"
After:  "write a validateEmail function. test cases: user@example.com is
         true, invalid is false, user@.com is false. run the tests after
         implementing"
```

### 2. Add specific context
Fixes: insufficient context (Category 3).

```
Before: "fix the login bug"
After:  "users report that login fails after session timeout. check the
         auth flow in src/auth/, especially token refresh. write a failing
         test that reproduces the issue, then fix it"
```

### 3. Reference existing patterns
Fixes: the agent invents a style inconsistent with the codebase (Category 3).

```
Before: "add a calendar widget"
After:  "look at how existing widgets are implemented on the home page to
         understand the patterns. HotDogWidget.php is a good example.
         follow the pattern to implement a new calendar widget with month
         selection and pagination"
```

### 4. Cut context bloat
Fixes: irrelevant detail carried along "just in case" (Category 6).

```
Before: "here is a long unrelated history ... fix the dropdown"
After:  "fix the dropdown in src/ui/Dropdown.tsx. issue: keyboard navigation
         skips items. keep the prompt focused; omit unrelated history"
```

### 5. Include rich inputs
Fixes: missing logs, error messages, references (Category 3).

```
Before: "build fails"
After:  "build fails with this error: [paste error]. run the smallest
         relevant test command. if needed, read the build script and
         package config"
```

### 6. Make exploration/planning explicit
Fixes: no planning cue on a complex or ambiguous task (Category 3).

```
Before: "refactor auth to support OAuth"
After:  "first explore src/auth and summarize current flow, then propose a
         plan. after approval, implement with tests"
```

### 7. Root-cause the symptom
Fixes: symptom-only description (Category 2).

```
Before: "search is broken"
After:  "users report search returns empty results for queries with hyphens.
         reproduce in src/search/. paste the error log if any. write a
         failing test for 'foo-bar' returning results, fix the root cause,
         run: pnpm test --filter search"
```

### 8. State the deliverable
Fixes: ambiguous deliverable — plan vs. implement vs. analyze (Category 7).

```
Before: "clean up the auth code"
After:  "inspect src/auth and list duplication hotspots. propose a refactor
         plan scoped to one module. after approval, remove duplication
         without changing behavior. add a targeted test if coverage is
         missing. run the smallest relevant test command"
```

## Task-Type Calibration

What a well-formed prompt includes, by task type:

| Task type  | A good prompt for it includes                                                     |
|------------|------------------------------------------------------------------------------------|
| Bugfix     | symptom + repro, root-cause instruction, failing test, targeted test command      |
| Feature/UI | spec or screenshot, reference patterns, verification (compare renders / lint)     |
| Refactor   | scope bound to one module, behavior-preservation requirement, plan-then-implement |
| Research   | question, evidence requirements (logs, timings), hypotheses, "do not implement yet" |
| Ops        | failure log, target script/config, fix + rollback plan, dry-run when available    |
| Docs       | target files, source of truth (existing scripts), "confirm commands exist"        |

Worked examples:

```
UI/visual
Before: "make the dashboard look better"
After:  "implement the attached screenshot for the dashboard header in
         src/ui/DashboardHeader.tsx. match spacing and typography. take a
         new screenshot and list any differences. run: pnpm lint"
```

```
Research
Before: "why is this API slow?"
After:  "explore request flow around src/api/. summarize likely bottlenecks
         with evidence (logs, timings). propose 2-3 hypotheses and what data
         is needed to confirm. do not implement yet. if needed, ask for
         access to profiling output"
```

```
Ops
Before: "deployment failed"
After:  "deploy fails with error: [paste log]. identify the failing step in
         scripts/deploy.sh and related CI config. suggest a fix and a
         rollback plan. run: ./scripts/deploy.sh --dry-run (if available)"
```

```
Docs
Before: "update the README"
After:  "update README.md to include install + dev steps based on existing
         scripts. keep it concise. confirm commands exist and match actual
         scripts"
```

## Fill-In Templates

When the improved prompt benefits from a reusable structure, use one of
these instead of prose. Keep only the sections that apply; when a section
is filled with a question instead of an answer, surface that question
alongside the rewrite.

Full form:

```
[Task]
- Goal:
- Target files/paths (@path references over prose descriptions, where the
  target agent supports them):
- Constraints (runtime/version/deps/security/compat):
- Context (symptom, logs, repro, links):

[Verification]
- Commands:
- Expected results:
- UI checks (screenshots/visual diffs):

[Exploration/Planning]
- Do exploration/planning first? (Yes/No) + reason:

[Execution Preference]
- Implement now / plan only / analyze only
- Output format (concise report, patch summary, checklist, etc.)
```

Shortest effective form:

```
Goal: ...
Targets: path1/path2
Context: symptom + repro + logs
Constraints: runtime/deps/compat
Verify: command + expected result
Explore/Plan: yes/no (why)
Execute: implement / plan only / analyze only
Output: concise format
```

## Parallel and Delegated Investigation

When the improved prompt covers several independent investigations, or an
independent review pass is valuable (research, code review), the prompt may
ask the executing agent to run them independently or in parallel and merge
the results. Phrase it as an outcome ("investigate independently and
summarize separately"), never as instructions tied to a specific tool or
product.
