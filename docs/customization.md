# Customization

How to customize agentic for individual projects without modifying the shared library.

## Local Profile

When you deploy a profile, a copy is saved to `.agentic/profile.yaml`. This is your project's own configuration that you can edit freely.

### What You Can Customize

- Add or remove fragments
- Add or remove skills (including `project:` prefixed skills)
- Modify `tech_stack` (languages, frameworks, proprietary libraries)
- Change build/test/lint commands
- Adjust tier configuration (for nested projects)

### Regenerating After Changes

After editing `.agentic/profile.yaml`, regenerate your project:

```bash
agentic sync
```

This re-runs compose with your local profile, regenerates vendor files, and preserves your active vendors.

## Project-Local Skills

For skills specific to a single project, create them in `.agentic/project-skills/`:

```bash
mkdir -p .agentic/project-skills/my-workflow
```

Create `.agentic/project-skills/my-workflow/SKILL.md` with frontmatter and steps, then reference it in your profile:

```yaml
skills:
  - code-review              # from library
  - project:my-workflow      # from .agentic/project-skills/
```

See [extending.md](extending.md) for the full skill format and frontmatter requirements.

## When to Use What

| Need | Solution |
|------|----------|
| Customize one project | Edit `.agentic/profile.yaml`, run `agentic sync` |
| Reusable skill for one project | Create in `.agentic/project-skills/` |
| Shared across all projects | Add to library (see [extending.md](extending.md)) |

## What to Commit to Your Project Repo

agentic automatically injects a managed `.gitignore` block on every `deploy` or `sync`
so you never have to figure this out manually. The block is delimited by
`# agentic:start` / `# agentic:end` and is updated in-place on re-runs.

What goes in and what stays out depends on whether you deployed with `--link` or not.

### Copy mode (default)

`.agentic/skills/`, `.agentic/fragments/`, and `.agentic/vendor-files/` contain real
files copied from the library. They are committed to the repo so the project is
self-contained and cloneable without the library installed on every machine.

### Link mode (`--link`)

Those same directories are symlinks pointing to the library on the deploying machine.
Committing a symlink to an absolute local path breaks every other machine, so they
are gitignored automatically.

### What this means for your repo

| Path | Copy mode | Link mode | Why |
|---|---|---|---|
| `AGENTS.md` | ✅ commit | ✅ commit | Source of truth — review in PRs |
| `.agentic/config.yaml` | ✅ commit | ✅ commit | Reproducibility anchor |
| `.agentic/profile.yaml` | ✅ commit | ✅ commit | Per-project customization |
| `.agentic/project-skills/` | ✅ commit | ✅ commit | Your code — treat as source |
| `.agentic/skills/` | ✅ commit | 🚫 ignore | Real files vs symlink to library |
| `.agentic/fragments/` | ✅ commit | 🚫 ignore | Real files vs symlink to library |
| `.agentic/vendor-files/` | ✅ commit | 🚫 ignore | Real files vs symlink to library |
| `CLAUDE.md`, `GEMINI.md`, vendor symlinks | 🚫 ignore | 🚫 ignore | Always recreated by `agentic sync` / `agentic switch` |

> **Note**: vendor entry-point files (`CLAUDE.md`, `.github/copilot-instructions.md`,
> `.gemini/system.md`, etc.) are always gitignored in both modes — they are always
> regenerated and have no standalone value in git history.

### Switching between modes

**Switching copy → link mode** (stop carrying library files in your repo):

1. Re-deploy with `--link`: `agentic sync` (if config already has link mode) or re-run deploy with `--link`
2. Remove the now-symlinked directories from git's index:
   ```bash
   git rm -r --cached .agentic/skills .agentic/fragments .agentic/vendor-files
   git commit -m "chore: switch agentic to link mode"
   ```
3. The managed `.gitignore` block is updated automatically — the three paths are added to it.

**Switching link → copy mode** (make the project fully self-contained):

1. Re-deploy without `--link`: update `deploy_mode` in `.agentic/config.yaml` to `copy` then run `agentic sync`
2. Stage the newly materialized directories:
   ```bash
   git add .agentic/skills .agentic/fragments .agentic/vendor-files
   git commit -m "chore: switch agentic to copy mode"
   ```
3. The managed `.gitignore` block is updated automatically — the three paths are removed from it.
