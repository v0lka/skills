# Skill Authoring Checklist

Run this checklist **in full against every generated skill, every time**,
during the Validate Phase. A skill is deliverable only when every item
passes. Fix failures and re-run the checklist from the top; do not
hand-wave any item. If a machine-readable validator (`skills-ref
validate`) is available in the environment, run it first and resolve its
findings before the manual pass.

## A. Specification compliance (mechanical)

- [ ] `SKILL.md` exists at the skill root and contains YAML frontmatter
      between `---` delimiters followed by Markdown body.
- [ ] YAML parses without errors (watch for unquoted values containing
      colons — quote them or use a `>` block scalar).
- [ ] `name` present; only `a-z`, `0-9`, `-`; no leading/trailing `-`; no
      `--` anywhere; ≤ 64 characters.
- [ ] `name` matches the parent directory name exactly.
- [ ] `description` present, non-empty, ≤ 1024 characters (count after
      YAML folding, not the source line count).
- [ ] Optional fields used are valid: `license` (short),
      `compatibility` (≤ 500 chars), `metadata` (string → string map).
      `allowed-tools` avoided unless the user explicitly requires it
      (experimental).
- [ ] All file references inside the skill are **relative** paths from the
      skill root, one level deep; no absolute paths; no `~/` paths.
- [ ] No secrets, tokens, credentials, or environment-specific values
      embedded in any file.
- [ ] Every referenced file exists; no dangling links to planned-but-
      unwritten resources.
- [ ] Directory contains only what the design called for (`references/`,
      `scripts/`, `assets/`); no human-ops files (`CHANGELOG`,
      installation guides) unless the user asked for them.

## B. Routing quality (the description is the router)

- [ ] Description states **what** the skill does **and** **when** to use
      it, in the third person.
- [ ] Description contains concrete keywords a user's request would
      actually contain (not domain jargon alone).
- [ ] Description has at least one negative trigger ("Do not use for …").
- [ ] Router test: reading only `name` + `description`, a fresh agent
      would activate this skill for the user's original request.
- [ ] Near-miss test: reading only `name` + `description`, a fresh agent
      would **not** activate it for plausible near-miss requests (same
      keywords, different need).

## C. Scope and body quality

- [ ] One skill = one coherent capability. If the description contains
      "and" joining two independent actions, it was split or the split was
      proposed to the user.
- [ ] Body is under 500 lines and reads as under ~5,000 tokens.
- [ ] Body encodes a **procedure** (numbered phases, explicit decision
      points), not a declaration of facts.
- [ ] Nothing re-teaches what a competent agent already knows (file
      formats, protocol basics, generic coding advice).
- [ ] Specifics come from the user's real context (their conventions,
      their failure cases, their worked examples) — no invented
      "generic expertise".
- [ ] Prescriptive exact-steps are used only for fragile/deterministic
      sequences; flexible steps grant intent-level freedom and say **why**.
- [ ] Defaults exist where the body offers choices; alternatives appear
      only as escape hatches, not menus.
- [ ] Gotchas — environment-specific traps and corrections — live in the
      body itself, not hidden in a reference file.
- [ ] If the skill produces output, the expected output format is spelled
      out explicitly.
- [ ] `references/` files are each small, single-topic, and linked at
      their point of use with a load condition ("Read X when Y").
- [ ] `scripts/` (if any) are tiny single-purpose tools with clear
      errors on stdout/stderr; no long-lived library code.
- [ ] Destructive or irreversible operations described in the skill are
      gated behind an explicit confirmation or plan-validate-execute step.
- [ ] No time-sensitive facts (dates, versions, prices, "current" state)
      baked in as permanent instructions.

## D. Portability (agent- and language-agnostic)

- [ ] No instructions that call a specific agent product's tools/APIs by
      name (e.g. a proprietary question-asking or file-editing tool) —
      capabilities are described, not wired to one product.
- [ ] No assumed programming language, package manager, or runtime unless
      the user confirmed it; any code that *is* included was justified by
      the user's context during the Clarify Phase.
- [ ] Instructions work for an agent whose only guaranteed abilities are
      reading/writing files in the skill directory and following the text.

## E. Traceability

- [ ] Every unanswered Clarify-Phase question has its chosen default
      recorded in the skill (so maintainers see the assumption).
- [ ] The user's original request is satisfiable by the generated skill:
      re-read it and confirm nothing requested was silently dropped.

## Scoring

- All items pass → deliver, and report the assumptions taken.
- Any item fails → fix, then re-run **the whole checklist**; partial
  re-runs miss regressions introduced by the fix.
