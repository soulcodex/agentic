---
name: code-review
description: >
  Performs a structured code review on the current diff or specified files.
  Checks for correctness, security vulnerabilities, test coverage, code style,
  and adherence to the project's architecture patterns. Invoked when the user
  asks for a review, code check, pr review, or quality assessment.
version: 1.0.0
tags:
  - quality
  - review
  - security
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

Perform a structured, thorough code review following the process below.

### Step 1 — Load the Checklist

Read `checklist.md` (in this skill's directory) and apply every item before writing the review.

### Step 2 — Determine Scope

- If the user specifies files, review those.
- Otherwise, review the current diff (`git diff HEAD` or the staged changes).
- Do not review files outside the stated scope.

### Step 3 — Analyze

Work through the checklist systematically. For each issue found, note:
- File path and line number
- Severity: `blocking`, `suggestion`, or `nit`
- Clear description of the issue and why it matters

### Step 4 — Write the Review

Output the review in this exact format:

```
## Code Review

### Summary
[One paragraph: overall quality, confidence in the change, merge recommendation]

### Blocking Issues
<!-- Must be fixed before merge. Empty = none. -->
- `path/to/file.ts:42` [blocking] Description and why it must change.

### Suggestions
<!-- Non-blocking improvements worth considering. -->
- `path/to/file.ts:18` [suggestion] Description.

### Nits
<!-- Trivial style or wording notes. -->
- `path/to/file.ts:5` [nit] Description.

### What Works Well
- [At least one specific positive observation]
```

### Step 5 — Tone

Be direct and specific. Reference exact line numbers. Explain *why* — not just *what* to change.
Assume good intent. Acknowledge what is done well.
