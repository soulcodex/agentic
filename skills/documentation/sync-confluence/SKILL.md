---
name: sync-confluence
description: >
  Syncs engineering documentation (ADR, RFC, architecture) from docs/engineering/ to
  Confluence Cloud using the `mark` tool. Operates in two modes: scaffold (creates the
  directory tree locally) and CI sync (pushes on every main push). Only files with mark
  metadata headers are synced. Enforces diagram hierarchy (Mermaid > PlantUML > SVG > PNG).
version: 1.1.0
tags:
  - documentation
  - confluence
  - sync
  - ci
  - engineering
resources:
  - adr-template.md
  - rfc-template.md
  - architecture-template.md
  - engineering-scaffold.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Sync Confluence Skill

This skill syncs Markdown documentation from `docs/engineering/` to Confluence Cloud
using the `mark` tool. It operates in two distinct modes.

---

## Mode A — Scaffold (run once, locally)

Triggered when `docs/engineering/` does not exist. Run this once before any CI sync.

### Step A1 — Verify prerequisites

Ensure `mark` is installed:

```bash
mark --version
```

If not installed: `brew install mark` or `go install github.com/kovetskiy/mark@latest`.

### Step A2 — Create directory structure

Creates the full tree with `INDEX.md` stubs:

```
docs/engineering/
├── INDEX.md
├── adr/
│   └── INDEX.md
├── rfc/
│   └── INDEX.md
└── architecture/
    ├── INDEX.md
    └── resources/
```

### Step A3 — Add sample documents

Creates one example ADR and one example RFC using the templates so engineers have
a concrete reference to copy from.

### Step A4 — Output instructions

After scaffolding, output:

> Scaffold complete. Next steps:
> 1. Review and commit the new directory structure
> 2. Add mark metadata headers to your documents
> 3. Configure CONFLUENCE_* secrets in your CI environment
> 4. Push to main — CI sync will run automatically

**Do NOT push to Confluence in scaffold mode.**

---

## Mode B — CI Sync (run on every push to main)

Triggered in CI. No interactive prompts. Fails fast on any error.

### Step B1 — Verify environment

Check required env vars are set:

```bash
: "${CONFLUENCE_URL:?missing}"
: "${CONFLUENCE_USER:?missing}"
: "${CONFLUENCE_API_TOKEN:?missing}"
```

Exit 1 if any are missing.

### Step B2 — Verify scaffold exists

```bash
test -d docs/engineering || exit 1
```

Exit 1 if `docs/engineering/` does not exist (scaffold was not run).

### Step B3 — Scan for eligible documents

Scan for files with mark headers:

```bash
find docs/engineering/adr docs/engineering/rfc docs/engineering/architecture \
  -name '*.md' -exec grep -l '<!-- Space:' {} \;
```

### Step B4 — Diagram enforcement

**Mermaid**: Supported natively by `mark`. No action needed.

**PlantUML**: MUST be pre-rendered before committing. If any file contains a fenced
` ```plantuml ``` ` block, exit 1 with:

> ERROR: PlantUML block found in <file>. Pre-render to PNG before committing.

**PNG**: Warn (but continue) for any `.png` reference:

> WARN: PNG reference found in <file>. Prefer SVG or Mermaid.

### Step B5 — Sync to Confluence

Run `mark` with `--changes-only`:

```bash
mark \
  --base-url "$CONFLUENCE_URL" \
  --username "$CONFLUENCE_USER" \
  --password "$CONFLUENCE_API_TOKEN" \
  --changes-only \
  --files docs/engineering/adr docs/engineering/rfc docs/engineering/architecture
```

Report: pages created / updated / skipped.

---

## Diagram Enforcement Hierarchy

Enforce this preference order in all documents:

1. **Mermaid** — preferred, text-based, diffable, auto-rendered
2. **PlantUML** — acceptable only when Mermaid cannot express the diagram; must pre-render
3. **SVG** — acceptable for design-tool exports, vector, diffable
4. **PNG** — last resort; warn in CI

---

## Mark Metadata Headers

Every document must include:

```markdown
<!-- Space: YOUR_SPACE_KEY -->
<!-- Title: Your Page Title -->
<!-- Parent: Parent Page Name -->
<!-- Label: label1 -->
```

- `Space` (required): Confluence space key
- `Title` (required): Page title
- `Parent` (recommended): Parent page (defaults to space root)
- `Label` (optional): One or more labels

---

## Known Limitations

- **One-way sync**: Edits in Confluence are overwritten on next push
- **PlantUML**: Must pre-render to PNG before committing (not handled in CI)
- **Bidirectional sync**: Out of scope
- **Opt-in**: Only files with mark headers are synced