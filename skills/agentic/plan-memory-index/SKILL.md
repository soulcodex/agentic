---
name: plan-memory-index
description: >
  Maintains an indexed memory of applied plans under .agentic/plans/ so agents
  can retrieve relevant prior context quickly before pulling full issue threads.
  Stores concise per-plan memory entries with optional GitHub issue links and
  status metadata, then supports list-first and select-first retrieval.
version: 1.0.0
tags:
  - agentic
  - planning
  - memory
  - indexing
resources:
  - index-template.md
  - memory-entry-template.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Plan Memory Index Skill

Keep a compact, queryable memory of plans that were already applied, so agents can
recover only the right context first and fetch full external issue details later.

Use this skill for concise continuity memory. Do not use it as a full session log.

### Step 1 - Ensure Deterministic Storage Layout

Ensure this directory structure exists:

```text
.agentic/
  plans/
    index.md
    memory/
```

Rules:
- Create `.agentic/plans/` and `.agentic/plans/memory/` when missing.
- Keep the index filename exactly `index.md` (lowercase).
- Keep all plan memory entries in `.agentic/plans/memory/`.

### Step 2 - Create or Update a Memory Entry

Create one Markdown file per memory entry:

```text
.agentic/plans/memory/YYYY-MM-DD-{plan-slug}.md
```

Example:
```text
.agentic/plans/memory/2026-05-16-issue-149-plan-memory-index.md
```

Frontmatter fields:
- `id`: stable unique ID, e.g. `plan-memory-2026-05-16-001`
- `plan_slug`: kebab-case plan identifier
- `summary`: concise applied-plan excerpt
- `linked_issues`: optional list of GitHub issue URLs
- `status`: one of `draft`, `in-progress`, `done`, `superseded`
- `last_used_at`: ISO-8601 UTC timestamp
- `tags`: short list for retrieval

Use `memory-entry-template.md`.

### Step 3 - Enforce Summary Length Guidance

Keep memory entries high signal and small:
- `summary`: target 1 to 3 sentences.
- Hard cap: 280 characters.
- Do not copy full issue bodies, long logs, or full plans into memory entries.
- If more detail is needed, store a short pointer in `summary` and defer deep fetch.

### Step 4 - Upsert `.agentic/plans/index.md`

Create `index.md` from `index-template.md` if missing. Then add or update a single row
for the memory entry.

Required columns:
- `id`
- `plan_slug`
- `status`
- `last_used_at`
- `linked_issues`
- `memory_file`

Upsert behavior:
- If `id` already exists, update that row in place.
- Otherwise append one new row.
- Keep rows sorted by `last_used_at` descending.

### Step 5 - Retrieval Workflow (Select Before Deep Fetch)

When context is needed:
1. Read only `.agentic/plans/index.md`.
2. Filter by `plan_slug`, `tags`, or `linked_issues`.
3. Select one candidate memory entry.
4. Read the selected memory file.
5. Fetch full GitHub issue context only if still needed.

This list-first workflow avoids loading unnecessary historical context.

### Step 6 - Update and Prune Rules

Update rules:
- Update `last_used_at` every time a memory entry is used.
- Update `status` when plan lifecycle changes.
- Keep the same `id` and file path; do not create duplicates for the same applied plan
  unless there is a materially new plan variant.

Prune rules:
- Prefer `status: superseded` over deletion.
- If deletion is required, delete the memory file and remove its row from `index.md`
  in the same change.
- During periodic cleanup, archive or remove entries not used for 180+ days only when
  they are `done` or `superseded` and have no active dependencies.
