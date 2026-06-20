# Vendors

agentic generates vendor-specific instruction files from a single `AGENTS.md` source of truth.

## Supported Vendors

| Vendor | Output file(s) | How it's used |
|---|---|---|
| **Claude** (Claude Code) | `AGENTS.md`, `CLAUDE.md` | `AGENTS.md` natively; `CLAUDE.md` is a thin wrapper pointing to it; skills in `.claude/skills/` |
| **GitHub Copilot** | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` | Global always-on instructions + glob-scoped per-language files |
| **OpenAI Codex** | `AGENTS.md` | `AGENTS.md` natively; hierarchical for monorepos (tier AGENTS.md files) |
| **Gemini CLI** | `GEMINI.md`, `.gemini/system.md` | Root context file (auto-discovered) + system-prompt override |
| **Opencode** | `AGENTS.md` | `AGENTS.md` natively; skills in `.opencode/skills/` |
| **Cursor** | `.cursor/rules/*.mdc` | Rules model with one always-on core rule + auto-attached language rules |

## How Each Vendor Uses AGENTS.md

### Claude Code

Claude Code reads `AGENTS.md` natively. In lean mode, `CLAUDE.md` is a redirect stub that points to the `AGENTS.md` file. Skills are deployed to `.claude/skills/` where Claude can load them on demand with `@.claude/skills/code-review/SKILL.md`.

### GitHub Copilot

Copilot does not read `AGENTS.md` natively. The adapter transforms it into two
Copilot-native surfaces:

| Output | Purpose |
|---|---|
| `.github/copilot-instructions.md` | Always-on global guidance (security, git conventions, code review, testing philosophy, documentation) |
| `.github/instructions/*.instructions.md` | Glob-scoped guidance activated per file pattern |

Language-specific guidance (TypeScript, Go, Python, PHP) is emitted into
`.github/instructions/*.instructions.md` with frontmatter such as:
- `applyTo: "**/*.ts"`
- `applyTo: "**/*.go"`

The adapter reads the mapping from `vendors/copilot/adapter.json`.

### Copilot Glob Mechanism

Language files in `.github/instructions/` are activated by `applyTo` globs.

```markdown
---
applyTo: "**/*.go"
---
```

### Gemini CLI

Gemini CLI auto-discovers `GEMINI.md` at the project root — no environment variables
required. The vendor adapter also generates `.gemini/system.md` as a full
system-prompt override; set `GEMINI_SYSTEM_MD=1` to activate it.
Skills are deployed natively to `.gemini/skills/` and activated lazily via the
`activate_skill` tool, keeping the initial context lean.

### Opencode

Opencode reads `AGENTS.md` natively. Skills are deployed to `.opencode/skills/`.

### Cursor

Cursor uses `.cursor/rules/*.mdc` as its runtime rules surface.

- The adapter generates canonical artifacts under:
  - `.agentic/vendor-files/cursor/rules/`
- `agentic switch cursor` links only:
  - `.cursor/rules` → `.agentic/vendor-files/cursor/rules`
- This is intentionally rules-only, so unrelated `.cursor/*` files are preserved
  (for example `.cursor/mcp.json`).

For nested profiles:

- `vendor-gen` also generates tier-specific rule trees at:
  - `.agentic/vendor-files/cursor/rules/<tier>/`

Safety and recovery behavior:

- If a real `.cursor/rules` directory already exists, switch migrates it to:
  - `.cursor/rules.backup`, then `.cursor/rules.backup.N` on subsequent collisions.
- If a multi-vendor switch fails after mutations start, agentic rolls back:
  - prior symlinks/config state, and
  - any migrated Cursor rules directories.

Scope boundary:

- Cursor provider/model mapping is intentionally unsupported until Cursor
  publishes an official project-local contract for that configuration surface.

## MCP Pivot Model

MCP server declarations are authored once in `.agentic/mcp.yaml` and then
translated per vendor when `agentic compose` / `agentic sync` runs.

Source file:

- `.agentic/mcp.yaml` (`strategy` + `servers`)

Generated targets:

- `.mcp.json` uses `mcpServers` (Claude-compatible shape)
- `opencode.json` uses `mcp` with translated transport keys
- `.gemini/settings.json` uses `mcpServers` with Gemini-specific field mapping
- `.cursor/mcp.json` uses `mcpServers` (Cursor-compatible project shape)
- existing `opencode.json`, if present, uses `mcp` with translated transport
  keys

Source of truth:

- `.agentic/mcp.yaml` (authoritative)

## Vendor Commands

### Generate Vendor Files

```bash
# Using global CLI (from anywhere)
agentic deploy <profile> [target] <vendors>
```

### Switch Active Vendors

Switch which vendors are active via symlinks. Vendor files are stored in
`.agentic/vendor-files/{vendor}/` and activated by symlinking to their
expected locations.

```bash
# Using global CLI (from anywhere)
agentic switch claude                # Activate only Claude
agentic switch gemini                # Activate only Gemini
agentic switch claude,copilot        # Activate multiple vendors
agentic switch list                  # Show all vendors

# With explicit target
agentic switch /path/to/project gemini
```

Multiple vendors can be active simultaneously since their symlink paths don't conflict:

| Vendor | Symlink locations |
|--------|-------------------|
| `claude` | `CLAUDE.md`, `.claude/skills` |
| `copilot` | `.github/copilot-instructions.md`, `.github/instructions/` |
| `codex` | `.agents/skills`, `.codex/agents` (reads `AGENTS.md` natively) |
| `gemini` | `GEMINI.md`, `.gemini/system.md`, `.gemini/skills` |
| `opencode` | `.opencode/skills`, `.opencode/agents` |
| `cursor` | `.cursor/rules` |

For orchestration switching, `agents` are declared in `.agentic/agents.yaml`, and provider-local `subagents` paths (`.codex/agents`, `.opencode/agents`) are symlinks to generated artifacts under `.agentic/agents/{provider}/`.
