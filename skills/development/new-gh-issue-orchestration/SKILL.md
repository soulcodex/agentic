---
name: new-gh-issue-orchestration
description: >
  Orchestrates a GitHub-issue-driven delivery workflow from issue intake to PR
  creation using reviewer-first then worker execution. Invoked when the user
  provides a GitHub issue link/number and asks to start end-to-end delivery.
version: 1.0.0
tags:
  - workflow
  - github
  - issue
  - orchestration
  - automation
resources:
  - resources/workflow-checklist.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## New GitHub Issue Orchestration Skill

### Trigger Contract

Use this skill when the user input matches one of these patterns:
- `new-gh-issue: https://github.com/<org>/<repo>/issues/<number>`
- `new-gh-issue: <number>`

Important:
- `new-gh-issue:` is a workflow trigger phrase, not a shell command.
- Never try to execute `new-gh-issue` in a terminal.
- Parse the value after `new-gh-issue:` as issue identifier input.

### Step 1 - Preflight Checks

Run:

```bash
git status --short
git branch --show-current
```

Rules:
- If working tree is dirty, stop and ask whether to stash/commit before proceeding.
- If issue identifier is missing/invalid, ask for a valid GitHub issue URL or number.

### Step 2 - Resolve Issue Context

Run:

```bash
gh issue view <issue> --repo <owner>/<repo> --comments
```

Extract:
- issue title, number, and intent
- implementation constraints
- any prior planning comments

### Step 3 - Create Proper Branch from Rebased Main

Run:

```bash
git checkout main
git fetch origin main
git rebase origin/main
git checkout -b <type>/<issue-number>-<scope-slug>
```

Branch naming rules:
- Use Conventional Commit type prefix (`feat/`, `fix/`, `docs/`, `chore/`).
- Include issue number and short kebab-case slug from issue scope.

### Step 4 - Reviewer-First Analysis

Delegate to reviewer agent to:
- identify scope risks and blockers
- tighten file-level boundaries
- produce a worker-ready checklist

If reviewer finds blocking ambiguity, resolve it before coding.

### Step 5 - Worker Execution

Delegate to worker with reviewer-constrained checklist:
- implement requested scope
- run required validations
- report changed files and tradeoffs

### Step 6 - Validate and Finalize

Run required checks for the repository scope:
- `just lint`
- `just index` when skills/fragments changed
- `just test` when tooling/tests changed

Then:

```bash
git add <files>
git commit -m "<conventional-commit-message>"
git push -u origin <branch>
```

### Step 7 - Open PR and Verify Body

Create PR with a real body (summary, changed files, validation, issue link):

```bash
gh pr create --base main --head <branch> --title "<title>" --body-file <body-file>
```

Immediately verify PR description is not empty:

```bash
gh pr view <pr-number-or-branch> --json url,body,title
```

If body is empty, repair with `gh pr edit --body-file ...` and verify again.

### Failure Handling

- Network/API failure: retry with appropriate permissions and surface exact failure.
- Existing branch collision: derive a new branch slug and retry.
- Missing `gh` auth: stop and request authentication.
- Validation failure: fix, rerun checks, then continue.
