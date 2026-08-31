## Module Federation Observability Workflow

Use this reference when debugging needs phase-level loading evidence.

### When To Use Observability

Use observability when:

- a page is blank or stuck loading and URL checks are inconclusive;
- a runtime error code does not identify the owner;
- shared dependency selection is unclear;
- the failure is intermittent or production-only;
- SSR and browser behavior differ;
- build output, runtime state, and loaded remote version need correlation.

Do not require observability for every issue. Console, network, manifest, and
config evidence may be enough for simple URL or expose mistakes.

### Report Sources

Valid sources include:

- Module Federation Chrome DevTools Loading Trace export;
- browser reader output from
  `window.__FEDERATION__.__OBSERVABILITY__['runtime_host']`;
- `.mf/observability/latest.json`;
- `.mf/observability/events.jsonl`;
- `.mf/observability/build-info.json`;
- `.mf/observability/build-report.json`;
- application telemetry records produced from `onReport`.

For Module Federation `2.5.0+`, prefer
`@module-federation/observability-plugin` when diagnostics must be retained,
uploaded, or read from Node/SSR.

For one-off browser diagnosis, the Chrome DevTools Loading Trace path can
collect runtime loading evidence without adding a permanent application
dependency.

### Analyze Reports In Order

Read:

1. `diagnosis.status`
2. `diagnosis.title`
3. `diagnosis.ownerHint`
4. `diagnosis.errorCode`
5. `diagnosis.facts`
6. `diagnosis.actions`
7. `summary.outcome`
8. `summary.error`
9. `summary.phases`
10. `summary.shared`
11. `build`
12. `moduleInfo`
13. `events`

Start with diagnosis and summary fields. Use raw events only when phase order,
interleaving, or trace timing matters.

### Interpret Carefully

- `runtime-loaded` proves the Module Federation runtime loaded the remote
  module.
- `component-loaded` is only a component-level ready signal when the producer
  emits one.
- `shared-resolved` identifies the selected shared provider and version.
- `failed` needs the failed phase, owner hint, and error details before fixing.
- `recovered` means a fallback or handled path completed after an earlier
  failure. It is not automatically a clean success.
- Missing shared fields do not prove sharing is healthy when the runtime version
  is old or shared events were not emitted.
- `moduleInfo` is clipped runtime metadata. Do not treat it as a full expose,
  component, or asset inventory.

### Production Safety

Keep console output small in production. Use `onReport` for retained reports and
application telemetry. Use `onEvent` only when event-level telemetry is
intentional.

Do not paste or persist sensitive DOM, local storage, session storage, cookies,
authorization headers, tenant identifiers, or personal data unless the user
explicitly authorizes it and the data is needed for the diagnosis.

### Final Debug Report

Report back with:

- report source;
- likely owner: host, remote, shared, network, runtime, build, SSR, or unknown;
- key evidence;
- smallest fix applied or recommended;
- verification performed;
- remaining missing evidence when the failure is not fully proven.

