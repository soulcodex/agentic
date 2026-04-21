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

**Arguments:**
- `profile` — Name of the profile (see `agentic list profiles`)
- `target` — Project directory (auto-detected if omitted)
- `vendors` — Comma-separated vendors to activate (e.g., `claude,copilot`)

**Options:**
- `--full` — Inline all fragment content (monolithic AGENTS.md)
- `--link` — Use symlinks instead of file copies (POSIX only; see Link Mode section below)
- `--skills LIST` — Deploy specific skills (default: all from profile)

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

**Options:**
- `--full` — Inline all fragment content
- `--link` — Use symlinks instead of file copies (POSIX only)

**Examples:**
```bash
agentic compose golang-hexagonal-cobra-cli ./my-cli
agentic compose typescript-hexagonal-microservice --full
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

### list

List available resources.

```bash
agentic list <resource>
```

**Resources:**
- `profiles` — Available composition profiles
- `skills` — Available skills (group, name, description)
- `fragments` — Available fragment files
- `vendors` — Supported vendor adapters

**Examples:**
```bash
agentic list profiles
agentic list skills
agentic list vendors
```

---

## Config Lock File

Every `agentic deploy` or `agentic compose` writes `TARGET/.agentic/config.yaml`:

```yaml
# Managed by agentic library — do not edit manually
library_commit: "abc123..."
profile: "golang-hexagonal-cobra-cli"
profile_version: "1.0.0"
composed_at: "2026-03-03T12:00:00Z"
mode: lean
agentic_root: "/Users/you/agentic"
active_vendors:
  - claude
  - copilot
structure: nested          # only for nested profiles
tiers: [backend, ui]       # only for nested profiles
```

The `agentic_root` and `active_vendors` fields enable the global CLI to work
from any directory within your project.
