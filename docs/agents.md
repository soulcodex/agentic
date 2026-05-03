# Agents Orchestration Switching

Use `.agentic/agents.yaml` to define project-local agent orchestration and generate provider-local agent files.
This feature is additive and optional: if the file is missing, or `enabled: false`, sync behavior is unchanged.

## Default behavior

`agentic init` scaffolds `.agentic/agents.yaml` in explicit no-op mode:

```yaml
version: "1"
enabled: false
agents: {}
```

When `enabled: false` (or when the file is missing), `agentic sync` skips agents orchestration switching.

## Opt in

Set `enabled: true` and define agents.

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/soulcodex/agentic/main/schemas/agents.schema.json
version: "1"
enabled: true
agents:
  architect:
    description: "Plans and scopes implementation."
    prompt: ".agentic/portable/architect.md"
    providers:
      codex:
        enabled: true
        model: "gpt-5.3-codex"
      opencode:
        enabled: true
        model: "openai/gpt-5"
```

Notes:
- Agent names are lowercase letters only (`architect`, `reviewer`, `worker`).
- `prompt` paths are project-relative and must stay local (no absolute paths, no parent traversal).
- If `enabled: true` and `agents` is empty, sync warns and performs no mutations.
- Provider outputs are generated to local project paths:
  - Codex: `.agents/orchestration/<agent>.md`
  - OpenCode: `.opencode/agents/<agent>.md`
- All outputs are preflighted before writing; unmanaged destination conflicts fail before mutation.
- Provider behavior stays isolated in vendor adapters.
