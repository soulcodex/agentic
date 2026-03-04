# Profiles

A profile is a named YAML preset that selects which fragments, tech stack details, and skills to include. Pick one, run `agentic deploy`, done.

## Available Profiles

| Profile | What it's for | Language(s) |
|---|---|---|
| `typescript-hexagonal-microservice` | TypeScript backend service with Hono, hexagonal architecture, DDD | TypeScript |
| `typescript-bff` | Backend-for-Frontend aggregation layer | TypeScript |
| `typescript-hexagonal-nuxt-vite-ui` | Hono backend + Nuxt 3 / Vue 3 frontend (SSR) | TypeScript |
| `typescript-hexagonal-vue-vite-ui` | Hono backend + Vue 3 SPA frontend (no SSR) | TypeScript |
| `go-hexagonal-microservice` | Go backend microservice, hexagonal + DDD | Go |
| `golang-hexagonal-nuxt-vite-ui` | Go backend + Nuxt 3 / Vue 3 frontend (SSR) | Go + TypeScript |
| `golang-hexagonal-vue-vite-ui` | Go backend + Vue 3 SPA frontend (no SSR) | Go + TypeScript |
| `golang-hexagonal-cobra-cli` | Go CLI tool with Cobra + Viper, hexagonal + DDD | Go |
| `python-fastapi-microservice` | FastAPI service with uv + Pydantic, hexagonal | Python |
| `python-hexagonal-typer-cli` | Python CLI tool with Typer + Rich, hexagonal | Python |
| `php-hexagonal-ddd` | PHP 8.3+ Symfony application, hexagonal + DDD + CQRS | PHP |

## Nested Output Mode

Full-stack profiles (`*-nuxt-vite-ui`, `*-vue-vite-ui`) use `output.structure: nested`. Instead of a single `AGENTS.md`, they produce:

```
my-project/
  AGENTS.md            ← root: cross-cutting conventions + tier table + skills
  backend/AGENTS.md    ← backend-specific languages, frameworks, architecture
  ui/AGENTS.md         ← UI-specific languages, frameworks, architecture
  .agentic/
    config.yaml        (mode, structure: nested, tiers: [backend, ui])
    fragments/         ← ALL fragments copied here (root + all tiers)
```

Each tier gets its own `languages`, `frameworks`, `architecture`, and `commands` block from the profile's `tiers:` section.

## Tier Declaration

```yaml
tiers:
  backend:
    languages: [go]
    frameworks: []
    architecture: [hexagonal, ddd, microservices]
    commands:
      build_command: "go build ./..."
      test_command:  "go test ./... -race -cover"
      lint_command:  "golangci-lint run"
  ui:
    languages: [typescript]
    frameworks: [vue, nuxt]
    architecture: []
    commands:
      build_command: "pnpm build"
      test_command:  "pnpm test"
      lint_command:  "pnpm lint"
```

## Profile Schema Fields

| Field | Required | Description |
|---|---|---|
| `meta.name` | ✓ | Display name |
| `meta.description` | ✓ | One-paragraph description |
| `meta.version` | ✓ | Semver version string |
| `fragments.*` | ✓ | Fragment lists per layer |
| `tech_stack` | — | Generates `## Technical Stack` table |
| `tech_stack.proprietary_libraries` | — | Internal packages with doc links |
| `skills` | — | On-demand agent task skill names |
| `output.structure` | — | `flat` (default) or `nested` |
| `tiers` | — | Per-tier fragment + command declarations (nested only) |
| `vendors.enabled` | — | Which vendor adapters to generate |

## Dry-Run

Preview the composed AGENTS.md without writing any files:

```bash
just dry-run typescript-hexagonal-microservice
```
