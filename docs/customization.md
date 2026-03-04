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
