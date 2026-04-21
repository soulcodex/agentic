# Extending agentic

Here is how to extend the library with new fragments, profiles, skills, and project-local customisations.

## Add a Fragment

Fragments are composable Markdown building blocks in `agents/{group}/{name}.md`.

Rules:
- Exactly one `## Heading` per file (no subheadings at H1 level).
- Plain Markdown — no hardcoded project names, paths, or secrets.
- Group: `base`, `languages`, `frameworks`, `architecture`, `practices`, or `domains`.

```bash
# 1. Create the file
touch agents/practices/my-practice.md
# Write your guidelines — one ## H2 heading at the top, plain Markdown, no project-specific content
```

After creating the file, run `agentic list fragments` to confirm it is discovered.

Then add the fragment name to any profile's `fragments.practices` list:

```yaml
fragments:
  practices:
    - tdd
    - api-design
    - my-practice     # ← add here
```

## Add a Profile

Profiles are YAML presets in `profiles/{name}.yaml`.

```bash
cp profiles/golang-hexagonal-cobra-cli.yaml profiles/my-profile.yaml
# Edit: name, description, fragment lists, tech_stack, skills, output commands

# Preview the assembled AGENTS.md without writing any files
agentic compose my-profile --dry-run
```

Minimum required fields:

```yaml
meta:
  name: "My Profile"
  description: What this profile is for.
  version: "1.0.0"

fragments:
  base: [git-conventions, security, code-review, testing-philosophy, documentation]
  languages: [go]
  frameworks: []
  architecture: [hexagonal]
  practices: [tdd]
  domains: []

output:
  build_command: "go build ./..."
  test_command:  "go test ./..."
  lint_command:  "golangci-lint run"

vendors:
  enabled: [claude, copilot, codex, gemini, opencode]
```

Optional fields: `tech_stack`, `skills`, `output.structure: nested`, `tiers`.

## Add a Skill

Skills are reusable agent task definitions in `skills/{group}/{name}/SKILL.md`.

```bash
mkdir -p skills/development/my-skill
# Groups: development, agentic, data, quality, architecture, or any custom name
# Write skills/development/my-skill/SKILL.md with frontmatter + steps
```

Run `agentic list skills` to confirm the skill is discovered after creating it.

Required frontmatter:

```yaml
---
name: my-skill
description: >
  What this skill does. Invoked when the user asks to ...
version: 1.0.0
tags: [quality, ...]
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---
```

Then add the skill name to any profile's `skills` list:

```yaml
skills:
  - code-review
  - my-skill
```

## Add Project-Local Skills

> See also: [customization.md](customization.md) for a quick overview of all project customization options.

For skills that are specific to a single project and shouldn't live in the shared library,
create them in the project's `.agentic/project-skills/` directory:

```bash
# In your target project
mkdir -p .agentic/project-skills/my-custom-workflow

# Create the skill file
cat > .agentic/project-skills/my-custom-workflow/SKILL.md << 'EOF'
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
EOF
```

Then reference it in your profile or deploy command with the `project:` prefix:

```yaml
# In .agentic/profile.yaml
skills:
  - code-review           # from library
  - project:my-custom-workflow  # from .agentic/project-skills/
```

Or deploy directly:

```bash
agentic deploy <profile> [target] <vendors> --skills project:my-custom-workflow

# Example:
agentic deploy typescript-hexagonal-microservice ./my-project claude --skills project:my-custom-workflow
```

Project skills are copied to `.agentic/skills/` alongside library skills and symlinked
to vendor-specific paths just like regular skills.

## Declare Proprietary Libraries

List internal packages that agents need to be aware of. Agents are told to load
the relevant documentation before making changes.

**Project-wide** (in `tech_stack`, appears in root `AGENTS.md`):

```yaml
tech_stack:
  proprietary_libraries:
    - name: "@acme/core"
      description: "Core domain primitives shared across all services"
      url_doc: "https://docs.acme.internal/core"   # optional
```

**Tier-specific** (nested profiles only — appears in that tier's `AGENTS.md`):

```yaml
tiers:
  backend:
    proprietary_libraries:
      - name: "@acme/domain-kit"
        description: "Backend domain helpers"
        url_doc: "https://docs.acme.internal/domain-kit"
```

`url_doc` is optional. When omitted the Docs column shows `—`.

## Add a Vendor Adapter

Adding a new vendor adapter requires changes to the library internals. Open an issue
or pull request on the [GitHub repository](https://github.com/soulcodex/agentic)
describing the vendor and its expected output format. See the existing adapters in
`vendors/` for the implementation pattern.
