# 🧩 agentic

A centralized, vendor-agnostic library for composing AI agent instructions — fork it, pick a profile, run one command, and every AI tool in your project reads the same source of truth.

![CI](https://github.com/soulcodex/agentic/actions/workflows/validate.yml/badge.svg)

One library. One deploy. All your AI tools stay in sync.

---

## The Problem

```
Without agentic              With agentic
─────────────────────────    ────────────────────────────────────
my-project/                  my-project/
├── CLAUDE.md                ├── AGENTS.md       ← one source
├── .github/                 ├── CLAUDE.md       ← generated
│   └── copilot-instr.md     ├── .github/        ← generated
├── .cursor/rules/           │   └── copilot-instr.md
│   └── *.mdc                ├── .gemini/        ← generated
└── .gemini/                 │   └── systemPrompt.md
    └── systemPrompt.md      └── .agentic/config.yaml ← locked
```

- Instructions drift and contradict each other across tools
- Every new project means starting from scratch
- Adding a new AI tool means updating N files manually

---

## Quickstart

```bash
# 1. Fork this repo — it becomes your team's instruction library
git clone https://github.com/your-org/agentic ~/agentic

# 2. Pick a profile
just list-profiles

# 3. Deploy to your project
just deploy typescript-hexagonal-microservice ~/code/my-api
```

Writes into `~/code/my-api`:

```
my-api/
├── AGENTS.md                           # canonical — Claude, Codex, Opencode
├── CLAUDE.md                           # symlink → AGENTS.md (Claude Code)
├── opencode.json                       # Opencode config
├── .github/
│   ├── copilot-instructions.md
│   └── instructions/
│       └── typescript.instructions.md
└── .gemini/
    └── systemPrompt.md
```

No manual editing. Run `just deploy` again after updating a fragment to sync all projects.

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

```bash
just dry-run typescript-hexagonal-microservice
```

---

## Mental Model

### Library structure

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

### Pipeline

```
step 1 — just compose
┌──────────────────────────────────────────────────────────────┐
│ PROFILE (my-profile.yaml)                                    │
│                                                              │
│  fragments:   agents/base/*.md                               │
│               agents/languages/go.md                         │
│               agents/frameworks/cobra.md                     │
│               agents/architecture/hexagonal.md               │
│               agents/practices/tdd.md                        │
│                                                              │
│  tech_stack:  Go 1.23+, Cobra + Viper                        │
│  skills:      [code-review, write-adr]                       │
└──────────────────────────────┬───────────────────────────────┘
                               │
                               ▼
              ┌────────────────────────────────────┐
              │ AGENTS.md  (canonical)             │
              │                                    │
              │  ## Commands                       │
              │  ## Technical Stack  ◄ tech_stack  │
              │  ## Git Conventions  ◄ base/       │
              │  ## Go               ◄ languages/  │
              │  ## Cobra CLI        ◄ frameworks/ │
              │  ## Hexagonal Arch.  ◄ architecture│
              │  ## TDD              ◄ practices/  │
              │  ## Skills listing   ◄ skills[]    │
              └──────────────┬─────────────────────┘
                             │
               ┌─────────────┴──────────────┐
               │                            │
               ▼                            ▼
  step 2 — just vendor-gen      step 3 — just deploy-skills
  ─────────────────────────     ─────────────────────────────
  CLAUDE.md                     .claude/skills/
  .github/copilot-instr.md          code-review/SKILL.md
  .gemini/systemPrompt.md           write-adr/SKILL.md
  opencode.json
               │                            │
               └────────────────────────────┘
                             │
                             ▼
              ~/code/my-project/
              .agentic/config.yaml  ← version lock
```

> **Tip:** `just compose-full PROFILE TARGET` embeds full skill content inline into `AGENTS.full.md` — useful when the target tool doesn't support on-demand file reads.

---

## Supported AI Tools

| Vendor | Output file(s) | How it's used |
|---|---|---|
| **Claude** (Claude Code) | `AGENTS.md`, `CLAUDE.md` | `AGENTS.md` natively; `CLAUDE.md` symlink; skills in `.claude/skills/` |
| **GitHub Copilot** | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` | Global instructions + glob-scoped per-language files |
| **OpenAI Codex** | `AGENTS.md` | `AGENTS.md` natively; hierarchical for monorepos |
| **Gemini CLI** | `.gemini/systemPrompt.md` | Single system prompt file |
| **Opencode** | `AGENTS.md`, `opencode.json` | `AGENTS.md` + `opencode.json`; skills in `.claude/skills/` |

---

## Extending

### Add a fragment

One `## Heading` per file, plain Markdown, no hardcoded project names or paths.

```bash
touch agents/practices/my-practice.md
# write your rules, then:
just index
```

### Add a profile

Copy an existing profile and adjust the fragment lists.

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

Run `just lint` after adding a profile.

### Add a skill

Skills are reusable agent task definitions in `skills/{group}/{name}/SKILL.md`.

```bash
mkdir -p skills/development/my-skill
touch skills/development/my-skill/SKILL.md
just index
```

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
just mcp-add TARGET                     # interactive wizard: add an MCP server
just mcp-remove TARGET SERVER_NAME      # remove an MCP server
just mcp-list TARGET                    # list all configured MCP servers
```

Writes `.mcp.json` in the target project and optionally syncs to `opencode.json` and `.gemini/settings.json`.

---

## Prerequisites & Contributing

Run `just setup` to check (and install on macOS) all required tools: `just`, `bash`, `yq`, `jq`.

Contributions welcome — new fragments, profiles, vendor adapters, and skills. Run `just lint && just test` before opening a PR.

MIT
