## SSR Module Federation Host And Remote Recipes

Use this reference when creating or reviewing host and remote setup.

### Client-Rendered Rsbuild Host Or Remote

Use this for non-SSR React/Vue MFE work.

- Install `@module-federation/rsbuild-plugin`.
- Keep `module-federation.config.ts` next to `rsbuild.config.ts`.
- Enable manifest-based remotes with `mf-manifest.json`.
- Share framework singletons deliberately: `react`, `react-dom`, and for
  version-sensitive Bridge integrations `react-dom/`; or `vue` for Vue apps.
- Verify with Vitest for component behavior, `pnpm build`, and a Playwright
  host/remote smoke check.

### Modern.js SSR Host Or Remote

Use this as the preferred new SSR MFE application path when Modern.js is an
acceptable framework choice.

- Install the Modern.js Module Federation plugin that matches the app tools
  major version, normally `@module-federation/modern-js-v3` for Modern.js v3.
- Keep shared config in `module-federation.config.ts`.
- Register the Module Federation plugin in `modern.config.*`.
- Use the framework-supported SSR mode rather than a custom Vite SSR runtime.
- Keep data loading request-scoped and pass data through documented loader or
  props boundaries.
- Smoke test rendered HTML, streaming or suspense fallback behavior, hydration,
  and remote failure behavior.

### Rslib Dual Producer

Use this when a remote package must be consumed by both browser and server
runtimes.

- Build dual browser and Node outputs.
- Keep environment-specific entry points explicit.
- Avoid browser-only globals in server exports.
- Publish generated types together with the remote artifacts.
- Promote one immutable build output across environments.

### Nuxt SSR Host Or Remote

Use this only after accepting beta risk and deployment constraints.

- Use the Nuxt Module Federation package rather than plain Vite federation when
  true Nuxt SSR federation is required.
- Verify both client and server entries are generated and reachable.
- Check whether the deployment target permits the runtime cache/write behavior
  the Nuxt integration needs.
- Use Nuxt SSR-safe state and data APIs. Do not store request data in process
  globals.
- Add a route smoke test for server-rendered HTML, hydration, and fallback
  behavior.

### Next.js Host Or Remote

Use this only for legacy Pages Router maintenance with an explicit exception.

- Do not recommend Module Federation for new App Router SSR architecture.
- If maintaining an existing Pages Router setup, use `@module-federation/nextjs-mf`
  with local webpack and explicit server/client remote entry paths.
- Prefer framework-native alternatives for new Next.js work: multi-zones, shared
  packages, BFF boundaries, or independent deployments behind routing.
- Document migration pressure whenever a Next Pages Router MFE is touched.

### Vinext Or Plain Vite SSR

Use this only when the repository already adopted the stack or explicitly owns
the experiment.

- Treat client-side federation through `@module-federation/vite` as distinct
  from true SSR federation.
- Require tests that prove server render, client hydration, server artifact
  resolution, and fallback behavior.
- Keep escape hatches documented because compatibility with the Next ecosystem
  or Vite SSR runtime behavior may change.

