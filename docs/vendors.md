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

## How Each Vendor Uses AGENTS.md

### Claude Code

Claude Code reads `AGENTS.md` natively. In lean mode, `CLAUDE.md` is a redirect stub that points to the `AGENTS.md` file. Skills are deployed to `.claude/skills/` where Claude can load them on demand with `@.claude/skills/code-review/SKILL.md`.

### GitHub Copilot

Copilot does not read `AGENTS.md` natively. The vendor adapter splits `AGENTS.md` into:
- **`.github/copilot-instructions.md`** — always-on global instructions (security, git conventions, code review, testing philosophy, documentation).
- **`.github/instructions/*.instructions.md`** — glob-scoped files that activate per file pattern. The language-specific sections (TypeScript, Go, Python, PHP) are placed here with `applyTo: "**/*.ts"` etc.

The adapter reads the mapping from `vendors/copilot/adapter.json`.

### Copilot Glob Mechanism

Each language instruction file has frontmatter that tells Copilot when to apply it:

```markdown
---
applyTo: "**/*.go"
---
## Go

[Go-specific guidelines here]
```

This means the Go conventions are injected only when Copilot is working on `.go` files, keeping the global context lean.

### Gemini CLI

Gemini CLI auto-discovers `GEMINI.md` at the project root — no environment variables
required. The vendor adapter also generates `.gemini/system.md` as a full
system-prompt override; set `GEMINI_SYSTEM_MD=1` to activate it.
Skills are deployed natively to `.gemini/skills/` and activated lazily via the
`activate_skill` tool, keeping the initial context lean.

### Opencode

Opencode reads `AGENTS.md` natively. Skills are deployed to `.opencode/skills/`. Opencode also supports `.claude/skills/` and `.agents/skills/` as compatibility fallbacks.

## Vendor Commands

### Generate Vendor Files

```bash
# Using global CLI (from anywhere)
agentic deploy <profile> [target] <vendors>

# Using just (from library directory)
just vendor-gen /path/to/project
just vendor-gen /path/to/project claude,copilot   # specific vendors
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

# Using just (from library directory)
just vendor-switch /path/to/project gemini
just vendor-switch /path/to/project claude,copilot
just vendor-switch /path/to/project list
```

Multiple vendors can be active simultaneously since their symlink paths don't conflict:

| Vendor | Symlink locations |
|--------|-------------------|
| `claude` | `CLAUDE.md`, `.claude/skills` |
| `copilot` | `.github/copilot-instructions.md`, `.github/instructions/` |
| `codex` | `.agents/skills` (reads `AGENTS.md` natively) |
| `gemini` | `GEMINI.md`, `.gemini/system.md`, `.gemini/skills` |
| `opencode` | `.opencode/skills` |
