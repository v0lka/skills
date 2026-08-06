# Secure Go Development

A standalone [Agent Skill](https://agentskills.io/specification) for writing secure Go applications through everyday development practices — no AppSec expertise required. It covers the 12 OWASP Top 10 categories (2021 & 2025) with idiomatic Go patterns, standard-library defaults, recommended libraries, and a security-focused linter setup.

Go starts from a strong position: no buffer overflows (GC, bounds-checked slices), strict static typing, explicit error handling, a single static binary, and `go.sum` + checksum database guaranteeing dependency integrity. Go cryptographic packages passed an independent [Trail of Bits audit](https://github.com/trailofbits/publications) in 2025.

## When to use

| Situation                                                              | Use this skill |
| --------------------------------------------------------------------- | -------------- |
| Writing or reviewing Go backend code                                  | ✅             |
| Designing Go APIs                                                     | ✅             |
| Configuring production deployments or CI/CD security checks           | ✅             |
| Hardening existing Go services                                        | ✅             |
| Writing non-Go code                                                   | ❌             |

## How it works

The skill is organized around the OWASP Top 10 structure (2021 with 2025 mappings noted in each section):

```
OWASP A01  Access Control           — deny by default, authz in middleware, ownership-bound data
OWASP A02  Data Protection           — hashing, secrets, crypto/rand, response structs
OWASP A03  Injection                 — parameterized queries, input validation
OWASP A04  Insecure Design           — secure defaults, threat modeling
OWASP A05  Misconfiguration          — config, dependencies, supply chain
OWASP A06  Auth & Sessions           — token handling, session management
OWASP A07  Error Handling            — no information leakage
OWASP A08  Integrity & Tampering     — integrity checks, signature verification
OWASP A09  Logging & Monitoring      — security event logging
OWASP A10  SSRF / External Objects   — safe outbound requests, external resource safety
```

Each category provides idiomatic Go rules and recommended libraries (e.g. [Casbin](https://github.com/casbin/casbin), [Oso](https://github.com/osohq/oso) for access control) backed by concrete code examples in the reference files.

## Bundled resources

| File                                    | Purpose                                                          |
| --------------------------------------- | ---------------------------------------------------------------- |
| `SKILL.md`                              | Skill definition, the OWASP-mapped structure, and rules          |
| `references/access-and-data.md`         | Access control & data protection code examples                   |
| `references/input-and-design.md`        | Injection defense & secure design examples                       |
| `references/config-and-deps.md`         | Configuration, dependencies & supply chain examples              |
| `references/auth-and-errors.md`         | Authentication, sessions & error handling examples               |
| `references/integrity-and-logging.md`   | Integrity, tampering & logging examples                          |
| `references/external-safety.md`         | SSRF & external object safety examples                           |
| `references/linters.md`                 | Security-focused linter setup                                    |
| `references/checklist.md`               | Secure coding checklist                                          |

## Compatibility

The skill is agent-agnostic. It describes **what** to do, not which specific tools to call, so it works with any AI agent that can read and write files. A Go toolchain is needed when applying the rules to real code.

The skill follows the [Agent Skills specification v1](https://agentskills.io/specification).

## License

MIT
