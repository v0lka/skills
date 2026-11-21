# Agent Skills Specification — Digest

Normative requirements distilled from the official specification
(<https://agentskills.io/specification>), version as published November
2025. Load this file during the Design Phase and again during the Validate
Phase. When this digest and the live specification disagree, the live
specification wins.

## Format

A skill is a **directory** containing at minimum a `SKILL.md` file.
`SKILL.md` must contain YAML frontmatter between `---` delimiters,
followed by Markdown instructions. The body has no format restrictions.
The base directory (parent of `SKILL.md`) is the anchor for all relative
paths used inside the skill.

## Frontmatter fields

| Field           | Required | Constraints |
| --------------- | -------- | ----------- |
| `name`          | Yes      | Max 64 chars. Only `a-z`, `0-9`, `-`. Must not start or end with `-`; must not contain `--`. **Must match the parent directory name exactly.** |
| `description`   | Yes      | 1–1024 chars, non-empty. Must describe **what the skill does and when to use it**; should include keywords agents can match against tasks. |
| `license`       | No       | License name or reference to a bundled license file. Keep short. |
| `compatibility` | No       | Max 500 chars if present. Environment requirements (product, packages, network). Most skills do not need it. |
| `metadata`      | No       | Map of string keys to string values. Prefer reasonably unique key names. |
| `allowed-tools` | No       | Space-separated pre-approved tool list. **Experimental** — support varies between implementations; do not rely on it. |

### Description rules in practice

- Plain scalars that contain `:` are a common YAML breakage — use quotes
  or a block scalar (`>` / `>-`).
- Unparseable YAML makes loaders **skip the skill silently**: no error is
  shown, the skill simply never appears.
- A missing or empty description also causes loaders to skip the skill
  (the description is essential for disclosure).

## Directory conventions

```
skill-name/
├── SKILL.md      # Required: frontmatter + instructions
├── references/   # Optional: documentation loaded on demand
├── scripts/      # Optional: executable code
├── assets/       # Optional: templates, static resources
└── ...
```

- All file references inside the skill use **relative paths from the skill
  root** and stay **one level deep** from `SKILL.md`.
- The specification does not mandate where skill directories live — only
  what goes inside one. Common locations are project `.agents/skills/` and
  user `~/.agents/skills/`; project-level skills override user-level ones
  on name collision.

## Progressive disclosure (three tiers)

1. **Metadata** — `name` + `description` only (~100 tokens per skill),
   loaded for every skill at session start. This is the catalog agents
   route with.
2. **Instructions** — the full `SKILL.md` body, loaded on activation.
   Keep it **under 500 lines**; the working recommendation is under 5,000
   tokens.
3. **Resources** — `references/`, `scripts/`, `assets/` files, read
   individually only when the instructions point to them at the moment of
   need. Keep each resource file small and focused.

## Validation

- The reference validator is `skills-ref`
  (<https://github.com/agentskills/agentskills> → `skills-ref`, Python,
  Apache-2.0, explicitly a demo tool): `skills-ref validate ./my-skill`
  checks frontmatter validity and naming conventions; `read-properties`
  emits them as JSON.
- Clients are specified to load **leniently**: name/directory mismatch or
  an over-long name produces a warning and the skill still loads; missing
  description or broken YAML skips the skill entirely.
- The minimum client-side record for a skill is `name`, `description`,
  and the absolute location of its `SKILL.md`.

## What the specification deliberately does not cover

- The content quality of instructions (authoring concern — see the
  authoring checklist).
- Any particular agent product, tool API, or runtime: a compliant skill
  makes **no assumptions** about which agent loads it or which
  programming languages its host can execute.
