---
name: module-federation
description: >
  Add, review, or debug Module Federation support in Rsbuild-first TypeScript
  applications. Covers host/remote roles, exposes, remotes, shared dependencies,
  generated types, runtime loading failures, and observability checks.
version: 1.0.0
tags:
  - ui
  - module-federation
  - micro-frontends
  - rsbuild
  - typescript
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Module Federation Skill

Use this skill when adding Module Federation, reviewing host/remote contracts,
debugging federated loading, or fixing type generation and shared dependency
issues.

### Step 1 - Inspect The Project

Read the project root before changing files:

- `package.json`
- `pnpm-lock.yaml` when dependency versions matter
- `rsbuild.config.*`
- `module-federation.config.*`
- `tsconfig*.json`
- app entry points and route registration that import remotes or exposed modules

If the project has no Rsbuild, Rspack, Webpack, Modern.js, Next, Vite, or related
build config, treat it as a new project and recommend the official scaffold:

```bash
npm create module-federation@latest
```

For new in-repo implementation, prefer Rsbuild unless local project instructions
name another framework-owned build system.

### Step 2 - Determine The Role

Classify the app before editing config:

| Role | Meaning |
|---|---|
| `consumer` | Loads modules from remote apps through `remotes`. |
| `provider` | Exposes modules to other apps through `exposes`. |
| `both` | Publishes exposes and consumes remotes. |

Use the package name as the starting app name, converted to snake_case. Module
Federation app names must not contain hyphens.

### Step 3 - Configure Rsbuild First

For Rsbuild apps, install the official plugin:

```bash
pnpm add @module-federation/rsbuild-plugin
```

Create `module-federation.config.ts`:

```ts
import { createModuleFederationConfig } from '@module-federation/rsbuild-plugin'

export default createModuleFederationConfig({
  name: '<app_name>',
  shareStrategy: 'loaded-first',
  shared: {
    react: { singleton: true },
    'react-dom': { singleton: true },
  },
})
```

Register it from `rsbuild.config.ts`:

```ts
import { pluginModuleFederation } from '@module-federation/rsbuild-plugin'
import moduleFederationConfig from './module-federation.config'

export default defineConfig({
  plugins: [
    pluginModuleFederation(moduleFederationConfig),
  ],
})
```

Adjust `shared` for the actual framework:

- React: `react` and `react-dom` as singletons.
- Vue: `vue` as a singleton.
- Mixed framework workspaces: share only dependencies intentionally used across
  host and remote boundaries.

### Step 4 - Add Exposes Or Remotes

For providers, expose small stable entry points:

```ts
exposes: {
  './Button': './src/components/Button.tsx',
}
```

For consumers, prefer manifest-based remotes:

```ts
remotes: {
  provider: 'provider@https://example.com/mf-manifest.json',
}
```

Do not expose broad application folders or private implementation paths. Treat
each exposed key as a public contract.

### Step 5 - Handle Types

Module Federation type generation is part of the public host/remote contract.

- Producers should emit type artifacts during build.
- Consumers should pull remote types into `@mf-types`.
- Add or merge this path mapping only when remote type imports need it:

```json
{
  "compilerOptions": {
    "paths": {
      "*": ["./@mf-types/*"]
    }
  }
}
```

For producer type failures, inspect `.mf/observability/latest.json` when present
and run TypeScript against the temporary config path reported by Module
Federation diagnostics. Avoid running a broad type check when the temp config
gives a narrower failing boundary.

### Step 6 - Check Shared Dependencies

Before declaring a shared dependency healthy:

- Confirm the package is not also listed in `externals`.
- Confirm host and remotes resolve singleton packages to compatible versions.
- Check for import rewriting that can hide shared UI packages from Module
  Federation. In Rsbuild and Modern.js, inspect `source.transformImport`.
- When duplicate shared versions appear in build artifacts, prefer an alias or
  workspace constraint over runtime fallback behavior.

### Step 7 - Debug Runtime Loading

For loading failures, collect evidence in this order:

1. Confirm the configured manifest or remote entry URL is reachable.
2. Confirm the remote publishes the requested expose key.
3. Confirm the host remote name matches the configured container or manifest.
4. Check console and network errors for Module Federation runtime codes.
5. Use Module Federation observability reports when URL, expose, and shared
   dependency checks do not explain the failure.

Treat captured browser state as sensitive. Redact cookies, tokens, local storage,
session storage, and user data from saved reports and chat output.

### Step 8 - Verify

Run the narrowest checks that prove the change:

- `pnpm lint`
- `pnpm test --run` for Vitest projects
- `pnpm build` for the Rsbuild production bundle
- A host/remote smoke check when exposes, remotes, shared dependency policy, or
  deployment URLs changed
