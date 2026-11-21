# Mandatory-Review Sources

This list is the floor, not the ceiling: poll every reachable source each run, then supplement with targeted web searches per coverage area. Some sources may be dormant or unreachable on a given day — verify liveness per run rather than assuming; note unreachable sources and continue.

## Polling strategy

- Fetch each site's front page or blog index directly, or run a `site:<domain>` search restricted to the selection window.
- Many of these sites expose RSS/Atom feeds. If you use one, discover the feed URL from the page itself — never construct or guess feed URLs. The feed URLs listed below were verified to work.
- Some sites guard their HTML pages behind a Cloudflare JS challenge (`cf-mitigated: challenge`, "Just a moment..." page). Browser-based fetchers pass it; plain HTTP fetchers do not. If a site returns 403 with that signature, try its RSS/Atom feed — feeds are usually served without the challenge (this is why InfoSec Write-ups is listed by its feed URL).
- Record for each polled source: reachable or not, and the newest item date seen. This feeds the freshness check in SKILL.md Step 3.
- Entries that appear in more than one group below were deduplicated; each distinct URL appears once.

## Security research and practitioner blogs

| Source | URL |
|---|---|
| Schneier on Security | https://www.schneier.com/ |
| Crypto-Gram archive (Schneier on Security) | https://www.schneier.com/crypto-gram/ |
| Krebs on Security | https://krebsonsecurity.com |
| A Few Thoughts on Cryptographic Engineering | https://blog.cryptographyengineering.com |
| Google Project Zero | https://projectzero.google/ |
| GMO Flatt Security Research posts | https://flatt.tech/research/posts/ |
| Quarkslab blog | https://blog.quarkslab.com/ |
| Doyensec blog | https://blog.doyensec.com/ |
| TaoSecurity | https://taosecurity.blogspot.com/ |
| Secjuice | https://secjuice.com/ |
| Blaze's Security Blog | https://bartblaze.blogspot.com/ |
| PortSwigger Blog | https://portswigger.net/blog |
| Detectify blog | https://blog.detectify.com/ |
| Rawsec | https://blog.raw.pm/ |
| Pen Test Partners blog | https://www.pentestpartners.com |
| PenTestIT | https://pentestit.com/ |
| ElcomSoft blog (Advanced Password Cracking) | https://blog.elcomsoft.com |
| InfoSec Write-ups (Medium, RSS feed) | https://infosecwriteups.com/feed |

## Vendor and product security blogs

| Source | URL |
|---|---|
| Google Online Security Blog | https://blog.google/security/ |
| Semgrep blog | https://semgrep.dev |
| NetSPI | https://www.netspi.com/ |
| Veracode (Application Security News, Research) | https://www.veracode.com/ |
| Contrast Security — AppSec Observer | https://www.contrastsecurity.com/security-influencers |
| Imperva Data Security Blog | https://www.imperva.com/blog/ |
| Qualys Security Blog | https://blog.qualys.com |
| Acunetix Web Application Security Blog | https://www.acunetix.com/blog/ |
| Sucuri Blog | https://blog.sucuri.net/ |
| Check Point Research | https://research.checkpoint.com/ |
| R-Vision | https://rvision.ru/ |

## Security news media and aggregators

| Source | URL |
|---|---|
| Ars Technica | https://arstechnica.com |
| The Record (Recorded Future News) | https://therecord.media |
| CISA Alerts & Advisories | https://www.cisa.gov/news-events/cybersecurity-advisories |
| The Hacker News | https://thehackernews.com |
| Daily CyberSecurity | https://securityonline.info/ |
| The Register — Security | https://www.theregister.com/security/ |
| IBM Think — Security (ex-Security Intelligence) | https://www.ibm.com/think/security |
| Reddit r/netsec | https://www.reddit.com/r/netsec/ |

## AI research, labs, and practitioner sources

| Source | URL |
|---|---|
| Simon Willison's weblog (LLMs, agents, tooling) | https://simonwillison.net |
| Hugging Face Blog | https://huggingface.co/blog |
| Google DeepMind News | https://deepmind.google/blog/ |
| OpenAI News | https://openai.com/news/ |
| Anthropic Newsroom | https://www.anthropic.com/news |
| The GitHub Blog | https://github.blog |

## Cryptography

| Source | URL |
|---|---|
| Habr — Cryptography hub, all articles | https://habr.com/ru/hubs/crypto/articles/ |
| Reddit r/crypto | https://www.reddit.com/r/crypto/ |
| Reddit r/cryptography | https://www.reddit.com/r/cryptography/ |

## Russian-language sources

| Source | URL |
|---|---|
| Habr — Information Security hub, top articles | https://habr.com/ru/hubs/infosecurity/articles/ |
| Xakep | https://xakep.ru |

## Notes

- A source being absent from this list never disqualifies a story; a primary source is still required for every published item (SKILL.md Step 3).
- When several polled sources cover the same event, merge them into one item and link the primary source.
- Removed during the 2026-11 maintenance pass, do not re-add without re-verification:
  - Threatpost (publication closed, archive frozen 2022-08), Naked Security/Sophos (retired, redirects to vendor marketing blog), OWASP blog at owasp.blogspot.com (last post 2020-10; OWASP now publishes on owasp.org), BadCyber (ended ~2021), NotSoSecure (blog frozen 2021-11, absorbed into Claranet), Hakin9 (site now sells courses/membership, no dated publications), AppSec Ezine (last issue 2025-11), Andrey Dugin's blog (dormant since 2023-10), Dennis Yurichev's blog (author deceased 2021, site frozen).
  - Unreachable: E Hacking News (ehackingnews.com, TCP timeout), Daily CyberSecurity (cyberpress.org, TLS handshake aborted), Positive Technologies Research Lab (blog.ptsecurity.com, domain removed from DNS).
