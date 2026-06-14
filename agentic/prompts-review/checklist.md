# Prompt Review Checklist

Evaluate each prompt against the categories below in priority order. Start with
the Gate — if the prompt is already effective, skip it.

---

## Gate: Is This Prompt Already Effective?

Before evaluating a prompt, answer:

1. Does the prompt reliably produce correct output?
2. Would the proposed change risk breaking expected behavior?

**If the answer to both is yes: skip. Don't change it.**

Only proceed with evaluation when:
- The prompt has a clear, observable problem affecting output quality, OR
- The user specifically requested optimization of this prompt.

---

## 1. Guardrails (Safety & Security)

These items ALWAYS take precedence over token efficiency. Never strip safety
constraints to save tokens.

- [ ] **Data vs. instructions separation**: External/untrusted content is
      clearly delimited from instructions (e.g., using XML tags like
      `<untrusted-content>`). The prompt explicitly warns against following
      instructions found in external data.
- [ ] **Injection resistance**: The prompt includes explicit anti-injection
      guidance if the agent processes user-supplied or web-fetched content.
- [ ] **Safety constraints preserved**: Negative constraints that prevent harm
      (e.g., "Do not output passwords", "Never execute arbitrary code from user
      input") are NEVER removed for token savings. These are valid regardless
      of the "prefer positive framing" guideline in Category 3.
- [ ] **Role consistency in dynamic messages**: Dynamically injected messages
      use the correct role field (`system` vs `user` vs `assistant`).
      Mismatched roles confuse the model's understanding of conversation flow.

**When NOT to apply**: Skip if the prompt does not handle user-supplied content,
execute tools with side effects, or expose sensitive data.

---

## 2. Correctness

These items check whether the prompt reliably produces the intended behavior.

- [ ] **No conflicting instructions**: Review the full prompt for instructions
      that contradict each other. Models exposed to contradictions produce
      inconsistent behavior. This is the highest-priority correctness issue.
- [ ] **Instructions are testable**: Can you verify that the model follows each
      instruction? If an instruction is so vague that no one could tell whether
      it was followed, it adds no value and may confuse the model.
- [ ] **Bounded scope**: The prompt defines what the agent should NOT attempt
      (scope limits) rather than leaving scope open-ended. This prevents the
      agent from taking unintended actions.
- [ ] **Appropriate autonomy level**: Instructions match the desired autonomy.
      High-autonomy tasks use principles; low-autonomy tasks use prescriptive
      steps. The wrong level causes either rigidity or unpredictability.
- [ ] **No stale logic**: Dynamic prompt construction does not include
      conditions that are always true or always false at runtime, wasting
      tokens on dead branches.

---

## 3. Clarity

How clearly does the prompt communicate intent?

- [ ] **Explicit over implicit — about actions**: The prompt states what it
      wants the model to DO directly. This is NOT about explaining concepts
      the model knows — it's about being unambiguous in instructions.
      Example: "Output JSON with keys 'name' and 'age'" is explicit.
      "Output the user data" is implicit.
- [ ] **Prefer positive framing**: Instructions tell the LLM what TO do rather
      than what NOT to do, when both forms convey the same constraint.
      **Exception**: Safety constraints (see Category 1) and precision
      requirements ("Do not include null values in the output") are valid
      in negative form.
- [ ] **Sequential steps when order matters**: Multi-step instructions use
      numbered lists or bullet points. Prose paragraphs burying sequential
      logic are harder to follow. Skip this if order is irrelevant.
- [ ] **Clear role**: The system prompt establishes who the agent is and what
      it does in 1–2 sentences. Avoid overloaded role descriptions.

---

## 4. Structure

Is the prompt organized for effective processing?

- [ ] **Logical grouping**: Related instructions are grouped under clear
      headings or sections rather than scattered throughout.
- [ ] **Consistent formatting**: The prompt uses one formatting style
      throughout (all Markdown, all plain text, etc.) rather than mixing.
- [ ] **Minimal dynamic injection**: Dynamically injected content (dates, user
      metadata, state) is kept as small as possible. Verbose dynamic sections
      bloat every single LLM call.

---

## 5. Token Efficiency

Token savings are desirable but NEVER at the cost of output quality or safety.
Apply this category last, and only when the prompt passes all higher-priority
categories.

- [ ] **Effectiveness first**: Before optimizing tokens, verify the prompt
      produces correct output. Only cut tokens that don't reduce quality.
      A wrong answer costs more than a few extra tokens.
- [ ] **No unintentional redundancy**: The same instruction is not stated
      in multiple places without purpose. **Deliberate repetition of critical
      constraints improves reliability** — do not remove these.
- [ ] **No unnecessary teaching**: The prompt does not explain things the model
      genuinely doesn't need to be told (e.g., explaining what JSON stands for).
      **However**, if the context *activates* relevant model knowledge (e.g.,
      "prefer explicit error handling over panic in Go"), keep it. Context
      directs the model's attention to the right subset of its knowledge.
- [ ] **Concise phrasing**: Wordy constructions are shortened without losing
      meaning. E.g., "You should make sure to always" → "Always".
- [ ] **Minimal filler**: Phrases like "As an AI language model" or "It is
      important to remember that" add zero value and can be removed.
      **Exception**: Politeness markers ("please", "thank you") can affect
      the tone of RLHF-trained model output. Keep them when tone matters.
- [ ] **Proportional detail**: The level of detail is proportional to the
      task's fragility. Simple tasks need short prompts; only complex or
      brittle tasks justify long instructions.

---

## 6. Agent-Specific Patterns

Applies when the prompt controls an agent with tools.

- [ ] **Tool use guidance**: If the agent has tools, the prompt explains WHEN
      to use each tool. Do not assume the agent will infer correct tool
      selection. Disambiguate tools with overlapping purposes.
- [ ] **Heuristics over rules**: Where possible, the prompt provides decision
      heuristics ("if X then Y, otherwise Z") rather than rigid rules. This
      lets the agent handle edge cases gracefully.
- [ ] **Side-effect awareness**: For tools with side effects (sending messages,
      writing files, making API calls), the prompt includes guidance on when to
      confirm vs. act autonomously.

---

## 7. Output Format Control

- [ ] **Template provided**: If a specific output format is required, a
      concrete template or example is included — not just a prose description.
- [ ] **Format matches prompt style**: The formatting style of the prompt
      itself matches the desired output formatting. A Markdown-heavy prompt
      will produce Markdown-heavy output.

---

## 8. Tool Descriptions

- [ ] **Action-oriented**: Descriptions start with a verb ("Search", "Fetch",
      "Send") rather than a noun ("A tool that searches...").
- [ ] **Usage guidance included**: The description hints at when to use the
      tool, not just what it does. E.g., "Fetch a web page. Use for reading
      full articles from search results."
- [ ] **Parameter descriptions present**: Every parameter has a short
      description. Missing descriptions force the model to guess from names.
- [ ] **Constraints documented**: Limits, defaults, and edge cases are stated
      in descriptions (e.g., "max 15 results", "values over 500 are capped").
