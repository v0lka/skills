# Fix prompts-review Skill: Stop Ruining Prompts

## Context

Testing showed that the `prompts-review` skill systematically makes prompts worse instead of better. Root cause analysis identified 6 structural problems:

1. **Self-contradictory checklist items** — "Explicit over implicit" (1.1) clashes with "No obvious knowledge" (2.3); "Positive framing" (1.2) clashes with necessary negative constraints; "No over-prompting" (10.1) clashes with need for safety emphasis.
2. **"No obvious knowledge" (2.3) is actively harmful** — models need context to *activate* knowledge, not just *know* it. Stripping domain reminders degrades output.
3. **No "leave it alone" guidance** — 40+ checklist items with a "find problems" framing guarantees false positives and unnecessary changes.
4. **Over-optimization for token count** — the implicit goal becomes "fewer tokens" not "better output."
5. **Bad advice for real-world LLM behavior** — "No filler" strips politeness cues that affect RLHF-trained models; "No CRITICAL/IMPORTANT" removes necessary emphasis.
6. **Conflating prompt engineering across models** — checklist treats all LLMs interchangeably.

## Approach

Revise both `SKILL.md` and `checklist.md` with these principles:
- **Effectiveness-first**: output quality beats token savings. Only cut when quality is preserved.
- **Resolve contradictions**: establish clear priority rules between conflicting items.
- **Add "don't touch" gate**: first assess if the prompt already works well.
- **Fix "no obvious knowledge"**: replace with "no genuinely redundant context" — distinguish activation from teaching.
- **Reduce checklist scope**: merge redundant categories, drop harmful items, add severity/category guidance.
- **Model-awareness**: acknowledge that different models need different approaches.

## Changes to `checklist.md`

### Structural changes
- Reorder categories by priority: Safety → Correctness → Clarity → Structure → Efficiency
- Each category gets a "When NOT to apply" note
- Drop category 10 (Model-Awareness) as a separate section — integrate model-notes inline where relevant
- Merge category 6 (Security) into a higher-priority "Guardrails" section at the top
- Reduce from 10 categories to 7

### Item-level changes

**Category: Guardrails (new, merged from old #6 + safety-relevant parts)**
- Keep: data vs instructions separation, injection resistance
- Drop: "No information leakage" → move to Security-specific skill territory, too contextual
- Add: "Don't strip safety constraints" — negative constraints that prevent harm are ALWAYS acceptable regardless of token cost

**Category: Correctness (new)**
- Add: "No conflicting instructions" (moved from old 10.3, now top-priority)
- Add: "Instructions are testable" — can you verify the model follows them?
- Drop: old 1.4 "No ambiguous pronouns" → too nitpicky, models handle pronouns fine

**Category: Clarity (merged old #1)**
- Keep: "Explicit over implicit" — but add NOTE: explicitness is about *what to do*, not about *explaining concepts the model knows*
- Keep: "Sequential steps" — but add: "only when order matters"
- Soften: "Positive framing" → change to "Prefer positive framing, BUT negative constraints are valid for safety and precision. 'Do not output passwords' is correct."
- Drop: old 1.4 "No ambiguous pronouns" → moved to "don't apply unless ambiguity is real"

**Category: Structure (old #3, trimmed)**
- Keep: "Logical grouping"
- Keep: "Consistent formatting"
- Drop: "XML tags for boundaries" → Claude-specific, moved to model-notes
- Drop: "Long context placement" → model-specific, not universally correct

**Category: Token Efficiency (old #2, heavily revised)**
- ADD NEW FIRST ITEM: "Effectiveness beats efficiency. Before optimizing tokens, verify the prompt produces correct output. Only cut tokens that don't reduce quality."
- Soften: "No redundancy" → "No UNINTENTIONAL redundancy. Deliberate repetition of critical constraints improves reliability."
- REPLACE: "No obvious knowledge" → "No UNNECESSARY teaching. If the context *activates* relevant model knowledge (e.g., 'prefer explicit error handling in Go'), keep it. Only remove explanations that genuinely add nothing (e.g., explaining what JSON stands for)."
- Keep: "Concise phrasing"
- Keep: "No filler" → but add: "EXCEPT politeness markers that affect tone of model output. 'Please' and 'thank you' can improve RLHF-trained model compliance."
- Keep: "Proportional detail"

**Category: Agent-Specific (old #5, trimmed)**
- Keep: "Tool use guidance"
- Keep: "Heuristics over rules"
- Keep: "Side-effect awareness"
- Drop: "No prescriptive few-shot for agents" → depends on model, not universal
- Drop: "No over-constraining" → too vague, rarely applies

**Category: Output Format (old #9, kept as-is but de-prioritized)**

**Category: Dynamic Prompts (old #7, kept as-is)**

**Category: Tool Descriptions (old #8, kept as-is)**

### New: "Don't Touch" Gate (added at TOP of checklist, before any evaluation)

```
## Gate: Is This Prompt Already Effective?

Before evaluating a prompt, answer:

1. Does the prompt reliably produce correct output? [yes/no]
2. Would the proposed change risk breaking expected behavior? [yes/no]
3. Is the issue severity "medium" or higher? [yes/no]

If (1=yes AND 2=yes) OR (3=no): **Skip. Don't change it.**
Only proceed with changes when the prompt has a clear problem affecting output quality.
```

## Changes to `SKILL.md`

### Review Process section

**Current problem**: The process says "For each discovered prompt, evaluate against the checklist" — no filtering, no judgment.

**Fix**: Add before the evaluation step:

```
### Pre-Evaluation Gate

For each discovered prompt, first ask:
- Is this prompt currently producing correct, reliable output?
- If yes, apply the "Don't Touch" gate from the checklist before evaluating.
- Only proceed to full evaluation if there's evidence of a problem OR the user 
  specifically requested optimization.
```

### Key Principles section

**Current:**
> "When evaluating, remember: the LLM is already very capable. Only instruct what it cannot infer. Every token competes for context window space."

**Replace with:**
> "When evaluating, prioritize output quality over token savings. The LLM is very capable, but context *activates* its knowledge — don't strip reminders that direct attention to the right domain. Every token competes for context window space, but a wrong answer costs more than a few extra tokens. When in doubt, preserve the prompt."

### Add a "When This Skill Should NOT Be Used" section

```
## When NOT to Use This Skill

- The prompt is already producing correct, reliable output and no specific issue has been reported
- The prompt is small (<50 tokens) — micro-optimizations risk breaking behavior
- The prompt uses model-specific patterns (XML tags for Claude, markdown for GPT-4) that don't match generic advice in the checklist
- The user hasn't asked for a review — don't proactively optimize prompts that work
```

## Verification

1. Read the revised `checklist.md` and verify:
   - No contradictory items remain
   - "Don't Touch" gate is first
   - "Effectiveness-first" principle is embedded in Token Efficiency section
   - "No obvious knowledge" is replaced with the safer version
   - Safety constraints are protected from over-optimization

2. Read the revised `SKILL.md` and verify:
   - Pre-evaluation gate is present before the review process
   - Key Principles section prioritizes quality over tokens
   - "When NOT to use" section exists

3. Mental test: run the revised skill against a known-good prompt and verify the "Don't Touch" gate would prevent unnecessary changes.
