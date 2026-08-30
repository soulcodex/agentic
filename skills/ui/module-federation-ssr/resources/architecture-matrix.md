## SSR Module Federation Architecture Matrix

Use this reference to decide whether a project should use true SSR federation,
client-rendered federated islands inside an SSR app, or a different composition
model.

### Recommended Paths

| Stack | Use For | Guidance |
|---|---|---|
| Rsbuild + `@module-federation/rsbuild-plugin` | New client-rendered React/Vue MFE hosts and remotes | Default for non-SSR federation. Keep host/remote smoke tests and manifest-based remotes. |
| Modern.js + `@module-federation/modern-js-v3` | New React SSR MFE applications | Preferred SSR application path when the project can adopt Modern.js. Its Module Federation integration owns the server/client rendering contract. |
| Rslib | SSR-capable remote libraries or design-system producers | Use dual browser and Node outputs when a remote can be consumed by SSR hosts. |
| Nuxt + `@module-federation/nuxt` | Vue/Nuxt SSR federation experiments or owned beta adoption | Beta. Verify server entry generation, cache writes, deployment target, and hydration before calling it production-ready. |
| Next.js + `@module-federation/nextjs-mf` | Existing Pages Router maintenance | Legacy only. Requires local webpack and does not cover App Router as a new default. |
| Vinext + `@module-federation/vite` | Existing Vinext projects that accept experimental risk | Client-side MF is documented. Treat SSR federation as project-owned until proven by tests and deployment evidence. |
| Plain Vite SSR + MF | Custom runtimes owned by the project | Do not recommend as a default. Require explicit server/client artifact and hydration validation. |

### Rendering Modes

CSR federation inside an SSR app is acceptable when the remote is intentionally
client-only. Use dynamic imports, client-only wrappers, and a product-approved
loading or fallback state. The host still owns route HTML and data fetching.

True SSR federation is required when a remote must contribute to server-rendered
HTML, SEO, initial data, or first paint. The host server must resolve the remote,
render the exposed module, serialize compatible state, and hydrate the same
remote in the browser.

Dual producers publish browser and server artifacts for other applications.
They should keep environment-specific exports explicit and avoid hidden process
or browser globals.

### Red Lines

- Do not recommend Next.js Module Federation for new App Router SSR work.
- Do not claim Vite SSR federation is production-ready just because Vite supports SSR.
- Do not adopt Nuxt SSR federation on read-only or serverless targets until its
  cache and server entry behavior is verified for that target.
- Do not expose whole route trees, app shells, private folders, or framework
  internals as remote contracts.
- Do not pass auth, cookies, locale, tenant, or tracing through globals. Use
  explicit request-scoped inputs.
- Do not mix framework singleton versions without a documented version policy.
- Do not use hand-written remote module declarations as a permanent type
  contract when generated Module Federation types are available.
- Do not silently switch from SSR to client-only rendering on remote failure
  without a product decision.

### Acceptance Criteria

An SSR MFE implementation is not done until:

- the host can fetch the remote manifest or entry from the server runtime;
- the browser can fetch the matching client artifact;
- the exposed module renders server-side without browser-only API failures;
- hydration completes without mismatch warnings for the remote boundary;
- shared singleton versions are compatible across host and remotes;
- generated types are available to consumers or a temporary typed shim has an
  owner and removal path;
- route smoke tests cover the host/remote path and the fallback path;
- observability or logs identify the failing phase when remote loading breaks.

