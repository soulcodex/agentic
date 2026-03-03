# Command Reference

All commands are run from the agentic library root (`~/agentic` or wherever you cloned it).

## Discovery

```bash
just list-profiles          # list all available composition profiles
just list-skills            # list all available skills (with group, name, description)
just list-fragments         # list all available fragment files
```

## Composition

```bash
# Assemble AGENTS.md into a target project from a named profile (lean mode — default)
just compose PROFILE TARGET

# Preview what would be composed without writing any files
just dry-run PROFILE

# Validate an assembled AGENTS.md in a project
just validate TARGET

# Check if a project's config has drifted from the current library
just sync-check TARGET
```

**Lean mode** (default): copies fragment `.md` files to `TARGET/.agentic/fragments/` and writes a reference table in `AGENTS.md`. Agents load fragments on demand.

**Full mode**: embeds all fragment content inline into `AGENTS.md` — no separate fragment files needed:

```bash
just compose-full PROFILE TARGET
```

## Deployment

```bash
# Full pipeline: compose (lean) + vendor-gen + deploy skills
just deploy PROFILE TARGET
just deploy PROFILE TARGET code-review,write-adr   # with specific skills only

# Full pipeline with monolithic AGENTS.md
just deploy-full PROFILE TARGET

# Generate vendor-specific files only (from existing AGENTS.md)
just vendor-gen TARGET
just vendor-gen TARGET claude,copilot              # specific vendors only

# Deploy skill files only
just deploy-skills TARGET all
just deploy-skills TARGET code-review,write-adr

# Switch active AI vendor(s) via symlinks
just vendor-switch TARGET gemini
just vendor-switch TARGET claude,copilot           # activate multiple vendors
just vendor-switch TARGET list                     # show all vendors
```

## Library Maintenance

```bash
just lint                   # validate all fragments, profiles, adapters, and skills
just test                   # run the integration test suite (currently 97 assertions)
just index                  # rebuild index/skills.json and index/fragments.json
just setup                  # check (and install on macOS) required tools
```

## MCP Servers

```bash
just mcp-add TARGET                     # interactive wizard: add an MCP server
just mcp-remove TARGET SERVER_NAME      # remove an MCP server
just mcp-list TARGET                    # list all configured MCP servers
```

Writes `.mcp.json` in the target project and optionally syncs to `opencode.json` and `.gemini/settings.json`.

## Config Lock File

Every `just compose` or `just deploy` writes `TARGET/.agentic/config.yaml`:

```yaml
# Managed by agentic library — do not edit manually
library_commit: "abc123..."
profile: "golang-hexagonal-cobra-cli"
profile_version: "1.0.0"
composed_at: "2026-03-03T12:00:00Z"
mode: lean
library_path: "/Users/you/agentic"
active_vendors:
  - claude
  - copilot
structure: nested          # only for nested profiles
tiers: [backend, ui]       # only for nested profiles
```

The `library_path` and `active_vendors` fields power the `agentic` wrapper script placed in the target project root.
