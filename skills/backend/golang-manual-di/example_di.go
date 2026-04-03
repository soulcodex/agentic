//go:build ignore

package main

// NOTE: This file is illustrative — it is never compiled.
// It demonstrates the complete DI wiring pattern for a hypothetical service.

import (
	"context"
	"os"
	"os/signal"
	"syscall"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/trace"

	"{REPO_MODULE}/pkg/otel"
	"{REPO_MODULE}/pkg/timeprovider"
	"{REPO_MODULE}/pkg/uuidprovider"
	"{REPO_MODULE}/pkg/healthcheck"
	"{REPO_MODULE}/pkg/postgres"
	domain "{REPO_MODULE}/internal/{MODULE}/domain"
	cmdorder "{REPO_MODULE}/internal/{MODULE}/commands"
	agenticcommand "{REPO_MODULE}/pkg/agentic/command"
	agenticquery "{REPO_MODULE}/pkg/agentic/query"
	"github.com/rs/zerolog"
)

// =============================================================================
// Step 2: Must* Entrypoint — signal-driven context
// =============================================================================

// Must{SERVICE_NAME} is the single public entrypoint.
// It captures OS signals and blocks until termination.
func Must{SERVICE_NAME}(cfg {MODULE}Config) {
	// NOTE: signal.NotifyContext creates a context that cancels on SIGINT/SIGTERM.
	ctx, cancelSignal := signal.NotifyContext(
		context.Background(),
		os.Interrupt,
		syscall.SIGTERM,
	)
	defer cancelSignal() // NOTE: Release OS signal handlers after exit.

	// NOTE: Wiring runs in a goroutine so Must{SERVICE_NAME} can block on <-ctx.Done().
	go run{SERVICE_NAME}(cfg, ctx)

	// NOTE: Block until a signal is received.
	<-ctx.Done()
}

// =============================================================================
// Step 7: run{SERVICE_NAME} — wires all components, returns immediately
// =============================================================================

// run{SERVICE_NAME} assembles all dependencies in the correct order.
// After it returns, the Must* entrypoint blocks on <-ctx.Done().
func run{SERVICE_NAME}(cfg {MODULE}Config, ctx context.Context) {
	// NOTE: Step 3 — Wire common providers (OTEL first).
	providers := initCommonProviders(ctx, cfg)

	// NOTE: Step 4 — Build infrastructure components.
	db := mustInitPostgres(ctx, cfg.PostgresConfig, providers.logger)

	// NOTE: Step 5 — Apply tracing wrappers (return interfaces, not concretes).
	orderRepo := newOrderRepositoryWithTracing(
		postgres.NewOrderRepository(db),
		providers.tracer,
	)

	// NOTE: Step 6 — Register buses with OTEL middleware.
	cmdBus := mustInitCommandBus(providers.tracer)
	queryBus := mustInitQueryBus(providers.tracer)

	MustRegisterOrderCommands(cmdBus, orderRepo)
	MustRegisterOrderQueries(queryBus, orderRepo)

	// NOTE: Step 7 — Start entrypoints.
	startHTTPServer(cfg.HTTPPort, providers, cmdBus, queryBus)
}

// =============================================================================
// Step 3: commonProviders — bundles cross-cutting singletons
// =============================================================================

type commonProviders struct {
	logger        zerolog.Logger
	timeProvider timeprovider.Provider
	uuidProvider uuidprovider.Provider
	healthcheck  healthcheck.Checker
	tracer       trace.Tracer
}

// initCommonProviders builds all cross-cutting providers.
// NOTE: OTEL is initialised FIRST — it is a dependency of the logger.
func initCommonProviders(ctx context.Context, cfg {MODULE}Config) commonProviders {
	// NOTE: OTEL must be initialised before the logger.
	tp := mustInitOTEL(ctx, cfg)

	logger := zerolog.New(os.Stdout).With().Caller().Logger()

	return commonProviders{
		logger:        logger,
		timeProvider:  timeprovider.New(),
		uuidProvider:  uuidprovider.New(),
		healthcheck:   healthcheck.New(tp),
		tracer:        tp.Tracer("{service-name}-tracer"),
	}
}

// mustInitOTEL initialises OpenTelemetry.
func mustInitOTEL(ctx context.Context, cfg {MODULE}Config) *otel.TracerProvider {
	tp, err := otel.NewTracerProvider(
		otel.WithServiceName(cfg.ServiceName),
		otel.WithResource(otel.NewResource()),
	)
	if err != nil {
		panic(err)
	}
	return tp
}

// =============================================================================
// Step 4: mustInit* builders — private, panic on error
// =============================================================================

// mustInitPostgres creates a Postgres connection pool.
// NOTE: Panic on failure — the process must not start in a broken state.
func mustInitPostgres(ctx context.Context, cfg PostgresConfig, logger zerolog.Logger) *pgxpool.Pool {
	pool, err := pgxpool.New(ctx, cfg.ConnString())
	if err != nil {
		logger.Error().Err(err).Msg("failed to connect to postgres")
		panic(err)
	}
	if err := pool.Ping(ctx); err != nil {
		logger.Error().Err(err).Msg("postgres health check failed")
		panic(err)
	}
	return pool
}

// =============================================================================
// Step 5: new*WithTracing — returns domain interface, not concrete
// =============================================================================

// NOTE: Domain interface segregation — callers receive an interface.
type OrderRepository interface {
	Create(ctx context.Context, order domain.Order) error
	GetByID(ctx context.Context, id string) (domain.Order, error)
}

// newOrderRepositoryWithTracing wraps a plain repository with tracing.
// NOTE: Returns the domain interface, not *postgres.OrderRepository.
func newOrderRepositoryWithTracing(repo *postgres.OrderRepository, tracer trace.Tracer) OrderRepository {
	return tracestorage.NewDecorator(repo, tracer, "order-repository-tracer")
}

// =============================================================================
// Step 6: Bus registration — middleware first, public MustRegister
// =============================================================================

// mustInitCommandBus creates a command bus with OTEL middleware attached.
// NOTE: OTEL middleware must be attached BEFORE registering handlers.
func mustInitCommandBus(tracer trace.Tracer) *agenticcommand.Bus {
	bus := agenticcommand.New()
	bus.Use(otelcommand.NewMiddleware(tracer))
	return bus
}

// mustInitQueryBus creates a query bus with OTEL middleware attached.
func mustInitQueryBus(tracer trace.Tracer) *agenticquery.Bus {
	bus := agenticquery.New()
	bus.Use(otelquery.NewMiddleware(tracer))
	return bus
}

// MustRegisterOrderCommands registers order command handlers.
// NOTE: Accepts domain interface, not *postgres.OrderRepository.
func MustRegisterOrderCommands(bus *agenticcommand.Bus, repo OrderRepository) {
	handler := cmdorder.NewCreateHandler(repo)
	agenticcommand.MustRegister(bus, "order.create", handler)
}

// MustRegisterOrderQueries registers order query handlers.
func MustRegisterOrderQueries(bus *agenticquery.Bus, repo OrderRepository) {
	// handler setup...
}

// =============================================================================
// Step 7: start* functions — accept commonProviders, launch in goroutine
// =============================================================================

func startHTTPServer(addr string, providers commonProviders, cmdBus *agenticcommand.Bus, queryBus *agenticquery.Bus) {
	mux := http.NewServeMux()
	// Register routes using the buses...

	server := &http.Server{Addr: addr, Handler: mux}

	go func() {
		providers.logger.Info().Str("addr", addr).Msg("starting http server")
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			providers.logger.Error().Err(err).Msg("http server failed")
		}
	}()
}

// =============================================================================
// Placeholder types for compilation sanity
// =============================================================================

type {MODULE}Config struct {
	ServiceName string
	PostgresConfig
	HTTPPort string
}

type PostgresConfig struct {
	ConnString func() string
}

type domain struct{}

func main() {}