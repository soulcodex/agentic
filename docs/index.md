# Agentic

**One library. One deploy. All your AI tools stay in sync.**

A centralized, vendor-agnostic library for composing AI agent instructions.
Pick a profile, run one command, and every AI tool in your project reads the
same `AGENTS.md` source of truth — automatically.

---

## Install

```bash
curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash
```

Installs the `agentic` CLI to `~/.local/bin`. Requires `bash`, `just`, `yq`, `jq`.
The installer auto-detects missing prerequisites and offers to install them.

---

## What it does

| Without agentic | With agentic |
|---|---|
| Maintain `CLAUDE.md`, `.github/copilot-instructions.md`, `.gemini/systemPrompt.md`… separately | Maintain one `AGENTS.md` — all vendor files are generated or symlinked automatically |
| Every new project starts from scratch | Pick a profile, deploy in one command |
| Adding a new AI tool means updating N files | Run `agentic switch <vendor>` |

---

## Deploy to a project

```bash
# See available profiles
agentic list profiles

# Deploy — composes AGENTS.md, generates vendor files, deploys skills
agentic deploy typescript-hexagonal-microservice ~/code/my-api claude
```

---

## Sections

- [**Installation**](getting-started/installation.md) — one-line install, manual install, prerequisites
- [**Quickstart**](getting-started/quickstart.md) — deploy examples, sync, vendor switching
- [**Commands**](commands.md) — full CLI reference
- [**Profiles**](profiles.md) — all available profiles and their fragments
- [**Vendors**](vendors.md) — supported AI tools and their output files
- [**Customization**](customization.md) — per-project overrides, project skills, proprietary libraries, link mode vs copy mode
- [**Custom Rules**](custom-rules.md) — `AGENTS.local.md` injection
