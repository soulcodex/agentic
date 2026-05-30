---
name: code-review-python
description: >
  Deep Python-specific code review covering type annotations, async pitfalls, mutable defaults,
  threading safety, and domain modeling. Applied in addition to the generic code-review
  skill when Python code is detected. Invoked when reviewing Python PRs, Py changes, or
  performing Python-specific quality checks.
version: 1.0.0
tags:
  - review
  - quality
  - python
  - async
resources:
  - checklist.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Code Review — Python

Apply Python-specific linting using the checklist in this skill directory.

### Step 0 — Load Project Map

Check for `.agentic/project-map.md`:
- **If present**: read it. Use the layer structure, key modules table, and non-obvious
  conventions it defines to orient all findings. Skip redundant filesystem exploration.
- **If absent**: run lightweight auto-discovery:
  - Read `pyproject.toml` to identify dependencies and build system
  - Detect framework (FastAPI, Django, Typer, etc.) from dependencies
  - List top-level `src/` or app directories
  - Suggest running the `project-map` skill after this review to avoid this overhead next time

### Step 1 — Load Checklist

Read `checklist.md` in this skill directory and apply every item to the codebase.

### Step 2 — Determine Scope

- **If the user specifies files**, review those.
- **Otherwise review the current diff**: `git diff HEAD` or staged changes.
- **Do not review files outside stated scope**.

### Step 3 — Analyze with Python-specific Lenses

Work through the checklist systematically. For each issue found, note:
- File path and line number
- Risk level: `critical` / `high` / `medium` / `low`
- Description of the issue
- Why it matters
- Verifiable source reference when the finding is non-obvious

Focus particularly on:
- Type annotation completeness and mypy strict mode violations
- Mutable default arguments
- Async/blocking I/O in coroutines
- Threading safety issues
- Domain modeling with dataclasses/Pydantic

### Step 4 — Write the Review

Output the review in this exact format:

```
## Code Review — Python

### What Works Well
- [At least one specific positive observation with file reference]

### Findings

#### Critical
- `path/to/file.py:42` [critical] Description. Why it must change. *Source: [PEP 484 — Type Hints](https://peps.python.org/pep-0484/)*

#### High
- `path/to/file.py:18` [high] Description. Why it matters. *Source: ...*

#### Medium
- `path/to/file.py:7` [medium] Description.

#### Low
- `path/to/file.py:5` [low] Minor note.

### Suggested Improvements
[Concrete alternatives and solutions for the most impactful findings]

### Summary
[One paragraph: overall quality, main risks, merge recommendation]
```

### Step 5 — Tone and Sources

- Be direct and specific. Reference exact line numbers.
- Cite verifiable sources (PEP documents, Python docs, well-known style guides)
  inline for non-obvious findings. Include the source name and URL.
- Explain *why*, not just *what* to change.
- Assume good intent. Use sandwich communication: open with positives, then findings
  by severity descending, then actionable improvement path.
- For async coroutine or threading state issues too complex for prose: emit a `stateDiagram-v2`
  Mermaid block showing the problematic and correct state transitions.