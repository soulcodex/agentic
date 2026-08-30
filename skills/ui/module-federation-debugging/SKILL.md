---
name: module-federation-debugging
description: >
  Diagnose Module Federation failures with evidence-first triage across
  manifests, remote entries, runtime errors, shared dependencies, generated
  types, browser loading, Node/SSR loading, and hydration boundaries.
version: 1.0.0
tags:
  - ui
  - module-federation
  - debugging
  - observability
  - typescript
resources:
  - resources/evidence-map.md
  - resources/runtime-triage.md
  - resources/observability-workflow.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Module Federation Debugging Skill

Use this skill when a Module Federation host or remote fails to load, renders a
blank page, hangs in a loading state, throws a `RUNTIME-xxx` error, has unclear
shared dependency behavior, cannot resolve generated types, fails only in
production, or behaves differently between browser and SSR.

For SSR-specific architecture choices and host/remote creation, also use the
`module-federation-ssr` skill when it is available. This skill owns the
debugging investigation; the SSR skill owns SSR architecture boundaries.

### Step 1 - Name The Failure Boundary

Do not start by changing configuration. First classify the likely boundary:

| Boundary | Common Signals |
|---|---|
| config | missing plugin, wrong plugin, bad expose key, missing async startup |
| producer artifact | stale or missing manifest, remote entry, exposes, stats, types |
| network | 404, 5xx, CORS, DNS, timeout, CDN, gateway, mixed content |
| runtime | `RUNTIME-xxx`, container missing, script execution failure |
| shared dependency | duplicate React/Vue, wrong singleton, externals conflict |
| type contract | missing `@mf-types`, producer DTS failure, path mapping issue |
| render | remote loaded but component throws or error boundary trips |
| SSR/hydration | server loads differently than browser, hydration mismatch |
| cache/version | host and remote use different deployed artifact versions |

If the boundary is unclear, read
[resources/evidence-map.md](resources/evidence-map.md) and collect the minimum
facts needed to narrow it.

### Step 2 - Collect Evidence In Order

Use this order unless a hard error points to a narrower path:

1. Effective host and remote Module Federation config.
2. Runtime role: host, remote, or both.
3. Rendering mode: CSR, client-only island in SSR app, or true SSR federation.
4. Remote declaration, manifest URL, remote entry URL, and requested expose key.
5. Browser Network and console evidence.
6. Server logs and Node/SSR observability files when SSR is involved.
7. Shared dependency versions and singleton policy.
8. Generated type artifacts and TypeScript diagnostics.
9. Build stats, manifest/snapshot data, and deployment version.

Prefer primary evidence from the running app over assumptions from package
names. Redact DOM, storage, cookies, tokens, headers, and user data from reports
unless the user explicitly authorizes sharing them.

### Step 3 - Use The Right Diagnostic Path

Read [resources/runtime-triage.md](resources/runtime-triage.md) when there is a
runtime error code, blank page, missing container, missing expose, script load
failure, or shared dependency issue.

Read [resources/observability-workflow.md](resources/observability-workflow.md)
when the project has `@module-federation/observability-plugin`, a Chrome
Loading Trace export, a `traceId`, a `read:` command, or `.mf/observability/*`
files.

If there is no report and the console/network evidence is thin, recommend
Module Federation `2.5.0+` plus `@module-federation/observability-plugin` for
retained diagnostics. For one-off browser debugging, use the Module Federation
Chrome DevTools Loading Trace path when available instead of adding a permanent
dependency.

### Step 4 - Fix The Smallest Proven Cause

Only change the boundary that the evidence identifies.

- URL or manifest problem: fix the remote URL, public path, CDN route, or
  deployment path.
- Missing expose: fix the producer `exposes` key and regenerate artifacts.
- Plugin/config problem: use the plugin that matches the detected toolchain and
  enable async startup where required.
- Shared dependency problem: align singleton versions and remove conflicts with
  `externals`, aliases, or import transforms.
- Type problem: fix producer DTS generation or consumer `@mf-types` resolution.
- SSR problem: verify server entry, browser entry, server egress, request scope,
  and hydration before changing fallback behavior.

Avoid broad dependency upgrades, retries, and cache clearing as first fixes
unless the evidence points there.

### Step 5 - Verify From The Failing Side

Run the narrowest checks that prove the fix:

- `pnpm lint`, with Rslint for new TypeScript/JavaScript linting where it fits;
- `pnpm test --run` or the repository's Vitest command for affected logic;
- `pnpm build` for each changed host or remote;
- direct manifest or remote entry fetch from the host runtime;
- browser smoke check for the original loading path;
- SSR route smoke check when server rendering or hydration was involved;
- commitlint through the existing hook or CI range check when commit validation
  is configured.

When reporting back, state the boundary, evidence, fix, and verification. If the
failure remains unproven, say what evidence is missing instead of guessing.

