# Vendor Capability Matrix

This document records what each vendor supports so adapter authors know what is possible.

## File Format Support

| Feature | Claude | Copilot | Codex | Gemini | Opencode |
|---|---|---|---|---|---|
| Reads AGENTS.md natively | Yes (also CLAUDE.md) | No | Yes | No | Yes |
| Custom instructions file | CLAUDE.md | `.github/copilot-instructions.md` | AGENTS.md | `.gemini/systemPrompt.md` | AGENTS.md |
| Per-file scoping (glob) | No | Yes (`.github/instructions/*.instructions.md`) | No | No | No |
| Multiple rules files | Yes (`.claude/` dir) | Yes (`.github/instructions/`) | No | No | No |
| Skills / slash commands | Yes (`.claude/skills/`) | No | Yes (`.agents/skills/`) | No | Yes (multiple paths) |
| Config file generated | CLAUDE.md (symlink) | — | — | — | `opencode.json` (symlink) |

## Context Window and Limits

| Limit | Claude | Copilot | Codex | Gemini | Opencode |
|---|---|---|---|---|---|
| Instruction file size limit | ~200KB practical | ~64KB practical | ~32KB | ~32KB | ~200KB practical |
| Hard per-file char limit | None documented | None documented | None documented | None documented | None documented |
| Notes | Reads multiple files; total context is shared with conversation | Content prepended to every request | Reads AGENTS.md hierarchically | Reads systemPrompt.md once per session | Reads AGENTS.md natively; config in opencode.json |

## Section Type Support

| Section | Claude | Copilot | Codex | Gemini | Opencode |
|---|---|---|---|---|---|
| Git conventions | Yes | Yes | Yes | Yes | Yes |
| Language rules | Yes | Yes | Yes | Yes | Yes |
| Architecture rules | Yes | Yes | Yes | Yes | Yes |
| Practice rules | Yes | Yes | Yes | Yes | Yes |
| Build/test commands | Yes | Yes | Yes | Yes | Yes |
| Skills (native) | Yes | No* | No* | No* | Yes |
| Glob-scoped rules | No† | Yes | No | No | No |
| Domain context | Yes | Yes | Yes | Yes | Yes |

`*` Injected as prompt text for non-native vendors
`†` Claude Code and Opencode apply rules globally; scoping is via tool configuration

**Note on Gemini:** `gen_gemini()` uses `awk` to extract all H2 sections from `AGENTS.md` regardless of the adapter's `section_mappings` entries. The 8 mappings in `vendors/gemini/adapter.json` are informational only and are not used during generation.

## Deployment Artifacts per Vendor

### Claude
- `AGENTS.md` (primary, read natively)
- `CLAUDE.md` (symlink → `.agentic/vendor-files/claude/CLAUDE.md`)
- `.claude/skills/` (symlink → `.agentic/skills/`)

### GitHub Copilot
- `.github/copilot-instructions.md` (global instructions, always applied)
- `.github/instructions/*.instructions.md` (glob-scoped instructions, optional)
- Skills injected as prompt text (no native skill support)

### OpenAI Codex
- `AGENTS.md` (read natively, hierarchically from root and subdirectories)
- `.agents/skills/` (symlink → `.agentic/skills/`)

### Gemini CLI
- `.gemini/systemPrompt.md` (symlink → `.agentic/vendor-files/gemini/systemPrompt.md`)
- `GEMINI.md` (alternative location at project root)
- Skills injected as prompt text (no native skill support)

### Opencode
- `AGENTS.md` (primary, read natively)
- `opencode.json` (symlink → `.agentic/vendor-files/opencode/opencode.json`)
- `.opencode/skills/` (symlink → `.agentic/skills/`)
- Also reads: `.claude/skills/`, `.agents/skills/`

## Vendor Switching Architecture

The agentic library uses a symlink-based vendor switching system:

1. **Canonical locations**: All generated files live in `.agentic/vendor-files/{vendor}/`
2. **Skills**: Deployed once to `.agentic/skills/`, symlinked to vendor-specific paths
3. **Entrypoints**: Vendor config files (CLAUDE.md, opencode.json, etc.) are symlinks
4. **Switching**: Only symlinks change — no file movement or copying
5. **Git**: Symlinks are gitignored; recreate locally via `agentic switch <vendor>`

## Update Log

| Date | Change |
|---|---|
| 2026-03-01 | Initial capability matrix created |
| 2026-03-02 | Added Opencode column; added Gemini awk note |
| 2026-03-03 | Updated for symlink-based vendor switching; added Codex skills support; documented canonical .agentic/ paths |
