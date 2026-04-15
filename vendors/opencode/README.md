# Opencode Vendor Adapter

This adapter generates Opencode-compatible files from an assembled `AGENTS.md`.

## How Opencode reads instructions

Opencode reads `AGENTS.md` natively (same as Claude Code and OpenAI Codex). No transformation of the instruction content is needed — the adapter is a passthrough.

## Output files

| File | Path | Purpose |
|---|---|---|
| `AGENTS.md` | project root | Canonical instructions, read natively by Opencode |
| `.opencode/skills/` | project root | Skills directory (Opencode's native path) |

## Skills

Skills deploy to `.opencode/skills/` — Opencode's native skills path. Opencode also supports `.claude/skills/` and `.agents/skills/` as compatibility fallbacks, but `.opencode/skills/` is the canonical location.
