# Opencode Vendor Adapter

This adapter generates Opencode-compatible files from an assembled `AGENTS.md`.

## How Opencode reads instructions

Opencode reads `AGENTS.md` natively (same as Claude Code and OpenAI Codex). No transformation of the instruction content is needed — the adapter is a passthrough.

## Output files

| File | Path | Purpose |
|---|---|---|
| `AGENTS.md` | project root | Canonical instructions, read natively by Opencode |
| `.opencode/skills/` | project root | Skills directory (Opencode's native path) |
| `.opencode/agents/` | project root | Provider-local subagents path (symlink target when orchestration switching is enabled) |

## Skills

Skills deploy to `.opencode/skills/` — Opencode's native skills path. Opencode also supports `.claude/skills/` and `.agents/skills/` as compatibility fallbacks, but `.opencode/skills/` is the canonical location.

## Agents orchestration

Orchestration `agents` are declared in `.agentic/agents.yaml`. Generated artifacts live in `.agentic/agents/opencode/` and are exposed at provider-local `.opencode/agents/` (subagents path).
