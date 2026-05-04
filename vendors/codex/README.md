# OpenAI Codex Vendor Adapter

## How Codex Reads Instructions

OpenAI Codex reads `AGENTS.md` natively:
- Searches for `AGENTS.md` from the current working directory up to the repo root.
- In monorepos, service-level `AGENTS.md` files in subdirectories are merged with the root.
- No transformation needed — the composed `AGENTS.md` is used directly.

## Output Files

| File | Purpose |
|---|---|
| `AGENTS.md` | Primary — Codex reads this natively |
| `.codex/agents/` | Provider-local subagents path (symlink target when orchestration switching is enabled) |

## Monorepo Support

For monorepos, place an `AGENTS.md` at the root (global rules) and compose additional
service-specific `AGENTS.md` files in each service subdirectory:

```
monorepo/
├── AGENTS.md              # Global rules (base fragments)
├── services/
│   ├── order-service/
│   │   └── AGENTS.md     # Service-specific rules (language + architecture fragments)
│   └── user-service/
│       └── AGENTS.md
```

Use `just compose` once per service with its own profile.

## Notes

- Codex is the most native consumer of AGENTS.md — no adapter transformation is required.
- The passthrough adapter exists to track which sections were intended for Codex.
- Orchestration `agents` are declared in `.agentic/agents.yaml`; generated artifacts live in `.agentic/agents/codex/` and are exposed at provider-local `.codex/agents/`.
