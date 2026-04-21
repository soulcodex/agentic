# Contributing to agentic

Thank you for your interest in contributing to agentic! This library serves as a vendor-agnostic foundation for AI agent configurations, and we welcome contributions that improve its quality, coverage, and usability.

## Prerequisites

Before contributing, ensure you have the following tools installed:

- **just** — command runner (install via `brew install just` or your package manager)
- **yq** — YAML processor (install via `brew install yq` or your package manager)
- **jq** — JSON processor (install via `brew install jq` or your package manager)
- **bash** — shell (version 4.0 or higher)

Run `just setup` to verify all dependencies are installed (macOS can auto-install them).

## Fork & Local Setup

1. **Fork the repository** on GitHub
2. **Clone your fork locally:**
   ```bash
   git clone https://github.com/your-username/agentic.git
   cd agentic
   ```
3. **Create a feature branch:**
   ```bash
   git checkout -b feat/your-feature-name
   # or
   git checkout -b fix/your-fix-description
   ```

## Quality Checks

**Before opening a pull request, you must run:**

```bash
just lint && just test
```

- `just lint` — validates all fragments, profiles, and adapter files against schemas
- `just test` — runs 29+ assertions to ensure tooling works correctly

All tests must pass before your PR can be merged.

## Adding Library Assets

### Add a Fragment

Fragments are composable Markdown building blocks in `agents/{group}/{name}.md`.
Groups: `base`, `languages`, `frameworks`, `architecture`, `practices`, `domains`.

```bash
touch agents/practices/my-practice.md
# Write your guidelines — one ## H2 heading at the top, plain Markdown, no project-specific content
```

Add the fragment name to any profile's `fragments.<group>` list:

```yaml
fragments:
  practices:
    - tdd
    - my-practice
```

Run `just index && just lint` before opening a PR.

### Add a Profile

Profiles are YAML presets in `profiles/{name}.yaml`. Naming convention: `{language}-{framework}-{pattern}.yaml`.

```bash
cp profiles/golang-hexagonal-cobra-cli.yaml profiles/my-profile.yaml
# Edit: name, description, fragment lists, tech_stack, skills, output commands
agentic compose my-profile --dry-run   # Preview the assembled AGENTS.md
```

Minimum required fields: `meta` (name, description, version), `fragments`, `output` (build/test/lint commands), `vendors.enabled`.
Optional: `tech_stack`, `skills`, `output.structure: nested`, `tiers`.

Run `just lint` before opening a PR.

### Add a Skill

Skills are reusable agent task definitions in `skills/{group}/{name}/SKILL.md`.

```bash
mkdir -p skills/development/my-skill
# Write skills/development/my-skill/SKILL.md with frontmatter and steps
```

Required frontmatter: `name`, `description` (>=20 chars), `version` (SemVer), `tags`, `resources`, `vendor_support` (claude/opencode: `native`; copilot/codex/gemini: `prompt-inject`).

Run `just index && just lint` before opening a PR.

### Add a Vendor Adapter

Adding a vendor adapter requires changes to the library internals. Open an issue or PR describing the vendor and its expected output format. See existing adapters in `vendors/` for the implementation pattern.

## Fragment Authoring Rules

Fragments are composable building blocks in `agents/`. Each fragment must be:

- **Self-contained** — no cross-references to other fragments, no project-specific paths, no hardcoded credentials
- **Properly structured** — starts with a single H2 heading (`## Section Name`) matching its purpose
- **Concise** — must not exceed 300 lines; split larger content into focused fragments
- **Tokenized** — use `{TOKEN_NAME}` syntax for project-specific values substituted at compose time (e.g., `{BUILD_CMD}`, `{PROJECT_NAME}`)

## Skill Authoring Rules

Skills are reusable agent skill definitions in `skills/`. Each skill directory must have:

- **SKILL.md** with valid YAML frontmatter containing:
  - `name` — skill identifier
  - `description` — what the skill does
  - `version` — SemVer format (MAJOR.MINOR.PATCH)
  - `tags` — searchable tags
  - `vendor_support` — supported vendors
- **resources:** declaration in frontmatter listing all supporting files
- All referenced files must exist in the skill directory

## Commit Conventions

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>
```

**Types:**
- `feat` — new feature (fragment, profile, skill, vendor adapter)
- `fix` — bug fix in existing content
- `chore` — maintenance tasks (CI, tooling, index updates)
- `docs` — documentation changes
- `refactor` — code restructuring without behavior change

**Scopes:**
- `fragments` — changes to agent fragments
- `skills` — changes to skills
- `profiles` — changes to profile definitions
- `vendors` — changes to vendor adapters
- `tooling` — changes to scripts or CLI
- `index` — changes to index files
- `ci` — changes to CI/CD configuration

**Examples:**
```
feat(fragments): add new code review fragment
feat(profiles): add python-fastapi-async profile
fix(skills): correct skill description in SKILL.md
chore(index): rebuild index after fragment addition
chore(ci): add validate workflow for PRs
```

## Index Updates

After adding or modifying any fragment or skill, **you must regenerate the index**:

```bash
just index
```

This updates `index/skills.json` and `index/fragments.json`. Commit these changes alongside your source modifications in the same commit.

## Pull Request Checklist

Before submitting your PR, verify:

- [ ] `just lint` passes with no errors
- [ ] `just test` passes (all assertions green)
- [ ] `just index` was run if you added/modified fragments or skills
- [ ] Commit message follows Conventional Commits format
- [ ] Documentation updated if adding new features
- [ ] New fragments/skills follow authoring rules (self-contained, H2 heading, <300 lines, proper frontmatter)

## Getting Help

- Open an issue for bugs or feature requests
- Use discussions for questions
- Check existing issues and discussions before posting

We appreciate every contribution, no matter how small!
