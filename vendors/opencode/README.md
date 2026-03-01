# Opencode Vendor Adapter

This adapter generates Opencode-compatible files from an assembled `AGENTS.md`.

## How Opencode reads instructions

Opencode reads `AGENTS.md` natively (same as Claude Code and OpenAI Codex). No transformation of the instruction content is needed — the adapter is a passthrough.

## Output files

| File | Path | Purpose |
|---|---|---|
| `AGENTS.md` | project root | Canonical instructions, read natively by Opencode |
| `opencode.json` | project root | Starter config: model, permissions, and empty MCP block |
| `.claude/skills/` | project root | Skills directory (Opencode reads this Claude-compatible path) |

## MCP setup

The generated `opencode.json` includes an empty `mcp: {}` block. To populate it interactively:

```bash
just mcp-add /path/to/project
```

This wizard writes `.mcp.json` (Claude standard format) and optionally syncs the entry to `opencode.json`.

List configured servers:

```bash
just mcp-list /path/to/project
```

Remove a server:

```bash
just mcp-remove /path/to/project github
```

## The `_meta` object

`opencode.json` uses a `_meta` object instead of JSONC comments for generation metadata. This keeps the file valid JSON (compatible with `jq` and all JSON parsers). Do not edit the `_meta` fields manually — they are overwritten on each `just vendor-gen` run.

## Skills

Skills deploy to `.claude/skills/` (not `.opencode/skills/`). Opencode reads the `.claude/skills/` path for Claude compatibility. The `.opencode/skills/` path declared in `output_paths.skills` is reserved for Opencode-native skills only.
