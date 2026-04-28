# Plan: `/new-gh-issue <issue-link>` Workflow Automation

## Objective
Provide a repeatable workflow where invoking `/new-gh-issue <issue-link>` triggers issue-driven delivery flow:

1. Read GitHub issue content.
2. Create a meaningful branch from rebased `main`.
3. Run reviewer pre-analysis.
4. Delegate implementation to worker.
5. Validate (`just lint`, `just index`, `just test` as needed).
6. Commit, push, create PR, and verify PR description is present.

This plan covers two implementations:
- Phase 1: skill-only orchestration (fast, low risk)
- Phase 2: true slash-command routing (better UX, higher integration work)

## Scope Boundaries
- In scope: orchestration guidance and optional command mapping.
- Out of scope: changing project-specific business logic or redefining existing branch/PR conventions.
- Must preserve existing repo standards in `AGENTS.md`.

## Phase 1 — Skill-Only Orchestration

### Deliverables
1. New skill:
- `skills/development/new-gh-issue-orchestration/SKILL.md`

2. Optional local references in the skill directory:
- `resources/checklist.md`
- `resources/pr-template.md`

3. Discoverability updates:
- `docs/skills.md`
- `index/skills.json` (via `just index`)

### Behavior Contract
The skill should interpret input like:
- `/new-gh-issue https://github.com/<org>/<repo>/issues/<n>`
- `/new-gh-issue <n>`

And execute this sequence:
1. Parse and validate issue input.
2. Fetch issue details with `gh issue view`.
3. Derive branch name from issue title/scope.
4. `git checkout main && git fetch origin main && git rebase origin/main`.
5. Create branch with derived name.
6. Spawn reviewer for pre-implementation risk/scope analysis.
7. Spawn worker with constrained checklist from reviewer output.
8. Run required validations.
9. Prepare commit + push + PR creation body.
10. Verify PR body is non-empty after creation.

### Acceptance Criteria
- Skill exists with valid frontmatter and SemVer.
- Workflow steps are explicit and deterministic.
- Includes safe-failure handling (network error, existing branch, dirty worktree, empty PR body).
- Docs and skill index include the new skill.

### Validation
- `just index`
- `just lint`
- `just test` (if any tooling/test files are touched)

## Phase 2 — True Slash-Command Routing

### Deliverables
1. Command router mapping `/new-gh-issue` to skill invocation path.
2. Configuration docs describing command availability and expected format.
3. Regression checks for parsing and command dispatch (where applicable).

### Implementation Options
1. Repo-native wrapper approach:
- Add a small command entrypoint that translates `/new-gh-issue ...` into a structured worker prompt.

2. Client-side command map approach:
- Configure Codex environment to route slash commands to a skill prompt template.

### Recommended Path
Start with option 2 if command routing is external to this repo and easier to iterate.
Use option 1 only if the team wants portable automation embedded in repository artifacts.

### Acceptance Criteria
- Typing `/new-gh-issue <issue-link>` consistently triggers the Phase 1 workflow without manual rephrasing.
- Invalid formats return actionable errors.
- Routing docs clearly explain prerequisites (`gh` auth, repo remote access, branch permissions).

## Risk Register
1. Workflow scope creep
- Mitigation: keep skill focused on orchestration, not implementation details of every issue.

2. Drift between skill instructions and actual command behavior
- Mitigation: keep a short canonical checklist and test sample transcripts.

3. Environment mismatch (missing `gh`, auth, network)
- Mitigation: include preflight checks and fallback guidance.

4. PR body empty bug recurrence
- Mitigation: include explicit post-create verification step and auto-repair path.

## Decision Gates
- Gate A (after Phase 1):
  - Is skill-only good enough for team usage and consistency?
- Gate B (before Phase 2):
  - Do we need strict slash-command UX now, or can we defer integration complexity?

## Rollout Proposal
1. Ship Phase 1 in a dedicated PR.
2. Trial in 3-5 real issues.
3. Collect friction points.
4. Decide whether to ship Phase 2 routing in follow-up PR.

## Suggested Branch/PR Sequencing
- Branch 1: `feat/new-gh-issue-orchestration-skill`
- Branch 2: `feat/new-gh-issue-command-routing`

This branch currently contains only this planning document so you can review and choose direction before implementation.
