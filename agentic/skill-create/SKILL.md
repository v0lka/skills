---
name: skill-create
description: >-
  Create a new Agent Skill — a spec-compliant SKILL.md plus optional
  references, scripts, and assets — from a user-provided description of the
  capability, asking targeted clarifying questions whenever the description
  is underspecified, and validating the generated skill against the Agent
  Skills specification before delivery. Use when the user asks to create,
  write, generate, scaffold, or author a new skill, agent skill, SKILL.md,
  or reusable capability package for an AI agent. Do not use for reviewing,
  improving, or fixing an existing skill, or for one-off prompts that will
  not become a reusable package.
---

# Skill Creation

Turn a plain-language description of a capability into a working Agent Skill
directory: a spec-compliant `SKILL.md`, optional supporting files, and a
validation pass that must succeed before delivery.

A skill is a directory whose behavior is defined entirely by its files —
the agent that loads it is unknown at authoring time. Everything this skill
produces must therefore be **agent-agnostic** (describe *what* to do, never
which tool APIs to call) and **programming-language-agnostic** (choose
languages only from the user's stated context, never by default).

## When NOT to Use This Skill

- The user wants to *improve* an existing skill — review and edit it in
  place instead of generating a new one.
- The user wants a prompt template, system prompt, or one-off instruction
  sheet that will live inside a single conversation. Skills are reusable
  file-based capabilities; ephemeral text does not need one.
- The capability is trivial and the agent already handles it reliably with
  no instruction — a skill would add context cost for no behavioral change.

## Intake Phase

Collect from the user, in their words, the raw description of the
capability. Do not restructure or editorialize it yet. Establish only:

1. **What the agent should do** — the observable outcome, not the
   implementation.
2. **Rough scope** — is this one coherent capability, or several? (If the
   description contains "and" between two independent actions, flag it:
   it is probably two skills.)
3. **Where it should live** — target directory or repository for the skill.
   If the user names a conventions-following repository, existing sibling
   skills define the layout, frontmatter style, and README pattern; read
   one before generating.

## Clarify Phase

Ask targeted clarifying questions **before generating anything** whenever
the description is underspecified. This phase is mandatory: do not guess
and do not fill gaps with assumptions. Use whatever question-and-answer
mechanism your environment provides, batch questions into one round, and
offer a sensible default with each question so the user can confirm fast.

Ask when the answer is not already stated — never interrogate the user
about things the description already settles. Typical gaps, in priority
order:

| # | Gap to resolve | Why it matters |
|---|----------------|----------------|
| 1 | **Trigger situations** — in which situations should the skill activate? Ask for phrases a user would actually say. | The frontmatter description is the routing contract; without triggers the skill never activates. |
| 2 | **Anti-triggers** — when should the skill *not* be used, even if keywords match? | Prevents the skill from hijacking near-miss tasks. |
| 3 | **Capability boundary** — one skill or two? If several independent actions were described, propose splitting. | Mega-skills dilute routing and bloat activation context. |
| 4 | **Ground truth** — does real expertise exist to encode (runbooks, past incidents, project conventions, worked examples)? A skill synthesized from generic knowledge produces generic procedures. | Generic skills re-teach what the agent already knows. |
| 5 | **Environment needs** — must it run commands, access a network, or depend on installed packages? Any destructive operations involved? | Determines whether `compatibility`, `scripts/`, and confirmation gates are needed. |
| 6 | **Deliverable format** — if the skill produces output, what does a good result look like? | Unspecified output format gets improvised by the agent at runtime. |

If the user cannot answer a question, record the chosen default in the
generated skill so the next maintainer can see the assumption.

## Design Phase

Decide the structure before writing files. Apply progressive disclosure:
metadata routes, the body instructs, resources carry detail.

1. **Name** — lowercase letters, digits, and hyphens; no leading, trailing,
   or repeated hyphens; 64 characters or fewer; must equal the directory
   name. Derive it from the capability (`code-review`, `pdf-forms`), not
   from the trigger phrase.
2. **Frontmatter** — always `name` + `description`. Add optional fields
   (`license`, `compatibility`, `metadata`) only when a concrete need
   exists; see [the specification digest](references/spec-digest.md).
3. **Body budget** — plan for under 500 lines and under 5,000 tokens.
   Anything longer or only occasionally needed moves to `references/`
   (loaded on demand), fixed artifacts to `assets/`, deterministic fragile
   logic to `scripts/` (tiny single-purpose tools, not libraries).
4. **File references** — relative paths from the skill root, one level
   deep. Never absolute paths, never secrets, never reference chains that
   force loading a second file to understand the first.
5. **Specificity calibration** — prescribe exact steps only for fragile or
   deterministic sequences; give intent-level freedom (with the *reason*)
   where the agent should adapt.

## Generate Phase

Write the files using [the templates](references/templates.md). The body is
written for the *runtime* agent in imperative voice; it encodes a
procedure, real specifics, and gotchas — not definitions of things the
agent already knows.

1. **`SKILL.md` frontmatter** — write the description first and proofread
   it carefully: it must state what the skill does **and** when to use it,
   in the third person, with concrete trigger keywords and at least one
   negative trigger ("Do not use for …"). Keep it well under the
   1,024-character limit; quote or block-scalar it if it contains colons.
2. **`SKILL.md` body** — title, one-paragraph purpose, when/when-not
   section, then the procedure as numbered phases with explicit decision
   points ("if X, do Y; otherwise skip to phase N"). Put the highest-value
   corrections — the gotchas — in the body itself, not in a reference
   file, because the runtime agent may fail to open the file when the trap
   springs.
3. **Supporting files** — only what the design called for. Link each
   `references/` file at its point of use with a load condition: "Read
   `references/foo.md` when the input is a multi-file change." Keep every
   reference file small and single-topic.
4. **Language discipline** — instructions and examples in the user's
   working language; command or code snippets only in languages the user's
   context justifies. No agent-specific tool names, no API calls to a
   particular product, no assumptions about installed runtimes unless the
   user confirmed them in the Clarify Phase.

## Validate Phase

Run [the authoring checklist](references/authoring-checklist.md) against
the generated skill **in full, every time**. This phase is mandatory: a
skill is not delivered until every checklist item passes.

1. Walk the spec-compliance items mechanically (naming rules, frontmatter
   limits, YAML validity, relative paths, directory/name match).
2. Walk the quality items critically (routing strength, single capability,
   body budget, no re-teaching, no invented specifics).
3. For every failed item, fix the files and re-run the checklist from the
   top. Iterate until zero failures.
4. If the description was changed during fixing, re-check its length and
   re-read it as the router: would a fresh agent, seeing only name and
   description, activate it for the user's original request — and *not*
   activate it for near-miss requests?

Report to the user: the created file tree, the validation result, the
assumptions taken where questions went unanswered, and one suggested
real-task trial to confirm the skill triggers and performs.

## Key Principles

- **The description is the router.** Agents see only name + description at
  startup; a vague description makes the skill invisible no matter how
  good the body is.
- **One skill, one capability.** Split independent actions into separate
  skills that can reference each other.
- **Ask, don't assume.** An underspecified description is a blocker, not a
  prompt for invention; unanswered questions become recorded defaults.
- **Specifics beat generality.** Ground the body in the real expertise the
  user provided; delete anything a competent agent would do anyway.
- **Invalid YAML silently kills a skill.** Many loaders skip it without an
  error — treat validation as part of generation, not an afterthought.
- **Every sentence must earn its context cost.** Test: would the runtime
  agent get this wrong without the sentence? If not, cut it.
