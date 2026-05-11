## Hono API (TypeScript)

### Controller Structure

- Define HTTP controllers as classes, not free-floating route functions.
- One controller class per bounded context/resource (`UsersController`, `BillingController`).
- Controller constructors receive application-layer ports/use cases only; no direct repository or SDK wiring.
- Expose a semantic `build()` method that returns the configured route subtree and middleware stack.

```ts
export class UsersController {
  constructor(private readonly getUser: GetUserUseCase) {}

  build(): Hono {
    const app = new Hono()
    app.get("/:userId", this.getById)
    return app
  }

  private getById = async (c: Context) => { ... }
}
```

### Semantic Builders

- `build()` methods must be intent-revealing (`buildPublicRoutes()`, `buildAdminRoutes()`) when a controller exposes multiple route families.
- Route registration order and middleware composition are owned by the controller builder, not scattered across bootstrap files.
- Bootstrap/composition root mounts prebuilt controller route trees; it does not define business endpoints inline.

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
