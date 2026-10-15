# Compact research state

Use this layout as a checklist, not a requirement for a particular memory API. Write research content in the user's language or the expicitly requested one. Stable field names and IDs may remain English.

## Storage selection

1. Prefer a documented memory or checkpoint facility that can store and retrieve this investigation's state across iterations. Namespace the entry with a unique session identifier; do not mix investigations or reuse a prior session's completion decision.
2. If no suitable mechanism is available, keep a single Markdown state file in the host's normal scratch/project workspace, for example `work/fordec-research/<session-id>/state.md`. Record its exact path and tell the user where it is. Use a unique directory to avoid overwriting another investigation. Do not write runtime state inside the installed skill.
3. If memory fails, checkpoint to the file and record the storage change. If neither memory nor file writing is possible, provide a compact state snapshot in chat, disclose the persistence limitation, and ask how the user wants to preserve it. Do not claim durable memory.

Store only necessary research data, with pointers to bulky artifacts. Use the memory mechanism within its normal access scope. Do not extract conversation history from private application storage or search unrelated sessions. Do not make a full prior-art library or research graph by default.

## Suggested record

```markdown
# FORDEC research state

- Session ID:
- Primary question:
- Useful answer criteria:
- User language:
- Available data and tools:
- User-supplied constraints (if any):
- Storage reference:
- Iteration: 1
- Iteration question:
- Stage: F
- Status: awaiting-input
- Last confirmed stage inputs:
- Pending question or continuation choice:
- Last explicit user continuation/completion decision:

## Fact board
| ID | Category | Claim or gap | Evidence and conditions | Remaining uncertainty |
| --- | --- | --- | --- | --- |

## Options
| ID | Explanation or approach | Discriminating prediction | Status | Evidence for revision |
| --- | --- | --- | --- | --- |

## R assessment
| Option / test | Impact | Uncertainty | Testability | Cost | Decision value | Rationale |
| --- | --- | --- | --- | --- | --- | --- |

## Frozen experiment contract
Question; option IDs; inputs and versions; procedure; baseline and controls;
measurements; predicted outcomes; support / contradiction / inconclusive
criteria; validity checks; decision implications; contract revision.

## Execution evidence
Actual steps and conditions; raw artifact pointers; results; deviations;
errors; whether reproduced, user-reported, simulated, or estimated.

## Check and iteration history
One compact entry per iteration: question, experiment contract revision,
key result and evidence pointer, knowledge delta, option changes,
remaining uncertainty, user continuation decision.
```

Use `awaiting-input`, `executing`, `awaiting-continuation`, `paused`, or `completed` to distinguish research progress from tool activity. On restoration, verify the session ID and primary question, recover the pending gate, and continue from that point. Do not rerun completed experiments merely because the conversation was compacted. If interrupted during execution, inspect saved evidence before considering a retry; incomplete records do not prove a run finished.

A stored recommendation to finish is not a user completion decision. Preserve the latest fact board and the short history of evidence-based revisions; do not erase a rejected hypothesis or silently replace predeclared criteria after results are known.
