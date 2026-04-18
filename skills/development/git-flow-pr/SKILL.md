---
name: git-flow-pr
description: >
  Executes the full PR-driven development workflow: create an isolated feature
  branch from the current work, commit all staged changes, rebase cleanly onto
  origin/main (skipping any ancestor commits already merged), push the branch,
  and open a GitHub pull request linked to a related issue. Invoked when the
  user says "open a PR", "create a pull request", "push and PR", or "branch,
  rebase and PR".
version: 1.0.0
tags:
  - git
  - github
  - pull-request
  - workflow
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: native
---

## Git Flow PR Skill

Complete workflow for creating a clean, rebased pull request from in-progress work.

### Step 1 — Confirm Current State

Before doing anything, understand what exists:

```bash
git status --short          # Are there uncommitted changes?
git log --oneline -10       # What commits exist on this branch?
git branch --show-current   # Which branch are we on?
git fetch origin main       # Get latest state of main
git log --oneline origin/main..HEAD   # Commits unique to this branch
```

Identify:
- The **base branch** (usually `main`)
- Any **uncommitted changes** that need to be staged
- Whether the current branch's ancestor commits are **already merged into main**
  (this determines which `--onto` strategy to use in Step 4)

### Step 2 — Stage and Commit (if uncommitted changes exist)

If there are uncommitted changes, stage and commit them now:

```bash
git add <files>     # Stage relevant files; be specific — don't `git add .` blindly
git commit -m "<type>(<scope>): <summary>

<body explaining why, not just what>

Closes #<issue-number>"
```

Commit message rules:
- Follow Conventional Commits: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`
- Scope should reflect the area changed: `(gemini)`, `(tooling)`, `(docs)`, `(skills)`, etc.
- Reference the issue with `Closes #N` or `Fixes #N` in the commit body
- Keep the subject line ≤ 72 characters

### Step 3 — Create the Feature Branch

Create a new branch from the tip of the current work and give it a descriptive name:

```bash
COMMIT=$(git rev-parse HEAD)
git checkout -b feat/<short-description> "$COMMIT"
```

Branch naming convention:
- `feat/<description>` — new feature or enhancement
- `fix/<description>` — bug fix
- `docs/<description>` — documentation only
- `chore/<description>` — maintenance, tooling, dependencies

Use kebab-case. Keep it short but descriptive (3–5 words max).

### Step 4 — Rebase onto origin/main

**Critical:** determine the correct rebase strategy before running.

#### Case A — No ancestor commits already in main (simple case)

The branch was created fresh and diverged directly from main:

```bash
git rebase origin/main
```

#### Case B — Ancestor commits are already merged into main (squash-merge or similar)

This happens when:
- The branch was created on top of another branch that was already merged
- The repo uses squash-merge PRs, so commit SHAs on the branch differ from main

Identify the last commit **not** in main:

```bash
# Find the oldest commit on this branch not present in main
git log --oneline origin/main..HEAD
# The last line shows the oldest unique commit — its *parent* is the rebase base
ANCESTOR=$(git log --oneline origin/main..HEAD | tail -1 | awk '{print $1}')
PARENT=$(git rev-parse "$ANCESTOR"^)
```

Then rebase only the unique commits onto main:

```bash
git rebase --onto origin/main "$PARENT" HEAD
```

This replays only the commits that are genuinely new, dropping the already-merged ones.

#### After rebase — verify

```bash
git log --oneline -5          # Should show: new commit(s) on top of origin/main HEAD
git status                    # Should be clean
```

If there are conflicts, resolve them file by file, then `git add <file> && git rebase --continue`. Never use `git rebase --skip` unless you are certain the commit is truly redundant.

### Step 5 — Run Quality Gates

Before pushing, run the project's verification suite. For this repo:

```bash
just test    # All assertions must pass
just lint    # Zero findings
```

For other projects, run whatever the project defines as its quality gate (CI commands, test suite, type-check, etc.). Do not push a branch that fails its own quality gates.

### Step 6 — Push the Branch

```bash
git push origin <branch-name> -u
```

The `-u` flag sets the upstream, making future `git push` / `git pull` work without arguments.

If the push is rejected because the remote already has a version of this branch (e.g., you rebased), use force-push **only on feature branches** (never on `main`):

```bash
git push origin <branch-name> --force-with-lease
```

`--force-with-lease` is safer than `--force`: it fails if someone else pushed to the branch since your last fetch.

### Step 7 — Open the Pull Request

```bash
gh pr create \
  --title "<type>(<scope>): <concise summary>" \
  --base main \
  --head <branch-name> \
  --body "$(cat <<'EOF'
## Summary

- <bullet 1: what changed and why>
- <bullet 2>
- <bullet 3>

## Changes

| Area | Files |
|------|-------|
| <area> | <files> |

Closes #<issue-number>
EOF
)"
```

PR title rules:
- Same format as the commit message subject
- Must match the branch's purpose exactly
- ≤ 72 characters

Body rules:
- 2–4 bullet summary (what + why, not just what)
- Changes table for non-trivial diffs
- `Closes #N` links the PR to the issue and auto-closes it on merge

### Step 8 — Verify

After opening:

```bash
gh pr view        # Confirm PR is open with correct title, base branch, and issue link
```

Check:
- [ ] PR title follows Conventional Commits format
- [ ] Base branch is `main` (not another feature branch)
- [ ] Issue is linked via `Closes #N` in the body
- [ ] CI checks are triggered and passing (check `gh pr checks`)
- [ ] Branch is up to date with `main` (no "behind by N commits" warning)