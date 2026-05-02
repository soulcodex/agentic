# Cursor Adapter

Cursor vendor adapter for `.cursor/rules/*.mdc` output.

- Generated source files live in `.agentic/vendor-files/cursor/rules/`.
- In nested profiles, additional tier rules are generated under
  `.agentic/vendor-files/cursor/rules/<tier>/`.
- `agentic switch cursor` uses `.agentic/vendor-files/cursor/switch-manifest.json`
  to manage Cursor rule symlinks (root and tier-local paths).
- Unrelated `.cursor/*` files (for example `.cursor/mcp.json`) are preserved.
- If a managed Cursor rules path already exists as a real directory, `agentic switch cursor`
  migrates it to a deterministic backup path (`<path>.backup`, then `<path>.backup.N`)
  before creating symlinks.
- Cursor switching is rollback-safe: if a later step fails during multi-vendor activation,
  prior symlinks, config, and migrated Cursor rules paths are restored.

Not in scope for this adapter:

- `.agentic/providers.yaml` integration
