---
name: git-flow-pr
description: >
  Executes the full PR-driven development workflow: create an isolated feature
  branch from the current work, commit all staged changes, rebase cleanly onto
  the selected base branch (skipping any ancestor commits already merged), push
  the branch, and open a GitHub pull request linked to a related issue.
  Includes guidance for stacked/chained PRs. Invoked when the user says "open a
  PR", "create a pull request", "push and PR", or "branch, rebase and PR".
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
BASE_BRANCH="<base-branch>" # e.g. main, develop, release/*
git fetch origin "$BASE_BRANCH"
git log --oneline "origin/$BASE_BRANCH"..HEAD   # Commits unique to this branch
```

Identify:
- The **base branch** (often `main`, but use the repo's actual target)
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
- For final PRs that should auto-close the issue on merge, use `Closes #N` or `Fixes #N`
- For stacked/chained PRs or partial work, use `Refs #N` to link without auto-closing
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

### Step 4 — Rebase onto origin/<base-branch>

**Critical:** determine the correct rebase strategy before running.

#### Case A — No ancestor commits already in the selected base branch (simple case)

The branch was created fresh and diverged directly from the selected base branch:

```bash
git rebase "origin/$BASE_BRANCH"
```

#### Case B — Ancestor commits are already merged into the selected base branch (squash-merge or similar)

This happens when:
- The branch was created on top of another branch that was already merged
- The repo uses squash-merge PRs, so commit SHAs on the branch differ from the selected base branch

Identify the last commit **not** in the selected base branch:

```bash
# Find the oldest commit on this branch not present in the selected base branch
git log --oneline "origin/$BASE_BRANCH"..HEAD
# The last line shows the oldest unique commit — its *parent* is the rebase base
ANCESTOR=$(git log --oneline "origin/$BASE_BRANCH"..HEAD | tail -1 | awk '{print $1}')
PARENT=$(git rev-parse "$ANCESTOR"^)
```

Then rebase only the unique commits onto the selected base branch:

```bash
git rebase --onto "origin/$BASE_BRANCH" "$PARENT" HEAD
```

This replays only the commits that are genuinely new, dropping the already-merged ones.

#### After rebase — verify

```bash
git log --oneline -5          # Should show: new commit(s) on top of origin/<base-branch> HEAD
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
  --base "$BASE_BRANCH" \
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

<issue-footer: Refs #<issue-number> | Closes #<issue-number>>
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
- Use `Refs #N` for stacked/chained PRs and intermediate slices
- Use `Closes #N` only on the final PR that should auto-close the issue

### Step 7.1 — Stacked/Chained PRs

When a change is too large for one reviewable PR, split into a chain:

1. Create `feat/<topic>-base` from the base branch and open PR A (`--base "$BASE_BRANCH"`).
2. Create `feat/<topic>-part-2` from `feat/<topic>-base` and open PR B (`--base feat/<topic>-base`).
3. Continue similarly for PR C, D, etc., each targeting the prior branch.

Rules for stacked PRs:
- Keep each PR independently reviewable and logically scoped.
- PR body should include `Refs #N` (not `Closes #N`) until final branch in the chain.
- After lower PRs merge, rebase higher branches onto the updated base branch and force-push with lease.
- Update PR base with `gh pr edit --base <new-base>` when needed.

### Step 8 — Verify

After opening:

```bash
gh pr view        # Confirm PR is open with correct title, base branch, and issue link
```

Check:
- [ ] PR title follows Conventional Commits format
- [ ] Base branch is correct for the workflow (`$BASE_BRANCH` or parent branch for stacked PRs)
- [ ] Issue linkage uses `Refs #N` for intermediate PRs and `Closes #N` only for final PRs
- [ ] CI checks are triggered and passing (check `gh pr checks`)
- [ ] Branch is up to date with the selected base branch (no "behind by N commits" warning)
