---
name: write-plan
description: >
  Automatically persists every plan produced by the agent as a structured
  Markdown file under .agentic/plans/ with a datestamped slug and updates
  the plans index. Prevents PLAN.md from being accidentally committed to
  the repository. Invoked automatically at the end of any planning session —
  no user prompt required. Triggered whenever an agent completes a plan,
  proposes a multi-step approach, or produces an architectural decision.
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

## Write Plan Skill

Automatically capture every agent-produced plan as a discoverable file in
`.agentic/plans/` — so plans are preserved locally but never pollute the git tree.

> **This skill is agent-invoked, not user-invoked.** Do not prompt the user for
> metadata. Derive everything from context and write silently.

---

### Step 1 — Derive Metadata from Context

Extract automatically — no prompts:

- **Title**: from the plan's main heading or the task description.
- **Type**: infer from the nature of the work:
  - `feature` — new capability being added
  - `architecture` — structural or design decision
  - `decision` — a choice between alternatives
  - `refactor` — improving existing code without behaviour change
  - `investigation` — exploring a problem or unknown
- **Status**: always `draft` on auto-save.
- **Affected**: list of modules, files, or systems touched by the plan.
- **Author**: the agent name or model identifier.

---

### Step 2 — Build the Filename

```
YYYY-MM-DD-{kebab-case-title}.md
```

Rules:
- Use today's date in `YYYY-MM-DD` format.
- Slugify the title: lowercase, replace spaces and special characters with `-`, strip leading/trailing hyphens.
- If a file with the same slug already exists for today, append `-2`, `-3`, etc.

Examples:
```
2026-04-04-add-golang-manual-di-skill.md
2026-04-04-refactor-auth-module.md
```

---

### Step 3 — Write the Plan File

Save to `.agentic/plans/{filename}` using `plan-template.md` as the structure.

Mandatory sections (never omit):

- **Context** — what situation or problem prompted this plan?
- **Goals** — verifiable bullet points (done / not done).
- **Approach** — key decisions, alternatives considered, rationale.
- **Steps** — ordered list of concrete tasks.
- **Risks & Open Questions** — unknowns and blockers.
- **Outcome** — leave blank; filled in when status moves to `completed`.

---

### Step 4 — Ensure `.agentic/plans/` is Gitignored

Check the project's `.gitignore`. If `.agentic/plans/` is not present, add it:

```
# Agentic — local plan files (managed by write-plan skill)
.agentic/plans/
```

This ensures plan files are never accidentally committed.

---

### Step 5 — Upsert the Plans Index

Append one row to `.agentic/plans/INDEX.md`. Create the file with this header if it does not exist:

```markdown
# Plans Index

| Date | Title | Type | Status | File |
|------|-------|------|--------|------|
```

Append:
```markdown
| YYYY-MM-DD | {Title} | {Type} | {Status} | [{filename}]({filename}) |
```

---

### Step 6 — Clean Up Any PLAN.md

If a `PLAN.md` exists in the working directory or repo root, **delete it** after saving
to `.agentic/plans/`. This is the primary reason this skill exists — `PLAN.md` at the
repo root is a commit accident waiting to happen.

---

### Step 7 — Report

Emit exactly one line:

```
Plan saved: .agentic/plans/{filename}
```

Do not emit anything else unless there was an error.
