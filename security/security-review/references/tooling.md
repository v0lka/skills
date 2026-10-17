# Ecosystem Security Tooling — Catalog and Usage Rules

Auxiliary scanners accelerate the review but never replace it. Use **every tool that is installed and applicable** to the project's stack; skip and note the ones that are not. Detect the stack from manifest files before choosing.

## Usage Rules

1. **Read-only.** Run scanners against the working tree. Do not run anything that modifies the repository, commits, pushes, or sends crafted payloads at external/production systems.
2. **Check availability first** (`command -v govulncheck`), note versions in the report (`govulncheck` prints its version; `npm audit` runs with the local npm). A missing tool is a *coverage gap to report*, not a failure.
3. **Network-dependent tools** (registry lookups: `npm audit`, `cargo audit`, `osv-scanner`) may fail offline — record that.
4. **Output handling:** prefer JSON output where available (`--json`) for precise extraction; fall back to human-readable. Capture exit codes — most scanners exit non-zero when findings exist.
5. **Every tool finding must be verified** (see SKILL.md): version confirmed as a declared dependency, vulnerable path reachable. Unverified results go to "Unverified tool findings" — no CVSS score.
6. **Lockfiles are the source of truth** for what actually ships (`go.sum`, `package-lock.json`, `yarn.lock`, `Cargo.lock`, `poetry.lock`, `gradle.lockfile`, `Gemfile.lock`, `composer.lock`).

## Dependency & Vulnerability Scanners by Ecosystem

| Ecosystem | Detector | Command (typical) | Notes |
|---|---|---|---|
| **Go** | govulncheck | `govulncheck ./...` | Symbol-level reachability analysis — a `govulncheck` hit is strong evidence; still confirm the call path is attacker-influenced |
| | `go vet` | `go vet ./...` | Not security-specific; catches misuse patterns |
| **Node.js / JS** | npm audit | `npm audit --json` | Requires network to the registry; audit-ci for thresholds |
| | pnpm / yarn | `pnpm audit --json` / `yarn audit --json` | Use whichever lockfile is present |
| | njsscan | `njsscan .` | Static analysis for Node security anti-patterns |
| **Rust** | cargo audit | `cargo audit --json` | RustSec advisory DB; needs network first run |
| | cargo deny | `cargo deny check advisories bans licenses` | Also duplicates, wildcards, license policy |
| **Python** | pip-audit | `pip-audit -r requirements.txt` (or `pip-audit` in the env) | Also `pip-audit --requirement poetry.lock` where applicable |
| | safety | `safety check --json` | Alternative advisory source |
| | bandit | `bandit -r . -f json` | SAST for Python security anti-patterns (exec, pickle, weak crypto) |
| **JVM** | OWASP Dependency-Check | `dependency-check --scan . --format JSON` | NVD-based; needs NVD API key for decent speed |
| **.NET** | dotnet CLI | `dotnet list package --vulnerable --include-transitive` | Built into the SDK |
| **PHP** | composer audit | `composer audit --format=json` | Built into Composer ≥ 2.4 |
| **Ruby** | bundler-audit | `bundle audit check --format json` | Gem advisories |
| | brakeman | `brakeman -o json .` | Rails-specific SAST |
| **Multi-ecosystem** | osv-scanner | `osv-scanner --lockfile <lock>` / `osv-scanner -r .` | Google OSV database; covers many ecosystems incl. Go, npm, pip, cargo, maven |
| | trivy (fs/repo) | `trivy fs --format json .` | Dependency + config + secret scanning in one pass |
| | grype | `grype dir:.` | Vulnerability matching against SBOMs or dirs |

## Static Analysis (SAST) & Linting

| Scope | Tool | Notes |
|---|---|---|
| Multi-language | **semgrep** | `semgrep --config auto --json` (network) or `--config p/owasp-top-ten`, `p/security-audit`, `p/secrets`; write a custom rule when you can express the pattern precisely |
| | grep-based sweeps | When no scanner is installed, ripgrep for high-signal sinks: `eval(`, `exec.Command`, `InsecureSkipVerify`, `os.system`, `pickle.loads`, `yaml.load(`, `dangerouslySetInnerHTML`, `Math.random`, `SELECT.*%s`, `innerHTML =`, `--insecure`, `md5\|sha1`, `BEGIN (RSA\|EC\|OPENSSH) PRIVATE KEY` |
| Go | gosec | `gosec -fmt json ./...` — Go-specific security rules (G101 hardcoded creds, G204 subprocess, G402 TLS skip, G601 race-ish) |
| JS/TS | eslint-plugin-security | `npx eslint . --format json` if configured in the repo |
| Secrets | gitleaks / trufflehog | `gitleaks detect --source . --report-format json` — committed credentials are CWE-798 findings |
| Containers | hadolint, dockle, `trivy image` | Dockerfile anti-patterns; image CVEs when an image is in scope |
| IaC / k8s | checkov, `trivy config`, kube-linter | Terraform/K8s misconfigurations when in scope |

## Race & Concurrency Detectors

| Ecosystem | Tool | Notes |
|---|---|---|
| Go | `go test -race ./...` | Runs the existing test suite under the race detector; a hit is direct evidence (CWE-366/362). Read-only with respect to the repo |
| C/C++/Rust/Swift | ThreadSanitizer | `-fsanitize=thread` — requires building; do this only when a build is already part of the workflow |
| Rust | loom / Miri | For `Arc`/`Mutex`-heavy code; `cargo miri run` on targeted tests when feasible |
| JVM | jcstress | For concurrency libraries, rarely part of app review — code reading dominates |
| .NET | `dotnet counters`+review | No mainstream detector; rely on the checklist |

A clean detector run **does not prove** the absence of races — coverage of concurrent paths decides. Report the run scope (which packages/tests executed).

## From Tool Output to Finding

For each scanner hit, walk this ladder; the finding's confidence tracks the highest rung you reached:

1. **Version match** — the flagged version is what the lockfile pins (scanners occasionally resolve differently).
2. **Reachability** — the vulnerable symbol/path is imported and called from code in scope (`govulncheck` does this for Go; for others, grep the dependency's usage sites).
3. **Attacker influence** — input the attacker controls can reach the vulnerable call (the attack scenario).
4. **Impact confirmation** — the advisory's impact matches your scenario (many CVEs are Windows-only, dev-tool-only, or require a feature you don't use — then it's not a finding, note it in triage).

Rung 4 → full finding with CVSS v4.0 (re-score yourself; quote the advisory's score separately). Rungs 1–2 → finding with `Confidence: Probable` and the unverified link named. Rung 0 or tool-specific doubt → "Unverified tool findings" section.

When the advisory provides a CVSS v3.1 score, cite it as quoted (`Advisory CVSS:3.1 9.8`) and add your own CVSS:4.0 vector for the *actual* reachability context — a 9.8 advisory on a dev-only code path often re-scores to Medium once PR/UI/AT reflect reality, and saying so is exactly the value of review triage.
