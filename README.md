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
├── CLAUDE.md                ├── AGENTS.md               ← source of truth
├── .github/                 ├── CLAUDE.md               ← symlink
│   └── copilot-instr.md     ├── .github/
├── .cursor/rules/           │   └── copilot-instr.md    ← symlink
│   └── *.mdc                ├── .gemini/
└── .gemini/                 │   └── systemPrompt.md     ← symlink
    └── systemPrompt.md      └── .agentic/
                                 ├── config.yaml         ← locked config
                                 ├── profile.yaml        ← customize per-project
                                 ├── project-skills/     ← your custom skills
                                 ├── fragments/          ← on-demand context
                                 ├── skills/             ← deployed skills
                                 └── vendor-files/       ← generated once
                                     ├── claude/
                                     ├── copilot/
                                     └── gemini/
```

Instructions drift and contradict each other. Every new project starts from scratch. Adding a new AI tool means updating N files manually.

Customize per-project with local profiles and project-specific skills → [docs/customization.md](docs/customization.md)

---

## Quickstart

### One-line Install

```bash
curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash
```

This clones the library to `~/.local/share/agentic` and installs the `agentic` CLI to `~/.local/bin`.

### Manual Install (for forking)

```bash
# 1. Fork this repo — it becomes your team's instruction library
git clone https://github.com/your-org/agentic ~/agentic-library

# 2. Install the global CLI
cd ~/agentic-library
just install
# (installs to ~/.local/bin — add to PATH if needed)
```

### Deploy to a Project

```bash
# List available profiles
agentic list profiles

# Deploy to your project
agentic deploy typescript-hexagonal-microservice ~/code/my-api claude
```

Writes `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `.gemini/systemPrompt.md`, `opencode.json`, and `.agentic/config.yaml` into `~/code/my-api`. Run `agentic sync` from within any project to regenerate from local profile.

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
# Global CLI (install with: just install)
agentic deploy PROFILE TARGET VENDORS    # compose + vendor-gen + deploy skills
agentic compose PROFILE [TARGET]         # assemble AGENTS.md from profile
agentic switch [TARGET] VENDORS          # switch active vendor(s)
agentic sync [TARGET]                    # regenerate from local profile
agentic list profiles|skills|vendors     # list available resources

# Legacy just recipes (still work from library dir)
just deploy PROFILE TARGET VENDORS       # same as agentic deploy
just dry-run PROFILE                     # preview without writing files
just lint && just test                   # validate the library
```

<details>
<summary>Full command reference</summary>

See [docs/commands.md](docs/commands.md) for the complete reference including discovery, composition, deployment, maintenance, and MCP server commands.

</details>

---

## Extending

Add a fragment, profile, skill, or vendor adapter — all in plain Markdown and YAML.

**Project-local skills**: Create project-specific skills in `.agentic/project-skills/` and reference them with the `project:` prefix. See the extending guide for details.

[Extending guide →](docs/extending.md)

---

## Prerequisites & Contributing

Run `just setup` to check (and install on macOS) all required tools: `just`, `bash`, `yq`, `jq`.

Contributions are welcome — new fragments, profiles, vendor adapters, and skills. Please see our [Contributing Guide](.github/CONTRIBUTING.md) for details on how to set up the development environment, run quality checks, and submit pull requests. Run `just lint && just test` before opening a PR.

---

## License

This project is licensed under the [MIT License](LICENSE).
