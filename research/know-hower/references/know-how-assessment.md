# Know-How Assessment Guide

Load when building evidence dossiers or assessing candidates (workflow steps 4
and 6). Use this guide with the inventory and coverage ledger in
[the skill](../SKILL.md). Public-source work follows
[public verification](public-verification.md); report and exclusion decisions
follow [the report and `.aiignore` guide](aiignore-guidance.md).

## 1. Define the idea before judging it

A candidate is a problem-solving idea, learned constraint, empirical recipe,
or useful combination, not necessarily a function or a file. Describe:

- **Problem:** the technical or domain decision being made, including constraints.
- **Mechanism:** how inputs, rules, transformations, parameters, and feedback
  produce an outcome; distinguish intended behavior from observed execution.
- **Boundary:** where the idea starts and ends, dependencies it needs, and
  conditions under which it may fail or cease to apply.
- **Contribution:** public/inherited technique versus adaptation, calibration,
  accumulated experience, domain content, or system-level combination.
- **Counterclaim:** what evidence would show that the apparent contribution is
  conventional, unused, ineffective, third-party, or misinterpreted.

Use stable `KH-…` IDs. Merge duplicate expressions of the same idea, retaining
anchors for each manifestation. Split candidates when mechanisms, evidence,
or disclosure consequences genuinely differ. Record rejected and deferred
candidates with reasons; do not silently remove inconvenient evidence.

## 2. Discover technical, domain, and distributed knowledge

Use the whole-project inventory, not a fixed keyword list, as the discovery
boundary. These lenses are prompts, not assertions that each project contains
valuable know-how:

| Lens | Candidate material | Questions that test significance |
| --- | --- | --- |
| Algorithms and systems | Scheduling, caching, indexing, consistency, recovery, resource policies, protocol adaptations | Which constraint drove this choice? Which boundary cases does it handle beyond a standard method? |
| Domain models and decisions | Taxonomies, eligibility rules, exception hierarchies, scoring, matching, pricing constraints, optimization objectives | Which expert distinctions or exceptions change decisions? Are they standards, customer requirements, or learned adaptations? |
| Data and empirical practice | Acquisition, cleaning, labeling, features, curated corpora, thresholds, calibration, evaluations | What was selected or rejected, why, and with what evidence? Is the value in the method, data, tuning, or their interaction? |
| Integration and operations | Compatibility workarounds, migrations, failure handling, playbooks, capacity decisions | What non-obvious external behavior or failure mode is encoded? Is the workaround still required? |
| Negative knowledge | Failed approaches, abandoned experiments, warnings, incident-derived rules | What costly mistake can this knowledge prevent? Is the reason recorded or merely guessed? |
| Combinations | Ordinary components joined by contracts, ordering, feedback, or shared assumptions | What emerges from the combination that no component explains alone? |

Do not restrict attention to source code. Tests, fixtures, configuration,
documents, notebooks, schemas, data descriptions, generated artifacts, and
accessible history can carry the same insight. Credentials and personal data
are outside this classification; report incidental concerns separately in
redacted terms, without copying or scoring them as know-how.

### Trace a distributed idea

Start from an observable decision or output, then follow verified relationships:

```text
input/schema → transformation → decision rule → consumer/output
                     ↑               ↑               ↓
                curated data     configuration    evaluation
                     ↖──── documents / tests / feedback ────↙
```

For each link record the producer, consumer, shared contract, evidence anchor,
and inspection status. A matching filename or term is a lead, not proof of
interaction. Trace callers, imports, configuration loading, data provenance,
and test setup far enough to establish the relationship. Distinguish an active
path from dead code or an example when evidence permits; otherwise mark it
unknown. Note inaccessible services, generated copies, and suspected alternate
expressions as gaps rather than verified locations.

A hypothetical domain-scoring pipeline might combine conventional aggregation,
a project-specific exception table, and calibrated thresholds. Treat the
pipeline as one candidate if the interaction is the insight, while separately
assessing which layers are public and which remain unverified. This example
is not evidence about the audited project and supplies no exclusion paths.

## 3. Construct a falsifiable evidence dossier

For every material candidate maintain:

| Dossier field | Required content |
| --- | --- |
| Identity and scope | KH ID, problem, idea boundary, inspected revision/date |
| Evidence map | Verified implementation, callers/consumers, tests, docs, data/configuration, provenance, and their relationships |
| Claims | One consequential claim per row, label, source anchor, and reasoning where needed |
| Challenges | Counterexamples, contradictory sources, conventional alternatives, unused/deprecated paths |
| Limits | Missing access, sampling, unexecuted checks, assumptions, reproducibility and portability limits |
| Public comparison | Direct publication, analogues, incremental differences, and search-ledger IDs |
| Assessments | Separate dimensions, evidence, rationale, and confidence for each |
| Disposition | Material / deferred / rejected, attention rationale, next check, and any later EX rule links |

Cite repository-relative paths and real line ranges, document sections, notebook
cells, or versioned dataset/schema identifiers. Read anchors before citing
them. Prefer precise pointers to copied code, complete recipes, exact private
parameters, or raw data. The dossier itself may concentrate sensitive knowledge.

### Keep evidence and conjecture separate

- **Observed:** directly supported by an inspected artifact or retrieved source.
  State what was actually observed: a branch exists, a fixture contains a case,
  or a document makes a claim. Do not inflate this into runtime effectiveness.
- **Inferred:** an interpretation supported by cited observations. Explain the
  reasoning and plausible alternatives; for example, two verified consumers
  appear to share a calibration assumption.
- **Hypothesis:** a plausible but unverified proposition. State a concrete
  validation path, such as obtaining an evaluation report or comparing outcomes
  on an appropriate dataset. Do not silently promote it to a finding of fact.
- **Unknown / conflicting:** evidence is unavailable or incompatible. Show the
  disagreement and its impact; do not fabricate a reconciliation.

A comment can establish stated intent, not actual behavior. Reading a test
shows the checked case and assertions, not a passing run. A benchmark script
shows an evaluation design, not measured speed. A historical result may apply
to another revision or workload. A document's business claim is a source claim,
not an independently established benefit. Record execution only if it actually
occurred and was within scope; builds, scripts, tests, and experiments are not
mandatory for this audit.

Seek disconfirming evidence deliberately: alternate implementations, fallback
paths, ignored parameters, dependency defaults, copied upstream code, failing
cases, contradictory documentation, and evaluation leakage. Absence of such
material in a sample does not establish its absence from the project.

## 4. Assess independent dimensions

Do not calculate a single secret, novelty, or protection score. Assign each
assessment its own rationale and confidence; confidence is not a fifth score
to average with the other four.

| Dimension | Vocabulary | Evidence and reasoning required |
| --- | --- | --- |
| Public availability | Directly public / partly public / analogues only / not found within stated search / unknown | Identify the exact layer: idea, implementation, adaptation, combination, configuration, or data recipe. Link retrieved public evidence or bounded negative-search results. |
| Technical or domain originality | Conventional / project-specific adaptation / potentially distinctive combination or contribution / unresolved | Compare mechanisms, assumptions, domain distinctions, and incremental differences. Cosmetic names and complexity do not establish originality. |
| Potential value | Low / medium / high / unknown, relative to stated context | Explain utility, effort saved, replication cost, accumulated learning, scarcity, or possible advantage. Separate measured outcomes from plausible benefits; do not invent a market. |
| Disclosure consequences | Low / medium / high / unknown, for an explicit scenario | Explain what a recipient could learn or reconstruct, the incremental exposure beyond public material, dependencies, remaining barriers, and context lost if excluded. |
| Confidence | Low / medium / high for each dimension above | Explain source quality, coverage, correspondence, contradictions, and gaps. Strong implementation evidence does not imply strong commercial or public-search evidence. |

Use **high confidence** only where relevant evidence is direct, sufficiently
scoped, and consistent; **medium** where meaningful evidence supports the
assessment but important assumptions remain; **low** where evidence is sparse,
indirect, sampled, or conflicting. An **unknown** assessment can be the correct
result even when implementation details are well understood. Explain the
basis rather than treating these labels as calibrated probabilities.

### Availability is not originality, value, or impact

- A public algorithm may have conventional originality but valuable private
  calibration. Evaluate the calibration separately from the published method.
- A domain heuristic may encode costly expert learning even when its code is
  short. Value still needs context; it is not established by expert terminology.
- An unusual mechanism can have unproven utility or high maintenance cost.
- A distributed combination may be reconstructable from several ordinary
  artifacts even when no file describes the complete recipe.
- A public description may make the principle available while leaving practical
  implementation or empirical tuning undisclosed. Conversely, direct public
  code may reduce incremental disclosure without making all related data public.

When the disclosure audience is unspecified, present labeled analytical
scenarios (for example, a recipient with only public material versus one with
related project artifacts). Do not assert that either is the user's intended
recipient. Consequences concern what becomes learnable under that scenario,
not a legal determination of trade-secret status, ownership, or patentability.

## 5. Decide attention and hand off without overclaiming

Explain priority in words: the suspected consequence, plausible utility,
evidence strength, and urgency of unresolved checks. Do not make uncertainty
an automatic reason for broad exclusions or conventionality an automatic reason
to dismiss a candidate. A material finding may reasonably be retained as useful
context, deferred pending evidence, or linked to a narrow proposed exclusion.

Before handing dossiers to [report synthesis](aiignore-guidance.md), check:

- Every claim is anchored or labeled, and contradictions remain visible.
- The candidate map covers technical and domain material, including distributed
  relationships; inspected, sampled, and inaccessible areas are distinguished.
- Public methods and project-specific contributions are separated, with
  [public verification](public-verification.md) status and limitations recorded.
- Availability, originality, value, and disclosure consequences each have their
  own rationale and confidence; no aggregate secret score or legal verdict.
- Hypotheses have concrete next checks; rejected/deferred candidates have reasons.
- Any exclusion recommendation is a handoff to the advisory rule ledger, not an
  instruction to modify the project or a guarantee of concealment.
