# Security Policy Generator

A standalone [Agent Skill](https://agentskills.io/specification) for security analysis and policy generation. It analyzes a project repository and generates a comprehensive `SECURITY.md` with a threat model, security architecture, and secure coding guidelines — combining classical application security with the emerging threat model for AI-driven systems.

## When to use

| Situation                                                                                               | Use this skill |
| ------------------------------------------------------------------------------------------------------- | -------------- |
| You need to create a `SECURITY.md` from scratch for a repository                                        | ✅             |
| You want a threat model derived from your actual code, dependencies, and architecture                   | ✅             |
| You are filling in a `SECURITY.md` template and need project-specific content                           | ✅             |
| Your project builds AI agents that take actions on behalf of users and you need agentic threat coverage | ✅             |

> **Agentic coverage is conditional.** A pure chatbot or RAG setup with no tool use and no multi-agent coordination needs only classical controls. The moment the system takes actions on behalf of a user, the agentic threat model (ASI01–ASI10) becomes mandatory — the bundled reconnaissance script auto-detects this.

## How it works

The skill follows a ten-step workflow, split into recon, analysis, and generation:

```
Reconnaissance & analysis                      Generation
───────────────────────                        ──────────
1. Project reconnaissance (incl. agentic)  ──► 8. Generate SECURITY.md
2. Identify assets and data flows               9. Register in AGENTS.md
3. Map attack surface                          10. Validate completeness
4. Assess dependencies & supply chain
5. Document security controls in place
6. Agentic risk assessment (ASI01–ASI10)
7. Derive secure coding rules
```

The unifying principle for the agentic section is **least agency** — grant an agent only the minimum autonomy required for a safe, bounded task. For every agent the skill asks: what is its *reach* (least privilege) and what is its *latitude* within that reach (least agency)?

### Agentic risk categories (ASI01–ASI10)

When agentic components are detected, the skill assesses each OWASP ASI category:

| ASI   | Risk                                        |
| ----- | ------------------------------------------- |
| ASI01 | Agent Goal Hijacking (indirect injection)   |
| ASI02 | Tool Misuse and Exploitation                |
| ASI03 | Agent Identity and Privilege Abuse          |
| ASI04 | Agentic Supply Chain Compromise             |
| ASI05 | Unexpected Code Execution                   |
| ASI06 | Memory and Context Poisoning                |
| ASI07 | Insecure Inter-Agent Communication          |
| ASI08 | Cascading Agent Failures                    |
| ASI09 | Human-Agent Trust Exploitation              |
| ASI10 | Rogue Agents                                |

## Bundled resources

| File                | Purpose                                                                                                |
| ------------------- | ------------------------------------------------------------------------------------------------------ |
| `SKILL.md`          | Skill definition, the ten-step workflow, and the full assessment checklists                            |
| `scripts/recon.sh`  | Reconnaissance script that auto-detects language, frameworks, dependencies, dangerous patterns, and agentic indicators |
| `template.md`       | The `SECURITY.md` template populated during generation                                                 |

## Output

The skill produces a single `SECURITY.md` at the repository root, covering supported versions and vulnerability reporting policy, a threat model derived from the actual attack surface, security architecture and controls, secure coding rules specific to the detected tech stack, and agentic constraints (conditional on detected AI agent components). It also registers the policy in `AGENTS.md`.

## Compatibility

The skill is agent-agnostic. It describes **what** to analyze and generate, not which specific tools to call, so it works with any AI agent that can run shell commands, read, and write files. The `recon.sh` script runs in a POSIX shell and requires no installation beyond standard Unix tools.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
