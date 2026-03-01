---
name: configure-mcp
description: >
  Guides the user through selecting and configuring an MCP (Model Context Protocol)
  server for a project. Recommends servers based on the stack, then walks through
  the just mcp-add wizard. Invoked when the user asks to set up MCP, add a tool
  integration, or configure external service access for AI agents.
version: 1.0.0
tags:
  - agentic
  - mcp
  - setup
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Configure MCP Skill

Guide the user through selecting and configuring an MCP server for their project.

### Step 1 — Understand the Stack

Ask the user:
- What language and framework is the project using?
- What external services or data sources does it interact with? (GitHub, databases, browser automation, documentation lookup, etc.)
- What tasks should the AI agent be able to help with?

### Step 2 — Recommend Servers

Based on the stack, recommend from the canonical short-list:

| Server | When to use it |
|---|---|
| `github` | GitHub repos, issues, PRs, CI status |
| `filesystem` | Direct file system access within a bounded path |
| `postgres` | Query and inspect a PostgreSQL database |
| `context7` | Live documentation lookup for libraries and frameworks |
| `playwright` | Browser automation and end-to-end testing |

Explain which servers apply to the user's project and why.

### Step 3 — Run the Wizard

Tell the user to run the interactive wizard:

```bash
just mcp-add /path/to/project
```

Walk them through the prompts:
1. Enter the server name (e.g. `github`)
2. Choose transport: `stdio` for local executables, `http` for remote servers
3. Enter the command (e.g. `npx -y @modelcontextprotocol/server-github`)
4. Add environment variables (e.g. `GITHUB_TOKEN`)
5. Confirm the write to `.mcp.json`
6. Optionally sync to `opencode.json` and/or `.gemini/settings.json`

### Step 4 — Verify

After the wizard completes, verify with:

```bash
just mcp-list /path/to/project
```

This should show the newly configured server in the table.

### Step 5 — Environment Setup

Remind the user: environment variables referenced in the MCP config (e.g. `${GITHUB_TOKEN}`) must be set in the shell before starting the AI tool. They are **not** stored in `.mcp.json` — only the variable references are.

Add them to the project's `.env` or the system environment as appropriate.
