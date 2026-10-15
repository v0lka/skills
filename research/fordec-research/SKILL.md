---
name: fordec-research
description: Conduct rapid engineering R&D with iterative FORDEC cycles, competing hypotheses, and minimum viable experiments. Use for bounded engineering questions about mechanisms, failures, performance, or architecture when the user wants an interactive research process with input clarification at every stage and user-controlled completion.
license: MIT
metadata:
  author: Vladimir Kochetkov
  version: "1.0.0"
---

# FORDEC Research

Reduce uncertainty through the cheapest experiment that can distinguish plausible explanations or engineering approaches. Follow **Facts → Options → Risks & Benefits → Decision → Execution → Check**.

## Session contract

- **One session = one primary question = one research investigation.** A session normally means one conversation. Keep the primary question stable across iterations. Each iteration addresses one subordinate question serving it, with one next experiment (which may contain controlled conditions or replicates).
- If the user introduces a different primary question, explain the scope change and ask them to start a separate session. Do not silently replace or combine investigations. A clarified wording of the same question is acceptable; record it.
- All skill instructions are English. Communicate with the user and write generated research notes in the language of their initiating research prompt, unless they request a change. Preserve technical identifiers, code syntax, and FORDEC labels as useful. For an ambiguous mixed-language prompt, ask their preference at the initial gate.
- **Every stage requires user input before execution.** Ask a focused question or present already-known inputs for confirmation; wait for an actual reply. No timeout, silence, previous generic permission, or agent-generated confirmation satisfies this stage gate.
- After each stage, report its intermediate result and immediately ask for the next stage's inputs in the same response. Do not add a separate approval gate for the finished stage.
- The agent selects the experiment at D after clarification. It may update, reject, or revive hypotheses with evidence and explanation. It may recommend completion, but **only the user may end the investigation**.
- At C, wait for the user's choice to finish, iterate, or pause. Goal achievement, exhausted options, missing data, or a failed experiment do not authorize autonomous completion. Do not automatically start another iteration.
- Do not require time, spending, resource, or iteration budgets. Ask initially for available data. The user is responsible for managing constraints and may supply them voluntarily; carry those inputs forward. Cost remains an R assessment criterion, not an imposed budget gate. Host permissions and tool authorization still apply.

## State and control flow

Read [references/state.md](references/state.md) when creating or restoring research state. Use an available, documented agent-memory mechanism capable of preserving session-scoped state across iterations. Otherwise use the compact file described there. Do not install a memory system or inspect application databases to obtain one.

Persist the primary question, current iteration and stage, available data, confirmed inputs, fact board, options, experiment contract, results, and pending question. Checkpoint before waiting, after each stage, and when paused or interrupted. Keep evidence pointers and enough history to explain revisions, without building a full research catalog or hypothesis tree.

For each stage:

1. Set `stage` and `status: awaiting-input`; state the iteration question and summarize relevant carried-forward inputs.
2. Ask only stage-relevant clarifications, using the prompts below. If nothing is missing, ask the user to confirm the input summary. Wait.
3. Incorporate the reply. If an essential input remains ambiguous, ask a focused follow-up and keep the gate open. An explicit “use your judgment” is sufficient for proposed assumptions; record them as assumptions, not facts.
4. Mark the confirmed gate, set `status: executing`, and perform the stage with available tools.
5. Save and report the result, its evidence and material uncertainty. Open the next stage's input gate immediately. At C, open the continuation decision instead.

Typical sequence: F question → reply → F result + O question → reply → O result + R question → reply → R result + D question → reply → D result + E question → reply → E result + C question → reply → C result + continuation choice.

Do not perform substantive work for the next stage before its reply. Restoring state and preparing a question do not count as stage execution. User corrections that invalidate completed work return to the earliest affected stage and reopen its gate; do not silently use stale outputs.

## F — Facts

**Purpose:** establish what is actually known and unknown, just enough to form testable options.

**Clarify:** the primary question on the first iteration; the subordinate question on later iterations; available code, versions, logs, datasets, measurements, publications, or user observations. Confirm what has changed since the previous C. Define a useful answer to the primary question without turning it into automatic permission to finish.

**Execute:** inspect the supplied data and use available research tools for a bounded evidence search. Stop gathering when there is enough evidence to formulate testable alternatives, rather than surveying the entire field.

Maintain four categories with stable fact IDs:

| Category | Meaning                                                             | Required distinction                                                                     |
| -------- | ------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Known    | Directly verified information or measurements within a stated scope | Cite the inspected artifact, reproduction, or authoritative evidence and its conditions. |
| Observed | A reported or observed behavior whose explanation is unresolved     | Preserve provenance; mark user reports as reported unless independently reproduced.      |
| Assumed  | An unverified premise, interpretation, or proposed explanation      | State what could test or invalidate it.                                                  |
| Unknown  | A relevant gap that must be resolved                                | State how an answer could affect the decision.                                           |

A verified measurement may be Known while its unexplained pattern remains Observed; separate these claims. Another author's causal assertion is not automatically a verified mechanism in this system. A user preference is a requirement, not empirical evidence. Never invent measurements, citations, or verification.

**Report:** the compact fact board, evidence scope, remaining uncertainty, and the iteration question. Ask O inputs next.

## O — Options

**Purpose:** identify competing explanations, architectures, or mechanisms.

**Clarify:** plausible alternatives the user wants considered and any supplied exclusions or corrections to F. If no additions are needed, ask them to confirm the fact board as the basis for option generation.

**Execute:** formulate at least two genuine competing options. Give each a stable ID, supporting and contradicting evidence, and a discriminating prediction. Architectural options should have a common evaluation condition; causal hypotheses should predict observable differences.

Include combined explanations when justified; do not force hypotheses to be mutually exclusive. Do not fabricate a token competitor to protect a preferred answer. If only one plausible option exists, identify the missing distinction and ask for more evidence or a legitimate baseline before proceeding to R.

**Report:** a short option table and the observable differences a test should distinguish. Ask R inputs next.

## R — Risks & Benefits

**Purpose:** identify which information most strongly affects the next decision.

**Clarify:** what engineering decision the answer must inform, relevant tradeoffs, and any corrections to the proposed comparisons. Do not demand budget limits.

**Execute:** assess each option and its cheapest discriminating test using the five source parameters:

| Parameter      | Question                                                                     |
| -------------- | ---------------------------------------------------------------------------- |
| Impact         | How important would it be if this hypothesis or approach were valid?         |
| Uncertainty    | How little do we know about it?                                              |
| Testability    | How easily can we check it with available data and tools?                    |
| Cost           | What would the experiment cost in effort, time, compute, or other resources? |
| Decision value | Would its answer change the subsequent decision?                             |

Use concise qualitative judgments with reasons, or concrete estimates when supported. Do not invent numerical probabilities, weights, or a scoring formula. Consider implementation consequences and the risk of remaining uncertain. Prefer information that changes the decision over the most interesting or impactful topic alone. An expensive test may be justified by high decision value, but propose the smallest informative form.

**Report:** the five-parameter comparison, material risks and benefits, and a ranked test recommendation with its reasoning. Ask D inputs next.

## D — Decision

**Purpose:** choose one next experiment, not solve the whole engineering problem.

**Clarify:** available experimental data and environment, acceptable proxies, meaningful outcome thresholds, and any user-supplied constraints affecting the recommendation. Present reasonable defaults for confirmation when already inferable.

**Execute:** independently select the minimum viable experiment with the strongest expected decision value. Freeze a compact experiment contract before E:

- One subordinate question and the options being distinguished.
- Procedure, inputs, versions, controlled variables, baseline, and tested conditions.
- Measurements and enough replicates or uncertainty handling for the decision at hand.
- Predicted outcomes per option and predeclared criteria for support, contradiction, and inconclusive evidence.
- Validity checks, confounders, and conditions making a run unusable.
- How each relevant outcome would change the next engineering decision.

Choose quantitative thresholds only when meaningful; qualitative criteria are acceptable for deterministic code inspection or architectural evidence. Avoid post-hoc reinterpretation and false certainty. If available tools cannot run the preferred test, choose a valid smaller proxy or ask for missing data rather than promising an inaccessible execution.

**Report:** the selected contract and why this experiment distinguishes the alternatives. Ask E inputs next; selection does not require a separate user vote.

## E — Execution

**Purpose:** conduct the minimum viable experiment and observe reality.

**Clarify:** confirm the run inputs, artifact locations, and readiness of the environment; ask for missing data or required action authorization. Installation, paid API use, external writes, and delegation must follow the host's capabilities and existing permissions. This skill grants no blanket permission for them.

**Execute:** run the agreed contract automatically using available tools. Disposable, incomplete, minimally abstracted code is acceptable when it reliably answers the question. Add only the validation needed to trust the measurement; do not turn the experiment into a production implementation or unrelated refactoring.

Record actual commands or equivalent steps, relevant versions and settings, raw result pointers, errors, and departures from the contract. Distinguish reproduced evidence, user-provided results, simulations, and estimates. Never describe a proposed test as executed.

If E clarification changes the question, procedure, or interpretation criteria materially, return to D and freeze a revised contract before running. If an execution fails or tools/data are unavailable, report that fact and ask for an input or feasible alternative; remain awaiting input. A failure can become a result for C only when it supplies interpretable evidence. Do not silently retry with different criteria.

**Report:** what ran, the actual measurements or observations, validity limitations, and artifacts. Ask C inputs next, including any outside observations or corrections needed for interpretation.

## C — Check

**Purpose:** determine how knowledge changed, rather than merely whether the run succeeded.

**Clarify:** user observations, corrections, and whether the recorded conditions and results are accurate enough to interpret. Even when all data is present, require confirmation of the interpretation inputs before performing C.

**Execute:** compare outcomes with the frozen criteria; distinguish support, contradiction, and inconclusive evidence. Update Known / Observed / Assumed / Unknown and option statuses. Explain eliminated or revived hypotheses with evidence and scope; retain their history so they can be reconsidered. Add newly discovered mechanisms or dependencies without automatically expanding the primary question.

Assess how the new knowledge informs the primary question. State residual uncertainty, whether a useful answer is available, and the most valuable candidate question for another iteration. A valid experiment may still be inconclusive; a failed run may reveal knowledge, but does not establish its intended hypothesis.

**Report:** the knowledge delta, option updates, decision implications, and remaining uncertainty. Set `status: awaiting-continuation` and checkpoint the pending choice. Give a recommendation, then ask the user to choose:

- **Finish:** produce a concise answer to the primary question, evidence, limits, and relevant artifacts. Set `status: completed` only after an explicit user decision to finish.
- **Iterate:** increment the iteration number and open F's input gate around one proposed subordinate question. A continuation reply can also satisfy F's gate only if the preceding message explicitly presented F's inputs for confirmation and the reply confirmed them; otherwise ask the F question and wait.
- **Pause:** checkpoint with `status: paused`, preserving the pending decision or stage. Resumption restores this same investigation and reopens any unconfirmed input gate.

A vague acknowledgment is not a finish or continuation decision. Ask which action they intend. The user may explicitly stop at any earlier stage; preserve partial findings, record user-directed completion, and state that a full iteration was not performed.
