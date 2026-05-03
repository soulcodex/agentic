# Portable Agents

Use `.agentic/agents.yaml` to keep provider-specific agent prompt files in sync from project-local source files.

## Default behavior

`agentic init` scaffolds `.agentic/agents.yaml` in explicit no-op mode:

```yaml
version: "1"
enabled: false
providers: {}
```

When `enabled: false` (or when the file is missing), `agentic sync` skips portable agents sync.

## Opt in

Set `enabled: true` and add provider mappings.

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/soulcodex/agentic/main/schemas/agents.schema.json
version: "1"
enabled: true
providers:
  codex:
    enabled: true
    mappings:
      - source: ".agentic/portable/codex.md"
        target: ".agents/AGENTS.md"
  opencode:
    enabled: true
    mappings:
      - source: ".agentic/portable/opencode.md"
        target: ".opencode/AGENTS.md"
```

Notes:
- `source` and `target` paths are project-relative.
- Missing `source` files are skipped with a warning.
- Mapping behavior stays provider-specific in vendor adapters.
