# 🧩 agentic

A centralized, vendor-agnostic library for composing AI agent instructions — pick a profile, run one command, and every AI tool in your project reads the same source of truth.

![CI](https://github.com/soulcodex/agentic/actions/workflows/validate.yml/badge.svg)

---

## The Problem

**Without agentic**

```
my-project/
├── CLAUDE.md
├── .github/
│   └── copilot-instr.md
├── .cursor/rules/
│   └── *.mdc
└── .gemini/
    └── systemPrompt.md
```

**With agentic**

```
my-project/
├── AGENTS.md                        ← source of truth
├── CLAUDE.md                        ← symlink
├── .github/
│   └── copilot-instructions.md      ← symlink
├── .gemini/
│   ├── GEMINI.md                    ← auto-discovered
│   ├── system.md                    ← symlink
│   └── skills/                      ← symlink
└── .agentic/
    ├── config.yaml                  ← locked config
    ├── profile.yaml                 ← customize per-project
    ├── project-skills/              ← your custom skills
    ├── fragments/                   ← on-demand context
    ├── skills/                      ← deployed skills
    └── vendor-files/                ← generated once
        ├── claude/
        ├── copilot/
        └── gemini/
```

Instructions drift and contradict each other. Every new project starts from scratch. Adding a new AI tool means updating N files manually.

---

## Install

```bash
curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash
```

Installs the `agentic` CLI to `~/.local/bin`. Requires `bash`, `just`, `yq`, `jq` — run `just setup` from the library directory to check prerequisites.

---

## Deploy to a project

```bash
# See what profiles are available
agentic list profiles

# Deploy — assembles AGENTS.md, generates vendor files, deploys skills
agentic deploy typescript-hexagonal-microservice ~/code/my-api claude
```

Run `agentic sync` from within any project to regenerate from the local profile.

---

## Commands

```bash
agentic deploy <profile> [target] <vendors>   # full deploy pipeline
agentic compose <profile> [target]            # assemble AGENTS.md only
agentic switch [target] <vendors>             # switch active AI tool
agentic sync [target]                         # regenerate from local profile
agentic list profiles|skills|vendors          # list available resources
```

→ [Full command reference](https://agentic.soulcodex.link/commands)

---

## Profiles

15 ready-made profiles covering TypeScript, Go, Python, PHP — frontend SPAs, microservices, CLIs, full-stack.

→ [Browse all profiles](https://agentic.soulcodex.link/profiles)

---

## Supported AI Tools

Claude, GitHub Copilot, Gemini CLI, OpenAI Codex, Opencode — all from one `AGENTS.md`.

→ [Vendor details](https://agentic.soulcodex.link/vendors)

---

## Customise

Edit `.agentic/profile.yaml` and run `agentic sync` to update your project.
Add project-specific skills in `.agentic/project-skills/`.

→ [Customization guide](https://agentic.soulcodex.link/customization) · [Custom rules](https://agentic.soulcodex.link/custom-rules)

---

## Contributing

Contributions are welcome — new fragments, profiles, and skills.
See the contributing guide for authoring rules, quality checks, and commit conventions.

→ [Extending guide](https://agentic.soulcodex.link/extending) · [Contributing guide](.github/CONTRIBUTING.md)

---

## License

[MIT](LICENSE)
