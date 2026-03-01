# automations/

This directory stores importable [n8n](https://n8n.io) workflow JSON files and
supporting documentation for automations that extend the agentic library.

## Directory pattern

Each workflow lives in its own subdirectory under `workflows/`:

```
automations/
└── workflows/
    └── <workflow-name>/
        ├── <workflow-name>.workflow.json   # importable n8n workflow
        └── README.md                       # optional: setup steps, credentials, env vars
```

To import a workflow into n8n, open **n8n → Workflows → Import from file** and select
the `.workflow.json` file.

## Planned workflows

| Workflow | Status | Description |
|---|---|---|
| `agents-md-sync` | planned | Detects changes to `agents/` or `profiles/` on `main` and triggers redeploy in downstream projects that use this library |
