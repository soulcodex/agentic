## CQRS (Command Query Responsibility Segregation)

CQRS separates the **write model** (commands that change state) from the **read model** (queries
that return data). This allows each model to be optimized independently.

### Commands

A command expresses **intent to change state**. It is named in the imperative:
`PlaceOrder`, `TransferFunds`, `VerifyEmail`.

- Commands carry the data needed to perform the operation — no more.
- Commands are validated before being dispatched.
- A command has exactly one handler.
- A command handler:
  1. Loads the aggregate from the repository.
  2. Calls the aggregate method.
  3. Persists the aggregate.
  4. (Optionally) publishes domain events.
- Command handlers return nothing (void) or a minimal result (created ID). They do not return
  read-model data.

```typescript
// Command
class PlaceOrderCommand {
  constructor(
    readonly customerId: CustomerId,
    readonly items: OrderItemDto[],
  ) {}
}

// Handler
class PlaceOrderHandler {
  async handle(cmd: PlaceOrderCommand): Promise<OrderId> {
    const order = Order.place(cmd.customerId, cmd.items)
    await this.orderRepository.save(order)
    await this.eventPublisher.publishAll(order.pullDomainEvents())
    return order.id
  }
}
```

### Queries

A query **reads state without changing it**. It is named as a question:
`GetOrderById`, `ListUserOrders`, `FindActiveProducts`.

- Queries are handled by a query handler that reads from a read model (may be a different
  datastore, a denormalized view, or a cache).
- Query handlers return DTOs or view models — never domain entities.
- Queries do not go through the domain layer. They may query the database directly for
  performance.

```typescript
class GetOrderByIdQuery {
  constructor(readonly orderId: OrderId) {}
}

class GetOrderByIdHandler {
  async handle(query: GetOrderByIdQuery): Promise<OrderViewDto | null> {
    return this.orderReadRepository.findById(query.orderId)
  }
}
```

### Message Bus / Dispatcher

Use a command/query bus to decouple callers from handlers:
- `commandBus.dispatch(new PlaceOrderCommand(...))` — finds the handler and executes it.
- `queryBus.ask(new GetOrderByIdQuery(...))` — finds the handler and returns the result.

The bus also provides a hook point for middleware: logging, validation, transactions, metrics.

### Read Model

- The read model is optimized for querying, not for domain integrity.
- It may be a denormalized SQL view, a separate table updated by event handlers, Redis, or
  Elasticsearch.
- The read model is rebuilt by projecting domain events — never by directly coupling to
  the write model's schema.
- A stale read model is acceptable. The write model is the source of truth.

### Contract & Schema Parity

Every command or query that crosses a service boundary must have a versioned,
machine-readable contract:

- **Commands that enter via HTTP/gRPC/message queue** must have a corresponding request schema
  (OpenAPI, Protobuf, JSON Schema). The schema is the single source of truth — generated code
  is derived from it, not the reverse.
- **Query responses that cross service boundaries** must have a versioned response schema.
  Query handlers return DTOs whose shape is governed by the contract.
- Validate generated artifacts (e.g., `oapi-codegen`, `protoc`, `spectral lint`) before
  shipping. Document the generation command in the project's README or `Makefile`/`justfile`
  so any contributor can reproduce it.
- **Schema drift is a breaking change**: removing or renaming a field in a command or query
  DTO that is part of a published contract requires a migration plan (version the route or
  message type, run old and new in parallel, retire old after consumers migrate).
- Stale contracts are worse than no contracts. Update the schema in the same commit as the
  handler change — never after.

### File Layout

```
src/application/
├── command/
│   ├── place-order/
│   │   ├── place-order.command.ts
│   │   └── place-order.handler.ts
│   └── transfer-funds/
│       ├── transfer-funds.command.ts
│       └── transfer-funds.handler.ts
└── query/
    ├── get-order-by-id/
    │   ├── get-order-by-id.query.ts
    │   ├── get-order-by-id.handler.ts
    │   └── order-view.dto.ts
    └── list-user-orders/
        ├── list-user-orders.query.ts
        ├── list-user-orders.handler.ts
        └── order-summary.dto.ts
```
