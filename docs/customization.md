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

For skills specific to a single project that shouldn't live in the shared library,
create them in `.agentic/project-skills/`:

```bash
mkdir -p .agentic/project-skills/my-custom-workflow
```

Create `.agentic/project-skills/my-custom-workflow/SKILL.md`:

```yaml
---
name: my-custom-workflow
description: >
  Project-specific deployment workflow for this repo.
version: 1.0.0
tags: [deployment, internal]
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Steps

1. Run pre-deploy checks: `make verify`
2. Build the artifact: `make build`
3. Deploy to staging: `make deploy-staging`
4. Run smoke tests: `make smoke-test`
```

Reference it in your profile:

```yaml
# In .agentic/profile.yaml
skills:
  - code-review                    # from library
  - project:my-custom-workflow     # from .agentic/project-skills/
```

Or deploy with it directly:

```bash
agentic deploy <profile> [target] <vendors> --skills project:my-custom-workflow
```

Project skills are copied to `.agentic/skills/` alongside library skills and
symlinked to vendor-specific paths just like regular skills.

## Declare Proprietary Libraries

List internal packages that agents need to be aware of. Agents are told to load
the relevant documentation before making changes to code that uses these packages.

### Project-wide

Declared in `tech_stack` in `.agentic/profile.yaml` — appears in the root `AGENTS.md`:

```yaml
tech_stack:
  proprietary_libraries:
    - name: "@acme/core"
      description: "Core domain primitives shared across all services"
      url_doc: "https://docs.acme.internal/core"   # optional
```

### Tier-specific (nested profiles only)

Declared under the relevant tier — appears in that tier's `AGENTS.md`:

```yaml
tiers:
  backend:
    proprietary_libraries:
      - name: "@acme/domain-kit"
        description: "Backend domain helpers"
        url_doc: "https://docs.acme.internal/domain-kit"
```

`url_doc` is optional. When omitted the Docs column in `AGENTS.md` shows `—`.

## When to Use What

| Need | Solution |
|------|----------|
| Customize one project | Edit `.agentic/profile.yaml`, run `agentic sync` |
| Reusable skill for one project | Create in `.agentic/project-skills/` (see above) |
| Shared across all projects | Add to library (see [Contributing guide](https://github.com/soulcodex/agentic/blob/main/.github/CONTRIBUTING.md)) |

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

## Config Lock File

Every `agentic deploy` or `agentic compose` writes `TARGET/.agentic/config.yaml`:

```yaml
# Managed by agentic library — do not edit manually
library_commit: "abc123..."
profile: "golang-hexagonal-cobra-cli"
profile_version: "1.0.0"
composed_at: "2026-03-03T12:00:00Z"
mode: lean
agentic_root: "/Users/you/agentic"
active_vendors:
  - claude
  - copilot
structure: nested          # only for nested profiles
tiers: [backend, ui]       # only for nested profiles
```

The `agentic_root` and `active_vendors` fields enable the global CLI to work
from any directory within your project.
