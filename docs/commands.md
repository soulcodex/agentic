# Command Reference

## CLI Overview

The `agentic` CLI provides a unified interface for managing agent instructions
across all your projects.

### Installation

One-line install (installs to ~/.local/bin):

```bash
curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash
```

Ensure `~/.local/bin` is in your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Library Discovery

When you run `agentic` from any directory, it finds the library using this priority:

1. `AGENTIC_REPO_ROOT` environment variable
2. `AGENTIC_ROOT` environment variable (alias)
3. `agentic_root` key in `.agentic/config.yaml` (walks up from current directory)
4. Install-time `LIBRARY_ROOT` (embedded by installer)
5. Error with instructions

### Target Auto-detection

Most commands accept an optional `[target]` argument. When omitted, agentic searches
for `.agentic/config.yaml` in the current directory or parent directories.

```bash
# Explicit target
agentic sync /path/to/my-project

# Auto-detected (run from within project)
cd /path/to/my-project
agentic sync
```

---

## Commands

### deploy

Full deployment pipeline: compose + vendor-gen + deploy skills + activate vendors.

```bash
agentic deploy <profile> [target] <vendors> [options]
```

| Argument | Required | Description |
|---|---|---|
| `profile` | ✅ | Profile name — see `agentic list profiles` |
| `target` | optional | Project directory, auto-detected from current dir if omitted |
| `vendors` | ✅ | Comma-separated vendors to activate: `claude`, `copilot`, `gemini`, `codex`, `opencode` |

| Option | Description |
|---|---|
| `--full` | Inline all fragment content into a monolithic `AGENTS.md` |
| `--link` | Use symlinks instead of file copies (POSIX only, not Windows without WSL) |
| `--skills LIST` | Deploy specific skills only (default: all skills declared in the profile) |

**Examples:**
```bash
agentic deploy golang-hexagonal-cobra-cli ./my-cli claude
agentic deploy typescript-hexagonal-microservice . claude,copilot
agentic deploy python-fastapi-microservice gemini --full
```

> **Link mode (`--link`):** Creates POSIX symlinks instead of copying files — POSIX only,
> not supported on Windows without WSL. The target repo stays minimal: only `config.yaml`,
> `profile.yaml`, and `project-skills/` are committed; fragments, skills, and vendor-files
> are live symlinks to the library. Run `agentic sync` to re-create broken symlinks.

### compose

Assemble AGENTS.md from a profile without generating vendor files.

```bash
agentic compose <profile> [target] [options]
```

| Argument | Required | Description |
|---|---|---|
| `profile` | ✅ | Profile name — see `agentic list profiles` |
| `target` | optional | Project directory, auto-detected from current dir if omitted |

| Option | Description |
|---|---|
| `--full` | Inline all fragment content into a monolithic `AGENTS.md` |
| `--link` | Use symlinks instead of file copies (POSIX only, not Windows without WSL) |

**Examples:**
```bash
agentic compose golang-hexagonal-cobra-cli ./my-cli
agentic compose typescript-hexagonal-microservice --full
```

### init

Scaffold a local `.agentic/` skeleton for a custom profile workflow.

```bash
agentic init [target] [options]
```

| Argument | Required | Description |
|---|---|---|
| `target` | optional | Project directory, defaults to current directory |

| Option | Description |
|---|---|
| `--sync` | Run `agentic sync` immediately after scaffolding |
| `--no-sync` | Skip sync after scaffolding |

Creates:

- `.agentic/config.yaml`
- `.agentic/profile.yaml`
- `.agentic/mcp.yaml`
- `.agentic/project-skills/`

**Examples:**
```bash
agentic init
agentic init ./my-project
agentic init ./my-project --sync
```

Library recipe equivalent:

```bash
just init /path/to/project
```

### switch

Switch active vendor(s) via symlinks.

```bash
agentic switch [target] <vendors>
agentic switch [target] list
```

**Examples:**
```bash
agentic switch claude              # Activate only Claude
agentic switch gemini              # Activate only Gemini
agentic switch claude,copilot      # Activate multiple vendors
agentic switch list                # Show available vendors
```

### sync

Regenerate AGENTS.md and vendor files from the local `.agentic/profile.yaml`.

```bash
agentic sync [target]
```

Active vendors are preserved after regeneration.

**Examples:**
```bash
agentic sync                # Auto-detect target from current directory
agentic sync ./my-project   # Explicit target
```

During sync, MCP seeding uses `.agentic/mcp.yaml` first. If absent, a legacy
`mcp:` block inside `.agentic/profile.yaml` is still supported (deprecated).

### list

List available resources.

```bash
agentic list <resource>
```

| Argument | Required | Description |
|---|---|---|
| `resource` | ✅ | Resource type to list: `profiles`, `skills`, `fragments`, or `vendors` |

**Examples:**
```bash
agentic list profiles
agentic list skills
agentic list vendors
```

### uninstall

Remove the `agentic` CLI binary from your PATH.

```bash
agentic uninstall           # remove from ~/.local/bin (default)
agentic uninstall --global  # remove from /usr/local/bin (requires sudo)
```

This removes only the CLI binary. The library directory (`~/.local/share/agentic`)
is left untouched — reinstall at any time with the one-line installer.
To fully remove the library: `rm -rf ~/.local/share/agentic`
