# CVSS v4.0 — Scoring Guide for Review Findings

[CVSS v4.0](https://www.first.org/cvss/specification-document) (released November 1, 2023 by FIRST) is the current version of the Common Vulnerability Scoring System and the prioritization standard for this skill. CVSS **v3.x and v2 are obsolete** — do not use them for new findings (you may quote an advisory's v3.1 score when triaging a CVE, alongside a v4.0 re-score of your own).

CVSS v4.0 consists of four metric groups:

| Group | Meaning | Assessed by | Used in this skill |
|---|---|---|---|
| **Base** | Intrinsic qualities, constant over time and environments | Security analyst (you) | **Always** — all 12 metrics mandatory |
| **Threat** | Time-dependent characteristics (exploit maturity) | Consumer of intel | Only when PoC/active exploitation is known |
| **Environmental** | Consumer-environment specifics | Deploying organization | Rarely — only when SECURITY.md defines the environment |
| **Supplemental** | Context that never changes the score | Anyone | Optional narrative color (e.g., AU:Y wormable) |

## Base Metrics

### Exploitability metrics

| Metric | Q | Values | Reviewer guidance |
|---|---|---|---|
| **AV** — Attack Vector | How remote can the attacker be? | `N` Network · `A` Adjacent · `L` Local · `P` Physical | Public HTTP/gRPC endpoint → N. Same VPC/LAN/VPN only → A. Requires local account, CLI, or attacker-plantable file → L. Hands on the machine → P. |
| **AC** — Attack Complexity | Must the attacker evade built-in security-enhancing conditions? | `L` Low · `H` High | Deterministic, repeatable attack → L. Needs to defeat ASLR/DEP, obtain a target-specific secret, or defeat an exploit-mitigation control → H. *Number of attempts/race-winnability is NOT AC* (that's AT). |
| **AT** — Attack Requirements | Do deployment/execution conditions enable the attack? | `N` None · `P` Present | Works in any instance of the vulnerable config → N. Needs a race won, an on-path network position, a specific config/state that isn't universal → P. |
| **PR** — Privileges Required | What must the attacker already hold? | `N` None · `L` Low · `H` High | Anonymous → N. Any registered user / low-privileged service account → L. Admin over the vulnerable system → H. Social-engineering findings and unchanged default credentials are usually N. |
| **UI** — User Interaction | Must another human participate? | `N` None · `P` Passive · `A` Active | Attacker-only → N. Victim just visits a page that renders attacker content (stored XSS, CSRF) → P. Victim must consciously do a specific act — import a file, dismiss a warning, paste a string (reflected/self-XSS) → A. |

### Impact metrics

Score the impact of **the scenario you proved** — the realistic final outcome, not imagination. All six take `H` High / `L` Low / `N` None.

| Metric | Measures impact on… | Reviewer guidance |
|---|---|---|
| **VC / VI / VA** | the **vulnerable system** (Confidentiality / Integrity / Availability) | Data exfiltrated → VC. Data or code modified, unauthorized action performed → VI. Service crashed/exhausted → VA. |
| **SC / SI / SA** | the **subsequent system(s)** beyond the vulnerable one | Use when the exploit's real damage lands elsewhere: SSRF stealing cloud-metadata credentials (SC:H on the cloud account), agent RCE pivoting to email/repos (SI/SA), wormable spread (SA on other hosts). No downstream impact → all three `N`. |

Rules of thumb:

- Score the **delta**: only what the attacker gains beyond their starting position.
- Use the **end state**: partial access → total disclosure scores VC:H.
- `H` vs `L` for confidentiality: all/most sensitive data exposed → H; a narrow slice (one field, one record class) → L.
- Subsequent-system impact is what distinguishes "app bug" from "infrastructure incident" — think one step past the vulnerable component, no further.

## Threat Metrics

| Metric | Values | Use |
|---|---|---|
| **E** — Exploit Maturity | `A` Attacked · `P` PoC · `U` Unreported · `X` Not Defined | Only cite with evidence: KEV listing / vendor advisory of active exploitation → A; public PoC code → P; nothing public → U or leave X. For your own code findings, E is usually not applicable. |

Environmental metrics (`CR/IR/AR`, `MAV…MSA`, `MSI:S`/`MSA:S` for human safety) belong to the deploying organization; assess them only when the project's SECURITY.md or deployment docs establish the environment, and then label the score **CVSS-BE** or **CVSS-BTE**.

## Vector String

```
CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N
```

- Starts with `CVSS:4.0/`; metrics in **fixed order**: AV, AC, AT, PR, UI, VC, VI, VA, SC, SI, SA — then optionally E, then Environmental, then Supplemental.
- **All 12 Base metrics are mandatory** in every vector you emit.
- Omitted optional metrics are `X` (Not Defined); you may include them explicitly.

## Nomenclature — label what you scored

| Label | Meaning |
|---|---|
| `CVSS-B` | Base only — **the default for review findings** |
| `CVSS-BT` | Base + Threat |
| `CVSS-BE` | Base + Environmental |
| `CVSS-BTE` | Base + Threat + Environmental |

Always show score **and** vector together, e.g. `8.7 (High, CVSS-B) CVSS:4.0/AV:N/…`.

## Qualitative Severity Bands

| Rating | Score |
|---|---|
| None | 0.0 |
| Low | 0.1 – 3.9 |
| Medium | 4.0 – 6.9 |
| High | 7.0 – 8.9 |
| Critical | 9.0 – 10.0 |

## Scoring Procedure for a Review Finding

1. **Freeze the scenario first.** Actor, entry point, steps, impact — the scenario selects every metric value. Never score an abstract "vulnerability class".
2. **Walk the metrics in order** (AV → AC → AT → PR → UI → VC/VI/VA → SC/SI/SA), citing the scenario fact that justifies each value. Note AT and AC explicitly for anything timing- or secret-dependent.
3. **Compute the score** with the [FIRST calculator](https://www.first.org/cvss/calculator/4.0) or the [NVD calculator](https://nvd.nist.gov/vuln-metrics/cvss/v4-calculator) if network/tools permit. Record `score (Rating, CVSS-B)` plus the vector.
4. **No calculator available:** emit the vector (authoritative) plus the qualitative band derived from the heuristic table below, and say the numeric score was not computed.
5. **Add E:A / E:P only with public evidence**; otherwise the finding is CVSS-B.

### Heuristic band fallback (no calculator)

Coarse, deliberately conservative — prefer a calculator whenever possible:

| Profile | Band |
|---|---|
| AV:N (or A) + PR:N + UI:N and any High impact on the vulnerable system | High; Critical if ≥2 High impacts or any subsequent-system High |
| AV:N + PR:L + UI:N, High impact | High |
| AV:N + PR:L/N, only Low impacts, no subsequent impact | Medium |
| Requires local access, physical access, or active user interaction; low impact | Low–Medium |
| Defense-in-depth gap with no provable exploit path | Not a finding — hardening note (no CVSS) |

### Worked examples

**SQL injection on a public search endpoint (CWE-89).** Anonymous, deterministic, dumps the user table: VC:H, VI:H ( UNION-based writes plausible only if proven — else VI:L/N), VA:N, no downstream system. → `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N` — High/Critical band, CVSS-B.

**Single-use coupon double-redemption race (CWE-362).** Any authenticated user fires parallel requests; must win a wide window (two sequential requests) → AT:N is defensible; financial loss to the business only → VI:H on the vulnerable system, VC:N. → `CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:N/VI:H/VA:N/SC:N/SI:N/SA:N` — Medium–High band, CVSS-B.

**SSRF to cloud metadata (CWE-918).** Webhook URL preview, unauthenticated; steal instance role credentials → the impact lands on the cloud account, not the app: SC:H, SI:L (attacker can act with stolen creds). → `CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:L/VI:N/VA:N/SC:H/SI:L/SA:N` — Critical band due to subsequent-system impact, CVSS-B.

## Pitfalls

- **Inflation:** claiming SC/SI/SA:H for anything that touches a network. Subsequent impact requires the *demonstrated* pivot, not "could theoretically move".
- **AT vs AC confusion:** race-winnable or needs-specific-state → AT:P; must defeat a security mechanism or obtain a target-specific secret → AC:H.
- **PR:N vs PR:L:** "must register an account" is PR:L, not N — unless the finding *is* the registration/open-signup itself. Free self-service accounts don't inflate to N.
- **UI:P vs UI:A:** stored XSS/CSRF where visiting is enough → P; reflected/self-XSS requiring the victim to paste or click a crafted link they were social-engineered into → A (per FIRST: the distinguishing question is whether the user consciously performs a specific interaction).
- **Scoring the class, not the instance:** two identical CWE-89s in different endpoints score differently when entry point, privileges, and data differ.
- **Mixing versions:** never emit a CVSS:3.1 vector for a new finding; when quoting a third-party advisory's v3.1 score, mark it as quoted and provide your own v4.0 vector.
