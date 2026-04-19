# Engineering Documentation Scaffold

This document describes the canonical directory structure for engineering documentation
under `docs/engineering/`. All docs in this tree are synced to Confluence via CI.

---

## Directory Tree

```
docs/
└── engineering/
    ├── INDEX.md                          # Space-level navigation
    ├── adr/
    │   ├── INDEX.md                      # ADR index: all ADRs with status
    │   ├── adr-0001-<slug>.md            # Single-file ADR
    │   └── adr-0002-<slug>/              # Multi-asset ADR (diagrams)
    │       ├── INDEX.md                  # Folder contents
    │       ├── adr-0002-<slug>.md        # The ADR itself
    │       └── diagram.svg               # Supporting diagram
    ├── rfc/
    │   ├── INDEX.md                      # RFC index: all RFCs with status
    │   ├── rfc-0001-<slug>.md
    │   └── rfc-0002-<slug>/
    │       ├── INDEX.md
    │       ├── rfc-0002-<slug>.md
    │       └── diagram.svg
    └── architecture/
        ├── INDEX.md                      # Architecture index
        ├── <component>.md                # Component doc (visual-first)
        └── resources/
            ├── <component>/
            │   └── <diagram>.(mmd|svg)
            └── <flow>/
                └── <diagram>.(mmd|svg)
```

---

## ADR vs RFC Distinction

| | ADR | RFC |
|---|---|---|
| **Purpose** | Binding architectural decision, already in force | Proposal / exploration, may or may not be adopted |
| **Lifecycle** | Accepted → Superseded (immutable once accepted) | Draft → Accepted / Rejected |
| **Graduation** | — | An accepted RFC *may* produce an ADR |
| **Numbering** | Sequential `adr-NNNN` | Sequential `rfc-NNNN` |

---

## INDEX.md Contract

Every `INDEX.md` in this tree must answer three questions without opening other files:

1. **What is this folder?** — one sentence describing the category.
2. **What is each entry?** — table with: filename/folder, one-line summary, status (ADR/RFC), date.
3. **Navigation hint** — short note like "If you are looking for X, open Y".

### Example: `adr/INDEX.md`

```markdown
# ADR Index

Binding architectural decisions in force for this project.
An ADR is immutable once Accepted; superseded ADRs are kept for history.

| # | File | Title | Status | Date |
|---|------|-------|--------|------|
| 0001 | [adr-0001-use-postgresql.md](adr-0001-use-postgresql.md) | Use PostgreSQL as primary store | Accepted | 2026-01-10 |
| 0002 | [adr-0002-event-sourcing/](adr-0002-event-sourcing/) | Adopt event sourcing for order service | Draft | 2026-03-22 |

> Navigation: looking for a data-storage decision? Check entries tagged `storage`.
> Looking for a superseded decision? Status column shows `Superseded`.
```

---

## Naming Conventions

- **ADR files**: `adr-NNNN-<kebab-case-slug>.md`
- **RFC files**: `rfc-NNNN-<kebab-case-slug>.md`
- **Architecture docs**: `<kebab-case-component-name>.md`
- **Folders for multi-asset docs**: Same name as the document (minus extension)
- All names: lowercase, kebab-case, no spaces

---

## Diagram Enforcement Hierarchy

When adding diagrams to any document, follow this preference order:

1. **Mermaid fenced block** — preferred for all flow/sequence/entity diagrams.
   Text-based, diffable, rendered automatically by `mark` to PNG.
2. **PlantUML** — acceptable only when Mermaid cannot express the diagram type.
   Must be pre-rendered to PNG before committing (not in CI).
3. **SVG** — acceptable for diagrams exported from design tools (Figma, draw.io).
   Vector, scalable, diffable as XML.
4. **PNG** — last resort. Binary, not diffable, not scalable.
   **CI will warn** if a `.png` reference is found.

---

## Mark Metadata Headers

Every document synced to Confluence must include mark headers:

```markdown
<!-- Space: YOUR_SPACE_KEY -->
<!-- Title: Your Page Title -->
<!-- Parent: Parent Page Name -->
<!-- Label: label1 -->
<!-- Label: label2 -->
```

- `Space` (required): Confluence space key
- `Title` (required): Page title in Confluence
- `Parent` (recommended): Parent page title (defaults to space root)
- `Label` (optional): One or more labels for organization

---

## CI Sync Workflow

The skill runs in CI on every push to `main`:

1. Verify `CONFLUENCE_URL`, `CONFLUENCE_USER`, `CONFLUENCE_API_TOKEN`
2. Verify `docs/engineering/` exists (scaffold must be run first)
3. Scan all `.md` files under `docs/engineering/` for mark headers
4. For any ` ```plantuml ``` ` block — **fail** (must pre-render)
5. Warn for any `.png` reference (prefer SVG or Mermaid)
6. Run `mark --changes-only` across eligible files
7. Report pages created / updated / skipped