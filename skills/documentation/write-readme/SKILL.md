---
name: write-readme
description: >
  Generates or updates a README.md for a project or package. Reads the source code
  to understand the project and produces a clear, accurate README following the
  project's conventions.
  Invoked when the user asks to write, update, or generate a README.
version: 1.0.0
tags:
  - documentation
  - readme
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Write README Skill

Generate or update the README.md for the current project or specified package.

### Step 1 — Read the Project

Read:
- `package.json` / `go.mod` / `pyproject.toml` / `composer.json` — for name, description, scripts
- Main entry point — to understand what the code does
- Existing `.env.example` — for environment variable documentation
- Existing README (if any) — to preserve information that cannot be inferred from code

### Step 2 — Draft the README

Include these sections in order:

```markdown
# {project-name}

{One to three sentence description of what this is and why it exists}

## Requirements

{Runtime, language version, any system dependencies}

## Getting Started

{Exact commands to clone, install dependencies, configure, and run}

## Configuration

{Table of environment variables from .env.example: name, required/optional, description, default}

## Running Tests

{Exact command(s) to run the test suite}

## Architecture

{Optional: 2-4 sentences on the key design decisions. Link to docs/adr/ if it exists.}

## Contributing

{How to contribute: branch naming, PR process, running checks locally}
```

Only include a section if there is real content for it. Do not include placeholder text.

### Step 3 — Accuracy Check

Every command in the README must be verified to actually work. If you cannot verify a command
because the environment is unavailable, mark it with `# verify this command` comment.

### Step 4 — Write the File

Write (or overwrite) `README.md` at the project root. If updating, preserve sections that
contain manually curated content (e.g., architecture notes, contributing guidelines) and only
regenerate sections derived from code.
