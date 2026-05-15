# Profiles

A profile is a named YAML preset that selects which fragments, tech stack details, and skills to include. Pick one, run `agentic deploy`, done.

## Available Profiles

| Profile | What it's for | Language(s) |
|---|---|---|
| `typescript-react-spa` | Standalone React SPA with Vite, React Router. No SSR. | TypeScript |
| `typescript-next-app` | Standalone Next.js app with SSR, App Router | TypeScript |
| `typescript-vue-spa` | Standalone Vue 3 SPA with Vite, Pinia, Vue Router. No SSR. | TypeScript |
| `typescript-nuxt-app` | Standalone Nuxt 3 app with SSR, file-based routing, Nitro | TypeScript |
| `typescript-hexagonal-microservice` | TypeScript backend service with Hono, hexagonal architecture, DDD | TypeScript |
| `typescript-bff` | Backend-for-Frontend aggregation layer | TypeScript |
| `typescript-hexagonal-next-ui` | Hono backend + Next.js frontend (SSR) | TypeScript |
| `typescript-hexagonal-react-vite-ui` | Hono backend + React SPA frontend (no SSR) | TypeScript |
| `typescript-hexagonal-nuxt-vite-ui` | Hono backend + Nuxt 3 / Vue 3 frontend (SSR) | TypeScript |
| `typescript-hexagonal-vue-vite-ui` | Hono backend + Vue 3 SPA frontend (no SSR) | TypeScript |
| `typescript-hexagonal-effect-cli` | TypeScript CLI with @effect/cli + @effect/platform-node, hexagonal + DDD | TypeScript |
| `go-hexagonal-microservice` | Go backend microservice, hexagonal + DDD | Go |
| `golang-hexagonal-next-ui` | Go backend + Next.js frontend (SSR) | Go + TypeScript |
| `golang-hexagonal-react-vite-ui` | Go backend + React SPA frontend (no SSR) | Go + TypeScript |
| `golang-hexagonal-nuxt-vite-ui` | Go backend + Nuxt 3 / Vue 3 frontend (SSR) | Go + TypeScript |
| `golang-hexagonal-vue-vite-ui` | Go backend + Vue 3 SPA frontend (no SSR) | Go + TypeScript |
| `golang-hexagonal-cobra-cli` | Go CLI tool with Cobra + Viper, hexagonal + DDD | Go |
| `python-fastapi-microservice` | FastAPI service with uv + Pydantic, hexagonal | Python |
| `python-hexagonal-typer-cli` | Python CLI tool with Typer + Rich, hexagonal | Python |
| `php-hexagonal-ddd` | PHP 8.3+ Symfony application, hexagonal + DDD + CQRS | PHP |
| `go-library` | Go reusable library/package with stable public API and minimal transitive dependencies | Go |
| `typescript-library` | TypeScript reusable library for npm/private registry, ESM-first, zero framework dependencies | TypeScript |
| `hcl-aws-terraform-module` | AWS-focused Terraform module development with design, module scaffolding, and test guardrails | HCL |

## Nested Output Mode

Full-stack profiles (`*-next-ui`, `*-nuxt-vite-ui`, `*-react-vite-ui`, `*-vue-vite-ui`) use `output.structure: nested`. Instead of a single `AGENTS.md`, they produce:

```
my-project/
  AGENTS.md            ← root: cross-cutting conventions + tier table + skills
  backend/AGENTS.md    ← backend-specific languages, frameworks, architecture
  ui/AGENTS.md         ← UI-specific languages, frameworks, architecture
  .agentic/
    config.yaml        (mode, structure: nested, tiers: [backend, ui])
    profile.yaml       (local profile used by sync)
    fragments/         ← all fragment references (copied in copy mode, symlinked in link mode)
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
    frameworks: [react, next]
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
