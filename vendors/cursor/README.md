# Cursor Adapter

Cursor vendor adapter for `.cursor/rules/*.mdc` output.

- Generated source files live in `.agentic/vendor-files/cursor/rules/`.
- `agentic switch cursor` only manages the `.cursor/rules` symlink.
- Unrelated `.cursor/*` files (for example `.cursor/mcp.json`) are preserved.

Not in scope for this adapter:

- `.agentic/providers.yaml` integration
- `.agentic/mcp.yaml` to `.cursor/mcp.json` translation
- nested `.cursor/rules` support
