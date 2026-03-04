# Command Reference

## Global CLI

The `agentic` CLI provides a unified interface for managing agent instructions across all your projects.

### Installation

```bash
# From the agentic library directory
just install           # Installs to ~/.local/bin (default)
just install global    # Installs to /usr/local/bin (requires sudo)

# Uninstall
just uninstall         # Remove from ~/.local/bin
just uninstall global  # Remove from /usr/local/bin
```

After installation, ensure `~/.local/bin` is in your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Library Discovery

When you run `agentic` from any directory, it finds the library using this priority:

1. `AGENTIC_REPO_ROOT` environment variable
2. `AGENTIC_ROOT` environment variable (alias)
3. `agentic_root` key in `.agentic/config.yaml` (walks up from current directory)
4. Error with instructions

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
- `--skills LIST` — Deploy specific skills (default: all from profile)

**Examples:**
```bash
agentic deploy golang-hexagonal-cobra-cli ./my-cli claude
agentic deploy typescript-hexagonal-microservice . claude,copilot
agentic deploy python-fastapi-microservice gemini --full
```

### compose

Assemble AGENTS.md from a profile without generating vendor files.

```bash
agentic compose <profile> [target] [options]
```

**Options:**
- `--full` — Inline all fragment content

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

## Just Recipes (Legacy)

These recipes still work when run from the agentic library directory. They're useful
for library development and for users who haven't installed the global CLI.

### Discovery

```bash
just list-profiles          # List all available composition profiles
just list-skills            # List all available skills
just list-fragments         # List all available fragment files
```

### Composition

```bash
just compose PROFILE TARGET           # Compose AGENTS.md (lean mode)
just compose-full PROFILE TARGET      # Compose AGENTS.md (full mode)
just dry-run PROFILE                  # Preview without writing files
just validate TARGET                  # Validate AGENTS.md in a project
just sync-check TARGET                # Check for config drift
```

### Deployment

```bash
just deploy PROFILE TARGET VENDORS          # Full pipeline
just deploy-full PROFILE TARGET VENDORS     # Full pipeline (monolithic)
just vendor-gen TARGET [VENDORS]            # Generate vendor files only
just deploy-skills TARGET SKILLS VENDORS    # Deploy skills only
just vendor-switch TARGET VENDORS           # Switch active vendors
```

### Library Maintenance

```bash
just lint    # Validate fragments, profiles, adapters, skills
just test    # Run integration test suite
just index   # Rebuild index files
just setup   # Check/install required tools
```

### MCP Servers

```bash
just mcp-add TARGET                  # Add an MCP server (interactive)
just mcp-remove TARGET SERVER_NAME   # Remove an MCP server
just mcp-list TARGET                 # List configured MCP servers
```

---

## Migration from ./agentic Wrapper

If you have projects using the old `./agentic` wrapper script, follow these steps
to migrate to the global CLI.

### 1. Update the Library

```bash
cd ~/agentic-library   # or wherever you cloned it
git pull origin main
```

### 2. Install the Global CLI

```bash
just install
# Installs to ~/.local/bin — add to PATH if needed
```

### 3. Remove the Old Wrapper

For each project with the old wrapper:

```bash
cd /path/to/your-project
rm ./agentic                    # Remove the wrapper script

# Edit .gitignore to remove the /agentic line if present
```

### 4. Update Config (Automatic)

The old `library_path` key is now `agentic_root`. This updates automatically
on the next `agentic sync` or `agentic deploy`. You can also update manually:

```yaml
# In .agentic/config.yaml
# Old:
library_path: "/path/to/agentic"

# New:
agentic_root: "/path/to/agentic"
```

### 5. Verify

```bash
cd /path/to/your-project
agentic sync              # Should work from within project
agentic switch list       # Show available vendors
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
