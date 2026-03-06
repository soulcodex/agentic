---
name: persist-plan
description: >
  Persists the current or completed plan as a structured Markdown file under
  .agentic/plans/ with a datestamped, slugged filename and registers it in the
  plans index. Enables multi-agent setups to discover past architectural decisions
  and plans without re-deriving context.
  Invoked when the user says "save this plan", "persist the plan", "record this decision",
  or at the end of any planning session that produced actionable architectural decisions.
version: 1.0.0
tags:
  - agentic
  - planning
  - architecture
  - multi-agent
resources:
  - plan-template.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Persist Plan Skill

Capture a plan or architectural decision as a discoverable, structured file so that
any agent or team member can find it later without re-deriving the context.

### Step 1 — Gather Plan Metadata

Collect (or confirm) the following before writing:

1. **Title** — a short, descriptive phrase (e.g., "Introduce CQRS in order service",
   "Migrate auth to hexagonal ports"). Used for the filename and H1 heading.
2. **Type** — one of: `feature`, `refactor`, `architecture`, `investigation`, `decision`.
3. **Status** — one of: `draft`, `in-progress`, `completed`, `superseded`.
4. **Affected areas** — which modules, bounded contexts, or services does this plan touch?
5. **Author** — the agent name or human handle that produced the plan.

### Step 2 — Derive the Filename

Build the filename as:

```
YYYY-MM-DD-{kebab-case-title}.md
```

Examples:
```
2026-03-06-introduce-cqrs-in-order-service.md
2026-03-06-migrate-auth-to-hexagonal-ports.md
```

- Use today's date in `YYYY-MM-DD` format.
- Slugify the title: lowercase, replace spaces and special characters with hyphens,
  strip leading/trailing hyphens.
- If a file with the same slug already exists for today, append `-2`, `-3`, etc.

### Step 3 — Write the Plan File

Save to `.agentic/plans/{filename}` using the template from `plan-template.md`.

Mandatory sections:

```markdown
# {Title}

**Date**: YYYY-MM-DD
**Type**: feature | refactor | architecture | investigation | decision
**Status**: draft | in-progress | completed | superseded
**Affected**: [list of modules / bounded contexts / services]
**Author**: {agent-name or handle}

## Context

What situation, problem, or question prompted this plan?
Be specific — a reader unfamiliar with the moment must understand the trigger.

## Goals

What does this plan aim to achieve?
Use bullet points. Each goal must be verifiable (done / not done).

## Approach

How will the goals be achieved?
Include the key decisions made, alternatives considered, and the rationale for
the chosen direction. Reference relevant fragments, ADRs, or tickets where applicable.

## Steps

Ordered list of concrete tasks derived from this plan.

1. ...
2. ...

## Risks & Open Questions

- Any unknowns, blockers, or decisions that still need to be made.

## Outcome

(Fill in when status moves to `completed` or `superseded`.)
What was the actual result? Did the plan change during execution? Why?
```

### Step 4 — Update the Plans Index

After writing the file, append a one-line entry to `.agentic/plans/INDEX.md`.
Create the file if it does not exist, with this header:

```markdown
# Plans Index

| Date | Title | Type | Status | File |
|------|-------|------|--------|------|
```

Append the new row:

```markdown
| YYYY-MM-DD | {Title} | {Type} | {Status} | [{filename}]({filename}) |
```

The index allows any agent to list all past plans with a single file read, without
scanning every individual plan file.

### Step 5 — Confirm

Report back:
- The full path of the written plan file.
- Whether the INDEX.md was created or updated.
- The plan's current status so the user knows whether to mark it `completed`.
