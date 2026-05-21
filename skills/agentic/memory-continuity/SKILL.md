---
name: memory-continuity
description: >
  Preserves cross-session continuity with deterministic MEMORY.md, index.md,
  and snapshot handoffs under .agentic/memories/.
version: 1.0.0
tags:
  - agentic
  - memory
  - continuity
  - workflow
resources:
  - memory-current-template.md
  - index-template.md
  - memory-template.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Memory Continuity Skill

Use this skill to preserve high-value context between clean sessions while
avoiding noisy or low-signal carryover.

### Storage Layout (Hybrid Contract)

Use this deterministic structure:

```text
.agentic/
  memories/
    MEMORY.md
    index.md
    snapshots/
      YYYY-MM-DDTHH-MM-SSZ.md
```

Rules:
- If `.agentic/memories/` does not exist, create it and required child paths.
- `MEMORY.md` is the current canonical continuity file.
- `index.md` is a small pointer log to snapshots.
- `snapshots/` stores timestamped continuity checkpoints.
- Use `memory-current-template.md` for `MEMORY.md` initialization.
- Use `index-template.md` for `index.md` initialization.

### First-Run Initialization and Bootstrap Rules

When `MEMORY.md` and `index.md` do not exist:

1. If there is active iteration context (for example an open issue/PR, active branch work,
   or already-decided next steps), initialize both files from templates immediately.
2. If there is no active iteration context, inspect commit history for signal:
- if history is rich enough to derive meaningful continuity, ask the user before generating
  a brief bootstrap memory from commits;
- if history is not rich enough, ask the user before leaving memory uninitialized.
3. Never invent synthetic history. If signal is insufficient, state that explicitly.

### Start-of-Session Retrieval Workflow

1. If files are missing, apply First-Run Initialization and Bootstrap Rules.
2. Read `.agentic/memories/MEMORY.md` if present.
3. If `index.md` exists, read only the latest 1 to 3 snapshot pointers.
4. Extract only high-signal items:
- current objective
- decisions made and rationale
- open risks/questions
- next concrete steps
5. Do not import verbose logs, full transcripts, or resolved low-impact details.

### End-of-Session Update Workflow

1. Create directories/files if missing:
- `.agentic/memories/`
- `.agentic/memories/snapshots/`
- `.agentic/memories/MEMORY.md` (from `memory-current-template.md`)
- `.agentic/memories/index.md` (from `index-template.md`)
2. Build a new memory entry using `memory-template.md`.
3. Update `MEMORY.md` additively:
- keep existing unresolved items
- append new high-signal updates
- remove or compress resolved/noisy items
4. Write a timestamped snapshot:
- filename format: `YYYY-MM-DDTHH-MM-SSZ.md`
5. Append one row in `index.md` pointing to the snapshot and objective.

### Multi-Agent and Worktree Coordination Rules

- Treat `MEMORY.md` as shared state: do not delete or rewrite another agent's active workstream
  row or unresolved items.
- Each agent should update only its own workstream row (keyed by worktree + branch + agent label)
  and append decisions/risks with timestamps.
- If multiple agents are active, preserve all active workstream rows and resolve conflicts by
  appending a new decision note rather than overwriting history.

### Signal-Over-Noise Constraints

Always exclude:
- full command history
- raw terminal dumps and repetitive logs
- obvious or already-resolved implementation minutiae
- speculative ideas with no immediate decision/value

Prefer compact, testable statements and explicit decisions.

### Pruning and Compaction Rules

- Keep `MEMORY.md` under ~120 lines by compacting resolved sections.
- Keep only the latest 20 snapshot files by default.
- Preserve older snapshots only if tagged as milestone decisions.
- On compaction, never drop unresolved risks or agreed next steps.

### Output Requirements

When this skill runs, report:
- files created or updated
- snapshot filename written
- whether first-run bootstrap was used (and whether user approval was requested)
- whether compaction/pruning occurred
- any unresolved risks carried forward
