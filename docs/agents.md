# Agents Orchestration Switching

Use `.agentic/agents.yaml` to define project-local agent orchestration and generate canonical provider outputs under `.agentic/agents/`.
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
    prompt: |
      You are the architect agent.
      Scope tasks, identify risks, and propose execution steps.
    providers:
      codex:
        enabled: true
        model: "gpt-5.3-codex"
      opencode:
        enabled: true
        model: "openai/gpt-5"
```

Notes:
- `agents` are orchestration roles declared in `.agentic/agents.yaml` (`architect`, `reviewer`, `worker`).
- Agent names are lowercase letters only.
- `prompt` is inline multiline instruction text in YAML.
- If `enabled: true` and `agents` is empty, sync warns and performs no mutations.
- Provider outputs are generated as artifacts under `.agentic/agents/`:
  - Codex: `.agentic/agents/codex/<agent>.md`
  - OpenCode: `.agentic/agents/opencode/<agent>.md`
- `agentic switch` activates provider-local agent paths:
  - Codex: `.codex/agents` → `.agentic/agents/codex`
  - OpenCode: `.opencode/agents` → `.agentic/agents/opencode`
- `model` must match the provider's valid model reference/name.
- `.agentic/agents/` is generated from `agents.yaml` and should be gitignored.
- `agents.yaml` remains the source of truth and should be tracked in git.
- `subagents` are provider-local runtime directories (`.codex/agents`, `.opencode/agents`) that point to generated artifacts.
- Provider behavior stays isolated in vendor adapters.
