---
name: project-map
description: >
  Generates a compact structural orientation document (.agentic/project-map.md)
  so any agent can understand codebase structure without filesystem exploration.
  Invoked when onboarding to a codebase, exploring unfamiliar projects, or auditing
  code layout and conventions.
version: 1.0.0
tags:
  - documentation
  - exploration
  - onboarding
resources:
  - template.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Project Map Skill

Generate `.agentic/project-map.md` to orient any agent to the codebase.

### Step 0 — Check Existing Map

Check if `.agentic/project-map.md` already exists:
- **If present**: Ask the user if they want to refresh it or keep existing.
  - Default: keep existing unless `--refresh` flag is passed or user explicitly requests refresh.
- **If absent**: Continue to Step 1.

### Step 1 — Auto-discover Codebase Structure

Detect the language and architecture by inspecting the filesystem:

1. **Detect language(s)** — inspect for manifest files:
   - `go.mod` → Go
   - `package.json` / `tsconfig.json` → TypeScript/JavaScript
   - `pyproject.toml` → Python
   - `composer.json` → PHP

2. **Detect architecture markers** — inspect directory names:
   - Hexagonal: `domain/`, `application/`, `infrastructure/`, `ports/`
   - CQRS: `command/`, `query/`
   - DDD: aggregate roots, value objects, domain events

3. **Read build/test/lint commands** — inspect:
   - `Makefile`
   - `justfile`
   - `package.json scripts`
   - `Taskfile.yml`

4. **Identify entry points** — look for:
   - `main.go`
   - `cmd/`
   - `src/index.ts`
   - `app/main.py`
   - `artisan`
   - `bin/`

5. **For monorepos** — detect tier structure from `.agentic/config.yaml` if present.

### Step 2 — Map the Layer Structure

1. **Identify architectural layers**:
   - Domain: entities, value objects, domain events, repository interfaces
   - Application: use cases, command/query handlers
   - Infrastructure: repository implementations, HTTP clients, messaging adapters
   - Ports/Adapters: HTTP controllers, CLI commands, message consumers

2. **List key modules/packages** (top 5-10) with one-line purpose each.

3. **Note non-obvious conventions**:
   - Naming rules (e.g., `*_test.go` suffix, `service.go` patterns)
   - File organization (co-location rules, split by concern vs. feature)
   - Error handling patterns
   - Token/entity naming conventions

### Step 3 — Identify Complexity Hotspots

1. **Largest files by line count** — use `wc -l` or equivalent on key source files.

2. **Modules with most dependencies** — inspect imports to identify central dependencies.

3. **Known TODO/FIXME concentrations** — search for `TODO`, `FIXME`, `XXX` comments.

4. **Cross-cutting modules** — identify files that touch multiple layers (potential SRP violations).

### Step 4 — Write the Project Map

Read `template.md` from this skill directory and populate it with discovered information:
- Fill in all placeholders marked with `{PLACEHOLDER}`
- Use today's date for `{DATE}`
- Create `.agentic/` directory if it doesn't exist
- Write `.agentic/project-map.md`

### Step 5 — Verify and Report

1. **Confirm file written**: Report the path and file size.

2. **List gaps**: Explicitly note areas where auto-detection failed:
   - e.g., "Could not detect test framework — please fill in manually"
   - e.g., "Project purpose unclear — add 'What This Project Does'"

3. **Suggest committing**: Recommend adding `.agentic/project-map.md` to the repo so all team members and agents benefit from this orientation.