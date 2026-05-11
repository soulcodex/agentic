## Hono API (TypeScript)

### Controller Structure

- Define HTTP controllers as classes, not free-floating route functions.
- One controller class per bounded context/resource (`UsersController`, `BillingController`).
- Controller constructors receive application-layer ports/use cases only; no direct repository or SDK wiring.
- Expose a semantic `register(app: Hono)` method that registers routes/middleware on a provided app instance.

```ts
export class UsersController {
  constructor(private readonly getUser: GetUserUseCase) {}

  register(app: Hono): void {
    app.get("/:userId", this.getById)
  }

  private getById = async (c: Context) => { ... }
}
```

### Semantic Registration

- `register()` methods must be intent-revealing (`registerPublicRoutes(app)`, `registerAdminRoutes(app)`) when a controller exposes multiple route families.
- Route registration order and middleware composition are owned by the composition root, not scattered across bootstrap files.
- Bootstrap/composition root owns app instantiation and mounts controller registrations; it does not define business endpoints inline.

### Middleware Dependency Injection

- Middleware that depends on external resources (Redis, config, clients, feature flags) must be
  created in the composition root and injected into controllers as ready handlers or factories.
- Controllers may compose middleware, but must never initialize infrastructure clients directly.
- Keep cross-cutting middleware order (auth, request ID, tracing, global rate-limit) in bootstrap;
  keep resource-specific middleware registration inside the controller.

### Params and Input Contracts

- Parse and validate `param`, `query`, `header`, and `json` values at the controller boundary with explicit schemas.
- Never pass raw `c.req.param()` or untyped payload objects into application/domain code.
- Convert transport primitives into command/query objects before invoking use cases.
- Keep parameter names semantic and domain-aligned (`orderId`, `tenantId`, `invoiceNumber`) over generic names (`id`, `value`).

### Error Mapping

- Controllers map domain/application errors to HTTP responses in one place (error mapper/presenter).
- Use domain-specific error classes and type guards for branching; avoid string matching on message text.
- Unknown/unexpected errors return a generic 500 payload while structured logs keep stack traces and context.

### Testing

- Unit-test controllers at the HTTP boundary with injected use-case doubles and real request/response assertions.
- Verify: param parsing, schema validation failures, domain error to HTTP status mapping, and success serialization.
- Keep domain tests framework-agnostic; Hono tests should not be required to validate domain invariants.
