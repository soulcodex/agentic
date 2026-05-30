---
name: code-review
description: >
  Orchestrates code review by detecting the project language and architecture, then
  routing to the appropriate specialized review skill (code-review-go,
  code-review-typescript, code-review-python, code-review-php,
  code-review-architecture). Falls back to the generic checklist when no specific
  skill applies. Invoked when the user asks for a review, code check, PR review,
  or quality assessment.
version: 2.0.0
tags:
  - quality
  - review
  - security
  - orchestration
resources:
  - checklist.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Code Review Skill

Entry point for all code reviews. Detects context and routes to the right specialized skill.

### Step 0 — Load Project Map

Check for `.agentic/project-map.md`:
- **If present**: read it. Use the layer structure, key modules, and conventions it defines
  as the foundation for all findings. Skip redundant filesystem exploration.
- **If absent**: run lightweight auto-discovery:
  - Detect language from `go.mod`, `package.json`, `tsconfig.json`, `pyproject.toml`, `composer.json`
  - List top-level directories to understand project structure
  - Read the entry point file (e.g. `main.go`, `src/index.ts`, `app/main.py`) for ~20 lines of context
  - Suggest running the `project-map` skill after this review to avoid discovery overhead next time

### Step 1 — Detect Language and Architecture

**Language detection** (inspect file extensions + manifest files):

| Signal | Language |
|---|---|
| `go.mod` present | Go |
| `tsconfig.json` or `package.json` with TypeScript devDep | TypeScript |
| `pyproject.toml` or `setup.py` | Python |
| `composer.json` | PHP |

**Architecture detection** (inspect directory names and import patterns):

| Signal | Architecture |
|---|---|
| `domain/`, `application/`, `infrastructure/`, `ports/` directories | Hexagonal / Clean |
| Aggregate root classes, domain events, value objects | DDD |
| `command/` + `query/` directories, command/query handler classes | CQRS |
| Multiple independent services each with their own data store | Microservices |

### Step 2 — Route to Specialized Skill(s)

Load and apply the appropriate skill(s):

| Detected | Skill to apply |
|---|---|
| Go | `code-review-go` |
| TypeScript / JavaScript | `code-review-typescript` |
| Python | `code-review-python` |
| PHP | `code-review-php` |
| Hexagonal / DDD / CQRS / Microservices markers | `code-review-architecture` (in addition to language skill) |
| Mixed or unrecognized | Apply generic `checklist.md` only |

Multiple skills can be active simultaneously (e.g. Go + Architecture for a Go hexagonal service).

### Step 3 — Apply Generic Checklist as Baseline

Always apply `checklist.md` (in this skill's directory) in addition to any specialized checklist.
This ensures correctness, security, tests, design, readability, performance, and observability
are evaluated regardless of language.

### Step 4 — Write the Combined Review

Merge findings from all active skills. Deduplicate findings that appear in multiple checklists.

Output format:

```
## Code Review

### What Works Well
- [At least one specific positive observation]

### Findings

#### Critical
- `path/to/file:line` [critical] Description. Why it must change. *Source: [name](url)*

#### High
- `path/to/file:line` [high] Description.

#### Medium
- `path/to/file:line` [medium] Description.

#### Low
- `path/to/file:line` [low] Minor note.

### Suggested Improvements
[Concrete alternatives and solutions for the most impactful findings]

### Summary
[One paragraph: overall quality, main risks, merge recommendation]
```

### Step 5 — Tone and Sources

- Be direct and specific. Reference exact line numbers.
- Cite verifiable sources (language specs, official docs, well-known style guides) inline for
  non-obvious findings. Format: *Source: [name](url)*
- Explain *why*, not just *what* to change.
- Assume good intent. Use sandwich communication: open with positives, then findings by
  severity descending, then actionable improvement path.
- For concurrency / state-machine issues too complex for prose: emit a `stateDiagram-v2`
  Mermaid block showing the problematic and correct state transitions.