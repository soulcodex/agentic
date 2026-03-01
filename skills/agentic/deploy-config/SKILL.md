---
name: deploy-config
description: >
  Meta-skill: deploys the full agentic configuration to a target project —
  AGENTS.md composition, vendor file generation, and skill deployment — in a single workflow.
  Invoked when the user asks to deploy or update agent config, sync the agentic setup, or set up agents in a project.
version: 1.0.0
tags:
  - agentic
  - meta
  - deployment
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Deploy Config Skill

Deploy the complete agentic configuration to a target project.

### Step 1 — Confirm Target and Profile

Ask the user:
1. Target project path (absolute or relative)
2. Profile name (run `just list-profiles` if unsure)
3. Skills to deploy (run `just list-skills` if unsure; can be "all" or a comma-separated list)
4. Which vendors to generate files for

### Step 2 — Check for Existing Config

Read `{target}/.agentic/config.yaml` if it exists.
If it does, show the current profile and version, and ask if the user wants to update or replace.

### Step 3 — Run the Full Deploy Pipeline

```bash
# 1. Compose AGENTS.md from the profile
just compose {profile} {target}

# 2. Generate vendor-specific files
just vendor-gen {target} --vendors {vendors}

# 3. Deploy selected skills
just deploy-skills {target} --skills {skills}
```

### Step 4 — Verify Output

After deploying, list the files created in the target project:
- `AGENTS.md` — primary agent instructions
- `CLAUDE.md` — Claude adapter (if claude vendor enabled)
- `.github/copilot-instructions.md` — Copilot adapter (if copilot enabled)
- `.gemini/systemPrompt.md` — Gemini adapter (if gemini enabled)
- `.claude/skills/*/` — deployed skill directories (if claude enabled)
- `.agentic/config.yaml` — lock file recording what was deployed

### Step 5 — Next Steps

Suggest to the user:
- Commit the generated files to the target project
- Run `just validate {target}` to verify the config is valid
- Run `just sync-check {target}` periodically to detect drift from the library
