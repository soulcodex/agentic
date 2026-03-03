# Vendors

agentic generates vendor-specific instruction files from a single `AGENTS.md` source of truth.

## Supported Vendors

| Vendor | Output file(s) | How it's used |
|---|---|---|
| **Claude** (Claude Code) | `AGENTS.md`, `CLAUDE.md` | `AGENTS.md` natively; `CLAUDE.md` is a thin wrapper pointing to it; skills in `.claude/skills/` |
| **GitHub Copilot** | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` | Global always-on instructions + glob-scoped per-language files |
| **OpenAI Codex** | `AGENTS.md` | `AGENTS.md` natively; hierarchical for monorepos (tier AGENTS.md files) |
| **Gemini CLI** | `.gemini/systemPrompt.md` | Single system prompt — all fragment content concatenated |
| **Opencode** | `AGENTS.md`, `opencode.json` | `AGENTS.md` natively; `opencode.json` for project config; skills in `.claude/skills/` |

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

Gemini reads a single system prompt from `.gemini/systemPrompt.md`. The vendor adapter concatenates all fragment content (in lean mode, reads from `.agentic/fragments/`) and appends it after the prompt header.

### Opencode

Opencode reads `AGENTS.md` natively. The `opencode.json` file configures the project name and model settings. Skills work the same way as Claude (`.claude/skills/`).

## Vendor Generation Commands

```bash
# Generate all enabled vendors (reads vendors.enabled from profile)
just vendor-gen /path/to/project

# Generate for specific vendors only
just vendor-gen /path/to/project claude,copilot

# Switch the active vendor (stash current, generate new)
just vendor-switch /path/to/project gemini

# List available vendors and which is active
just vendor-switch /path/to/project list
```

## Vendor-Switch

After `just deploy`, an `agentic` wrapper script is placed in the target project root. From inside the project:

```bash
./agentic list       # show all vendors, mark the active one
./agentic gemini     # switch to Gemini (stashes Claude files, generates Gemini)
./agentic claude     # switch back to Claude
```

The previous vendor's files are stashed to `.agentic/vendor-stash/{vendor}/` and can be restored by switching back.

| Vendor stash | What is moved |
|---|---|
| `claude` | `CLAUDE.md` |
| `copilot` | `.github/copilot-instructions.md` + `.github/instructions/*.instructions.md` |
| `codex` | Nothing — `AGENTS.md` is shared |
| `gemini` | `.gemini/systemPrompt.md` |
| `opencode` | `opencode.json` |
