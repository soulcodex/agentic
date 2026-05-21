---
name: format-markdown
description: >
  Formats Markdown files consistently using project-native tooling first
  (repo scripts/config), then safe fallback formatters, and verifies the result
  with lint/check commands. Invoked when the user asks to format markdown,
  tidy docs, normalize README files, or fix markdown style drift.
version: 1.0.0
tags:
  - documentation
  - markdown
  - formatting
  - linting
resources:
  - rules.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Markdown Formatting Skill

Format Markdown files so they are structurally correct, readable, and consistent with
the repository's formatting/lint rules.

### Step 1 - Determine Scope

- If the user provides files, format only those files.
- Otherwise format changed Markdown files in the current branch/diff.
- If no changed Markdown files exist, ask for explicit paths before proceeding.

### Step 2 - Load Local Conventions

- Read project formatting/lint config when present (for example `.prettierrc*`,
  `.markdownlint*`, lint scripts in `package.json`, `justfile`, `Makefile`).
- Apply the repository's conventions over generic defaults.
- Read `rules.md` and treat those rules as baseline behavior.

### Step 3 - Apply Formatter (Preferred Order)

1. Run repository-native formatting command if one exists (for example `just`, `make`, or package script targeting markdown).
2. If none exists, use a standard Markdown formatter available in the repo toolchain (for example Prettier).
3. If Markdown linter auto-fix is configured, run it after formatting.

Do not introduce formatting tools that are not already part of the repository unless the user asks.

### Step 4 - Validate

- Run markdown checks/lint commands available in the repository.
- If checks fail with auto-fixable findings, apply fixes and re-run checks.
- Report any remaining non-auto-fixable violations with file paths.

### Step 5 - Safety Rules

- Preserve document meaning and code block content.
- Do not rewrite prose for style unless the user asks.
- Do not alter links/anchors in ways that break navigation.
- Keep frontmatter valid and unchanged semantically.

### Step 6 - Output

Report:
- files formatted
- command(s) used
- verification command(s) and results
- any remaining manual fixes required
