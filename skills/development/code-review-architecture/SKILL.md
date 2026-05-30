---
name: code-review-architecture
description: >
  Architecture-focused code review covering hexagonal boundary violations, DDD anti-patterns,
  CQRS misuse, and microservices coupling issues. Applied in addition to the language-specific
  review skill when architecture markers are detected. Invoked when reviewing hexagonal architectures,
  DDD patterns, or microservices boundaries.
version: 1.0.0
tags:
  - review
  - quality
  - architecture
  - ddd
  - cqrs
  - microservices
resources:
  - checklist.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Code Review — Architecture

Apply architecture-focused review using the checklist in this skill directory.

### Step 0 — Load Project Map

Check for `.agentic/project-map.md` (this is essential for architecture review):
- **If present**: read it. Use the layer structure, key modules table, and non-obvious
  conventions as the core concern. Architecture reviews depend heavily on knowing which
  directories map to which layers.
- **If absent**: abort this specialized review and suggest running the `project-map` skill first.

### Step 1 — Load Checklist

Read `checklist.md` in this skill directory and apply every item to the codebase.

### Step 2 — Determine Scope

- **If the user specifies files**, review those.
- **Otherwise review the current diff**: `git diff HEAD` or staged changes.
- **Do not review files outside stated scope**.

### Step 3 — Analyze with Architecture-specific Lenses

Work through the checklist systematically. For each issue found, note:
- File path and line number
- Risk level: `critical` / `high` / `medium` / `low`
- Description of the issue
- Why it matters
- Verifiable source reference when the finding is non-obvious

Architecture concerns to focus on:
- Hexagonal/Clean architecture boundary violations
- Anemic domain model (DDD anti-pattern)
- God Aggregate violations
- CQRS command/query leakage
- Microservice coupling and shared databases

For aggregate lifecycle violations or async state machine bugs that are too complex for prose, emit a Mermaid `stateDiagram-v2` diagram.

### Step 4 — Write the Review

Output the review in this exact format:

```
## Code Review — Architecture

### What Works Well
- [At least one specific positive observation with file reference]

### Findings

#### Critical
- `path/to/domain/order.go:42` [critical] Description. Why it must change. *Source: [Hexagonal Architecture — Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture/)*

#### High
- `path/to/application/service.go:18` [high] Description. Why it matters. *Source: ...*

#### Medium
- `path/to/infrastructure/repository.go:7` [medium] Description.

#### Low
- `path/to/pkg/foo.go:5` [low] Minor note.

### Suggested Improvements
[Concrete alternatives and solutions for the most impactful findings]

### Summary
[One paragraph: overall quality, main risks, merge recommendation]
```

### Step 5 — Tone and Sources

- Be direct and specific. Reference exact line numbers.
- Cite verifiable sources (DDD books, architecture blog posts, well-known patterns)
  inline for non-obvious findings. Include the source name and URL.
- Explain *why*, not just *what* to change.
- Assume good intent. Use sandwich communication: open with positives, then findings
  by severity descending, then actionable improvement path.
- For aggregate lifecycle or state machine issues too complex for prose: emit a
  `stateDiagram-v2` Mermaid block showing the problematic and correct state transitions.