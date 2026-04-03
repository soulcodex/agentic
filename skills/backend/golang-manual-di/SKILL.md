---
name: golang-manual-di
description: >
  Guides manual dependency injection wiring for Go services: Must-pattern
  entrypoints, OS-signal-driven context lifecycle, common provider structs,
  infrastructure must-builders, interface-segregated bus registration,
  decorator/tracing wrappers, and per-responsibility DI file layout.
  Invoked when asked to wire or scaffold a Go service DI layer, or when
  reviewing code inside a di/ or wire/ package.
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

## Manual Dependency Injection for Go Services

This skill walks through the 7-step process for wiring a Go service by hand — no code generation, no reflection containers. Each step maps to patterns observed in production `cmd/di/` packages.

---

### Step 1 — Assess the Service Topology

Before writing any DI code, map the service surface area:

1. **Entrypoints**: How many independent servers or workers? (HTTP, gRPC, worker pool?)
2. **Shared infra**: What is shared across all modules? (logger, DB pool, OTEL tracer)
3. **Module-scoped infra**: What is specific to one bounded context? (repositories, searchers, bus handlers)

Output: a list of files you will create in the `di/` package.

---

### Step 2 — Bootstrap the Signal-Driven Context

The single public function an agent should look for: `Must{ServiceName}`.

**Rules:**
- Named `Must{SERVICE_NAME}` (exported, panics on fatal misconfiguration).
- Uses `signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)` — never a raw `context.Background()` passed into the graph.
- Launches the wiring function in a goroutine; blocks on `<-ctx.Done()`.
- Calls `cancelSignal()` after unblocking to release OS resources.

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

---

### Step 3 — Wire Common Providers

A struct bundles all cross-cutting singletons.

**Rules:**
- One unexported struct per service that bundles all cross-cutting singletons.
- Initialise OTEL **first** — it is a dependency of the logger and every tracing wrapper.
- Pass the struct **by value** everywhere — it is cheap (all fields are interfaces or pointers).
- No package-level `var` globals.

**Go snippet:**

```go
type commonProviders struct {
    logger     zerolog.Logger
    timeProvider timeprovider.Provider
    uuidProvider uuidprovider.Provider
    healthcheck healthcheck.Checker
    tracer      trace.Tracer
}

func initCommonProviders(ctx context.Context, cfg {MODULE}Config) commonProviders {
    tracer := mustInitOTEL(ctx, cfg)
    logger := zerolog.New(os.Stdout).With().Caller().Logger()
    return commonProviders{
        logger:     logger,
        timeProvider: timeprovider.New(),
        uuidProvider: uuidprovider.New(),
        healthcheck: healthcheck.New(tracer),
        tracer:    tracer,
    }
}
```

**Red flags:**
- Global `var logger` / `var db` at package level.
- Initialising the logger before OTEL (tracer won't be wired into it).

---

### Step 4 — Build Infrastructure Components

Private builders for each infrastructure adapter.

**Rules:**
- Private lowercase functions: `mustInit{Component}` or `mustProvide{Component}`.
- Signature: `(ctx context.Context, cfg {Module}Config, logger zerolog.Logger) *ConcreteType`
- On error: log the reason then `panic(fmt.Errorf(...))` — fail fast, fail loud.
- Return the concrete infra type here (the interface boundary is applied in Step 5).

**Go snippet (DB pool):**

```go
func mustInitPostgres(ctx context.Context, cfg PostgresConfig, logger zerolog.Logger) *pgxpool.Pool {
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

**Red flags:**
- Returning `(T, error)` from a must-builder — callers should not handle infra init errors.
- Swallowing errors with `_ = err`.
- Initialising infra inside `main()` or the wiring function directly.

---

### Step 5 — Apply Decorator/Tracing Wrappers

Enforce the **D** of SOLID at the wiring layer.

**Rules:**
- One private builder per component that needs a tracing wrapper: `new{Name}WithTracing`.
- The builder: (a) constructs the plain adapter, (b) wraps it with the tracing decorator, (c) returns the **domain interface** — not the concrete struct.
- The tracer name follows the pattern `"{component-name}-tracer"`.
- Components without tracing wrappers return their domain interface directly via a simple `new{Name}` builder.

**Go snippet:**

```go
type Repository interface {
    Get(ctx context.Context, id string) (Entity, error)
}

func newOrderRepositoryWithTracing(repo *postgres.OrderRepository, tracer trace.Tracer) Repository {
    return tracestorage.NewDecorator(repo, tracer, "order-repository-tracer")
}

func newOrderRepository(db *pgxpool.Pool, tracer trace.Tracer) Repository {
    repo := postgres.NewOrderRepository(db)
    return newOrderRepositoryWithTracing(repo, tracer)
}
```

**Red flags:**
- Returning `*ConcretePostgresRepository` instead of `domain.Repository`.
- Sharing a single tracer instance across all components (each gets its own named tracer).
- Wiring the plain adapter directly into the bus without a tracing wrapper when one exists.

---

### Step 6 — Register Buses with Must* Functions

Group handler registration by bounded context × layer.

**Rules:**
- Two initialisation functions: `mustInitCommandBus` and `mustInitQueryBus` (private).
- Call `syncBus.Use(OTELMiddleware(...))` **before** registering any handler.
- Group handler registration into public `MustRegister{Module}{Layer}` functions (e.g. `MustRegisterOrderCommands`, `MustRegisterOrderQueries`).
- All function signatures accept **only domain interfaces**, never concrete infrastructure types.
- `MustRegister` panics on duplicate handler registration — this is intentional: it is a build-time safety check.

**Go snippet:**

```go
func mustInitCommandBus(tracer trace.Tracer) *agenticcommand.Bus {
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
- One giant `mustInitCommandBus` function with all registrations inline (no grouping by module).

---

### Step 7 — Start Entrypoints

Launch servers and workers in goroutines.

**Rules:**
- Private `start{Name}Server` / `start{Name}Worker` functions per entrypoint.
- Accepts `commonProviders` + buses as arguments — nothing global, nothing from closure.
- Launches the server/worker in a goroutine.
- The parent `run{ServiceName}` function assembles all components and calls all `start*` functions; then returns — the `Must*` entrypoint is what blocks.

**Go snippet:**

```go
func startHTTPServer(addr string, providers commonProviders, cmdBus *agenticcommand.Bus, queryBus *agenticquery.Bus) {
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

---

## File Layout

| File | Responsibility |
|---|---|
| `{service}_service.go` | `Must*` entrypoint + `run*` wiring orchestrator |
| `common.go` | `commonProviders` struct + `initCommonProviders` |
| `observability.go` | OTEL initialisation |
| `postgres.go` / `{infra}.go` | `mustInit*` infra builders |
| `aws.go` / `{cloud}.go` | Cloud client builders |
| `command.go` | `mustInitCommandBus` + `MustRegister*Commands` |
| `query.go` | `mustInitQueryBus` + `MustRegister*Queries` |
| `{module}_commands.go` | `MustRegister{Module}Commands` for large modules |
| `{module}_queries.go` | `MustRegister{Module}Queries` for large modules |
| `{module}_repos.go` | Repository builders for a module |
| `{module}_searchers.go` | Searcher/reader builders with tracing wrappers |