---
name: git-worktree-workspaces
description: >
  Sets up and uses Git worktrees for parallel task workspaces in the same
  repository clone, including safe cleanup of local worktrees. Invoked when the
  user asks to work on multiple branches at once, isolate tasks without extra
  clones, or create/remove worktrees.
version: 1.0.0
tags:
  - git
  - worktree
  - workflow
  - productivity
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Git Worktree Workspaces Skill

### Step 1 — Discover Current Repo State

```bash
git rev-parse --show-toplevel
git branch --show-current
git worktree list --porcelain
git remote show origin | sed -n '/HEAD branch/s/.*: //p'
```

Capture:
- Current repository root and active branch
- Existing worktrees and paths
- Remote default branch (do not assume a fixed branch name)

### Step 2 — Pick Naming and Layout

Use a predictable directory pattern outside the main working tree:

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_NAME="$(basename "$REPO_ROOT")"
WORKTREE_ROOT="$(dirname "$REPO_ROOT")/${REPO_NAME}-worktrees"
mkdir -p "$WORKTREE_ROOT"
```

Recommended names:
- Branch: `feat/<topic>`, `fix/<topic>`, `docs/<topic>`
- Path: `$WORKTREE_ROOT/<branch-slug>`

### Step 3 — Create a New Worktree

For a new branch:

```bash
BASE_BRANCH="$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')"
NEW_BRANCH="feat/<topic>"
TARGET_PATH="$WORKTREE_ROOT/${NEW_BRANCH//\//-}"

git fetch origin "$BASE_BRANCH"
git worktree add -b "$NEW_BRANCH" "$TARGET_PATH" "origin/$BASE_BRANCH"
```

For an existing branch:

```bash
EXISTING_BRANCH="<branch>"
TARGET_PATH="$WORKTREE_ROOT/${EXISTING_BRANCH//\//-}"

git fetch origin
git worktree add "$TARGET_PATH" "$EXISTING_BRANCH"
```

### Step 4 — Work Independently Per Task

Inside each worktree:

```bash
cd "$TARGET_PATH"
git status --short
git add <files>
git commit -m "feat(<scope>): <summary>"
```

Rules:
- One task per worktree branch.
- Keep commits scoped to that task only.
- Run project quality gates before pushing.

### Step 5 — Push and Open PRs

```bash
git push -u origin "$(git branch --show-current)"
gh pr create --base "<base-branch>" --head "$(git branch --show-current)"
```

Use `Refs #<issue>` for stacked/chained PRs that should not auto-close yet.
Use `Closes #<issue>` only on the final PR intended to close the issue on merge.

### Step 6 — Safe Cleanup (Local Only)

After a branch is merged and no longer needed locally:

```bash
WORKTREE_PATH="<absolute-path-to-worktree>"
BRANCH_NAME="<branch-name>"

git -C "$WORKTREE_PATH" status --short
git worktree remove "$WORKTREE_PATH"
git branch -d "$BRANCH_NAME"
git worktree prune
```

Safety checks:
- Ensure there are no uncommitted changes before removing.
- Use `-d` (not `-D`) so Git blocks branch deletion when unmerged.
- Do not script remote branch deletion by default in this skill.
