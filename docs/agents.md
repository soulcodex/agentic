# Agents Orchestration

Use `.agentic/agents.yaml` to define project-local agent orchestration and generate canonical provider outputs under `.agentic/agents/`.
This feature is additive and optional: if the file is missing, or `enabled: false`, sync behavior is unchanged.

## Source of Truth and Artifacts

- `agents.yaml` is the source of truth and should be tracked in git.
- `.agentic/agents/` is generated from `agents.yaml` and should be gitignored.
- Provider-local runtime directories (`.codex/agents`, `.opencode/agents`) are switch-managed symlinks to generated artifacts.
- Provider behavior stays isolated in vendor adapters.

## Enablement Modes

`agentic init` scaffolds `.agentic/agents.yaml` in explicit no-op mode:

```yaml
version: "1"
enabled: false
agents: {}
```

When `enabled: false` (or when the file is missing), `agentic sync` skips agents orchestration.

To opt in, set `enabled: true` and define agents (and optional subagents):

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
        reasoning_effort: "high"
      opencode:
        enabled: true
        model: "openai/gpt-5"
        reasoning_effort: "extra_high"
  reviewer:
    description: "Reviews code quality and risk."
    prompt: |
      You are the reviewer agent.
      Focus on correctness, regressions, and test gaps.
subagents:
  worker:
    parent: "architect"
    description: "Implements bounded changes delegated by architect."
    prompt: |
      You are the worker subagent.
      Implement the assigned change and report modified files.
    providers:
      codex:
        enabled: true
        model: "gpt-5.3-codex"
        reasoning_effort: "medium"
      opencode:
        enabled: false
```

## Configuration Contract

- `agents` are orchestration roles declared in `.agentic/agents.yaml` (`architect`, `reviewer`, `worker`, etc.).
- Agent and subagent keys must match `^[a-z]+$` (lowercase letters only).
- `prompt` is inline multiline instruction text in YAML (`|` block style recommended).
- Provider keys inside `agents.*.providers` and `subagents.*.providers` are currently limited to `codex` and `opencode`.
- `model` must be a valid model reference/name for the selected provider.
- `version` must be exactly `"1"`.
- `enabled` fields must be booleans.
- `reasoning_effort` (when set) must be one of: `low`, `medium`, `high`, `extra_high`.

## Sync Behavior Matrix

| Condition | Sync behavior |
|---|---|
| Missing `.agentic/agents.yaml` | No agents orchestration mutations are performed. |
| `enabled: false` | Logs disabled no-op; no agents orchestration mutations are performed. |
| `enabled: true` with empty `agents` and empty `subagents` | Warns and performs no mutations. |
| `enabled: true` with definitions but no provider outputs resolved | Warns and performs no mutations. |
| `enabled: true` with valid definitions | Renders provider artifacts under `.agentic/agents/`. |

## Generated Outputs

Provider outputs are generated as artifacts under `.agentic/agents/`:

- Codex: `.agentic/agents/codex/<agent>.md`
- OpenCode: `.agentic/agents/opencode/<agent>.md`

Subagent outputs follow the same provider artifact directories and are generated from `.agentic/agents.yaml` definitions.

## Activation via Switch

`agentic switch` activates provider-local runtime paths by linking them to generated artifacts:

- Codex: `.codex/agents` → `.agentic/agents/codex`
- OpenCode: `.opencode/agents` → `.agentic/agents/opencode`

This keeps runtime/provider directories disposable and reproducible while `agents.yaml` remains the durable, reviewable source.
