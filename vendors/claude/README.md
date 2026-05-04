# Claude Vendor Adapter

## How Claude Reads Instructions

Claude Code reads agent instructions from (in priority order):
1. `AGENTS.md` in the project root and parent directories
2. `CLAUDE.md` in the project root
3. `.claude/CLAUDE.md`

Since Codex and Claude both read `AGENTS.md` natively, the composed `AGENTS.md` is the primary
output. A `CLAUDE.md` is generated as a thin pointer to avoid confusion for users who expect it.

## Skills

Claude Code supports native skills via `.claude/skills/{skill-name}/SKILL.md`.
The `vendor-gen` step copies skill directories from this library into the target project's
`.claude/skills/` directory.

## Output Files

| File | Purpose |
|---|---|
| `AGENTS.md` | Primary — assembled from fragments, read by Claude natively |
| `CLAUDE.md` | Thin pointer to AGENTS.md for Claude entrypoint conventions |
| `.claude/skills/*/` | Skill directories copied from this library |

## Notes

- Claude Code respects AGENTS.md in parent directories — useful for monorepos.
  Place the root AGENTS.md at the monorepo root; service-specific fragments go in subdirectory
  AGENTS.md files.
- The `.claude/` directory can also contain `settings.json` for tool permissions — this is
  not managed by this library.
