# Extending agentic

The library is designed to be forked and extended. Here is how to add each type of asset.

## Add a Fragment

Fragments are composable Markdown building blocks in `agents/{group}/{name}.md`.

Rules:
- Exactly one `## Heading` per file (no subheadings at H1 level).
- Plain Markdown — no hardcoded project names, paths, or secrets.
- Group: `base`, `languages`, `frameworks`, `architecture`, `practices`, or `domains`.

```bash
# 1. Create the file
touch agents/practices/my-practice.md
# Write your guidelines (one ## H2 heading at the top)

# 2. Rebuild the index so lint and compose can find it
just index

# 3. Validate
just lint
```

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
just lint
just dry-run my-profile
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
# Write skills/development/my-skill/SKILL.md with frontmatter + steps
just index
just lint
```

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

Vendor adapters live in `vendors/{name}/`. Each adapter transforms `AGENTS.md`
into the format expected by a specific AI tool.

1. Create `vendors/my-tool/` directory.
2. Add a template file (e.g., `template.my-tool.md`).
3. Add the generation logic to `tooling/lib/vendor-gen.sh` as a `gen_mytool()` function.
4. Add `my-tool` to the `resolve_vendors` function.
5. Add `my-tool` to the `vendors.enabled` list in any profiles that should use it.
6. Run `just lint && just test`.
