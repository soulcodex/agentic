# Quickstart

## 1. List available profiles

```bash
agentic list profiles
```

## 2. Deploy to your project

Choose a profile that matches your stack and deploy:

```bash
# TypeScript hexagonal microservice with Claude
agentic deploy typescript-hexagonal-microservice ~/code/my-api claude

# Go + Vue 3 SPA with multiple vendors
agentic deploy golang-hexagonal-vue-vite-ui ~/code/my-app claude,copilot

# Standalone Nuxt 3 app with Gemini
agentic deploy typescript-nuxt-app ~/code/my-site gemini
```

This writes to your project:

- `AGENTS.md` — the assembled source of truth
- Vendor entry-point files (`CLAUDE.md`, `.github/copilot-instructions.md`, etc.)
- `.agentic/config.yaml` — locked config (commit this)
- `.agentic/profile.yaml` — your profile (commit this)
- `.agentic/fragments/` — on-demand context files

## 3. Regenerate after library updates

```bash
cd ~/code/my-api
agentic sync
```

Reads `.agentic/profile.yaml` and regenerates `AGENTS.md` and all vendor files.
Active vendors are preserved.

## Optional: start with a custom local profile

```bash
agentic init ~/code/my-api
agentic sync ~/code/my-api
```

This scaffolds `.agentic/profile.yaml` and `.agentic/mcp.yaml` so you can
customize fragments, commands, skills, and MCP servers from scratch.

## 4. Switch active vendor

```bash
agentic switch claude          # activate only Claude
agentic switch claude,copilot  # activate multiple vendors
agentic switch list            # show available vendors
```

## 5. What to commit

After deploying, commit these files from your project:

| File / Directory | Commit? |
|---|---|
| `AGENTS.md` | yes — source of truth |
| `.agentic/config.yaml` | yes — reproducibility anchor |
| `.agentic/profile.yaml` | yes — your customisation |
| `.agentic/mcp.yaml` | yes — MCP source-of-truth |
| `.agentic/project-skills/` | yes — your custom skills |
| `CLAUDE.md`, `GEMINI.md`, vendor symlinks | no — recreated by `agentic sync` |
| `.agentic/skills/`, `.agentic/fragments/`, `.agentic/vendor-files/` | no (link mode) / yes (copy mode) |

!!! tip
    `agentic deploy` automatically injects the correct `.gitignore` entries so you
    never have to figure this out manually.
