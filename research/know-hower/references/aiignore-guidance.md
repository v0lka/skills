# Report and Advisory `.aiignore` Guide

Load when synthesizing findings, writing the final report, or preparing the
proposed `.aiignore` (workflow step 7). This guide specifies deliverables, not a
new discovery method or an instruction to modify the analyzed project.

## 1. Delivery and sensitivity

Deliver a Markdown report with a draft `.aiignore` section by default. Create
standalone report/proposal files only when requested; use an agreed destination
and do not replace existing files without consent. Never silently write the
proposal into the analyzed project's active ignore configuration.

Treat the report as **potentially sensitive** even if all public citations are
public. It can consolidate a previously distributed recipe, pinpoint private
implementation, reveal calibration or business assumptions, and explain how to
reconstruct an idea. Exclusion paths and rule comments can also reveal meaning.

- State the intended audience if known; otherwise mark it unspecified. Describe
  sensitivity as an analytical caution, not a verified organizational label.
- Prefer concise mechanism descriptions and evidence links over copied code,
  exact tuning values, raw data, or complete recipes. Use line ranges or stable
  artifact anchors without embedding sensitive payloads.
- Preserve enough reasoning to justify recommendations. If necessary detail is
  omitted, identify the omission and where an authorized reviewer can inspect
  it; do not replace traceability with an unsupported verdict.
- Do not reproduce credentials or personal data. Mention incidental concerns
  separately in redacted terms, outside the know-how findings and scoring.
- Do not auto-publish or upload the report. If the user requests a shareable
  version, minimize/redact private paths, mechanisms, and business inferences;
  state the reduced evidentiary detail. Do not create that version by default.
- A proposed ignore rule does not protect the report, conversation, or material
  already disclosed. Do not impose an execution environment or query-approval
  gateway as a consequence of report sensitivity.

## 2. Report structure

Use all sections below; an empty section should state why it is empty, rather
than disappearing. Keep observation, comparison, assessment, and action separate.

### A. Executive summary

Include the project and revision/date; the audit's actual boundary; counts of
material findings, deferred/rejected candidates, and proposed exclusions;
high-priority ideas and practical implications; and the most important limits.
Explain attention order using separate assessments, not a single secret score.
State whether public verification was completed, partial, or unavailable and
whether coverage was complete, sampled, or partial. Note report sensitivity,
intended audience, and that the `.aiignore` is advisory and has not been applied.
Do not equate the number of rules with the number of findings.

### B. Scope and coverage

Record included/excluded components, accessible revision, inspection date,
available tools and sources, inaccessible dependencies/history/data, sampling,
and whether tests/benchmarks were read or actually executed. Reuse the workflow's
coverage ledger; account for every inventoried area, including areas with no
findings and uninspected areas. Reasons for audit-scope exclusions are not
recommendations to ignore those areas in AI context.

### C. Candidate map

| Finding ID | Idea / problem solved | Contributing components | Disposition and reason | Attention priority and uncertainty | Proposal rule IDs |
| --- | --- | --- | --- | --- | --- |
| KH-… | Concise description | Verified paths / components | Material finding / deferred / rejected | Rationale, not a combined score | EX-… or none |

Keep stable IDs across the report. Consolidate duplicate manifestations of one
idea, preserving their locations. Keep deferred and rejected candidates visible
with reasons; conventionality alone does not establish lack of value or impact.
A material finding need not produce an exclusion recommendation.

### D. Detailed finding card (repeat for each material finding)

#### KH-… — Descriptive title

- **Problem and idea:** what is solved; how the mechanism or domain knowledge
  works; what is inherited versus project-specific adaptation, combination,
  calibration, or empirical knowledge. Explain why it merits attention.
- **Implementation and evidence:** cite verified links such as
  `[module](relative/path.ext#L12-L28)`; use document sections, notebook cells,
  schema/dataset versions, or artifact identifiers where lines do not apply.
  Cite the inspected revision when available. Do not invent line numbers.
- **Distributed manifestations:** map implementation, callers/consumers, tests,
  fixtures, docs, examples, data, configuration, and derived/generated material
  that expresses or helps reconstruct the same idea. Explain relationships,
  not just a list of files. Distinguish verified locations from suspected ones.
- **Evidence versus interpretation:** label observed facts, inferences with
  their reasoning, hypotheses with validation paths, and unknown/conflicting
  evidence. Include contradictions, alternative explanations, and negative
  evidence. Reading an unexecuted test is not an observed runtime result.
- **Public comparison:** identify verified direct publications, close/partial
  analogues, and background techniques separately. Cite retrieved external
  sources and explain precisely what matches and what differs. Link to the
  search log; if no source was verified, state that instead of filling a slot
  with an invented citation.

| Independent dimension | Assessment | Rationale and evidence | Confidence and its limits |
| --- | --- | --- | --- |
| Public availability | Workflow vocabulary | Which idea/implementation/adaptation/data; search boundaries | Low / medium / high, with reason |
| Technical or domain originality | Workflow vocabulary | Incremental contribution versus inherited technique | Low / medium / high, with reason |
| Potential value | Low / medium / high / unknown | Utility, replication cost, effort or possible advantage; missing measurements/business context | Low / medium / high, with reason |
| Disclosure consequences | Low / medium / high / unknown | Explicit recipient/scenario, what becomes reproducible, incremental exposure | Low / medium / high, with reason |

- **Recommendation:** exclude, retain, narrow/redact where separately requested,
  or defer pending evidence; explain the trade-off rather than making public
  availability or originality alone decisive. Link proposed EX-… rule IDs or
  explicitly state why none is recommended. State remaining disclosure paths.
- **Open questions and next check:** what could change this assessment, which
  evidence would resolve it, and what remains unverified.

### E. Public-source comparison and search ledger

For each search record neutral query/concept, date, source/platform, retrieval
status, relevant finding IDs, comparison scope, and unresolved leads. For each
source provide title, URL, author/publisher and publication/version date when
available, access date, evidence type, and the exact supported claim. Cite a
section/page/commit where available. Keep inaccessible sources and snippet-only
leads distinct from sources actually read.

A source's assertion is not an independently verified benefit. Note provenance,
conflicting evidence, technical mismatches, and missing information. Say
“not found in the searched sources as of [date]”, not “unique” or “secret”.
When network verification is absent, preserve the ledger status and uncertainty;
no external citation is required when none could actually be retrieved.

### F. Proposed `.aiignore` and decision ledger

Follow sections 3–5 below. Include intended selectors, a clearly marked draft,
per-rule rationale, evidence and match checks, cost, existing-rule interaction,
and residual exposure. Explain explicitly if the justified draft is empty.

### G. Gaps and next steps

Prioritize missing evidence, contradictions, unverified runtime/value claims,
coverage gaps, and public-verification limits. Give concrete next checks, not
unsupported conclusions. Separate incidental redacted credential/privacy
concerns. State which checks were performed and which were not.

## 3. Derive exclusions from findings, not categories

Build a traceable decision ledger **before** drafting rules. Every proposed
exclusion must have at least one material finding ID and a reason grounded in
its evidence and disclosure scenario. One finding may need several rules;
one rule may serve several findings. Do not add blanket exclusions for all
source, tests, docs, data, or configuration merely because of their file type.

For each idea, inspect alternate expressions: tests and fixtures exposing
expected behavior; documentation and diagrams explaining the algorithm;
examples and notebooks reproducing the method; parameter tables and data
recipes; generated copies, snapshots and archives; or multiple ordinary files
whose combination reconstructs it. Include only verified, justified locations
in the proposed coverage. List suspected/inaccessible copies as unresolved.
A public description may expose a principle while private tuning remains
sensitive; distinguish the two rather than excluding every mention.

Use a ledger like this (one row per proposed rule):

| Rule ID | Finding IDs | Intended paths / selector and verified evidence | Disclosure reduced and rationale | Useful context lost / operational cost | Coverage and collateral matches | Existing-rule interaction / decision |
| --- | --- | --- | --- | --- | --- | --- |
| EX-… | KH-… | Real locations + anchors, separately state draft selector | Which knowledge is less exposed, why exclusion is justified | Affected reasoning/debugging, tests, contracts, examples, maintenance | Intended, unintended, missed and unresolved locations | Addition / already covered / conflict; propose, narrow, retain or defer |

Costs must be specific: e.g., losing fixtures may obscure boundary behavior;
losing a shared schema may impair interpretation of dependent components. If
cost is unknown, say why. Discuss alternatives such as fewer exact paths or
retaining generic interfaces; do not perform redaction/refactoring as part of
the audit. When several findings share a file, explain both the need and the
collateral loss of excluding the entire file. A line-level finding does not
imply that a consumer can exclude only those lines.

For every candidate explicitly record retain/defer/exclude and reasons. Findings
already sufficiently public may still justify exclusion of non-public additions;
findings with uncertain novelty do not automatically justify broad hiding.

## 4. Prepare and validate the advisory draft

1. Inspect any accessible existing `.aiignore`. Distinguish absent, present,
   inaccessible, and not checked. Preserve its content; compare additions,
   overlaps, conflicts, and apparent redundancy. Existing unexplained rules
   belong in a separate legacy inventory, not new findings invented to justify
   them. Do not remove or silently reformat those rules.
2. Default to **tool-neutral intended coverage**. State the project-relative
   base and what each selector is meant to include. Prefer exact files or
   narrowly justified directories; mark wildcard syntax as draft/unverified.
   Separate explanatory rule IDs and rationale from file text rather than
   assuming a consumer supports comments, ordering, negation, or glob syntax.
3. Check every proposed location against the actual inventory and source.
   Report intended matches, collateral matches, missed manifestations, and
   inaccessible areas. A broad pattern requires inspection of what it would
   exclude, not just one example. Path coverage checks are not proof that an
   AI consumer enforces the rules. If no matcher semantics were verified,
   label matches as intended coverage, not successful parser tests.
4. **Adapt to a specific tool only on the user's request.** Then verify the
   tool/version's current primary documentation for supported filename,
   syntax, root/base, precedence, and which ingestion paths are affected.
   Cite sources and distinguish documentation from any actual test. If the
   tool does not support `.aiignore`, or support is unverified, say so; do not
   promise enforcement or silently switch to another configuration file.
5. Present draft file text separately from the ledger. State whether it is an
   addition-only proposal or an explicitly requested combined draft. The
   default is not a replacement. Combined drafts must distinguish unchanged
   legacy rules from new recommendations. Never insert placeholder/example
   paths as if they were actual findings.
6. Label the result: **Advisory draft — not applied; support and enforcement
   depend on the consuming tool.** `.aiignore` is not a universal standard,
   security boundary, access control, deletion mechanism, confidentiality
   guarantee, or reversal of prior disclosure. Other ingestion channels and
   copies may remain outside intended coverage; identify known gaps without
   claiming unverified consumer behavior.

Do not create, merge, or edit active ignore files during this audit. An explicit
request to apply changes is a separate action, not implied by review of findings
or a request for tool adaptation. **Never overwrite an existing `.aiignore`
without explicit consent to that replacement.** If later application is
requested, re-read current content and show the planned delta before seeking
any missing consent. Manual review of this deliverable is not a gate for
network queries and does not prescribe the user's execution environment.

## 5. Empty results and final checks

Distinguish these outcomes:

- No material findings in inspected areas: report coverage, search boundaries,
  and rejected-candidate reasons. Do not claim the entire project has no value.
- Evidence or access insufficient to establish material findings or justify
  exclusions: report an inconclusive/partial audit, not a clean bill of health.
  List deferred candidates and required checks. Partial coverage alone does not
  invalidate independently supported findings or narrowly justified rules.
- Findings exist, but no exclusion is justified: retain dossiers and explain
  why the costs, public exposure, or uncertainty do not support rules.

For all three, provide an **empty proposed addition set** (zero rules), with the
reason outside the draft. Do not invent protective patterns, erase existing
rules, or fill the proposal with placeholders. Existing configuration remains
unchanged. If a file artifact was requested, explicitly describe it as an empty
proposal artifact, not a replacement for the active file.

Before delivery verify:

- Every inventory area has a coverage status and every material finding has
  an evidence-based card with separate assessments and confidence.
- Every consequential claim has an inspected source anchor or uncertainty
  label; external sources are actually retrieved or explicitly unavailable.
- Every proposed EX-… rule maps to KH-… findings, verified locations, a rationale,
  a specific context-loss cost, and coverage/residual-gap checks.
- Alternate materials revealing the same idea are accounted for; suspected
  coverage and tool enforcement are not represented as verified.
- Legacy rules and new recommendations are separated; no active file has been
  modified and no replacement is implied without consent.
- Tool adaptation occurred only if requested; support limits are explicit.
- Zero-rule outcomes are handled honestly, and the report's own sensitivity,
  omitted details, audience, and sharing cautions are visible.
