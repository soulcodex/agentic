---
name: github-actions-workflow
description: >
  Scaffolds or audits a GitHub Actions CI/CD workflow for a project. Covers job
  structure, caching, secrets handling, concurrency groups, and environment gates.
  Invoked when the user asks to set up CI, add a GitHub Actions workflow, or
  improve pipeline performance.
version: 1.0.0
tags:
  - devops
  - ci-cd
  - github-actions
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## GitHub Actions Workflow Skill

### Step 1 — Detect Project Type

Identify the runtime and package manager before scaffolding:
- Language (Go, TypeScript/Node, Python, PHP, …)
- Package manager (pnpm, npm, Go modules, uv, Composer)
- Test and lint commands (from `justfile`, `Makefile`, or `package.json`)
- Deploy targets (container registry, cloud provider, static host)

### Step 2 — Scaffold `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up runtime
        uses: <runtime-setup-action>   # e.g. actions/setup-go@v5
        with:
          <version-key>: <version>     # e.g. go-version: "1.23"
      - name: Cache dependencies
        uses: actions/cache@v4
        with:
          path: <cache-path>
          key: ${{ runner.os }}-<tool>-${{ hashFiles('<lockfile>') }}
      - name: Install dependencies
        run: <install-command>
      - name: Lint
        run: <lint-command>

  test:
    name: Test
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Set up runtime
        uses: <runtime-setup-action>
        with:
          <version-key>: <version>
      - name: Cache dependencies
        uses: actions/cache@v4
        with:
          path: <cache-path>
          key: ${{ runner.os }}-<tool>-${{ hashFiles('<lockfile>') }}
      - name: Install dependencies
        run: <install-command>
      - name: Test
        run: <test-command>

  build:
    name: Build
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: <build-command>
```

### Step 3 — Job Structure

| Job | Depends on | Purpose |
|-----|-----------|---------|
| `lint` | — | Fail fast on code quality issues |
| `test` | `lint` | Run unit and integration tests |
| `build` | `test` | Verify the artefact compiles/bundles |
| `deploy` | `build` | Push to environment (conditionally) |

Keep `lint` first — it is the cheapest gate. Never merge `lint` and `test` into
one job; separate jobs run independently and give faster feedback.

### Step 4 — Caching

Cache package manager directories keyed on the lockfile hash:

| Tool | Cache path | Key hash file |
|------|-----------|---------------|
| pnpm | `~/.pnpm-store` | `pnpm-lock.yaml` |
| npm | `~/.npm` | `package-lock.json` |
| Go modules | `~/go/pkg/mod` | `go.sum` |
| uv (Python) | `~/.cache/uv` | `uv.lock` |
| Composer | `~/.composer/cache` | `composer.lock` |

### Step 5 — Secrets

- Never hardcode secrets or tokens in workflow files.
- Store secrets in `Settings → Secrets and variables → Actions`.
- Reference them as `${{ secrets.MY_SECRET }}`.
- Use `${{ vars.MY_VAR }}` for non-sensitive configuration values.
- Prefer OIDC-based authentication (e.g., `aws-actions/configure-aws-credentials`)
  over long-lived access keys.

### Step 6 — Concurrency Groups

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

This cancels in-progress runs for the same branch when a new commit is pushed —
prevents queue pile-ups on active branches. Disable `cancel-in-progress` for
`main` if you want all main-branch runs to complete.

### Step 7 — Environment Gates

Use GitHub Environments for staged deployments:

```yaml
deploy-staging:
  environment: staging
  needs: build
  if: github.ref == 'refs/heads/main'

deploy-production:
  environment: production    # has manual approval gate configured in GitHub UI
  needs: deploy-staging
  if: github.ref == 'refs/heads/main'
```

Configure each environment in `Settings → Environments` with required reviewers
and deployment branch restrictions.

### Verify

- [ ] Workflow file passes `actionlint` with no errors.
- [ ] Jobs run in correct dependency order (lint → test → build → deploy).
- [ ] Dependency cache hits on the second run (check Actions logs).
- [ ] Secrets referenced via `${{ secrets.* }}` — no hardcoded values.
- [ ] Concurrency group prevents duplicate runs on the same branch.
