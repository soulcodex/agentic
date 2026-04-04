---
name: golang-manual-di
description: >
  Guides manual dependency injection wiring for Go services: three-tier naming
  taxonomy (Provide/MustProvide/Must), Must-pattern entrypoints, OS-signal-driven
  context lifecycle, common provider structs, infrastructure must-builders,
  interface-segregated bus registration, decorator/tracing wrappers, and
  per-responsibility DI file layout.
  Invoked when asked to wire or scaffold a Go service DI layer, or when
  reviewing code inside a di/ or wire/ package.
version: 1.1.0
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

## Manual Dependency Injection for Go Services

This skill walks through the 7-step process for wiring a Go service by hand — no code generation, no reflection containers. Each step maps to patterns observed in production `cmd/di/` packages.

---

### Naming Convention Taxonomy

Every function in the DI layer follows one of three tiers that communicate risk to the reader:

| Pattern | Intent | Risk |
|---|---|---|
| `Provide…()` / `provide…()` | Returns a value, no possible failure | None — safe to call anywhere |
| `MustProvide…()` / `mustProvide…()` | Builds infra that can panic on misconfiguration | Panics on bad config |
| `Must…()` / `must…()` | Starts a long-running service/process | Panics, process-level |

**Rules:**

- **Provide tier** — Use for infallible constructors. Functions that do no I/O and cannot fail. Example: `provideLogger(cfg LogConfig) zerolog.Logger`. Never use `Must` here.
- **MustProvide tier** — Use for infrastructure builders that can panic (DB pools, cloud clients, OTEL init). The risk is confined to the init path — if it panics, the service never starts.
- **Must tier** — Use for entrypoints that spin up goroutines running servers or workers. The risk is process-level — if it panics, the process terminates.

**Decision flowchart:**

1. Does the function return a value? → If NO → skip to question 2. If YES → Go to question 3.
2. Does it perform side-effectful bootstrap that wires a global? (e.g. OTEL SDK init) → If YES → use `init…` (the only valid use). If NO → error — every function must return a value or be a true bootstrap.
3. Does the function do I/O or have a failure path? → If NO → Use **Provide** tier. If YES → Can it panic instead of returning an error? → If YES → Use **MustProvide** tier (for infra) or **Must** tier (for entrypoints). If NO → Return `(T, error)` instead.

**Note on `init…`:**

The `init…` prefix is reserved **only** for true one-shot side-effectful bootstrap that wires a global and does **not** return a usable value. Example: `mustInitOTEL(ctx, cfg)` wires the OTEL SDK as a global and returns nothing. Every other function that constructs and returns a dependency must use `Provide…` or `MustProvide…`.

**Red flags:**

- Using `Must` on an infallible function (overstates risk).
- Using `init` on a function that returns a value (misleading).
- Using `Provide` on a function that can panic (understates risk).
- Using `new…` instead of `provide…` for dependency constructors.

---

### Step 1 — Assess the Service Topology

Before writing any DI code, map the service surface area:

1. **Entrypoints**: How many independent servers or workers? (HTTP, gRPC, worker pool?)
2. **Shared infra**: What is shared across all modules? (logger, DB pool, OTEL tracer)
3. **Module-scoped infra**: What is specific to one bounded context? (repositories, searchers, bus handlers)

Output: a list of files you will create in the `di/` package.

---

### Step 2 — Bootstrap the Signal-Driven Context (Must tier)

The single public function an agent should look for: `Must{ServiceName}`. This follows the **Must — start tier** because it spins up a service.

**Rules:**

- Named `Must{SERVICE_NAME}` (exported, panics on fatal misconfiguration).
- Uses `signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)` — never a raw `context.Background()` passed into the graph.
- Launches the wiring function in a goroutine; blocks on `<-ctx.Done()`.
- Calls `cancelSignal()` after unblocking to release OS resources.
- **Entrypoints that spin up a service always follow the `Must` tier (not `MustProvide`), because the risk is process-level, not dependency-level.**

**Go snippet:**

```go
func Must{SERVICE_NAME}(cfg {MODULE}Config) {
    ctx, cancelSignal := signal.NotifyContext(
        context.Background(),
        os.Interrupt,
        syscall.SIGTERM,
    )
    defer cancelSignal()

    go run{SERVICE_NAME}(cfg, ctx)
    <-ctx.Done()
}
```

**Red flags:**
- Context created inside the wiring function (signal handling is lost).
- `os.Exit` called directly instead of letting the signal propagate.
- No `cancelSignal()` call after `<-ctx.Done()`.
- Using `start…` instead of `must…` hides the panic risk from the reader.

---

### Step 3 — Wire Common Providers (Provide tier)

A struct bundles all cross-cutting singletons. This follows the **Provide tier** because it builds a value struct with no failure path.

**Rules:**

- One unexported struct per service that bundles all cross-cutting singletons.
- Initialise OTEL **first** — it is a dependency of the logger and every tracing wrapper.
- Pass the struct **by value** everywhere — it is cheap (all fields are interfaces or pointers).
- No package-level `var` globals.
- **If a provider function cannot fail, name it `Provide…` (exported) or `provide…` (unexported). Never prefix it with `Must`.**

**Go snippet:**

```go
type commonProviders struct {
    logger      zerolog.Logger
    timeProvider timeprovider.Provider
    uuidProvider uuidprovider.Provider
    healthcheck healthcheck.Checker
    tracer      trace.Tracer
}

func provideCommon(ctx context.Context, cfg {MODULE}Config) commonProviders {
    tracer := mustInitOTEL(ctx, cfg) // exception: true side-effectful bootstrap
    logger := zerolog.New(os.Stdout).With().Caller().Logger()
    return commonProviders{
        logger:      logger,
        timeProvider: timeprovider.New(),
        uuidProvider: uuidprovider.New(),
        healthcheck: healthcheck.New(tracer),
        tracer:      tracer,
    }
}
```

**Red flags:**
- Global `var logger` / `var db` at package level.
- Initialising the logger before OTEL (tracer won't be wired into it).
- Using `Must` on an infallible constructor (overstates risk).

---

### Step 4 — Build Infrastructure Components (MustProvide tier)

Private builders for each infrastructure adapter. These follow the **MustProvide tier** because they can panic on misconfiguration.

**Rules:**

- Private lowercase functions: `mustProvide{Component}` (unexported) or `MustProvide{Component}` (exported).
- Signature: `(ctx context.Context, cfg {Module}Config, logger zerolog.Logger) *ConcreteType`
- On error: log the reason then `panic(fmt.Errorf(...))` — fail fast, fail loud.
- Return the concrete infra type here (the interface boundary is applied in Step 5).
- **Infallible constructors (no I/O, cannot fail) use `provide{Component}` — e.g. `provideLogger(cfg LogConfig) zerolog.Logger`.**

**Go snippet (DB pool):**

```go
func mustProvidePostgres(ctx context.Context, cfg PostgresConfig, logger zerolog.Logger) *pgxpool.Pool {
    pool, err := pgxpool.New(ctx, cfg.ConnString())
    if err != nil {
        logger.Error().Err(err).Msg("failed to connect to postgres")
        panic(fmt.Errorf("postgres connection: %w", err))
    }
    if err := pool.Ping(ctx); err != nil {
        logger.Error().Err(err).Msg("postgres health check failed")
        panic(fmt.Errorf("postgres ping: %w", err))
    }
    return pool
}
```

**Go snippet (infallible constructor):**

```go
func provideLogger(cfg LogConfig) zerolog.Logger {
    return zerolog.New(os.Stdout).
        With().
        Level(zerolog.Level(cfg.Level)).
        Caller().
        Logger()
}
```

**Red flags:**
- Using `mustInit*` for a function that returns a dependency value (misleading — use `mustProvide*`).
- Returning `(T, error)` from a must-builder — callers should not handle infra init errors.
- Swallowing errors with `_ = err`.
- Initialising infra inside `main()` or the wiring function directly.

---

### Step 5 — Apply Decorator/Tracing Wrappers (Provide tier)

Enforce the **D** of SOLID at the wiring layer. These follow the **Provide tier** because they are pure value constructors that never do I/O and cannot fail.

**Rules:**

- One private builder per component that needs a tracing wrapper: `provide{Name}WithTracing` (unexported).
- The builder: (a) constructs the plain adapter, (b) wraps it with the tracing decorator, (c) returns the **domain interface** — not the concrete struct.
- The tracer name follows the pattern `"{component-name}-tracer"`.
- Components without tracing wrappers return their domain interface directly via a simple `provide{Name}` builder.
- **Decorator/tracing wrappers never do I/O and cannot fail — they are pure value constructors and must use the `Provide` tier.**

**Go snippet:**

```go
type Repository interface {
    Get(ctx context.Context, id string) (Entity, error)
}

func provideOrderRepositoryWithTracing(repo *postgres.OrderRepository, tracer trace.Tracer) Repository {
    return tracestorage.NewDecorator(repo, tracer, "order-repository-tracer")
}

func provideOrderRepository(db *pgxpool.Pool, tracer trace.Tracer) Repository {
    repo := postgres.NewOrderRepository(db)
    return provideOrderRepositoryWithTracing(repo, tracer)
}
```

**Red flags:**
- Returning `*ConcretePostgresRepository` instead of `domain.Repository`.
- Sharing a single tracer instance across all components (each gets its own named tracer).
- Wiring the plain adapter directly into the bus without a tracing wrapper when one exists.
- Using `new…` instead of `provide…` for dependency constructors (obscures the tier).

---

### Step 6 — Register Buses with Must* Functions (MustProvide tier)

Group handler registration by bounded context × layer. Bus construction follows the **MustProvide tier** because it can panic on duplicate registration.

**Rules:**

- Two initialisation functions: `mustProvideCommandBus` and `mustProvideQueryBus` (private). — **Note: `init…` is reserved for side-effectful bootstrap with no return value. Bus construction returns a value → use `mustProvide…`.**
- Call `syncBus.Use(OTELMiddleware(...))` **before** registering any handler.
- Group handler registration into public `MustRegister{Module}{Layer}` functions (e.g. `MustRegisterOrderCommands`, `MustRegisterOrderQueries`).
- All function signatures accept **only domain interfaces**, never concrete infrastructure types.
- `MustRegister` panics on duplicate handler registration — this is intentional: it is a build-time safety check.

**Go snippet:**

```go
func mustProvideCommandBus(tracer trace.Tracer) *agenticcommand.Bus {
    bus := agenticcommand.New()
    bus.Use(otelcommand.NewMiddleware(tracer))
    return bus
}

func MustRegisterOrderCommands(bus *agenticcommand.Bus, repo domain.OrderRepository) {
    handler := cmdorder.NewCreateHandler(repo)
    agenticcommand.MustRegister(bus, "order.create", handler)
}
```

**Red flags:**
- Registering handlers before attaching middleware.
- Accepting `*postgres.OrderRepository` instead of `domain.OrderRepository` in `MustRegister*`.
- One giant `mustProvideCommandBus` function with all registrations inline (no grouping by module).

---

### Step 7 — Start Entrypoints (Must tier)

Launch servers and workers in goroutines. These follow the **Must tier** because they launch long-running processes.

**Rules:**

- Private `must{Name}Server` / `must{Name}Worker` functions per entrypoint.
- Accepts `commonProviders` + buses as arguments — nothing global, nothing from closure.
- Launches the server/worker in a goroutine.
- The parent `run{ServiceName}` function assembles all components and calls all `must*` functions; then returns — the `Must*` entrypoint is what blocks.
- **Any function that launches a goroutine with a server/worker and panics on failure follows the `Must` tier.**

**Go snippet:**

```go
func mustHTTPServer(addr string, providers commonProviders, cmdBus *agenticcommand.Bus, queryBus *agenticquery.Bus) {
    mux := http.NewServeMux()
    // register routes...
    server := &http.Server{Addr: addr, Handler: mux}
    go func() {
        providers.logger.Info().Str("addr", addr).Msg("starting http server")
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            panic(err)
        }
    }()
}
```

**Red flags:**
- Starting servers before all buses are fully registered.
- Passing individual providers (logger, tracer, etc.) as separate args instead of `commonProviders`.
- `http.ListenAndServe` called without a goroutine (blocks the wiring function).
- Using `start…` instead of `must…` hides the panic risk from the reader.

---

## File Layout

| File | Responsibility | Naming tier |
|---|---|---|
| `{service}_service.go` | `Must*` entrypoint + `run*` wiring orchestrator | Must |
| `common.go` | `commonProviders` struct + `provideCommon` | Provide |
| `observability.go` | OTEL initialisation | MustProvide (init exception) |
| `postgres.go` / `{infra}.go` | `mustProvide*` infra builders | MustProvide |
| `aws.go` / `{cloud}.go` | Cloud client builders | MustProvide |
| `command.go` | `mustProvideCommandBus` + `MustRegister*Commands` | MustProvide |
| `query.go` | `mustProvideQueryBus` + `MustRegister*Queries` | MustProvide |
| `{module}_commands.go` | `MustRegister{Module}Commands` for large modules | Must |
| `{module}_queries.go` | `MustRegister{Module}Queries` for large modules | Must |
| `{module}_repos.go` | Repository builders for a module | Provide |
| `{module}_searchers.go` | Searcher/reader builders with tracing wrappers | Provide |