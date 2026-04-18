# Gemini Vendor Adapter

## How Gemini Reads Instructions

Gemini CLI loads agent instructions from multiple locations:

1. **GEMINI.md** at the project root — primary context file (auto-discovered, zero config)
2. **.gemini/system.md** — full system prompt override (requires `GEMINI_SYSTEM_MD=1` in environment)
3. **@import** — multi-file context loading via `@./path/to/file.md` syntax in prompts

This adapter generates both `GEMINI.md` and `.gemini/system.md` in `.agentic/vendor-files/gemini/`.

## Output Files

| File | Purpose | How Gemini CLI Loads It |
|------|---------|------------------------|
| `.agentic/vendor-files/gemini/GEMINI.md` | Primary context file | Auto-discovered at project root (zero config) |
| `.agentic/vendor-files/gemini/system.md` | Full system prompt override | Loaded when `GEMINI_SYSTEM_MD=1` is set in environment |

## Symlinks Created

When you run `agentic switch gemini`, the following symlinks are created:

- `GEMINI.md` (project root) → `.agentic/vendor-files/gemini/GEMINI.md`
- `.gemini/system.md` → `../.agentic/vendor-files/gemini/system.md`
- `.gemini/skills` → `../.agentic/skills`

## Native Skills Support

Gemini supports native skills at `.gemini/skills/`. Skills are deployed to the canonical `.agentic/skills/` directory and symlinked to `.gemini/skills/`.

To activate a skill in a Gemini session, use the `activate_skill` tool:

```
Use the activate_skill tool to load the code-review skill.
```

Skills are loaded lazily on-demand, not injected into the system prompt.

## Conditional Rules and Scoping

- **Instruction-level rules**: All content from `GEMINI.md` is always-on — Gemini does not apply conditional scoping at the instruction level.
- **Tool-level scoping**: Available via the policy engine using `.gemini/policies/*.toml` files.

## Multi-File Context (@import)

Gemini supports loading additional context files via the `@import` syntax in prompts:

```
@./path/to/file.md
@./docs/architecture.md
```

This allows granular context loading without modifying the primary `GEMINI.md`.

## Gitignore

The `.gemini/` directory and `GEMINI.md` at the project root are gitignored by Gemini CLI's default patterns. Explicitly un-ignore these in your project's `.gitignore` if you want to commit them:

```gitignore
# Un-ignore Gemini CLI files
!.gemini/
!GEMINI.md
```

## Notes

- Keep `GEMINI.md` focused — Gemini's context window is shared with the conversation.
- Use `.gemini/system.md` only when you need a complete system prompt override.
- Skills are loaded lazily via `activate_skill`, reducing prompt bloat.