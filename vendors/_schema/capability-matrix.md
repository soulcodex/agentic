# Vendor Capability Matrix

This document records what each vendor supports so adapter authors know what is possible.

## File Format Support

| Feature | Claude | Copilot | Codex | Gemini | Opencode |
|---|---|---|---|---|---|
| Reads AGENTS.md natively | Yes (also CLAUDE.md) | No | Yes | No | Yes |
| Custom instructions file | CLAUDE.md | `.github/copilot-instructions.md` | AGENTS.md | `.gemini/systemPrompt.md` | AGENTS.md |
| Per-file scoping (glob) | No | Yes (`.github/instructions/*.instructions.md`) | No | No | No |
| Multiple rules files | Yes (`.claude/` dir) | Yes (`.github/instructions/`) | No | No | No |
| Skills / slash commands | Yes (`.claude/skills/`) | No | No | No | Yes (`.claude/skills/`) |
| Config file generated | CLAUDE.md | — | — | — | `opencode.json` |

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
- `CLAUDE.md` (symlink or copy of AGENTS.md for backward compatibility)
- `.claude/skills/{skill-name}/` (skill directories)

### GitHub Copilot
- `.github/copilot-instructions.md` (global instructions, always applied)
- `.github/instructions/*.instructions.md` (glob-scoped instructions, optional)

### OpenAI Codex
- `AGENTS.md` (read natively, hierarchically from root and subdirectories)

### Gemini CLI
- `.gemini/systemPrompt.md` (loaded at session start)
- `GEMINI.md` (alternative location at project root)

### Opencode
- `AGENTS.md` (primary, read natively)
- `opencode.json` (starter config: model, permissions, empty MCP block)
- `.claude/skills/{skill-name}/` (skill directories; Opencode reads this Claude-compatible path)

## Update Log

| Date | Change |
|---|---|
| 2026-03-01 | Initial capability matrix created |
| 2026-03-02 | Added Opencode column; added Gemini awk note |
