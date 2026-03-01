---
name: compose-agents-md
description: >
  Meta-skill: helps create an AGENTS.md for a new project by guiding the user through
  selecting the right profile from the agentic library and running the compose command.
  Also helps create a custom AGENTS.md from scratch when no profile fits.
  Invoked when the user asks to set up agent instructions, create AGENTS.md, or configure agents for a project.
version: 1.0.0
tags:
  - agentic
  - meta
  - setup
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Compose AGENTS.md Skill

Help the user create an `AGENTS.md` for their project.

### Step 1 — Understand the Project

Ask (if not already known):
1. What language(s) does the project use?
2. What architectural pattern (hexagonal, microservices, BFF, monolith)?
3. What is the primary purpose of the project?
4. Which AI vendors are used on this project?

### Step 2 — Recommend a Profile

Check `just list-profiles` to show available profiles.

Match the user's answers to an existing profile. If a match exists:
```bash
just compose {profile-name} {/path/to/target-project}
```

If no profile matches closely enough, offer to:
a) Compose from individual fragments (guided selection)
b) Create a new profile for this project type

### Step 3 — Fragment Selection (if no profile matches)

Guide the user through selecting fragments:

**Base fragments** (always recommended):
- `git-conventions` — always include
- `security` — always include
- `code-review` — include if team does code reviews
- `testing-philosophy` — include if testing standards matter
- `documentation` — include if docs standards matter

**Language**: pick from `agents/languages/`
**Architecture**: pick from `agents/architecture/`
**Practices**: pick from `agents/practices/`
**Domain**: pick from `agents/domains/` if a match exists

### Step 4 — Compose and Deploy

Run the compose and vendor-gen commands:
```bash
just compose {profile-or-custom} {target-path}
just vendor-gen {target-path}
```

### Step 5 — Verify

Open `{target-path}/AGENTS.md` with the user and confirm:
- The content accurately represents the project's standards
- Build/test/lint commands are correct
- No placeholder tokens (`{{TOKEN}}`) remain unfilled
