---
name: sync-confluence
description: >
  Syncs Markdown documentation to Confluence Cloud using the `mark` tool. Scans
  docs directories for files with mark metadata headers, validates them, performs
  a dry-run preview, handles Mermaid/PlantUML diagrams, and pushes to Confluence.
  Invoked when the user wants to publish documentation from the repo to Confluence.
version: 1.0.0
tags:
  - documentation
  - confluence
  - sync
resources:
  - confluence-page-template.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Sync Confluence Skill

This skill syncs Markdown documentation from the repository to Confluence Cloud using
the `mark` tool (github.com/kovetskiy/mark). Only files with mark metadata headers are synced
(opt-in).

---

### Step 1 — Prerequisites check

Verify `mark` is available:

```bash
mark --version
```

If not installed, provide one of these options:

- **Homebrew**: `brew install mark`
- **Go**: `go install github.com/kovetskiy/mark@latest`
- **Docker**: `docker pull kovetskiy/mark:latest`

Verify required environment variables are set:

```bash
echo "CONFLUENCE_URL: ${CONFLUENCE_URL:+set}"
echo "CONFLUENCE_USER: ${CONFLUENCE_USER:+set}"
echo "CONFLUENCE_API_TOKEN: ${CONFLUENCE_API_TOKEN:+set}"
```

If any are missing, stop and report which ones are missing. Do not proceed until all
three are set.

---

### Step 2 — Identify documents to sync

A document is eligible for sync if it contains a mark metadata header block (HTML
comments). The minimum required headers are `Space` and `Title`.

Default directories to scan: `docs/adr/`, `docs/processes/`, `docs/architecture/`.
Accept an optional path argument to override.

Scan for eligible `.md` files:

```bash
find docs/adr docs/processes docs/architecture -name '*.md' -exec grep -l '<!-- Space:' {} \;
```

If none found, inform the user and stop. Do NOT sync documents lacking mark metadata
headers.

---

### Step 3 — Validate metadata headers

For each eligible file, check:

- `<!-- Space: ... -->` — required
- `<!-- Title: ... -->` — required
- `<!-- Parent: ... -->` — recommended; warn if missing (page created at space root)
- `<!-- Label: ... -->` — optional; warn if absent

Example validation:

```bash
for file in "$eligible_files"; do
  grep -q '<!-- Space:' "$file" || echo "MISSING Space: $file"
  grep -q '<!-- Title:' "$file" || echo "MISSING Title: $file"
  grep -q '<!-- Parent:' "$file" || echo "WARN missing Parent: $file"
done
```

Report any files with invalid/missing required headers. Stop if required headers
are missing.

---

### Step 4 — Dry-run preview

Run mark in dry-run mode to preview changes:

```bash
mark \
  --base-url "$CONFLUENCE_URL" \
  --username "$CONFLUENCE_USER" \
  --password "$CONFLUENCE_API_TOKEN" \
  --dry-run \
  --files <eligible-files>
```

Show the user the list of pages that would be created or updated. Ask for explicit
confirmation before proceeding to the live push. Do not skip this step.

---

### Step 5 — Diagram pre-rendering (optional)

**Mermaid**: `mark` handles Mermaid automatically — renders to PNG and attaches to
the page. No action needed. Inform the user that Mermaid blocks will be pre-rendered.

**PlantUML**: `mark` does NOT render PlantUML natively. If any eligible file contains
a fenced ` ```plantuml ``` ` block:

1. Instruct the user to pre-render PlantUML diagrams to PNG using a PlantUML server
   or CLI (`java -jar plantuml.jar -tpng diagram.puml`).
2. Replace the fenced PlantUML block with an image reference.
3. List the affected files.

---

### Step 6 — Push to Confluence

Run mark with `--changes-only` to skip unchanged pages:

```bash
mark \
  --base-url "$CONFLUENCE_URL" \
  --username "$CONFLUENCE_USER" \
  --password "$CONFLUENCE_API_TOKEN" \
  --changes-only \
  --files <eligible-files>
```

For Docker users:

```bash
docker run --rm \
  -v "$(pwd):/docs" \
  -e CONFLUENCE_URL \
  -e CONFLUENCE_USER \
  -e CONFLUENCE_API_TOKEN \
  kovetskiy/mark:latest \
    --base-url "$CONFLUENCE_URL" \
    --username "$CONFLUENCE_USER" \
    --password "$CONFLUENCE_API_TOKEN" \
    --changes-only \
    --files /docs/docs/adr /docs/docs/processes /docs/docs/architecture
```

Report success/failure per file. On any failure, show the mark error output and stop.

---

### Step 7 — Optional: Scaffold CI workflow

If the user asks for CI integration, scaffold `.github/workflows/confluence-sync.yml`:

```yaml
name: Sync to Confluence

on:
  push:
    branches: [main]
    paths: ['docs/**/*.md']

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Sync to Confluence
        uses: kovetskiy/mark@v16
        with:
          base_url: ${{ secrets.CONFLUENCE_URL }}
          username: ${{ secrets.CONFLUENCE_USER }}
          password: ${{ secrets.CONFLUENCE_API_TOKEN }}
          files: |
            docs/adr
            docs/processes
            docs/architecture
          changes_only: true
```

Warn: secrets must be registered in repo Settings → Secrets and variables →
Actions.

---

### Step 8 — Caveats & known limitations

- **One-way sync only**: Edits made directly in Confluence will be overwritten on
  the next push from the repo. Confluence is the read surface; the repo is the
  write surface.
- **PlantUML**: Not auto-rendered; pre-render to PNG required before syncing.
- **Bidirectional sync**: Explicitly out of scope for v1.0.0.
- **Opt-in**: Only files with mark metadata headers are synced.