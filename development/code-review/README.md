# Code Review

A standalone [Agent Skill](https://agentskills.io/specification) that provides comprehensive code review for evaluating code changes. It identifies bugs, logic errors, security issues, structural problems, performance concerns, and unintended behavior changes.

## When to use

| Situation                                                            | Use this skill |
| -------------------------------------------------------------------- | -------------- |
| Reviewing uncommitted changes (the default when no input is given)   | ✅             |
| Reviewing a specific commit                                          | ✅             |
| Comparing the current branch against another branch                  | ✅             |
| Reviewing a pull request                                             | ✅             |
| No version-controlled repository is available                        | ❌             |

## How it works

```
Determine scope  ──►  Gather context  ──►  Review  ──►  Report
```

1. **Determine scope** — based on input: no input → uncommitted changes; commit ref → that commit; branch name → branch diff; PR number/URL → pull request.
2. **Gather context** — diffs alone are not enough. The skill reads the **entire** modified file(s) to understand full context, existing patterns, and control flow. It also checks for `CONVENTIONS.md`, `AGENTS.md`, `SECURITY.md`, and `.editorconfig` to apply project-specific rules.
3. **Review** — evaluates changes across the categories below.
4. **Report** — actionable feedback, prioritized.

### Review categories

| Category     | Focus                                                                                         |
| ------------ | --------------------------------------------------------------------------------------------- |
| **Bugs** *(primary)* | Logic errors, control flow, edge cases, security (OWASP Top 10 — Web 2025 & Agentic), error handling |
| **Structure** | Does the code fit the codebase? Follows existing patterns? Uses established abstractions?    |
| **Performance** | Hot paths, unnecessary allocations, algorithmic complexity                                 |
| **Behavior**  | Unintended changes to existing behavior                                                       |

## Bundled resources

| File                        | Purpose                                                              |
| --------------------------- | ------------------------------------------------------------------- |
| `SKILL.md`                  | Skill definition, the review methodology, and scope determination   |
| `references/review-guide.md` | Detailed review guidance for each category                        |

## Compatibility

The skill is agent-agnostic. It requires access to a version-controlled repository with file-reading capabilities and may need network access for documentation lookup.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
