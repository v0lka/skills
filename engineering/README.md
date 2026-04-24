# AppSec Research Skills

A set of seven [Agent Skills](https://agentskills.io/specification) that automate the **Iterative Engineering Research Methodology**. The skills cover the entire lifecycle of a research project — from initial brief creation to the final report — while keeping the researcher in full control of every substantive decision.

All artifacts are plain Markdown files in a regular directory tree. No wiki engine, database, or external service is required.

## How the skills map to the methodology

The methodology defines three phases. The skills are split into **atomic** (reusable at any point) and **phase-level** (tied to a specific stage):

```
  Atomic skills                         Phase-level skills
  ─────────────                         ──────────────────
  research-init                         research-synthesis
  research-prior-art                    research-status
  research-hypothesis
  research-experiment
  research-decision
```

| Skill                 | Purpose                                                                                                                                                                                                                                               |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `research-init`       | Bootstrap a new research project: create the directory structure, populate the brief through a structured dialogue, validate the 3-month constraint, and register the project in the index.                                                           |
| `research-prior-art`  | Search for and catalog existing work — academic papers, CVEs, tools, conference talks, blog posts, standards — with relevance ratings. Can be invoked at any phase when additional context is needed.                                                 |
| `research-hypothesis` | Create, update, and manage hypothesis cards and the hypothesis graph (Mermaid DAG + catalog table). Handles identifier assignment, status transitions, result recording, and fork documentation.                                                      |
| `research-experiment` | Guide the design of a minimal experiment for a hypothesis, track progress against the timebox, and formally record the outcome. Includes a reproducibility checklist for experiments that will enter the final report.                                |
| `research-decision`   | Analyze a completed experiment result together with the full hypothesis graph and research brief to recommend one of the four iteration decisions: **continue**, **pivot**, **kill**, or **fork**. Proposes concrete next hypotheses when applicable. |
| `research-synthesis`  | Execute the final phase: determine report mode (simple vs. complex path), walk the hypothesis graph, build the prototype inventory, finalize the implementation plan, and generate the final report.                                                  |
| `research-status`     | Generate a read-only status snapshot at any point: hypothesis metrics, the current front line, key findings, risks, and suggested next actions. Supports a quarterly-review mode for demo preparation.                                                |

## File catalog structure

Every research project lives in a self-contained directory under a shared research root. The structure is created by `research-init` and maintained by the other skills:

```
{research-root}/
├── index.md                          ← registry of all research projects
└── R-NNN-short-name/                 ← one research project
    ├── brief.md                      ← research brief (entry point)
    ├── hypotheses/
    │   ├── graph.md                  ← Mermaid DAG + hypothesis catalog table
    │   ├── H-001.md                  ← hypothesis card
    │   ├── H-002.md
    │   └── ...
    ├── prior-art.md                  ← curated reference catalog
    └── report.md                     ← final report (created by research-synthesis only)
```

The research root can host any number of projects side by side. The `index.md` file aggregates metadata (ID, title, status, domain, quarter, researchers) for filtering and navigation.

## Recommended workflow

### Phase 1 — Exploration

```
research-init  →  research-prior-art  →  research-hypothesis (H-001)
```

Start by initializing the project. The agent walks you through twelve brief fields (title, problem domain, research question, success criteria, scope, constraints, prior art summary, related researches, implementation plan, ethical boundaries, quarter, researchers) and creates the file tree.

Next, run a prior-art survey. The agent derives search queries from the brief, searches across six source categories (papers, CVEs, tools, talks, blogs, standards), and populates `prior-art.md` with annotated, relevance-rated entries. It may also suggest refinements to the brief based on what it finds.

Finally, formulate the first hypothesis. The agent helps sharpen a vague idea into a falsifiable statement with a concrete verification criterion and a timebox.

### Phase 2 — Iterations

```
research-hypothesis  →  research-experiment  →  research-decision
        ▲                                              │
        └──────────── new hypotheses ◄─────────────────┘
```

This is the core loop. Each iteration tests one hypothesis:

1. **Formulate** (`research-hypothesis`) — create or pick a hypothesis card with a statement, criterion, and timebox.
2. **Experiment** (`research-experiment`) — design the minimal experiment, set up the environment, run it, and record the result. The agent monitors the timebox and alerts you when 75% is consumed.
3. **Decide** (`research-decision`) — the agent reads the completed card, the full graph, and the brief, then recommends one of four decisions:

| Decision     | What happens next                                                                                      |
| ------------ | ------------------------------------------------------------------------------------------------------ |
| **Continue** | Child hypotheses are created to deepen the confirmed direction.                                        |
| **Pivot**    | Open hypotheses on the current branch are cancelled; new ones are formulated in a different direction. |
| **Kill**     | The branch is pruned. Knowledge gained is preserved in the card, but no new work starts here.          |
| **Fork**     | Two or three competing hypotheses are created with individual timeboxes and selection criteria.        |

The agent then creates the appropriate hypothesis cards, and the cycle repeats.

Two skills can be invoked **at any point** during iterations:

- `research-prior-art` — when an experiment reveals a knowledge gap and you need more context.
- `research-status` — when you want a progress snapshot, metrics, or risk flags. Especially useful before standups or quarterly reviews.

### Phase 3 — Synthesis

```
research-status  →  research-synthesis
```

Synthesis begins when the research question is answered, the time budget is exhausted, or an external stakeholder decides to conclude. The agent:

1. Confirms readiness and handles any remaining open hypotheses.
2. Determines the report mode — **simple** (straight path, 1–2 pages) or **complex** (pivots and dead ends, as long as needed) — using the heuristic that >30% refuted/cancelled hypotheses or 2+ pivots trigger the complex mode.
3. Walks the graph to identify the critical path, key decision points, dead ends, and unexpected discoveries.
4. Builds a prototype inventory from all hypothesis cards.
5. Finalizes the implementation plan in the brief, choosing one of three models: development-team integration, research-team integration, or new product (MVP).
6. Generates `report.md` from the appropriate template.
7. Updates the brief status and the research index.

## Key decision heuristics

The methodology encodes several rules of thumb that the `research-decision` skill applies:

- **Timebox expiry + inconclusive = kill or pivot**, never extension.
- **Budget pressure triggers convergence**: when ~70% of time is consumed, prefer deepening over broadening.
- **Fork is the exception**, not the rule. Sequential testing is the default.
- **Dead ends still produce knowledge**: the "what we learned" section of a killed hypothesis must be thorough.

## Artifact ownership

Each skill owns specific files and never modifies files outside its responsibility:

| Skill                 | Creates                                                                        | Updates                                                                                  |
| --------------------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| `research-init`       | `R-NNN-*/brief.md`, `hypotheses/graph.md`, `prior-art.md`, entry in `index.md` | —                                                                                        |
| `research-prior-art`  | —                                                                              | `prior-art.md`; may propose edits to `brief.md`                                          |
| `research-hypothesis` | `hypotheses/H-NNN.md`                                                          | `hypotheses/graph.md` (diagram + catalog)                                                |
| `research-experiment` | —                                                                              | `hypotheses/H-NNN.md` (Experiment Notes, Result)                                         |
| `research-decision`   | —                                                                              | `hypotheses/H-NNN.md` (Decision field); delegates to `research-hypothesis` for new cards |
| `research-synthesis`  | `report.md`                                                                    | `brief.md` (status, implementation plan), `index.md`                                     |
| `research-status`     | —                                                                              | — (read-only)                                                                            |

## Skill interconnections

```
research-init ──────► research-prior-art ──────► research-hypothesis
      │                    ▲       │                  ▲    │
      │                    │       │                  │    ▼
      │               (any time)   └──────► ◄─── research-experiment
      │                    │                          │
      │                    │                          ▼
      │               research-status ◄───── research-decision
      │                    │                          │
      │                    ▼                          │
      └──────────────► research-synthesis ◄───────────┘
```

No skill operates in isolation. The typical call chain is:

`init → prior-art → hypothesis → experiment → decision → (hypothesis → …) → synthesis`

with `status` and `prior-art` available as cross-cutting utilities at any point.

## Compatibility

The skills are agent-agnostic. They describe **what** to do, not which specific tools to call, so they work with any AI agent that can read, write, and search files. No external services, APIs, or runtime dependencies are required beyond a filesystem.

All skills follow the [Agent Skills specification v1](https://agentskills.io/specification) and have been validated for frontmatter correctness, naming conventions, cross-references, and body size limits (all under 200 lines, well within the 500-line recommendation).

## License

MIT
