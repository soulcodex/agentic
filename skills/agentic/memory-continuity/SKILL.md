---
name: memory-continuity
description: >
  Maintains concise cross-session continuity by writing structured memory
  handoff artifacts under .agentic/memories/ and loading only high-signal
  entries at session start. Invoked when continuity is needed across fresh
  context windows without replaying full chat history.
version: 1.0.0
tags:
  - agentic
  - memory
  - continuity
  - workflow
resources:
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

### Start-of-Session Retrieval Workflow

1. Read `.agentic/memories/MEMORY.md` if present.
2. If `index.md` exists, read only the latest 1 to 3 snapshot pointers.
3. Extract only high-signal items:
- current objective
- decisions made and rationale
- open risks/questions
- next concrete steps
4. Do not import verbose logs, full transcripts, or resolved low-impact details.

### End-of-Session Update Workflow

1. Create directories/files if missing:
- `.agentic/memories/`
- `.agentic/memories/snapshots/`
- `.agentic/memories/index.md` (with header/table)
2. Build a new memory entry using `memory-template.md`.
3. Update `MEMORY.md` additively:
- keep existing unresolved items
- append new high-signal updates
- remove or compress resolved/noisy items
4. Write a timestamped snapshot:
- filename format: `YYYY-MM-DDTHH-MM-SSZ.md`
5. Append one row in `index.md` pointing to the snapshot and objective.

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
- whether compaction/pruning occurred
- any unresolved risks carried forward
