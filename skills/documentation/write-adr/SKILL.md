---
name: write-adr
description: >
  Creates an Architecture Decision Record (ADR) documenting a significant technical decision.
  Follows the standard ADR format with context, decision, and consequences.
  Invoked when the user says "write an ADR", "document this decision", or "create an architecture record".
version: 1.0.0
tags:
  - documentation
  - architecture
  - decision
resources:
  - adr-template.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Write ADR Skill

Create a well-structured Architecture Decision Record.

### Step 1 — Gather Information

Ask the user (if not already provided):
1. What decision was made?
2. What was the context or problem that prompted it?
3. What alternatives were considered?
4. What are the trade-offs or consequences of this decision?

### Step 2 — Determine the ADR Number

List existing ADRs in `docs/adr/` and increment the highest number.
If the directory does not exist, create it and start at `0001`.

### Step 3 — Write the ADR

Use the template from `adr-template.md`. Fill every section:
- **Title**: short, imperative phrase describing the decision
- **Status**: `Accepted` for a new decision
- **Date**: today's date in YYYY-MM-DD format
- **Context**: the situation that made a decision necessary — be specific about constraints
- **Decision**: what was decided — use active voice ("We will use X")
- **Consequences**: both positive and negative outcomes; what becomes easier and harder

The ADR must stand alone — a reader unfamiliar with the decision must understand it fully
from the ADR text without needing to ask follow-up questions.

### Step 4 — Write the File

Save to `docs/adr/NNNN-{kebab-case-title}.md`.

Example: `docs/adr/0003-use-postgresql-as-primary-store.md`
