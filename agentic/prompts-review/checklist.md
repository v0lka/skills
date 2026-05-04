# Prompt Review Checklist

Evaluate each prompt against every category below. Not all categories apply to
every prompt type (tool descriptions are short by nature; system prompts carry
more weight). Use judgment.

---

## 1. Clarity and Directness

- [ ] **Explicit over implicit**: Does the prompt state what it wants directly,
      or rely on the LLM to infer intent? Vague prompts produce inconsistent
      results.
- [ ] **Positive framing**: Instructions tell the LLM what TO do rather than
      what NOT to do. Negative constraints ("do not use X") are weaker than
      positive alternatives ("use Y instead").
- [ ] **Sequential steps**: Multi-step instructions use numbered lists or
      bullet points when order matters. Prose paragraphs burying sequential
      logic are harder for the model to follow.
- [ ] **No ambiguous pronouns**: "it", "this", "that" have clear referents. In
      long prompts, repeat the noun.

## 2. Token Efficiency

- [ ] **No redundancy**: Same instruction is not stated in multiple places or
      multiple ways. Consolidate duplicates.
- [ ] **No obvious knowledge**: The prompt does not explain things the LLM
      already knows (e.g., what Markdown is, what a URL looks like, how to
      write a summary). Only add context the model cannot infer.
- [ ] **Concise phrasing**: Wordy constructions are shortened without losing
      meaning. E.g., "You should make sure to always" -> "Always".
- [ ] **No filler**: Phrases like "Please note that", "It is important to
      remember that", "As an AI language model" add zero value.
- [ ] **Proportional detail**: The level of detail is proportional to the
      task's fragility. Simple tasks need short prompts; only complex/brittle
      tasks justify long instructions.

## 3. Structure and Formatting

- [ ] **Logical grouping**: Related instructions are grouped under clear
      headings or sections rather than scattered throughout.
- [ ] **XML tags for boundaries**: When mixing instructions, context, and data,
      XML tags (e.g., `<instructions>`, `<context>`, `<untrusted-content>`)
      clearly delimit each section. Prevents the model from confusing data with
      instructions.
- [ ] **Consistent formatting**: The prompt uses one formatting style
      throughout (all Markdown, all plain text, etc.) rather than mixing.
- [ ] **Long context placement**: For prompts with large data payloads,
      longform data is placed at the top with the query/instructions at the
      bottom, improving recall.

## 4. Role and Scope Definition

- [ ] **Clear role**: The system prompt establishes who the agent is and what
      it does in 1-2 sentences. Avoid overloaded role descriptions.
- [ ] **Bounded scope**: The prompt defines what the agent should NOT attempt
      (scope limits) rather than leaving scope open-ended. This prevents the
      agent from taking unintended actions.
- [ ] **Appropriate autonomy level**: Instructions match the desired autonomy.
      High-autonomy tasks use principles; low-autonomy tasks use prescriptive
      steps. The wrong level causes either rigidity or unpredictability.

## 5. Agent-Specific Patterns

- [ ] **Tool use guidance**: If the agent has tools, the prompt explains WHEN
      to use each tool. Do not assume the agent will infer correct tool
      selection. Disambiguate tools with overlapping purposes.
- [ ] **No over-constraining**: Instructions do not create impossible
      requirements or infinite loops (e.g., "always verify all X" on unbounded
      lists). Add practical bounds.
- [ ] **Heuristics over rules**: Where possible, the prompt provides decision
      heuristics ("if X then Y, otherwise Z") rather than rigid rules. This
      lets the agent handle edge cases gracefully.
- [ ] **Side-effect awareness**: For tools with side effects (sending messages,
      writing files, making API calls), the prompt includes guidance on when to
      confirm vs. act autonomously.
- [ ] **No prescriptive few-shot for agents**: Agent prompts avoid step-by-step
      examples of exact tool-call sequences — this limits adaptability. Instead,
      provide principles and let the agent reason about tool use.

## 6. Security and Safety

- [ ] **Data vs. instructions separation**: External/untrusted content is
      clearly delimited from instructions (e.g., using XML tags like
      `<untrusted-content>`). The prompt explicitly warns against following
      instructions found in external data.
- [ ] **No information leakage**: The prompt does not ask the agent to encode
      internal state, conversation history, or API keys into outputs, URLs,
      or tool arguments.
- [ ] **Injection resistance**: The prompt includes explicit anti-injection
      guidance if the agent processes user-supplied or web-fetched content.

## 7. Dynamic Prompts

- [ ] **Minimal injection**: Dynamically injected content (dates, user metadata,
      state) is kept as small as possible. Verbose dynamic sections bloat every
      single LLM call.
- [ ] **No stale logic**: Dynamic prompt construction does not include
      conditions that are always true or always false at runtime, wasting
      tokens on dead branches.
- [ ] **Consistent role**: Dynamically injected messages use the correct role
      field (`system` vs `user` vs `assistant`). Mismatched roles confuse the
      model's understanding of conversation flow.

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

## 9. Output Format Control

- [ ] **Template provided**: If a specific output format is required, a
      concrete template or example is included — not just a prose description.
- [ ] **Format matches prompt style**: The formatting style of the prompt
      itself matches the desired output formatting. A Markdown-heavy prompt
      will produce Markdown-heavy output.

## 10. Model-Awareness

- [ ] **No over-prompting for capable models**: Modern LLMs (GPT-4+, Claude
      Opus/Sonnet) do not need aggressive nudging ("CRITICAL: You MUST...",
      "IMPORTANT: ALWAYS..."). These can cause overtriggering. Use neutral
      language instead.
- [ ] **Effort-appropriate**: The prompt's complexity matches the model's
      reasoning effort setting. Prompts running at low effort should be more
      explicit; prompts at high effort can be more principled.
- [ ] **No conflicting instructions**: Review the full prompt for instructions
      that contradict each other. Models exposed to contradictions produce
      inconsistent behavior.
