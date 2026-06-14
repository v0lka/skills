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

### Agentic

Skills for building and maintaining AI agent systems.

| Skill                                                 | Description                                                                                                                                                          |
| ----------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**prompts-review**](agentic/prompts-review/SKILL.md) | Review all prompts in a codebase for optimality, balancing effectiveness and token efficiency. Covers explicit, string-literal, and dynamically constructed prompts. |

### Security

Skills for security analysis and policy generation.

| Skill                                                                   | Description                                                                                                                                              |
| ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**security-policy-generator**](security/security-policy-generator/SKILL.md) | Analyze a project repository and generate a comprehensive SECURITY.md with threat model, security architecture, and secure coding guidelines. |

### Development

Skills for writing secure, idiomatic, production-ready Go applications — from specification to correct code.

#### Secure Go

| Skill                                           | Description                                                                                                                                                                                                 |
| ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**secure-go**](development/secure-go/SKILL.md) | Write secure Go applications through everyday practices — idiomatic patterns, standard library defaults, OWASP Top 10 coverage, and a security-focused linter setup. Covers access control, data protection, input handling, secure design, configuration, dependencies, authentication, error handling, integrity, logging, external objects, and SSRF. |

#### Specification-Driven Development

Skills that implement a Specification-Driven Development workflow — from bootstrapping a spec system to keeping specs aligned with code. See [development/sdd/README.md](development/sdd/README.md) for the full workflow.

| Skill                                                              | Description                                                                                                                     |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| [**vibespec-init**](development/sdd/vibespec-init/SKILL.md)       | Initialize a specification system for a project from scratch by analyzing the codebase and generating the initial set of specs. |
| [**vibespec-create**](development/sdd/vibespec-create/SKILL.md)   | Create a new specification document following the project's spec system templates and conventions.                              |
| [**vibespec-consult**](development/sdd/vibespec-consult/SKILL.md) | Proactively consult project specifications before making structural changes to avoid violating documented invariants.           |
| [**vibespec-update**](development/sdd/vibespec-update/SKILL.md)   | Update existing specification documents after code changes that alter documented behavior, interfaces, or invariants.           |
| [**vibespec-check**](development/sdd/vibespec-check/SKILL.md)     | Detect discrepancies between project specifications and actual code, interactively resolving each finding with the user.        |

#### Idiomatic Go

Skills for writing idiomatic, correct, and performant Go code.

| Skill                                                                                        | Description                                                                                                  |
| -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| [**go-code-organization**](development/idiomatic-go/go-code-organization/SKILL.md)           | Well-organized Go code and projects — variable scoping, nested control flow, and project structure.          |
| [**go-concurrency-foundations**](development/idiomatic-go/go-concurrency-foundations/SKILL.md) | Foundational concurrency concepts — concurrency vs parallelism, goroutine scheduling, and channel semantics. |
| [**go-concurrency-practice**](development/idiomatic-go/go-concurrency-practice/SKILL.md)     | Practical Go concurrency rules — goroutines, channels, mutexes, and synchronization patterns.                |
| [**go-control-structures**](development/idiomatic-go/go-control-structures/SKILL.md)         | Correct usage of range loops, break statements, and defer in loops.                                          |
| [**go-data-types**](development/idiomatic-go/go-data-types/SKILL.md)                         | Common mistakes with basic data types, slices, and maps.                                                     |
| [**go-error-management**](development/idiomatic-go/go-error-management/SKILL.md)             | Go error management — panic usage, error wrapping, and checking error types and values.                      |
| [**go-functions-methods**](development/idiomatic-go/go-functions-methods/SKILL.md)           | Best practices for Go functions and methods — receivers, named results, nil receivers, and defer.            |
| [**go-optimizations**](development/idiomatic-go/go-optimizations/SKILL.md)                   | Performance-sensitive Go code — CPU cache, escape analysis, allocation reduction, profiling, and GC tuning.  |
| [**go-standard-library**](development/idiomatic-go/go-standard-library/SKILL.md)             | Common Go standard library mistakes — time.Duration, JSON handling, and HTTP pitfalls.                       |
| [**go-strings**](development/idiomatic-go/go-strings/SKILL.md)                               | Correct and efficient Go string code — iteration, concatenation, and conversions.                            |
| [**go-testing-mistakes**](development/idiomatic-go/go-testing-mistakes/SKILL.md)             | Common Go testing mistakes — test categorization, race detection, and test execution.                        |

## Quick Start

### Installation

These skills can be installed using the Skills CLI from [skills.sh](https://skills.sh):

```bash
# Install all skills collection
npx skills add v0lka/skills --all --full-depth
# Install a specific skill
npx skills add v0lka/skills --skill <skill-name> --full-depth
```

### Manual Usage

To use a skill manually, reference the agent skills [documentation](https://agentskills.io) or load it via your AI agent interface.

## License

MIT License — see [LICENSE](LICENSE) for details.
