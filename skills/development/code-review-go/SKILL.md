---
name: code-review-go
description: >
  Deep Go-specific code review covering goroutine lifecycle, data races,
  error wrapping, domain modeling, and interface design. Applied in addition
  to the generic code-review skill when Go code is detected. Invoked when
  reviewing Go PRs, Go code changes, or performing Go-specific quality checks.
version: 1.0.0
tags:
  - review
  - quality
  - go
  - concurrency
resources:
  - checklist.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Code Review — Go

Apply Go-specific linting using the checklist in this skill directory.

### Step 0 — Load Project Map

Check for `.agentic/project-map.md`:
- **If present**: read it. Use the layer structure, key modules table, and non-obvious
  conventions it defines to orient all findings. Skip redundant filesystem exploration.
- **If absent**: run lightweight auto-discovery:
  - Read `go.mod` to identify module name and Go version
  - List top-level directories
  - Read the entry point in `cmd/` for ~20 lines of context
  - Suggest running the `project-map` skill after this review to avoid this overhead next time

### Step 1 — Load Checklist

Read `checklist.md` in this skill directory and apply every item to the codebase.

### Step 2 — Determine Scope

- **If the user specifies files**, review those.
- **Otherwise review the current diff**: `git diff HEAD` or staged changes.
- **Do not review files outside stated scope**.

### Step 3 — Analyze with Go-specific Lenses

Work through the checklist systematically. For each issue found, note:
- File path and line number
- Risk level: `critical` / `high` / `medium` / `low`
- Description of the issue
- Why it matters (explain the impact)
- Verifiable source reference when the finding is non-obvious

For concurrency/state-transition issues too complex for prose, emit a Mermaid `stateDiagram-v2` diagram showing the problematic and correct state transitions.

### Step 4 — Write the Review

Output the review in this exact format:

```
## Code Review — Go

### What Works Well
- [At least one specific positive observation with file reference]

### Findings

#### Critical
- `path/to/file.go:42` [critical] Description. Why it must change. *Source: [Go Memory Model](https://go.dev/ref/mem)*

#### High
- `path/to/file.go:18` [high] Description. Why it matters. *Source: ...*

#### Medium
- `path/to/file.go:7` [medium] Description.

#### Low
- `path/to/file.go:5` [low] Minor note.

### Suggested Improvements
[Concrete alternatives and solutions for the most impactful findings]

### Summary
[One paragraph: overall quality, main risks, merge recommendation]
```

### Step 5 — Tone and Sources

- Be direct and specific. Reference exact line numbers.
- Cite verifiable sources (Go specification, Go Blog, official docs, well-known style guides)
  inline for non-obvious findings. Include the source name and URL.
- Explain *why*, not just *what* to change.
- Assume good intent. Use sandwich communication: open with positives, then findings
  by severity descending, then actionable improvement path.
- For race condition or state machine issues too complex for prose: emit a `stateDiagram-v2`
  Mermaid block showing the problematic and correct state transitions.