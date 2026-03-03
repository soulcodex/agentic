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

Instructions drift and contradict each other. Every new project starts from scratch. Adding a new AI tool means updating N files manually.

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

Writes `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `.gemini/systemPrompt.md`, `opencode.json`, and `.agentic/config.yaml` into `~/code/my-api`. Run `just deploy` again after updating a fragment to sync all projects.

---

## Available Profiles

| Profile | What it's for | Language(s) |
|---|---|---|
| `typescript-hexagonal-microservice` | TypeScript backend service with Hono | TypeScript |
| `typescript-bff` | Backend-for-Frontend aggregation layer | TypeScript |
| `typescript-hexagonal-nuxt-vite-ui` | Hono backend + Nuxt 3 / Vue 3 (SSR) | TypeScript |
| `typescript-hexagonal-vue-vite-ui` | Hono backend + Vue 3 SPA (no SSR) | TypeScript |
| `go-hexagonal-microservice` | Go backend microservice | Go |
| `golang-hexagonal-nuxt-vite-ui` | Go backend + Nuxt 3 / Vue 3 (SSR) | Go + TypeScript |
| `golang-hexagonal-vue-vite-ui` | Go backend + Vue 3 SPA (no SSR) | Go + TypeScript |
| `golang-hexagonal-cobra-cli` | Go CLI tool with Cobra + Viper | Go |
| `python-fastapi-microservice` | FastAPI service with uv + Pydantic | Python |
| `python-hexagonal-typer-cli` | Python CLI tool with Typer + Rich | Python |
| `php-hexagonal-ddd` | PHP 8.3+ Symfony application | PHP |

[Full profile details, nested mode, and tier config →](docs/profiles.md)

---

## Supported AI Tools

| Vendor | Output file(s) |
|---|---|
| **Claude** (Claude Code) | `AGENTS.md`, `CLAUDE.md`, `.claude/skills/` |
| **GitHub Copilot** | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` |
| **OpenAI Codex** | `AGENTS.md` |
| **Gemini CLI** | `.gemini/systemPrompt.md` |
| **Opencode** | `AGENTS.md`, `opencode.json` |

[Vendor details, glob mechanism, and vendor-switch →](docs/vendors.md)

---

## Key Commands

```bash
just deploy PROFILE TARGET          # compose + vendor-gen + deploy skills
just dry-run PROFILE                # preview without writing files
just vendor-switch TARGET list      # show available vendors
just vendor-switch TARGET gemini    # switch active vendor
just lint && just test              # validate the library
```

<details>
<summary>Full command reference</summary>

See [docs/commands.md](docs/commands.md) for the complete reference including discovery, composition, deployment, maintenance, and MCP server commands.

</details>

---

## Extending

Add a fragment, profile, skill, or vendor adapter — all in plain Markdown and YAML.

[Extending guide →](docs/extending.md)

---

## Prerequisites & Contributing

Run `just setup` to check (and install on macOS) all required tools: `just`, `bash`, `yq`, `jq`.

Contributions welcome — new fragments, profiles, vendor adapters, and skills. Run `just lint && just test` before opening a PR.

MIT
