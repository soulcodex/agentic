---
name: github-issue-planning
description: >
  Builds and persists implementation plans directly on a GitHub issue comment
  with an idempotent managed marker. Prefers GitHub MCP when available and
  falls back to gh CLI for persistence when MCP is unavailable or misconfigured.
  Uses local plan persistence only when issue persistence is unavailable or not
  desired.
version: 1.0.0
tags:
  - agentic
  - planning
  - github
  - issues
resources:
  - issue-comment-template.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## GitHub Issue Planning Skill

Use this skill when planning work tied to a GitHub issue and the plan should be
persisted on that issue for team visibility.

### Required Input

Do not proceed without one of:
- Full issue URL (`https://github.com/{owner}/{repo}/issues/{number}`), or
- Owner/repo plus issue number (`{owner}/{repo}#{number}`)

If neither is available, ask for it first.

### Persistence Contract (Managed Comment)

Persist the plan in one managed issue comment with a stable marker:

```html
<!-- agentic:github-issue-plan -->
```

Rules:
- Exactly one managed comment per issue per planning thread.
- Update that managed comment in place on subsequent runs (idempotent).
- Keep the marker at the top of the comment body so it is discoverable.
- Use `issue-comment-template.md` as the body scaffold.

### Decision Tree

1. MCP path (preferred):
- If GitHub MCP is available and configured, use MCP issue/comment tools to find
  existing comments containing `<!-- agentic:github-issue-plan -->` and update.
- Enforce deterministic managed-comment handling:
  - 0 matching comments: create one managed comment with marker + plan body.
  - 1 matching comment: update that exact managed comment.
  - More than 1 matching comment: stop and request manual cleanup before updating.

2. `gh` CLI fallback (primary fallback, not hard-block):
- If MCP is unavailable or misconfigured, continue using `gh` CLI.
- Check auth first:

```bash
gh auth status
```

- Create a managed comment:

```bash
gh issue comment {issue_number} --repo {owner}/{repo} --body-file /tmp/issue-plan.md
```

- Update existing managed comment (find exactly one comment id, then edit):

```bash
MATCHED_IDS=$(gh api repos/{owner}/{repo}/issues/{issue_number}/comments --paginate \
  --jq '.[] | select(.body | contains("<!-- agentic:github-issue-plan -->")) | .id')

MATCH_COUNT=$(printf "%s\n" "$MATCHED_IDS" | sed '/^$/d' | wc -l | tr -d ' ')
if [ "$MATCH_COUNT" -gt 1 ]; then
  echo "Multiple managed plan comments found; stop and ask for manual cleanup."
  exit 1
fi

COMMENT_ID=$(printf "%s\n" "$MATCHED_IDS" | sed '/^$/d' | head -n 1)

gh api repos/{owner}/{repo}/issues/comments/$COMMENT_ID \
  --method PATCH \
  --field body="$(cat /tmp/issue-plan.md)"
```

3. Local plan fallback (last resort):
- Use `write-plan` or `persist-plan` local file flow only when GitHub issue
  persistence is unavailable (no MCP, no working `gh`, or permission denied)
  or explicitly not desired by the user.
- Report that the plan was saved locally and not persisted to the issue.

### Output Requirements

Always report:
- Issue reference used.
- Persistence path used (`MCP`, `gh`, or `local`).
- Whether managed comment was created or updated.
- If fallback happened, include the concrete reason.
