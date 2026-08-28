---
name: static-code-analysis
description: >
  Selects, configures, and integrates a static analysis tool for the project's
  language. Covers tool selection, rule configuration, CI integration, fixing
  existing violations, and pre-commit hook setup. Invoked when the user asks to
  add linting, set up static analysis, or configure a code quality tool.
version: 1.0.0
tags:
  - quality
  - linting
  - static-analysis
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Static Code Analysis Skill

### Step 1 — Detect Language and Choose Tool

| Language | Recommended tool | Config file |
|----------|-----------------|-------------|
| TypeScript / JavaScript | Rslint (`@rslint/core`) for new projects; ESLint when already entrenched or plugin coverage requires it | `rslint.config.ts` or `eslint.config.ts` |
| Go | golangci-lint | `.golangci.yml` |
| Python | Ruff | `ruff.toml` or `pyproject.toml` |
| PHP | PHPStan | `phpstan.neon` |
| Rust | Clippy (built-in) | `clippy.toml` |

If a tool is already present, audit its configuration before making changes.
Do not replace an established ESLint setup with Rslint unless migration is part
of the task or the repo has no rules that Rslint cannot cover yet.

### Step 2 — Configure Rules

Apply a strict baseline.
If you use `import/*` rules, ensure `eslint-plugin-import` is installed and configured.

**TypeScript (Rslint)**
```bash
pnpm add -D @rslint/core
pnpm exec rslint --init
```

Use `pnpm lint` as the project script. For repositories that want lint and type
checking in one pass, configure parser projects and use:

```bash
pnpm exec rslint --type-check .
```

**TypeScript (ESLint fallback)**
```json
{
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unused-vars": "error",
    "import/no-commonjs": "error",
    "no-console": "warn",
    "eqeqeq": ["error", "always"]
  }
}
```

**Go (golangci-lint)**
```yaml
linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
linters-settings:
  govet:
    enable-all: true
```

**Python (Ruff)**
```toml
[tool.ruff]
select = ["E", "F", "I", "N", "UP", "S", "B"]
ignore = []
line-length = 100
```

### Step 3 — Integrate with CI

Add a lint job that runs **before tests** and **fails on any error** (exit code 1):

```yaml
# .github/workflows/ci.yml
lint:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Run linter
      run: <lint-command>   # e.g., pnpm lint, golangci-lint run, ruff check .
```

Do not suppress errors with `continue-on-error: true` — violations must be fixed.

### Step 4 — Fix Existing Violations

Run the auto-fixer first to resolve stylistic issues without manual effort:

```bash
# TypeScript
pnpm exec rslint --fix .

# Python
ruff check . --fix

# Go (no auto-fix in golangci-lint; use gofmt + goimports)
gofmt -w .
goimports -w .
```

Then address remaining violations manually. Prioritise `error`-level findings.
Document any intentional rule suppression inline with a comment explaining why:

```ts
// eslint-disable-next-line @typescript-eslint/no-explicit-any -- legacy API response type
const response: any = await legacyClient.fetch()
```

### Step 5 — Pre-commit Hook

Install a pre-commit hook so violations are caught before `git push`:

**Using Husky + lint-staged (JS/TS)**
```bash
pnpm add -D husky lint-staged @commitlint/cli @commitlint/config-conventional
npx husky init
```
```json
// package.json
"lint-staged": { "*.{ts,tsx,js,jsx}": "rslint --fix" }
```

Use commitlint from a `commit-msg` hook or CI commit-range check when the repo
uses Conventional Commits:

```bash
pnpm exec commitlint --edit "$1"
```

**Using pre-commit (Python/Go)**
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.0
    hooks:
      - id: ruff
        args: [--fix]
```

### Step 6 — Verify

- [ ] `<lint-command>` exits 0 with no output.
- [ ] CI lint job passes on a clean branch.
- [ ] Pre-commit hook blocks a commit that introduces a lint error.
- [ ] Commitlint blocks a non-Conventional Commit message when configured.
- [ ] No blanket `eslint-disable` or `#noqa` without explanatory comments.
