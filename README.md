# AI agents skills set

A set of AI agent skills designed to solve research and development tasks.

## Skills Overview

### Research

General-purpose research and ideation skills.

| Skill                                                    | Description                                                                                                                                                                |
| -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**deeper-research**](research/deeper-research/SKILL.md) | Conduct thorough, multi-source research using Tree of Thoughts methodology. Produces cited, multi-perspective syntheses with confidence ratings and evidentiary hierarchy. |
| [**explore**](research/explore/SKILL.md)                 | Enter explore mode — a thinking partner for exploring ideas, investigating problems, and clarifying requirements before implementation.                                    |
| [**scamper**](research/scamper/SKILL.md)                 | Transform existing ideas into improved variants using the SCAMPER method (Substitute, Combine, Adapt, Modify, Put to other use, Eliminate, Reverse).                       |
| [**triz-solver**](research/triz-solver/SKILL.md)         | Solve inventive engineering, product, process, or system-design problems using TRIZ methodology and contradiction resolution.                                              |
| [**vibe-research**](research/vibe-research/SKILL.md)     | Iterative research copilot for exploratory "vibe research" — progressively sharpens broad topics into high-value lines of inquiry.                                         |

### Engineering Research

Skills that automate the Iterative Engineering Research Methodology — from initial brief to final report. See [engineering/README.md](engineering/README.md) for the full workflow.

| Skill                                                               | Description                                                                                                                  |
| ------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| [**research-init**](engineering/research-init/SKILL.md)             | Bootstrap a new research project: create the directory structure, populate the brief, and register the project in the index. |
| [**research-prior-art**](engineering/research-prior-art/SKILL.md)   | Search for and catalog existing work — papers, CVEs, tools, talks, blogs, standards — with relevance ratings.                |
| [**research-hypothesis**](engineering/research-hypothesis/SKILL.md) | Create, update, and manage hypothesis cards and the hypothesis graph (Mermaid DAG + catalog).                                |
| [**research-experiment**](engineering/research-experiment/SKILL.md) | Guide experiment design, execution tracking, and result recording for a research hypothesis.                                 |
| [**research-decision**](engineering/research-decision/SKILL.md)     | Analyze hypothesis results and recommend continue, pivot, kill, or fork decisions.                                           |
| [**research-synthesis**](engineering/research-synthesis/SKILL.md)   | Execute the synthesis phase: determine report mode, walk the hypothesis graph, and generate the final report.                |
| [**research-status**](engineering/research-status/SKILL.md)         | Generate a comprehensive status overview of a research project.                                                              |

### Idiomatic Go

Skills for writing idiomatic, correct, and performant Go code.

| Skill                                                                              | Description                                                                                                  |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| [**go-code-organization**](idiomatic-go/go-code-organization/SKILL.md)             | Well-organized Go code and projects — variable scoping, nested control flow, and project structure.          |
| [**go-concurrency-foundations**](idiomatic-go/go-concurrency-foundations/SKILL.md) | Foundational concurrency concepts — concurrency vs parallelism, goroutine scheduling, and channel semantics. |
| [**go-concurrency-practice**](idiomatic-go/go-concurrency-practice/SKILL.md)       | Practical Go concurrency rules — goroutines, channels, mutexes, and synchronization patterns.                |
| [**go-control-structures**](idiomatic-go/go-control-structures/SKILL.md)           | Correct usage of range loops, break statements, and defer in loops.                                          |
| [**go-data-types**](idiomatic-go/go-data-types/SKILL.md)                           | Common mistakes with basic data types, slices, and maps.                                                     |
| [**go-error-management**](idiomatic-go/go-error-management/SKILL.md)               | Go error management — panic usage, error wrapping, and checking error types and values.                      |
| [**go-functions-methods**](idiomatic-go/go-functions-methods/SKILL.md)             | Best practices for Go functions and methods — receivers, named results, nil receivers, and defer.            |
| [**go-optimizations**](idiomatic-go/go-optimizations/SKILL.md)                     | Performance-sensitive Go code — CPU cache, escape analysis, allocation reduction, profiling, and GC tuning.  |
| [**go-standard-library**](idiomatic-go/go-standard-library/SKILL.md)               | Common Go standard library mistakes — time.Duration, JSON handling, and HTTP pitfalls.                       |
| [**go-strings**](idiomatic-go/go-strings/SKILL.md)                                 | Correct and efficient Go string code — iteration, concatenation, and conversions.                            |
| [**go-testing-mistakes**](idiomatic-go/go-testing-mistakes/SKILL.md)               | Common Go testing mistakes — test categorization, race detection, and test execution.                        |

## Quick Start

### Installation

These skills can be installed using the Skills CLI from [skills.sh](https://skills.sh):

```bash
# Install all skills collection
npx skills add v0lka/skills --all
# Install a specific skill
npx skills add v0lka/skills --skill <skill-name>
```

### Manual Usage

To use a skill manually, reference the agent skills [documentation](https://agentskills.io) or load it via your AI agent interface.

## License

MIT License — see [LICENSE](LICENSE) for details.
