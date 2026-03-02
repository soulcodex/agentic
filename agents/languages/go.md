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

### Interfaces

- Define interfaces in the package that *uses* them, not the package that *implements* them.
- Keep interfaces small (1-3 methods). Compose large behaviors from small interfaces.
- Accept interfaces, return concrete types (for most cases).

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
