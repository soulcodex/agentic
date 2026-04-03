# Plan: Add `golang-manual-di` Skill

**Status:** Draft — awaiting review  
**Date:** 2026-04-03  
**Author:** Architect agent

---

## 1. Goal

Create a new skill, `golang-manual-di`, under `skills/backend/`, that teaches an agent
how to wire a Go service by hand — no code-generation frameworks, no reflection-based
containers — following the patterns observed in
`identity-operations-fraud-detection/cmd/di`.

The skill must be self-contained, schema-valid, ≤ 300 lines, and immediately usable
without touching any other file *except* `index/skills.json` (updated via `just index`).

---

## 2. Observed Patterns (source of truth)

All patterns below are drawn directly from the files in `cmd/di/`.

| Pattern | File(s) | Description |
|---|---|---|
| **`Must*` entrypoint** | `fraud_detector_service.go` | `MustRunFraudDetectorService` captures OS signals via `signal.NotifyContext`, launches the wiring goroutine, and blocks on `<-ctx.Done()`. Calling code is a single line in `main.go`. |
| **Signal-driven context** | `fraud_detector_service.go` | `signal.NotifyContext(context.Background(), os.Interrupt, os.Kill)` threads a cancellable context through the whole graph; services receive the context, not a raw `context.Background()`. |
| **Common providers struct** | `common.go` | A plain struct (`commonProviders`) bundles cross-cutting singletons (logger, time, ticker, UUID, healthcheck, OTEL). Built once, passed by value everywhere. No global variables. |
| **Infrastructure `must*` builders** | `postgres.go`, `aws.go` | Private lowercase functions named `mustInit*` / `mustProvide*` that `panic` on fatal errors. Panic is intentional: the process must not start in a broken state. |
| **Observability bootstrap** | `observability.go` | OTEL is initialised before anything else inside `initCommonProviders`; the tracer is then injected into every infrastructure component that wraps a collaborator with tracing. |
| **Decorator / tracing wrappers** | `fraud_detector_matchers.go`, `gallery_item_searchers.go`, `fraud_detector_service.go` | Each infrastructure component has a plain version and a tracing-wrapped version. The constructor returns the **interface**, not the concrete type, so callers are decoupled. |
| **Domain-interface segregation** | `command.go`, `query.go`, `gallery_item_commands.go`, `gallery_item_queries.go` | Bus registration functions accept **domain interfaces** (e.g. `gallerydomain.Repository`, `galleryitemdomain.FaceDuplicateChecker`) — never concrete structs. |
| **`Must*` bus registration** | `command.go`, `query.go`, `gallery_item_commands.go`, `gallery_item_queries.go` | Public `MustRegister*` functions group related handlers. They call `agenticcommand.MustRegister` / `agenticquery.MustRegister` which panics on duplicate registration — a build-time safety net. |
| **Bus middleware (OTEL)** | `command.go`, `query.go` | A single `syncBus.Use(...)` call wires OTEL tracing into every command/query before any handler is registered. |
| **Entrypoint / server starters** | `http.go` | Private `start*HTTPServer` functions build the router, attach middleware, and launch in a goroutine. They receive `commonProviders` + buses as arguments, nothing global. |
| **Config as a value** | throughout | `cfg` is a concrete value type loaded once, sliced per-subsystem (e.g. `cfg.PostgresConfig`, `cfg.S3Config`), and passed to each builder — never stored in a global. |
| **File naming convention** | all files | One responsibility per file: `postgres.go`, `aws.go`, `observability.go`, `command.go`, `query.go`, `http.go`, `common.go`, `<module>_<layer>.go`. |

---

## 3. Skill File to Create

### Location

```
skills/backend/golang-manual-di/SKILL.md
```

### Frontmatter (schema-compliant)

```yaml
---
name: golang-manual-di
description: >
  Guides manual dependency injection wiring for Go services: Must-pattern
  entrypoints, OS-signal-driven context lifecycle, common provider structs,
  infrastructure must-builders, interface-segregated bus registration,
  decorator/tracing wrappers, and per-responsibility DI file layout.
  Invoked when asked to wire, scaffold, or review a Go service's DI layer.
version: 1.0.0
tags:
  - golang
  - dependency-injection
  - architecture
  - backend
  - solid
resources:
  - example_di.go
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---
```

### Body outline (≤ 300 lines total including frontmatter)

The skill body walks through **7 ordered steps**, each maps to one or more of the
patterns above:

1. **Step 1 — Assess the service topology**  
   Identify: how many independent server entrypoints exist? Which infra components are shared? Which are module-scoped?

2. **Step 2 — Bootstrap the signal-driven context**  
   Write the `Must*` public entrypoint using `signal.NotifyContext`. Explain: context flows top-down; never store it; always pass it into builders.

3. **Step 3 — Wire common providers**  
   Create the `commonProviders` struct. Initialise OTEL first (it is a dependency of logger and every tracing wrapper). Collect logger, time/ticker/UUID providers, healthchecker.

4. **Step 4 — Build infrastructure components (must-builders)**  
   Write private `mustInit*` / `mustProvide*` builder functions per infra adapter (DB, S3, external HTTP clients). Rules: accept `context.Context` + config slice + logger; return concrete type or panic; log the panic reason before returning.

5. **Step 5 — Apply decorator / tracing wrappers (interface returns)**  
   For each component that has a domain interface, create a `new<Name>WithTracing` builder that: (a) constructs the plain adapter, (b) wraps it with the tracing decorator, (c) returns the **interface** — not the struct. This is where D of SOLID is enforced at the wiring layer.

6. **Step 6 — Register buses with `Must*` functions**  
   Create `mustInitCommandBus` / `mustInitQueryBus`. Register OTEL middleware first. Group handler registration into `MustRegister<Module><Layer>` public functions (one per bounded context × layer). Accept **only domain interfaces** in function signatures.

7. **Step 7 — Start entrypoints**  
   Write `start*Server` / `start*Worker` private functions. Each accepts `commonProviders` + buses (no globals). Launch in a goroutine. The calling `runService` function assembles and fires them all, then the `Must*` entrypoint blocks on `<-ctx.Done()`.

Each step includes:
- A concise rule block (what to do / what to avoid)
- A minimal Go code snippet derived from the real codebase
- A "red flags" checklist for review

A final **File Layout** section gives the canonical naming convention for a DI package.

---

## 4. Index Update

After creating the skill file, run:

```
just index
```

This regenerates `index/skills.json` with the new entry. Both files must be committed
together.

---

## 5. Quality Gates

Before committing, the following must all pass:

| Check | Command | Expected |
|---|---|---|
| Schema lint | `just lint` | 0 errors |
| Index rebuild | `just index` | `skills.json` contains `golang-manual-di` |
| Test suite | `just test` | All assertions pass (no new tests required — the skill adds no tooling behaviour) |

> **Note:** No new test assertions are needed because the skill does not add or change
> any compose/vendor-gen/deploy-skills behaviour. The existing test suite is sufficient.

---

## 6. Commit

Single commit following Conventional Commits:

```
feat(skills): add golang-manual-di skill for Go manual DI wiring
```

Staged files:
- `skills/backend/golang-manual-di/SKILL.md` (new)
- `index/skills.json` (updated by `just index`)

---

## 7. Out of Scope

- No new fragment in `agents/` — the skill is self-contained.
- No new profile — adding a profile is a separate concern.
- No changes to tooling scripts.
- No modifications to existing skills or fragments.

---

## 8. Decisions (resolved)

1. **Category placement** → `skills/backend/` ✅

2. **Skill trigger condition** → fires both when asked to wire/scaffold **and** when reviewing code in a `di/` or `wire/` package. Description updated accordingly. ✅

3. **Code snippets** → illustrative Go using `{SERVICE_NAME}` / `{MODULE}` tokens as placeholders. ✅

4. **`resources:` array** → include an annotated `example_di.go` companion file. Declared in frontmatter `resources: [example_di.go]`. ✅

5. **Line budget** → keep all 7 steps; combined `SKILL.md` + `example_di.go` must stay within the 300-line limit for `SKILL.md`. `example_di.go` is a separate file so it does not count toward the fragment line limit. ✅
