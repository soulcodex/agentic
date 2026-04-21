# Project Customisation

How to extend your project's agentic setup with project-local skills and proprietary library declarations.

## Project-Local Skills

For skills specific to a single project that shouldn't live in the shared library,
create them in the project's `.agentic/project-skills/` directory.

> See also: [Customization](customization.md) for a quick overview of all project customisation options.

### Create a skill

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

### Reference it in your profile

```yaml
# In .agentic/profile.yaml
skills:
  - code-review                    # from library
  - project:my-custom-workflow     # from .agentic/project-skills/
```

### Or deploy with it directly

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

## Contributing to the Library

Want to add a new fragment, profile, skill, or vendor adapter to the shared library?
See the [Contributing guide](https://github.com/soulcodex/agentic/blob/main/.github/CONTRIBUTING.md).