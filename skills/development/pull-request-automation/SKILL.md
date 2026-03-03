---
name: pull-request-automation
description: >
  Audits and improves the pull request workflow for a GitHub repository. Covers
  PR description templates, auto-labelling, CODEOWNERS, PR size checks, and
  branch protection rules. Invoked when the user asks to improve the PR process,
  set up PR automation, or add a PR template.
version: 1.0.0
tags:
  - devops
  - pull-request
  - automation
  - github
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Pull Request Automation Skill

### Step 1 — Audit Current PR Workflow

Check what already exists:
- Is there a `.github/pull_request_template.md`?
- Is there a `.github/CODEOWNERS` file?
- Are there existing labelling or size-check actions?
- Are branch protection rules configured for `main`?

### Step 2 — PR Description Template

Create `.github/pull_request_template.md`:

```markdown
## Summary

<!-- What does this PR do? Why? -->

## Changes

<!-- Bullet list of key changes -->

## Test Plan

- [ ] Unit tests added / updated
- [ ] Manual testing performed: <describe steps>
- [ ] Breaking changes documented

## Related Issues

Closes #
```

Keep the template short — the goal is consistency, not bureaucracy.

### Step 3 — Auto-Labelling

Use `actions/labeler` to apply labels automatically based on changed file paths:

```yaml
# .github/labeler.yml
frontend:
  - changed-files:
    - any-glob-to-any-file: "src/features/**"
backend:
  - changed-files:
    - any-glob-to-any-file: "internal/**"
docs:
  - changed-files:
    - any-glob-to-any-file: "docs/**"
infrastructure:
  - changed-files:
    - any-glob-to-any-file: "deployments/**"
```

```yaml
# .github/workflows/labeler.yml
name: Label PR
on: [pull_request_target]
jobs:
  label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/labeler@v5
        with:
          repo-token: ${{ secrets.GITHUB_TOKEN }}
```

### Step 4 — CODEOWNERS

Define ownership in `.github/CODEOWNERS`. GitHub requests reviews from owners
automatically when their files are touched:

```
# Global fallback
*                  @org/platform-team

# Frontend
/src/features/     @org/frontend-team

# Infrastructure
/deployments/      @org/infra-team
/build/            @org/infra-team

# Database migrations
/internal/infrastructure/migrations/  @org/dba-team
```

### Step 5 — PR Size Check

Flag PRs that are too large to review effectively. Add a size-check action:

```yaml
# .github/workflows/pr-size.yml
name: PR Size Check
on: [pull_request]
jobs:
  size:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - name: Check PR size
        run: |
          LINES=$(git diff --stat origin/${{ github.base_ref }}...HEAD | tail -1 | grep -oE '[0-9]+ insertions' | grep -oE '[0-9]+' || echo 0)
          if [ "$LINES" -gt 500 ]; then
            echo "::warning::PR adds $LINES lines. Consider splitting into smaller PRs."
          fi
```

Adjust the threshold to match your team's preferences (200–500 lines is typical).

### Step 6 — Branch Protection Rules

Verify (or configure via `gh api`) that `main` has:
- Required status checks before merge.
- At least 1 required approving review.
- Dismiss stale reviews on new commits.
- No force pushes allowed.
- No deletions allowed.

```bash
gh api repos/{owner}/{repo}/branches/main/protection \
  --method PUT --input - <<'EOF'
{
  "required_status_checks": {"strict": true, "contexts": ["ci"]},
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF
```

### Verify

- [ ] `.github/pull_request_template.md` exists and is used on new PRs.
- [ ] Labels are applied automatically on open.
- [ ] CODEOWNERS triggers review requests on relevant paths.
- [ ] Large PRs receive a size warning.
- [ ] Branch protection is active on `main`.
