## Module Federation Debug Evidence Map

Use this reference to decide which facts to collect before changing code.

### Minimum Context

Collect:

- package manager and lockfile;
- framework and bundler: Rsbuild, Rspack, Webpack, Modern.js, Next.js, Nuxt,
  Vinext, or Vite;
- Module Federation packages and versions;
- host and remote roles;
- CSR, client-only SSR island, or true SSR federation mode;
- host `remotes` and remote `exposes`;
- remote manifest or remote entry URL;
- requested import path or `loadRemote` call;
- failing environment: local, preview, staging, production, browser, Node, SSR,
  CI, or type generation.

### Files To Inspect

Prefer the smallest set that reaches the failing boundary:

- `package.json`
- `pnpm-lock.yaml` when dependency versions matter
- `module-federation.config.*`
- `rsbuild.config.*`, `rspack.config.*`, `webpack.config.*`, `modern.config.*`,
  `next.config.*`, `nuxt.config.*`, or `vite.config.*`
- runtime plugin files referenced by the config
- route or component file that imports the remote
- exposed module file in the producer
- `tsconfig*.json`
- `@mf-types`, `.mf/typesGenerate.log`, or temporary TypeScript configs when
  type generation failed
- `.mf/observability/latest.json`, `events.jsonl`, `build-info.json`, or
  `build-report.json` when present

### Fast Questions To Answer

- Can the host fetch the manifest or remote entry from the same runtime where
  the failure happens?
- Does the manifest or stats output list the requested expose key?
- Does the remote name in the host match the producer name or manifest entry?
- Does the remote entry type match the consumer expectation, such as global
  script versus ESM?
- Are host and remote resolving the same framework singleton version?
- Did the host and remote deploy as one compatible artifact set?
- Does the failure happen before remote load, during remote entry execution,
  during expose factory execution, during render, or during hydration?

### Useful Local Checks

Fetch a remote manifest or entry:

```bash
curl -I "https://example.com/mf-manifest.json"
curl -s "https://example.com/mf-manifest.json" | jq .
```

Enable Module Federation debug mode for a local run:

```bash
FEDERATION_DEBUG=true pnpm dev
FEDERATION_DEBUG=true pnpm build
```

Enable browser debug mode for a page reload:

```js
localStorage.setItem('FEDERATION_DEBUG', 'true')
```

Inspect generated type output:

```bash
find . -maxdepth 3 -name '@mf-types' -o -name 'typesGenerate.log'
```

These checks guide the investigation; they are not proof by themselves. Compare
their output with the failing environment and the exact host/remote config.

