---
name: prompts-review
description: >-
  Review all prompts in a codebase for optimality, balancing effectiveness and
  token efficiency. Covers explicit prompt files, string-literal prompts, and
  dynamically constructed prompts in code. Use when the user asks to review,
  audit, or optimize prompts, system messages, LLM instructions, or agent
  prompts.
---

# Prompt Review

Conduct a structured review of every prompt in the codebase: system prompts,
summarization instructions, tool descriptions, dynamic injections, and any
string literal that will be sent to an LLM as instruction or context.

## When NOT to Use This Skill

- The prompt is already producing correct, reliable output and no specific
  issue has been reported.
- The prompt is small (<50 tokens) — micro-optimizations risk breaking
  behavior.
- The prompt uses model-specific patterns (XML tags for Claude, markdown for
  GPT-4) that don't match generic advice in the checklist.
- The user hasn't asked for a review — don't proactively optimize prompts
  that work.

## Discovery Phase

Locate ALL prompts before reviewing. Prompts appear in several forms:

1. **Dedicated prompt files** — `.txt`, `.md`, `.jinja2`, `.hbs`, `.mustache`,
   or constants modules (e.g. `prompts.py`, `prompts.ts`, `prompts.go`,
   `system_prompt.txt`).
2. **String-literal prompts** — variables/constants named `*PROMPT*`,
   `*INSTRUCTION*`, `SYSTEM_*`, or strings passed to LLM calls
   (`"role": "system"` in any language).
3. **Dynamically constructed prompts** — string interpolation (Python
   f-strings, JS template literals, Go `fmt.Sprintf`, Ruby `#{}`, etc.),
   `.format()`, template rendering, or concatenation that assembles messages
   at runtime.
4. **Tool/function descriptions** — `description` fields in OpenAI
   function-calling schemas, tool definitions, or similar structured metadata.
5. **Inline context injections** — ephemeral system messages injected per-call
   (dates, user metadata, progress state).

**Discovery strategy**: First determine which languages and frameworks the
project uses, then apply appropriate search patterns. Examples:

```
# constants / variable names (all languages)
grep -rn "PROMPT\|INSTRUCTION\|SYSTEM_"
# LLM message construction
grep -rn '"role".*"system"\|role.*system'
# string interpolation (adapt to project language)
#   Python: f"...", "...".format(
#   JS/TS:  `...${...}`
#   Go:     fmt.Sprintf(
#   Ruby:   "...#{...}"
# tool schemas
grep -rn '"description"' --include="*.json" --include="*.yaml" --include="*.yml"
```

## Review Process

### Pre-Evaluation Gate

For each discovered prompt, first ask:
- Is this prompt currently producing correct, reliable output?
- If yes, apply the "Don't Touch" gate from the checklist before evaluating.
- Only proceed to full evaluation if there's evidence of a problem OR the user
  specifically requested optimization.

### Evaluation

For prompts that pass the gate, evaluate against the checklist in
[checklist.md](checklist.md). Produce findings in this format:

### Per-Prompt Report

```
#### <Prompt Name / Location>
- **File:** path:line
- **Type:** system | summarization | tool-description | dynamic-injection | context
- **Token estimate:** ~N tokens
- **Issues found:**
  1. [Issue category]: description + suggested fix
  2. ...
- **Suggested revision:** (only if changes are non-trivial)
```

### Summary Report

After all prompts are reviewed, produce:

```
## Prompt Review Summary

| # | Prompt | File:Line | Tokens | Issues | Severity |
|---|--------|-----------|--------|--------|----------|
| 1 | ...    | ...       | ~N     | N      | high/med/low |

### Top Recommendations (ranked by token savings x impact)
1. ...

### Estimated Total Savings
- Current total: ~N tokens
- After fixes: ~N tokens
- Savings: ~N tokens (~X%)
```

## Severity Levels

- **High** — prompt actively harms output quality, causes misbehavior, or
  wastes >30% of its tokens on redundancy.
- **Medium** — prompt works but has clear optimization opportunities (10-30%
  token savings possible, or clarity improvements).
- **Low** — minor style or structure improvements; functional as-is.

## Key Principles

When evaluating, prioritize output quality over token savings. The LLM is
very capable, but context *activates* its knowledge — don't strip reminders
that direct attention to the right domain. Every token competes for context
window space, but a wrong answer costs more than a few extra tokens. When in
doubt, preserve the prompt.
