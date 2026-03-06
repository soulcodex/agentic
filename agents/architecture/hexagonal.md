## Hexagonal Architecture

Hexagonal architecture (Ports & Adapters) organizes the application so that the **domain and
application core are completely isolated from external concerns** (databases, HTTP, message
queues, file systems).

### The Dependency Rule

All dependencies point **inward**. The domain never imports from infrastructure.

```
           ┌─────────────────────────────────────────┐
           │  Infrastructure / Adapters (outer ring)  │
           │  ┌───────────────────────────────────┐   │
           │  │  Application (use cases, handlers) │   │
           │  │  ┌───────────────────────────────┐ │   │
           │  │  │    Domain (entities, VOs,      │ │   │
           │  │  │    domain events, rules)       │ │   │
           │  │  └───────────────────────────────┘ │   │
           │  └───────────────────────────────────┘   │
           └─────────────────────────────────────────┘
```

### Ports

A **port** is an interface defined in the application or domain layer that describes a
capability the core needs. There are two kinds:

- **Driving ports** (primary): interfaces that external actors use to drive the application
  (e.g., `PlaceOrderUseCase`, `UserQueryService`).
- **Driven ports** (secondary): interfaces the application uses to reach external systems
  (e.g., `UserRepository`, `EmailSender`, `EventPublisher`).

Ports live in `domain/` or `application/`. They must not import from `infrastructure/`.

### Adapters

An **adapter** implements a port. There are two kinds matching the port kinds:

- **Driving adapters**: HTTP controllers, gRPC handlers, CLI commands, message consumers.
  They call the application through a driving port.
- **Driven adapters**: PostgreSQL repository implementations, SMTP email sender, Kafka publisher.
  They implement a driven port.

Adapters live in `infrastructure/` or `ports/`. They may import from `domain/` and
`application/` but never the reverse.

### Directory Layout

```
src/
├── domain/
│   ├── model/          # Entities, value objects
│   ├── event/          # Domain events
│   ├── exception/      # Domain exceptions
│   └── repository/     # Repository interfaces (ports)
├── application/
│   ├── command/        # Commands + handlers
│   ├── query/          # Queries + handlers
│   └── port/           # Secondary port interfaces (if not in domain)
├── infrastructure/
│   ├── persistence/    # Repository implementations
│   ├── messaging/      # Event publisher implementations
│   └── external/       # Third-party API clients
└── ports/
    ├── http/           # HTTP controllers/routes
    ├── cli/            # CLI commands
    └── consumer/       # Message queue consumers
```

### Rules

1. **No leaking**: domain types must not be HTTP types, ORM types, or DTO types.
   Map at the boundary.
2. **No framework in domain**: zero imports of HTTP, ORM, or messaging in `domain/`.
3. **Test the core without infrastructure**: use cases and domain logic must be testable
   with pure unit tests — no database, no HTTP, no time.
4. **One adapter per port per deployment**: a port may have multiple adapters (real + test stub),
   but a running application wires exactly one adapter per port.
5. **Wiring happens in exactly one place**: infrastructure components are only instantiated at
   the composition root (e.g., `main`, `cmd/wire`, `AppModule`). No other layer creates concrete
   adapters. This makes the dependency graph explicit and replaceable.
6. **No circular dependencies**: before introducing a new import, verify the dependency graph
   stays acyclic (tools: `madge`, `go mod graph`, `deptrac`, `import-cycles`). When the
   direction is unclear, prefer events or DTO hand-offs over direct calls.
7. **Package names express purpose, not implementation**: name packages by what they do
   (`authorization`, `messaging`, `storage`), not by the technology behind them (`openfga`,
   `kafka`, `postgres`). Place concrete implementations in subpackages named after the
   technology (`authorization/openfga`, `storage/postgres`). This keeps the application layer
   decoupled from infrastructure choices.
8. **Application-layer errors are infrastructure-agnostic**: define meaningful error types at
   the application boundary (e.g., `ErrNotFound`, `ErrPermissionDenied`). Never let
   infrastructure-specific errors (SQL errors, HTTP status codes, driver errors) leak upward
   through the port interface.
