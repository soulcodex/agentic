---
name: monorepo-management
description: >
  Sets up or audits a monorepo workspace: tool selection, package naming,
  shared tooling, inter-package dependencies, selective CI, and versioning
  strategy. Invoked when the user asks to set up a monorepo, add a workspace,
  or manage multiple packages in a single repository.
version: 1.0.0
tags:
  - devops
  - monorepo
  - workspace
  - build
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Monorepo Management Skill

### Step 1 — Choose the Workspace Tool

| Language | Tool | When to use |
|----------|------|------------|
| TypeScript/JS | pnpm workspaces | Default for JS/TS monorepos |
| TypeScript/JS | Turborepo | Add on top of pnpm when build caching matters |
| Go | Go workspaces (`go.work`) | Multiple Go modules in one repo |
| Mixed | Nx | When you need cross-language task orchestration |

For most TypeScript projects: **pnpm + Turborepo**.
For Go: **go workspaces** for local development, separate modules for independent versioning.

### Step 2 — Package Naming

Follow a consistent naming scheme:

```
@acme/api          ← backend service
@acme/web          ← frontend application
@acme/ui           ← shared component library
@acme/core         ← shared domain types and utilities
@acme/config-ts    ← shared TypeScript config
@acme/config-eslint ← shared ESLint config
```

Rules:
- Use a consistent org prefix (`@acme/`, `@org/`).
- Separate packages for separate concerns — do not bundle the UI and the API.
- Keep shared config packages (tsconfig, eslint) in `packages/config-*/`.

### Step 3 — Shared Tooling at Root

Place shared configuration at the repo root; packages extend it:

```
monorepo/
  package.json          ← workspace root — scripts + dev deps
  pnpm-workspace.yaml   ← workspace package globs
  turbo.json            ← Turborepo pipeline
  tsconfig.base.json    ← shared TS config
  eslint.config.ts      ← shared ESLint config
  .gitignore
  packages/
    api/
    web/
    ui/
    core/
```

```yaml
# pnpm-workspace.yaml
packages:
  - "packages/*"
  - "apps/*"
```

### Step 4 — Inter-Package Dependencies

Use workspace protocol for internal dependencies:

```json
{
  "dependencies": {
    "@acme/core": "workspace:*"
  }
}
```

Rules:
- Never use a published version of an internal package in development.
- Dependency direction: `apps/*` → `packages/*`; `packages/*` must not depend on `apps/*`.
- Circular dependencies between packages are forbidden.

### Step 5 — Selective CI

Run only the pipelines affected by a given change. With Turborepo:

```json
// turbo.json
{
  "pipeline": {
    "build":  { "dependsOn": ["^build"], "outputs": ["dist/**"] },
    "test":   { "dependsOn": ["^build"] },
    "lint":   {}
  }
}
```

```bash
# CI: run affected tasks only (compared to main)
pnpm turbo run build test lint --filter='[origin/main...HEAD]'
```

Without Turborepo, use `git diff` to detect changed packages and run their scripts
selectively.

### Step 6 — Versioning Strategy

Choose one strategy and apply it consistently:

| Strategy | Tool | When to use |
|----------|------|------------|
| Independent versioning | Changesets | Packages are released separately to npm |
| Unified versioning | Changesets (fixed) | All packages share the same version number |
| App-only (no publishing) | None needed | No packages are published externally |

For published packages, add Changesets:
```bash
pnpm add -D @changesets/cli
pnpm changeset init
```

CI publishes on merge to `main`:
```yaml
- name: Create Release PR or Publish
  uses: changesets/action@v1
  with:
    publish: pnpm release
```

### Verify

- [ ] `pnpm install` succeeds from the repo root.
- [ ] `pnpm turbo run build` (or equivalent) builds all packages in dependency order.
- [ ] Internal packages use `workspace:*` protocol — no published version references.
- [ ] CI only runs pipelines affected by the change.
- [ ] No circular dependencies between packages.
