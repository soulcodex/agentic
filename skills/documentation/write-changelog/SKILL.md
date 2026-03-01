---
name: write-changelog
description: >
  Generates a CHANGELOG.md entry for a release by summarizing git commits
  since the last tag. Groups changes by type: Added, Changed, Fixed, Removed.
  Follows Keep a Changelog format (https://keepachangelog.com).
  Invoked when the user asks to update the changelog, write release notes, or prepare a release.
version: 1.0.0
tags:
  - documentation
  - release
  - changelog
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Write Changelog Skill

Generate a CHANGELOG.md entry for the next release.

### Step 1 — Determine the Version

Ask the user for the new version number (SemVer) if not provided.

### Step 2 — Gather Commits

Run: `git log {last-tag}..HEAD --oneline --no-merges`

If no previous tag exists: `git log --oneline --no-merges`

### Step 3 — Categorize Changes

Group commits by their Conventional Commit type:

| Commit type | Changelog section |
|---|---|
| `feat` | Added |
| `fix` | Fixed |
| `refactor`, `perf` | Changed |
| `docs` | Changed |
| `BREAKING CHANGE` footer | (prefix with `**BREAKING**`) |
| `chore`, `ci`, `build` | (omit from changelog) |

### Step 4 — Write the Entry

Format:

```markdown
## [{{VERSION}}] - {{DATE}}

### Added
- Description of new feature (refs #issue)

### Changed
- Description of change (refs #issue)

### Fixed
- Description of bug fix (refs #issue)

### Removed
- Description of removed feature (refs #issue)
```

- Each item starts with a capital letter, no period at the end.
- Include issue/PR references where available.
- Write from the user's perspective — what changed for them, not what code changed.

### Step 5 — Insert into CHANGELOG.md

Prepend the new entry below the `# Changelog` header and above previous entries.
If no CHANGELOG.md exists, create it with the standard header first.
