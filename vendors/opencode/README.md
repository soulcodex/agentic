# Opencode Vendor Adapter

This adapter generates Opencode-compatible files from an assembled `AGENTS.md`.

## How Opencode reads instructions

Opencode reads `AGENTS.md` natively (same as Claude Code and OpenAI Codex). No transformation of the instruction content is needed — the adapter is a passthrough.

## Output files

| File | Path | Purpose |
|---|---|---|
| `AGENTS.md` | project root | Canonical instructions, read natively by Opencode |
| `.claude/skills/` | project root | Skills directory (Opencode reads this Claude-compatible path) |

## Skills

Skills deploy to `.claude/skills/` (not `.opencode/skills/`). Opencode reads the `.claude/skills/` path for Claude compatibility. The `.opencode/skills/` path declared in `output_paths.skills` is reserved for Opencode-native skills only.
