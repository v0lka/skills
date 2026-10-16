# Know-Hower

A standalone Agent Skill that investigates a project's **technical and domain
know-how** across code, tests, documentation, data, and configuration. It traces
ideas distributed across components, compares them with public sources, and
produces an evidence-based report plus a **proposed `.aiignore` for manual
review**. It does not apply ignore rules or make legal determinations.

## When to use

| Situation | Use this skill |
| --- | --- |
| You want to identify non-obvious engineering decisions, expert rules, empirical recipes, or valuable combinations in a project | Yes |
| You need to distinguish public techniques from project-specific implementation, calibration, or accumulated knowledge | Yes |
| You want a traceable assessment of what disclosure could reveal and which context exclusions may be justified | Yes |
| You only need a code summary, credential scan, or personal-data audit | No |
| You need a legal opinion on trade secrets, ownership, patents, or guaranteed uniqueness | No |

## How it works

1. **Establish scope and access** — identify the project boundary, revision,
   available evidence, exclusions, and missing access without inventing context.
2. **Inventory the whole project** — map components and artifact classes, tracking
   inspected, sampled, metadata-only, excluded, and inaccessible areas.
3. **Discover candidates** — investigate technical mechanisms, domain rules,
   data practices, operational learning, and cross-component combinations.
4. **Build evidence dossiers** — trace each idea through related artifacts;
   separate observed facts, inferences, hypotheses, and unknown/conflicting evidence.
5. **Verify public sources** — distinguish close or partial analogues from direct
   publication of the project's actual material; record sources, comparisons,
   search boundaries, dates, and unsuccessful or unavailable verification.
6. **Assess independent dimensions** — evaluate public availability, technical or
   domain originality, potential value, and disclosure consequences, each with
   its own rationale and confidence. There is no combined “secret score.”
7. **Synthesize and propose** — deliver detailed findings and narrowly justified
   advisory exclusions, including alternate manifestations, context-loss costs,
   existing-rule interactions, coverage gaps, and remaining reconstruction paths.

### Inputs and outputs

**Input:** access to the project and the requested audit scope. Optional context
includes business goals, intended disclosure audience, known public sources,
and components to exclude from inspection. Missing context stays explicit;
it is not filled with assumed customers, competitive advantages, or revenues.

**Output:** a Markdown report containing an executive summary, scope/coverage
ledger, candidate map, evidence dossiers, public-source comparisons and search
log, proposed `.aiignore`, and concrete gaps/next checks. Findings use stable
`KH-…` IDs; proposed rules map back to findings and verified project locations.
The proposed addition set may be empty when no exclusions are justified.

The report itself may be sensitive because it brings distributed knowledge
together. It favors evidence anchors over copied code, raw data, or complete
private recipes. Credentials and personal data are handled separately in
redacted terms, not scored as know-how.

## Bundled resources

| File | Purpose |
| --- | --- |
| [SKILL.md](SKILL.md) | Skill definition, seven-step workflow, operating rules, and final report contract |
| [know-how-assessment.md](references/know-how-assessment.md) | Broad candidate discovery, distributed evidence tracing, claim labels, independent assessments, and confidence |
| [public-verification.md](references/public-verification.md) | Neutral queries, source evaluation, analogues versus direct publication, search ledgers, and negative-result limits |
| [aiignore-guidance.md](references/aiignore-guidance.md) | Report structure, finding-linked advisory exclusions, context costs, existing-rule handling, and final checks |

## Compatibility

The skill is agent-agnostic and uses available project-reading and research
tools. Network search and retrieval enable public verification; without them,
the audit continues with that phase marked not performed or partial. Lack of
search results is never proof of uniqueness, novelty, or secrecy. Builds,
scripts, tests, and experiments are not mandatory, and static inspection is
not reported as observed runtime behavior.

Execution environment and model choice belong to the user. The skill imposes
no local-first architecture, disclosure gateway, or per-query approval. External
queries use neutral public concepts rather than private project content.
Responses follow the user's language, defaulting to English if undetermined.

The audit does not modify the analyzed project. The `.aiignore` is an advisory,
not-applied draft for manual review; support and enforcement depend on the
consuming tool. Tool-specific adaptation is performed only on request and needs
verified documentation. Existing rules are preserved; applying changes is a
separate authorized action, and replacing an existing file requires explicit
consent. An ignore file is not access control, a security boundary, a guarantee
of confidentiality, or a reversal of earlier disclosure. This assessment is
technical and business-oriented, not legal advice.

## License

MIT
