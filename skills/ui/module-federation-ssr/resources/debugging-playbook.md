## SSR Module Federation Debugging Playbook

Use this reference when a server-rendered federated route fails, hydrates
incorrectly, loads a wrong version, or cannot resolve types.

### First Classification

Classify the failure before changing config:

| Symptom | Likely Boundary |
|---|---|
| Server cannot fetch manifest or remote entry | network, URL, CORS, CDN, deployment, allowlist |
| Browser can load remote but server cannot | SSR runtime URL, private network, server egress, credentials |
| Server renders but browser hydration warns | different artifacts, data mismatch, client-only API, singleton mismatch |
| Remote loads but component is missing | wrong expose key, stale manifest, wrong container name |
| TypeScript cannot resolve remote imports | missing `@mf-types`, producer DTS failure, consumer path config |
| Random cross-request state appears | global mutable state, singleton service leakage, cached request data |

### Evidence Order

Collect the smallest evidence that proves the owner:

1. Effective host and remote Module Federation config.
2. Server-accessible manifest or remote entry URL.
3. Browser Network result for the same remote.
4. Published exposes, shared dependencies, public path, server entry, and client
   entry from the manifest or build stats.
5. Server logs for the request that rendered the route.
6. Browser hydration warnings and Module Federation runtime error codes.
7. `.mf/observability/latest.json` and `.mf/observability/events.jsonl` when the
   observability plugin is enabled.
8. `.mf/observability/build-info.json` or `.mf/observability/build-report.json`
   when output shape or type generation is suspect.

### Runtime And Observability

For Module Federation `2.5.0+`, prefer `@module-federation/observability-plugin`
when URL, expose, and shared dependency checks do not explain the failure.

Use the report to identify:

- the loading phase;
- the owner hint, such as host, remote, shared, runtime, or build;
- the `traceId`;
- requested remote and expose;
- selected shared provider and version;
- recovered, pending, or failed outcome.

For Node or SSR reports, read `.mf/observability/latest.json` first. Use
`.mf/observability/events.jsonl` only when multiple traces or event ordering
matter.

For browser debugging, prefer the Module Federation Chrome DevTools Loading
Trace export or an installed observability plugin report. Treat DOM, storage,
cookies, tokens, and application state as sensitive.

### SSR-Specific Checks

- Confirm the host server resolves the same remote version the browser later
  hydrates.
- Confirm remote artifacts were built and promoted as one immutable version.
- Confirm server-rendered code avoids `window`, `document`, `localStorage`,
  layout measurement, and browser-only effects during render.
- Confirm request data is not stored in module-level state or singleton services.
- Confirm auth, cookie, tenant, locale, and tracing context are explicitly
  passed and redacted from reports.
- Confirm streaming boundaries and suspense fallbacks are intentional.
- Confirm remote failure behavior is product-approved: fail route, render known
  fallback, or client-only island.

### Common Fixes

- Wrong or unreachable URL: fix remote URL, public path, CDN route, or server
  egress allowlist.
- Missing expose: update the producer expose key and regenerate the manifest.
- Mismatched server/client artifacts: promote one remote build version and clear
  stale CDN/cache entries.
- Shared mismatch: align singleton versions and remove conflicts between
  `shared`, `externals`, aliases, and import transforms.
- Hydration mismatch: move browser-only behavior to client effects, stabilize
  serialized data, or make the remote client-only by design.
- Type failures: fix producer DTS output, inspect Module Federation diagnostics,
  and add `@mf-types` path mapping only when consumers need remote type imports.

