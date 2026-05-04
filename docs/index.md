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

Installs the `agentic` CLI to `~/.local/bin`. The installer checks prerequisites and offers to install any that are missing.

---

<div class="grid cards" markdown>

-   :material-puzzle:{ .lg .middle } **One source of truth**

    ---

    Write `AGENTS.md` once. Every AI tool reads the same instructions — no drift, no duplication.

-   :material-lightning-bolt:{ .lg .middle } **Deploy in one command**

    ---

    Pick a profile and run `agentic deploy`. Claude, Copilot, Gemini, Codex and Opencode all configured instantly.

-   :material-shape:{ .lg .middle } **21 ready-made profiles**

    ---

    TypeScript, Go, Python, PHP — microservices, CLIs, SPAs, full-stack. Start from a proven template, customise from there.

-   :material-brain:{ .lg .middle } **Skills system**

    ---

    Reusable agent task definitions. Deploy shared skills from the library or add project-local ones in `.agentic/project-skills/`.

-   :material-file-document-edit:{ .lg .middle } **Agents Orchestration Switching**

    ---

    Keep `agents.yaml` optional. Opt in per project to define agents orchestration with preflighted, local-only sync.

-   :material-shield-check:{ .lg .middle } **Safe by default**

    ---

    Preflight checks run before writes. Conflict and validation failures stop early so unmanaged files are never mutated.

</div>

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

> **Agents orchestration switching:** optional, project-local agent orchestration is documented in [Agents Orchestration Switching](agents.md).

## Sections

- [**Installation**](getting-started/installation.md) — one-line install, manual install, prerequisites
- [**Quickstart**](getting-started/quickstart.md) — deploy examples, sync, vendor switching
- [**Commands**](commands.md) — full CLI reference
- [**Profiles**](profiles.md) — all available profiles and their fragments
- [**Skills**](skills.md) — shared skill catalog plus persistent and ad hoc (selective) skill usage paths
- [**Vendors**](vendors.md) — supported AI tools and their output files
- [**Agents Orchestration Switching**](agents.md) — opt-in, project-local agent orchestration via `.agentic/agents.yaml`
- [**Customization**](customization.md) — per-project overrides, project skills, proprietary libraries, link mode vs copy mode
- [**Custom Rules**](custom-rules.md) — `AGENTS.local.md` injection
