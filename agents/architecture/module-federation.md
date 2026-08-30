## Module Federation

### Default Stack

- Separate client-rendered federation from SSR federation before choosing tools.
- Use Rsbuild as the default build tool for new client-rendered Module Federation hosts and remotes.
- Use `@module-federation/rsbuild-plugin` for Rsbuild integration.
- Keep Module Federation configuration in a dedicated `module-federation.config.ts` file.
- Register Module Federation from the application build config with `pluginModuleFederation(...)`.
- Use Vitest for unit and component tests. Use Playwright for routed host/remote smoke checks.
- For new SSR Module Federation applications, prefer an officially supported full-stack path such as Modern.js. Use Rslib for remotes that must publish both browser and Node artifacts.
- Treat Nuxt SSR federation as beta until the target deployment, cache, and server entry constraints are proven in the project. Treat Next.js Module Federation as legacy Pages Router maintenance only.

### Host And Remote Boundaries

- Name each federated app explicitly. Use snake_case names and avoid hyphens in Module Federation names.
- Treat exposed modules as public runtime contracts. Changing an exposed key, module shape, or exported component API is a consumer-facing change.
- Keep `exposes` owned by the remote that publishes the module.
- Keep `remotes` owned by the host that consumes the module.
- Do not let a remote reach into host internals. Shared state, routing, analytics, auth, and design-system contracts should cross through explicit APIs, shared packages, or documented runtime contracts.
- Prefer small, feature-level exposed entry points over exposing broad folders or application roots.

### SSR Boundaries

- Decide whether an SSR app only contains client-rendered federated islands, or whether the remote must participate in server render and hydration. These are different architectures.
- For true SSR federation, the host server must be able to resolve the remote manifest, load the server entry, render the exposed module, and hydrate the same component graph in the browser.
- Publish and promote matching server and browser artifacts together. Do not rebuild a remote separately for each environment.
- Keep per-request data, auth, cookies, locale, and tracing context host-owned. Pass only explicit request-scoped inputs to remotes.
- Do not let SSR remotes depend on mutable process globals, browser-only APIs during server render, or hidden host state.
- Make fallback behavior explicit. A server-render failure may fail the route, render a known fallback, or switch to a client-only island only when product requirements accept that behavior.
- Do not use `@module-federation/nextjs-mf` for new Next.js App Router SSR work. It is a legacy Pages Router path and needs a documented exception.
- Do not use beta Nuxt SSR federation on read-only or serverless runtimes unless SSR federation is disabled or the cache/write behavior is handled intentionally.

### Shared Dependencies

- Share framework singletons deliberately. React apps should share `react` and `react-dom` as singletons. Vue apps should share `vue` as a singleton.
- Do not configure the same package as both `shared` and `externals`.
- Keep singleton dependency versions aligned across host and remotes. Use aliases or workspace constraints when resolution would otherwise install multiple physical copies.
- Disable import rewriting for shared UI libraries when it prevents the shared dependency from being recognized. In Rsbuild and Modern.js, check `source.transformImport` before sharing libraries such as antd or Arco.

### Type Contracts

- Keep federated TypeScript contracts generated and consumed through Module Federation type support.
- Producers should emit remote type artifacts as part of the build.
- Consumers should pull remote types and configure `@mf-types` resolution only when the project needs remote type imports.
- Do not patch remote imports with local hand-written declarations unless the producer cannot emit types yet. Treat temporary declarations as migration debt with an owner.
- Run the narrowest type check that proves the affected host or remote contract. For producer type failures, reproduce against the temporary TypeScript config emitted by Module Federation diagnostics when available.

### Runtime And Observability

- Verify a federated change from both sides: the remote must publish the manifest and exposed module, and the host must load it from the configured URL.
- Prefer manifest-based remotes such as `mf-manifest.json` for Rsbuild projects.
- Keep runtime plugin behavior isolated from domain or feature logic.
- For loading failures, inspect the remote manifest or remote entry URL first, then use Module Federation observability data when the failure needs phase-level evidence.
- For SSR failures, collect both server-side and browser-side evidence. Check the server entry, client entry, request trace, hydration result, shared dependency negotiation, and any generated `.mf/observability/*` reports.
- Redact captured DOM, storage, cookies, tokens, and application state from reports and handoffs unless the user explicitly asks to share them.

### CI Gates

- Run lint/static analysis first, then Vitest, then the Rsbuild production build.
- Use Rslint for new TypeScript/JavaScript linting when its rule coverage fits the project. Keep commitlint in Node-capable repositories that enforce Conventional Commits.
- Add a host/remote smoke check when a change touches public exposes, remote URLs, shared dependency policy, runtime plugins, or deployment paths.
- For SSR federation, add a route-level smoke check that verifies rendered HTML, hydration, remote fallback behavior, and server reachability for the remote manifest or entry.
- Validate published artifacts once and promote the same build output through environments. Do not rebuild host and remote artifacts differently for staging and production.
