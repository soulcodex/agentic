## Module Federation Runtime Triage

Use this reference for runtime loading failures, blank pages, missing remotes,
shared dependency issues, and type contract failures.

### Runtime Error Codes

Treat `RUNTIME-xxx` codes as entry points, not final answers. Confirm the phase
with console, network, manifest, and observability evidence.

Common starting points:

- `RUNTIME-001`: failed to get remote entry exports. Check wrong URL, producer
  registration, network access, remote entry type mismatch, and missing global.
- `RUNTIME-006`: invalid `loadShareSync` call. Check async startup and whether
  the shared dependency was already loaded.
- `RUNTIME-007`: failed to get remote snapshot. Check versioned remote entries,
  deployment metadata, manifest/snapshot availability, and platform data flow.
- `RUNTIME-008`: failed to load script resources. Check URL reachability, CORS,
  status code, timeout, CDN, and script execution details.

For other runtime codes, look up the current official troubleshooting page and
use it with local evidence.

### Manifest And Remote Entry

For manifest-based remotes:

- fetch `mf-manifest.json` from the same network location as the failing host;
- inspect public path, remote entry, exposes, remotes, shared, and type URLs;
- verify the host uses the intended remote name and URL;
- confirm the requested expose key starts with `./` and exists in the producer.

For remote entry based remotes:

- verify the entry is reachable and served with the expected JavaScript content;
- verify global script versus ESM expectations match the host config;
- check whether the container is registered on `globalThis` or `window` when
  that runtime expects a global producer.

### Shared Dependencies

Shared dependency issues often appear as hooks errors, duplicate framework
instances, missing providers, or hydration mismatches.

Check:

- React apps share `react` and `react-dom` as singletons;
- Vue apps share `vue` as a singleton;
- host and remote versions are compatible;
- the package is not both `shared` and `externals`;
- aliases do not point host and remote to different physical copies;
- Rsbuild or Modern.js `source.transformImport` is not hiding shared UI
  libraries from Module Federation.

### Type Contracts

For producer type generation failures:

- enable debug mode with `FEDERATION_DEBUG=true`;
- set `dts.displayErrorInTerminal` when available;
- inspect `.mf/typesGenerate.log` and `.mf/observability/latest.json`;
- run TypeScript against the temporary config reported by diagnostics when
  available.

For consumer type failures:

- verify `@mf-types` exists;
- fetch the remote type zip or API from the manifest;
- add or merge `compilerOptions.paths` only when remote type imports need it:

```json
{
  "compilerOptions": {
    "paths": {
      "*": ["./@mf-types/*"]
    }
  }
}
```

Do not leave hand-written remote module declarations as permanent contracts
when the producer can emit generated types.

### SSR And Hydration

When the failure involves SSR:

- compare server fetch behavior with browser fetch behavior;
- verify the remote publishes both server and client artifacts when true SSR
  federation is required;
- confirm browser-only APIs are not used during server render;
- confirm request data is not stored in module-level mutable state;
- verify the server-rendered artifact and hydrated browser artifact are the
  same deployed version;
- treat silent fallback from SSR to client-only rendering as a product decision,
  not a debugging shortcut.

