---
name: module-federation-ssr
description: >
  Add, review, or debug server-side rendered Module Federation applications,
  including Modern.js, Nuxt, Next.js legacy Pages Router, Vinext, Vite SSR, and
  dual browser/server remote artifacts.
version: 1.0.0
tags:
  - ui
  - module-federation
  - ssr
  - micro-frontends
  - typescript
resources:
  - resources/architecture-matrix.md
  - resources/debugging-playbook.md
  - resources/host-remote-recipes.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Module Federation SSR Skill

Use this skill when a Module Federation task involves SSR, hydration, server
entries, streamed rendering, Modern.js, Nuxt, Next.js, Vinext, Vite SSR, or
server-rendered host/remote contracts.

If the task is a client-rendered Rsbuild MFE with no SSR requirement, use the
regular `module-federation` skill instead.

### Step 1 - Classify The Rendering Contract

Determine the real rendering mode before editing configuration:

| Mode | Meaning |
|---|---|
| CSR federation | An SSR-capable app loads the remote only in the browser. |
| SSR federation | The host server loads and renders the remote, then the browser hydrates the same graph. |
| Dual producer | A remote publishes browser and Node artifacts for SSR consumers. |

When the user says "SSR support", do not assume true SSR federation. Ask only
when local code and deployment config cannot reveal whether the remote must
render on the server.

### Step 2 - Choose The Implementation Family

Read [resources/architecture-matrix.md](resources/architecture-matrix.md) before
choosing or recommending a framework.

Default guidance:

- Use Rsbuild plus `@module-federation/rsbuild-plugin` for new client-rendered
  React/Vue host and remote applications.
- Use Modern.js and `@module-federation/modern-js-v3` as the preferred new SSR
  Module Federation application path when the project can adopt Modern.js.
- Use Rslib for remotes that need to publish both browser and Node artifacts.
- Treat Nuxt SSR federation as beta and verify deployment constraints before
  adopting it.
- Treat Next.js Module Federation as legacy Pages Router maintenance only. Do
  not recommend it for new App Router SSR architecture.
- Treat Vinext as experimental unless the repository already adopted it and owns
  the compatibility risk.

### Step 3 - Create Or Review Host And Remote Contracts

Read [resources/host-remote-recipes.md](resources/host-remote-recipes.md) when
creating or reviewing host/remotes.

For SSR federation, verify:

- the remote publishes matching browser and server artifacts;
- the host can resolve the remote from its server runtime and browser runtime;
- exposed modules are small public contracts, not route trees or implementation
  folders;
- request-scoped data, auth, cookies, locale, and trace context cross through
  explicit inputs;
- framework singletons are shared deliberately and version alignment is enforced.

### Step 4 - Debug With Server And Browser Evidence

Read [resources/debugging-playbook.md](resources/debugging-playbook.md) when
debugging runtime, hydration, shared dependency, manifest, or type failures.

For SSR failures, always collect evidence from both sides:

- server logs and `.mf/observability/latest.json` when available;
- browser console, Network panel, hydration warnings, and Loading Trace exports;
- published manifest or remote entry metadata;
- generated `@mf-types` artifacts and producer type diagnostics;
- build facts from `.mf/observability/build-info.json` or
  `.mf/observability/build-report.json` when build output is suspect.

### Step 5 - Verify

Run the narrowest checks that prove the changed boundary:

- `pnpm lint`, using Rslint for new TypeScript/JavaScript linting when it fits;
- `pnpm test --run` or the repository's Vitest script;
- `pnpm build` for each affected host and remote;
- an SSR route smoke check that verifies server-rendered HTML, hydration, and
  configured remote fallback behavior;
- commitlint through the existing hook or CI commit-range check when the
  repository enforces Conventional Commits.

