# Cursor Adapter

Cursor vendor adapter for `.cursor/rules/*.mdc` output.

- Generated source files live in `.agentic/vendor-files/cursor/rules/`.
- In nested profiles, additional tier rules are generated under
  `.agentic/vendor-files/cursor/rules/<tier>/`.
- `agentic switch cursor` only manages the `.cursor/rules` symlink.
- Unrelated `.cursor/*` files (for example `.cursor/mcp.json`) are preserved.
- If a real `.cursor/rules` directory already exists, `agentic switch cursor` migrates it
  to a deterministic backup path (`.cursor/rules.backup`, then `.cursor/rules.backup.N`)
  before creating the symlink.
- Cursor switching is rollback-safe: if a later step fails during multi-vendor activation,
  prior symlinks, config, and migrated `.cursor/rules` state are restored.

Not in scope for this adapter:

- `.agentic/providers.yaml` integration
- nested `.cursor/rules` support
