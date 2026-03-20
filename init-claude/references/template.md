# CLAUDE.md Minimal Template



Target: under 80 lines. Fill in auto-detected values; leave TODO comments for human-curated sections.



---



## Template



````markdown

# [Repo Name]



## Purpose



[One sentence: what this service does and why it exists]

[Domain: payroll | HR | identity | platform | etc.]



## Stack



- Language/Framework: [e.g. Ruby 3.2 / Rails 7.1 | TypeScript / Node 22 | Go 1.22]

- Runtime: [e.g. Node 22, JVM 21]

- Database: [e.g. PostgreSQL 15, Redis 7]

- Key dependencies: [only what Claude needs to know — not everything in package.json]



## Monorepo Structure



<!-- Include only if multi-package/multi-app repo -->



```



repo-root/

├── apps/api/ # REST API — main service

├── apps/worker/ # Background job processor

└── packages/shared/ # Shared types and utilities

```



## Common Commands



```bash

[test command]        # Run tests

[build command]       # Build / compile

[lint command]        # Lint and format

[migration command]   # Apply DB migrations (if applicable)

```



## Architecture Constraints



<!-- TODO: Add things Claude would get wrong without being told -->

<!-- Examples: -->

<!-- - Services MUST inherit from ServiceBase and return self -->

<!-- - Always scope DB queries by organisation_id — this repo is multi-tenant -->

<!-- - Use Result types, not exceptions, for business errors -->

<!-- - Never modify existing migrations — always create new ones -->



## Key Files



<!-- TODO: file:line references, not code snippets -->

<!-- Examples: -->

<!-- - `app/services/service_base.rb` — Base class all services inherit from -->

<!-- - `src/middleware/auth.ts` — Auth middleware — read before touching auth -->

<!-- - `config/routes.rb` — API routing configuration -->



## Known Quirks



<!-- TODO: Non-obvious gotchas, legacy workarounds, surprising decisions -->

<!-- Examples: -->

<!-- - Use Time.zone.now not Time.now — timezone handling is inconsistent -->

<!-- - Docker on Apple Silicon: add platform: linux/amd64 to docker-compose.yml -->

<!-- - LegacyWorker has 30-min timeout — do not add more work to it -->

````



---


Omit:


- **Code snippets** — go stale; use `file:line` references instead

- **Linter-enforced style rules** — RuboCop/ESLint handle this deterministically

- **Git workflow** — plugin covers branch naming, commits, PRs

- **README content** — reference it, don't duplicate it

- **API keys, secrets, credentials** — never in any CLAUDE.md



---



## Filling In The Template