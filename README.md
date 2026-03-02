# 🧩 agentic

A centralized, vendor-agnostic library for composing AI agent instructions — fork it, pick a profile, run one command, and every AI tool in your project reads the same source of truth.

![CI](https://github.com/soulcodex/agentic/actions/workflows/validate.yml/badge.svg)

---

## The Problem It Solves

Every project using AI coding tools ends up with a scatter of hand-written instruction files: a `CLAUDE.md` here, a `.github/copilot-instructions.md` there, a `.cursor/rules/` folder somewhere else. They drift apart, contradict each other, and get out of date. Onboarding a new tool means starting from scratch.

**agentic** treats agent instructions the way a design system treats UI components — you maintain one curated library of fragments, pick a named profile for each project, and the tooling assembles and distributes everything. Change a fragment once, redeploy, and every project stays consistent.

---

## Mental Model

This repo is to agentic configs what a design system is to UI components — a library you **compose from**, not a tool you run inside projects. You declare *what you want* in a profile; the tooling assembles, distributes, and version-locks everything.

### What the library contains

```
agentic/  (this repo — fork it, make it yours)
│
├── profiles/                    ← entry point: named composition presets
│   └── my-profile.yaml
│       ├── fragments:            which building blocks to include
│       ├── tech_stack:           runtime, frameworks, tools  (optional)
│       ├── skills:               on-demand agent tasks       (optional)
│       └── output:               build / test / lint commands
│
├── agents/                      ← composable Markdown building blocks
│   ├── base/                     git, security, testing philosophy, docs
│   ├── languages/                go, typescript, python, php
│   ├── frameworks/               vue, nuxt, cobra, typer …
│   ├── architecture/             hexagonal, ddd, cqrs, eda …
│   └── practices/                tdd, api-design, observability …
│
├── skills/                      ← agent task definitions (loaded on demand)
│   ├── development/              code-review, add-tests, fix-bug …
│   └── documentation/            write-adr, write-readme, write-changelog …
│
└── vendors/                     ← per-tool output adapters
    └── claude / copilot / codex / gemini / opencode
```

### How `just deploy` works

```
PROFILE (my-profile.yaml)
 │
 ├─ fragments:                           ┐
 │    agents/base/*.md                   │
 │    agents/languages/go.md             │
 │    agents/frameworks/cobra.md         │  step 1 — just compose
 │    agents/architecture/hexagonal.md   │
 │    agents/practices/tdd.md            │
 │                                       │
 ├─ tech_stack: Go 1.23+, Cobra + Viper  │
 │                                       │
 └─ skills: [code-review, write-adr]    ─┘
                    │
                    ▼
         AGENTS.md  (canonical source of truth)
         ├── ## Commands
         ├── ## Technical Stack     ◄── tech_stack
         ├── ## Git Conventions     ◄── agents/base/
         ├── ## Go                  ◄── agents/languages/
         ├── ## Cobra CLI (Go)      ◄── agents/frameworks/
         ├── ## Hexagonal Arch.     ◄── agents/architecture/
         ├── ## TDD                 ◄── agents/practices/
         └── ## Skills listing      ◄── skills[]
                    │
                    ├──► step 2 — just vendor-gen
                    │         CLAUDE.md
                    │         .github/copilot-instructions.md
                    │         .gemini/systemPrompt.md
                    │         opencode.json
                    │
                    └──► step 3 — just deploy-skills
                              .claude/skills/
                                  code-review/SKILL.md
                                  write-adr/SKILL.md

              ~/code/my-project/        ← all files land here
              .agentic/config.yaml      ← profile + library version lock
```

> **Tip:** `just compose-full PROFILE TARGET` embeds complete skill content inline into `AGENTS.full.md` instead of a path listing — useful when the target tool doesn't support on-demand file reads.

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
├── AGENTS.md                                  # canonical — read by Claude, Codex, Opencode, and others
├── CLAUDE.md                                  # symlink → AGENTS.md (Claude Code)
├── opencode.json                              # Opencode config: model, permissions, MCP block
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
| `typescript-hexagonal-microservice` | TypeScript backend service with Hono | TypeScript | Hexagonal, DDD, CQRS, event-driven |
| `typescript-bff` | Backend-for-Frontend aggregation layer | TypeScript | BFF, microservices, stateless |
| `typescript-hexagonal-nuxt-vite-ui` | Hono backend + Nuxt 3 / Vue 3 frontend | TypeScript | Hexagonal, DDD, SSR, Vite, Vitest |
| `typescript-hexagonal-vue-vite-ui` | Hono backend + Vue 3 SPA frontend | TypeScript | Hexagonal, DDD, Vite, Vitest |
| `go-hexagonal-microservice` | Go backend microservice | Go | Hexagonal, DDD, explicit error handling |
| `golang-hexagonal-nuxt-vite-ui` | Go backend + Nuxt 3 / Vue 3 frontend | Go + TypeScript | Hexagonal, DDD, SSR, Vite, Vitest |
| `golang-hexagonal-vue-vite-ui` | Go backend + Vue 3 SPA frontend | Go + TypeScript | Hexagonal, DDD, Vite, Vitest |
| `golang-hexagonal-cobra-cli` | Go CLI tool with Cobra + Viper | Go | Hexagonal, DDD, testable commands |
| `python-fastapi-microservice` | FastAPI service with uv + Pydantic | Python | Hexagonal, microservices, full type annotations |
| `python-hexagonal-typer-cli` | Python CLI tool with Typer + Rich | Python | Hexagonal, DDD, type-annotation contract |
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
| **Opencode** | `AGENTS.md`, `opencode.json` | Reads `AGENTS.md` natively; `opencode.json` generated with model defaults, permission settings, and empty MCP block. Skills land in `.claude/skills/` (Opencode reads this path for Claude compatibility) |

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

### MCP servers

```bash
just mcp-add TARGET                     # interactive wizard: add an MCP server to a project
just mcp-remove TARGET SERVER_NAME      # remove an MCP server from a project
just mcp-list TARGET                    # list all configured MCP servers in a project
```

Writes `.mcp.json` in the target project (Claude standard format) and optionally syncs to `opencode.json` and `.gemini/settings.json`.

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
