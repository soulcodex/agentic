## Go

### Tooling

- Use the standard `go` toolchain. Always pin the Go version in `go.mod`.
- Format with `gofmt` (non-negotiable — run on save). Lint with `golangci-lint`.
- Run `go vet` in CI. It catches common mistakes the compiler misses.

### Error Handling

- Errors are values. Handle them explicitly at every call site:
  ```go
  result, err := doSomething()
  if err != nil {
      return fmt.Errorf("doSomething: %w", err)
  }
  ```
- Always wrap errors with context using `fmt.Errorf("context: %w", err)` so the call stack
  is reconstructable from the error message.
- Define sentinel errors with `errors.New` for expected conditions that callers must handle.
- Prefer custom domain error types over generic errors when modeling business failures.
- Add explicit `IsXxxError(err error) bool` helper functions per domain error to centralize `errors.Is`
  / `errors.As` checks and avoid duplicating matching logic at call sites.
- Use custom error types (implementing `error`) when callers need to inspect error properties.
- Never ignore errors. Use `_` only when the error is probably irrelevant (e.g., writing to
  an in-memory buffer that never fails).

### Naming Conventions

| Construct | Convention |
|---|---|
| Packages | short, lowercase, no underscores: `auth`, `orderstore` |
| Exported | PascalCase: `UserRepository`, `FindByID` |
| Unexported | camelCase: `parseToken`, `userCache` |
| Interfaces | noun or noun + `-er`: `Reader`, `UserStore` |
| Error types | `FooError` or `ErrFoo` (sentinel) |
| Test files | `*_test.go` |

### Package Structure

For hexagonal/clean architecture:
```
internal/
├── domain/          # Entities, value objects, domain errors, repository interfaces
├── application/     # Use cases / command handlers / query handlers
├── infrastructure/  # Repository implementations, HTTP adapters, gRPC adapters
└── ports/           # HTTP handlers, gRPC server, message consumers
cmd/
└── server/
    └── main.go      # Wiring only — no logic in main
```

Packages must not have circular dependencies. `domain` must not import `infrastructure`.

### Domain Modeling Conventions

- Model business primitives as typed value objects instead of raw primitives at domain boundaries.
- Keep aggregate fields private and expose behavior methods for state transitions.
- Use explicit snapshot/primitives mappers to cross application and adapter boundaries.
- Prefer small, explicit mapping code over generic reflection-based mappers.

### Interfaces

- Define interfaces in the package that *uses* them, not the package that *implements* them.
- Keep interfaces small (1-3 methods). Compose large behaviors from small interfaces.
- Accept interfaces, return concrete types (for most cases).
- Split reader/writer interfaces when read and write concerns differ.

### Concurrency

- Use channels to communicate between goroutines; don't share memory.
- Always handle goroutine lifecycle: know who creates it, who waits for it, and how it exits.
- Use `context.Context` for cancellation and deadlines. Pass it as the first parameter.
- Protect shared state with `sync.Mutex` when channels would be awkward. Prefer `sync.RWMutex`
  for read-heavy data.

### Code Style

- Keep functions short. If a function is hard to read end-to-end, split it.
- Avoid `init()` functions — they run in unpredictable order and are hard to test.
- Use table-driven tests for cases that vary only in input/output.
- Avoid global state. Pass dependencies explicitly.
- Keep authorization checks in application handlers/services, not in domain entities.
- For repository adapters, prefer explicit SQL/query builders when domain mapping rules are non-trivial.
