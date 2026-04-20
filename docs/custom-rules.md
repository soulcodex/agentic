# Custom Rules — AGENTS.local.md

Add project-specific rules to your AGENTS.md without modifying the library or forking profiles.

## What is AGENTS.local.md?

`AGENTS.local.md` is a file that gets injected into the composed `AGENTS.md` at a configurable position. It's:

- **Not part of the library** — your project, your rules
- **Preserved on regenerate** — `agentic sync` won't overwrite it
- **Optional** — works with or without profile configuration

## Use Cases

### 1. Migrating from Existing AGENTS.md

You already have an AGENTS.md and want to install agentic:

```bash
# Run compose — it detects your existing AGENTS.md is user-authored
agentic compose typescript-hexagonal-microservice

# Options:
# --import adopt    → copies existing AGENTS.md to AGENTS.local.md, then composes
# --import skip    → aborts, requires manual migration
# --import overwrite → replaces, requires --yes or confirmation
```

The adapter behavior depends on `output.custom_rules.import_strategy` in your profile (default: `adopt`).

### 2. Adding Fresh Project Rules

Start from scratch:

```bash
# 1. Deploy a profile
agentic compose typescript-hexagonal-microservice

# 2. Create AGENTS.local.md
cat > AGENTS.local.md <<'EOF'
## Deployment Rules

- Deploy to production only on tagged commits
- Roll back within 5 minutes if error rate > 1%
EOF

# 3. Regenerate — local rules are injected
agentic sync
```

## The --import Flag

Three strategies for existing user-authored AGENTS.md:

| Strategy | Behavior |
|----------|----------|
| `adopt` (default) | Copies existing AGENTS.md → AGENTS.local.md, then composes. Skips if AGENTS.local.md already exists. |
| `skip` | Aborts with error. Use when you want to review and migrate manually. |
| `overwrite` | Replaces existing AGENTS.md. Prompts for confirmation unless `-y`/`--yes` is passed. |

Profile-level setting: `output.custom_rules.import_strategy` (default: `adopt`).

## Profile Configuration

In your profile YAML:

```yaml
output:
  custom_rules:
    placement: append          # append | prepend | after_section
    after_section: Commands  # required if placement is after_section
    import_strategy: adopt   # adopt | skip | overwrite
    description: "Project-specific deployment rules"
```

### Placement Options

- `append` (default) — at the end of AGENTS.md
- `prepend` — after the header block, before other content
- `after_section` — after a specific H2 heading

```yaml
# Example: inject after ## Commands
output:
  custom_rules:
    placement: after_section
    after_section: Commands
```

## Nested Mode (Per-Tier Overrides)

In nested mode (`structure: nested`), you can have:

- Root: `<project>/AGENTS.local.md` → injected into root AGENTS.md
- Per-tier: `<project>/<tier>/AGENTS.local.md` → injected into that tier's AGENTS.md

Example:

```
my-project/
├── AGENTS.md              ← root AGENTS.local.md injected here
├── AGENTS.local.md        ← your root-level overrides
└── backend/
    ├── AGENTS.md        ← backend/AGENTS.local.md injected here
    └── AGENTS.local.md  ← backend-specific overrides
```

Tier-level overrides follow the same placement rules but apply only to their tier.

## When to Use What

| Scenario | Approach |
|----------|----------|
| New project, want custom rules | Create AGENTS.local.md after first compose |
| Existing AGENTS.md, migrate to agentic | `agentic compose <profile> --import adopt` |
| Want to review before migrate | `agentic compose <profile> --import skip`, then create AGENTS.local.md manually |
| Quick overwrite existing | `agentic compose <profile> --import overwrite --yes` |
| Nested, rules for one tier only | Create `<tier>/AGENTS.local.md` |
| Nested, rules for all tiers | Use root AGENTS.local.md |

## Best Practices

1. **One H2 per concern** — keeps rules findable
2. **Keep it lean** — reference library fragments for full context
3. **Use after_section** — group related rules under existing sections
4. **Check before regenerate** — review AGENTS.local.md before each `agentic sync`

## Validation

Validation runs automatically as part of `agentic sync`. It checks:

- AGENTS.local.md exists → "[ OK ] Custom rules file present"
- custom_rules in profile but no AGENTS.local.md → "[WARN]"
- Duplicate H2 sections (also in AGENTS.md) → "[WARN]"

Regenerate doesn't touch AGENTS.local.md — your custom rules persist across updates.