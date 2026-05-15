# Skills

This page indexes all shared skills in this library, grouped by top-level skill type.

## Skills by Category

### Agentic

- `compose-agents-md` — Create project-specific `AGENTS.md` instructions from the agentic library.
- `configure-mcp` — Set up and configure MCP servers for agent tool access.
- `deploy-config` — Deploy composed config, vendor files, and skills to a target project.
- `github-issue-planning` — Issue-backed plan persistence on GitHub (prefer MCP, fallback to `gh` CLI).
- `persist-plan` — Save the current plan as a structured file under `.agentic/plans/`.
- `write-plan` — Auto-persist generated plans and keep a local plans index updated.

### Backend

- `ddd-aggregate-modeling` — Model aggregates, value objects, invariants, snapshots, and repository boundaries in DDD services.
- `golang-manual-di` — Implement explicit dependency injection wiring patterns for Go services.
- `health-check-endpoints` — Add liveness/readiness health endpoints aligned with probe conventions.
- `microservices-architecture` — Design microservice boundaries, communication, and resilience strategy.
- `nosql-database-design` — Model NoSQL schemas from access patterns and consistency needs.
- `serverless-architecture` — Design and implement serverless workloads with operational guardrails.
- `sql-query-optimization` — Diagnose and optimize SQL performance using plans, indexes, and rewrites.
- `technical-roadmap-planning` — Build prioritized engineering roadmaps with dependencies and milestones.
- `terraform-infrastructure` — Structure and review Terraform IaC modules, state, and pipelines.
- `webhook-development` — Build secure, reliable webhook receivers/senders with retries and idempotency.

### Data

- `json-to-toon` — Convert JSON into TOON format to reduce LLM token usage.
- `relational-database-design` — Design or review relational schemas, constraints, and migrations.

### Development

- `add-tests` — Add focused tests for existing code based on behavior and edge cases.
- `code-review` — Perform structured code review focused on correctness, risk, and quality.
- `fix-bug` — Investigate root cause and implement a verified bug fix with regression coverage.
- `git-flow-pr` — Execute branch, commit, rebase, push, and pull request workflow end-to-end.
- `git-worktree-workspaces` — Use Git worktrees to run parallel branch workspaces safely.
- `github-actions-workflow` — Create or improve GitHub Actions CI/CD workflows.
- `monorepo-management` — Set up and govern monorepo layout, tooling, and CI strategy.
- `new-gh-issue-orchestration` — Run an issue-driven workflow from intake to PR with reviewer-first delegation.
- `pull-request-automation` — Improve PR process with templates, labels, checks, and branch policies.
- `refactor` — Refactor code for clarity and structure without changing behavior.
- `static-code-analysis` — Configure and integrate static analysis tooling into local and CI workflows.

### Devops

- `create-terraform-module` — Create AWS-oriented Terraform module scaffolding with explicit interfaces, provider constraints, and reusable layout guardrails.
- `create-terraform-tests` — Design and implement risk-focused Terraform module tests (`terraform test`) with CI-friendly validation flow.
- `design-aws-terraform-iac` — Plan AWS Terraform architecture, service/module boundaries, state strategy, and acceptance criteria before implementation.
- `docker-compose-local-setup` — Configure local multi-service `docker compose` stacks with readiness, envs, volumes, migrations, and verification.
- `use-aws-mini-stack-emulator` — Use lightweight AWS emulation safely for local Terraform feedback loops, with explicit handoff to real AWS checks.
- `write-dockerfile` — Generate production-ready Dockerfiles with secure, efficient build patterns.

### Documentation

- `sync-confluence` — Sync engineering docs from the repo into Confluence Cloud.
- `write-adr` — Create Architecture Decision Records with context, decision, and consequences.
- `write-changelog` — Generate release changelog entries from commit history.
- `write-readme` — Generate or update README content based on project source and structure.

### UI

- `internationalization-i18n` — Add or improve i18n/l10n architecture, messages, and workflows.
- `next-application-structure` — Define scalable Next.js App Router project structure and conventions.
- `react-application-structure` — Define scalable React application architecture and folder layout.
- `react-component-design` — Design maintainable React component APIs and composition boundaries.
- `react-component-testing` — Apply layered React testing strategy with RTL and Playwright.
- `vue-application-structure` — Define scalable Vue application architecture and conventions.
- `vue-component-design` — Design robust Vue component APIs with clear contracts.
- `vue-component-testing` — Apply layered Vue testing strategy for logic, components, and flows.
- `wireframe-prototyping` — Produce low-fidelity wireframes with interaction and acceptance notes.
- `diagram-design` — Design implementation-grounded diagrams and flag ADR/RFC/code mismatches.

## Using a skill outside a profile

Some profiles do not include every skill by default. There are two supported paths:

1. Persistent/additive path: add the skill to `.agentic/profile.yaml`, run `agentic sync` to update AGENTS composition, then run `agentic deploy <profile> [target] <vendor>` to refresh `.agentic/skills/`.
2. Ad hoc selective path: pass explicit skills during deploy, for example `agentic deploy <profile> <target> <vendor> --skills <skill-name>`.

When `--skills` is used, it acts as a selective override for that deployment rather than deploying the full library skill set.
