# 🧩 agentic

A centralized, vendor-agnostic library for composing AI agent instructions — fork it, pick a profile, run one command, and every AI tool in your project reads the same source of truth.

![CI](https://github.com/soulcodex/agentic/actions/workflows/validate.yml/badge.svg)

---

## The Problem It Solves

Every project using AI coding tools ends up with a scatter of hand-written instruction files: a `CLAUDE.md` here, a `.github/copilot-instructions.md` there, a `.cursor/rules/` folder somewhere else. They drift apart, contradict each other, and get out of date. Onboarding a new tool means starting from scratch.

**agentic** treats agent instructions the way a design system treats UI components — you maintain one curated library of fragments, pick a named profile for each project, and the tooling assembles and distributes everything. Change a fragment once, redeploy, and every project stays consistent.

---

## Mental Model

This repo is to agentic configs what a design system is to UI components —
a library you **compose from**, not use directly.

Fragments from this repo are assembled into a single `AGENTS.md` and deployed
into target project repositories. Vendor-specific files are generated from that
canonical `AGENTS.md` and never edited manually.

```
agentic/ (this repo)
    agents/languages/typescript.md  ─┐
    agents/architecture/hexagonal.md ─┤──► compose ──► AGENTS.md ──► vendor-gen ──► target-project/
    agents/practices/tdd.md         ─┘                                              ├── AGENTS.md
                                                                                    ├── CLAUDE.md
                                                                                    ├── .github/copilot-instructions.md
                                                                                    ├── .github/instructions/*.instructions.md
                                                                                    └── .gemini/systemPrompt.md
```

---

## How It Works in 60 Seconds

1. **Fork this repo** — it becomes your team's instruction library.
2. **Pick a profile** — profiles are named presets that declare which fragments to compose.
3. **Run one command** — `just deploy` assembles and writes everything into your project.
4. **Done** — every AI tool reads its native file, all generated from the same source.

Concretely, for a TypeScript microservice:

```bash
just deploy typescript-hexagonal-microservice ~/code/my-api
```

This writes the following files into `~/code/my-api`:

```
my-api/
├── AGENTS.md                                  # canonical — read by Claude, Codex, and others
├── CLAUDE.md                                  # symlink → AGENTS.md (Claude Code)
├── .github/
│   ├── copilot-instructions.md                # global Copilot instructions
│   └── instructions/
│       └── typescript.instructions.md         # scoped to **/*.ts, **/*.tsx
└── .gemini/
    └── systemPrompt.md                        # Gemini CLI system prompt
```

No manual editing. No copy-pasting. Run `just deploy` again after updating a fragment to sync all projects.

---

## Available Profiles

| Profile | What it's for | Language | Key patterns |
|---|---|---|---|
| `typescript-hexagonal-microservice` | TypeScript backend service with NestJS | TypeScript | Hexagonal, DDD, CQRS, event-driven |
| `typescript-bff` | Backend-for-Frontend aggregation layer | TypeScript | BFF, microservices, stateless |
| `go-hexagonal-microservice` | Go backend microservice | Go | Hexagonal, DDD, explicit error handling |
| `python-fastapi-microservice` | FastAPI service with uv + Pydantic | Python | Hexagonal, microservices, full type annotations |
| `php-hexagonal-ddd` | PHP 8.3+ Symfony application | PHP | Hexagonal, DDD, CQRS, PHPStan level 8 |

Preview any profile without writing files:

```bash
just dry-run typescript-hexagonal-microservice
```

---

## Supported AI Tools

| Vendor | Output file(s) | How it's used |
|---|---|---|
| **Claude** (Claude Code) | `AGENTS.md`, `CLAUDE.md` | Reads `AGENTS.md` natively; `CLAUDE.md` is a symlink. Skills land in `.claude/skills/` |
| **GitHub Copilot** | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` | Global always-on instructions + glob-scoped per-language files with `applyTo` frontmatter |
| **OpenAI Codex** | `AGENTS.md` | Native passthrough — Codex reads `AGENTS.md` hierarchically (supports monorepo subdirectories) |
| **Gemini CLI** | `.gemini/systemPrompt.md` | All sections concatenated into a single system prompt file |

---

## Making It Your Own

The library is a pattern — the content is yours. Fork it and treat it as your team's living standard.

### Add a fragment

```bash
# 1. Create the file — one ## heading, self-contained, no cross-references
touch agents/practices/my-practice.md

# 2. Write your rules under a single ## heading
# 3. Rebuild the index
just index

# 4. Reference it in a profile or use it in a one-off compose
```

Fragment files follow a simple convention: one `## Heading` per file, plain Markdown, no hardcoded project names or paths.

### Add a profile

Profiles are YAML files in `profiles/`. Copy an existing one and adjust the fragment lists:

```yaml
name: My Custom Profile
description: What this profile is for.
version: 1.0.0
languages: [typescript]
architecture: [hexagonal]
practices: [tdd, api-design]
base: [git-conventions, security, code-review, testing-philosophy, documentation]
vendors: [claude, copilot, codex, gemini]
toolchain:
  build: pnpm build
  test: pnpm test --run
  lint: pnpm lint
```

Run `just lint` after adding a profile — it validates the schema.

### Add a skill

Skills are reusable agent task definitions. Create a directory under `skills/{group}/{name}/` with a `SKILL.md` file:

```bash
mkdir -p skills/development/my-skill
touch skills/development/my-skill/SKILL.md
just index   # rebuild the skill index
```

Deploy skills to a project:

```bash
just deploy-skills /path/to/project my-skill,code-review
# or all skills at once:
just deploy-skills /path/to/project all
```

### Add a vendor adapter

Add a directory under `vendors/{vendor}/` with an `adapter.json` following the schema in `vendors/_schema/adapter.schema.json`. The adapter declares output paths and how each section of `AGENTS.md` maps to the vendor's native format.

---

## Command Reference

### Discovery

```bash
just list-profiles          # list all available composition profiles
just list-skills            # list all available skills
just list-fragments         # list all available fragments
```

### Composition

```bash
just compose PROFILE TARGET         # assemble AGENTS.md into a target project
just dry-run PROFILE                # preview what would be composed (no files written)
just validate TARGET                # validate an assembled AGENTS.md in a project
just sync-check TARGET              # check if a project has drifted from the library
```

### Deployment

```bash
just deploy PROFILE TARGET                        # compose + vendor-gen + deploy skills
just deploy PROFILE TARGET code-review,write-adr  # same, with specific skills
just vendor-gen TARGET                            # generate vendor files only
just vendor-gen TARGET claude,copilot             # generate for specific vendors only
just deploy-skills TARGET skill1,skill2           # deploy specific skills
just deploy-skills TARGET all                     # deploy all skills
```

### Library maintenance

```bash
just lint                   # validate all fragments, profiles, and vendor adapters
just test                   # run the integration test suite
just index                  # rebuild index/skills.json and index/fragments.json
```

---

## Prerequisites

Run the setup command to check (and install on macOS) all required tools:

```bash
just setup
```

Or install manually:
- [just](https://github.com/casey/just) — command runner (`brew install just`)
- bash — macOS system `/bin/bash` 3.2+ works, no extra install needed
- [yq](https://github.com/mikefarah/yq) — YAML processor (`brew install yq`)
- [jq](https://stedolan.github.io/jq/) — JSON processor (`brew install jq`)

---

## Repository Structure

| Directory | Purpose |
|---|---|
| `agents/base/` | Universal fragments, always included |
| `agents/languages/` | Language-specific rules (TypeScript, Go, Python, PHP) |
| `agents/frameworks/` | Framework-specific rules |
| `agents/architecture/` | Architectural patterns (Hexagonal, DDD, CQRS, BFF, ...) |
| `agents/practices/` | Cross-cutting practices (TDD, API design, observability) |
| `agents/domains/` | Business-domain context (fintech, healthcare, SaaS) |
| `skills/` | Reusable agent skill definitions |
| `automations/` | n8n workflow exports and templates |
| `vendors/` | Vendor adapter configs and output templates |
| `profiles/` | Named composition presets (YAML) |
| `tooling/` | Assembly scripts (called via `just`) |
| `schemas/` | JSON Schemas for all structured files |
| `index/` | Auto-generated searchable indexes |

---

## Contributing / License

Contributions welcome — new fragments, profiles, vendor adapters, and skills. Run `just lint && just test` before opening a PR.

MIT
