## Effect CLI (TypeScript)

### Command Modeling

- Model each command as a dedicated module/class with a single responsibility.
- Keep command handlers thin: parse inputs, call application use cases, render output.
- Domain logic and business policies belong in domain/application layers, never inside CLI handlers.

### Ports and Adapters Wiring

- `@effect/cli` and `@effect/platform-node` are driving adapters around the application core.
- Define ports/interfaces in domain/application for outbound dependencies (filesystem, HTTP, process, clock).
- Implement those ports in infrastructure adapters using Effect services/layers.
- Perform layer assembly in the composition root only (`main.ts` or equivalent), not in command modules.

### Input and Validation

- Parse and validate command options/arguments once at the edge.
- Map validated CLI inputs into semantic command/query DTOs before invoking use cases.
- Keep option names explicit and stable; treat them as a public contract.

### Error Handling

- Prefer domain-specific error types over generic `Error` values.
- Translate typed domain/application errors into user-facing messages and exit codes in one error presenter.
- Unexpected defects should be logged with context and surfaced as a generic failure message.

### Testing

- Test command modules by exercising parsing, validation, and output rendering with mocked ports.
- Test application/domain logic independently from `@effect/cli` runtime concerns.
- Include tests for typed error mapping to exit code and user-facing output.
