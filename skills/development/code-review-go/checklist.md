# Go Code Review Checklist

Extends the generic checklist. Apply every item to Go-specific concerns.

## Goroutine Lifecycle

- [ ] Every goroutine has a clear creator, a clear waiter, and a clear exit path
  *Ref: [Go Concurrency Patterns — Rob Pike, Google I/O 2012](https://go.dev/blog/pipelines); [Concurrency is not Parallelism](https://go.dev/blog/waza-talk)*
- [ ] No unbounded goroutine spawning in loops without a semaphore or worker pool
  *Ref: [Go Blog — Pipelines and cancellation](https://go.dev/blog/pipelines)*
- [ ] `WaitGroup.Add()` called before goroutine start, never inside the goroutine
  *Ref: [sync.WaitGroup docs](https://pkg.go.dev/sync#WaitGroup)*
- [ ] `defer cancel()` called immediately after every `context.WithCancel` / `context.WithTimeout` / `context.WithDeadline`
  *Ref: [context package docs](https://pkg.go.dev/context)*

## Data Races and Shared State

- [ ] Concurrent map access protected by `sync.RWMutex` or replaced with `sync.Map`
  *Ref: [Go Memory Model](https://go.dev/ref/mem); [Go Data Race Detector](https://go.dev/doc/articles/race_detector)*
- [ ] No channel send/receive without a clear protocol preventing deadlock
  *Ref: [Effective Go — Channels](https://go.dev/doc/effective_go#channels)*
- [ ] `select` in hot paths has a `default` or `ctx.Done()` case to avoid indefinite blocking
- [ ] Shared slices/maps not mutated concurrently from multiple goroutines

## Error Handling

- [ ] Errors wrapped with `fmt.Errorf("context: %w", err)` at every call site boundary
  *Ref: [Go 1.13 Errors — Go Blog](https://go.dev/blog/go1.13-errors)*
- [ ] No error silently ignored with `_` unless the type is documented as never-failing
- [ ] Sentinel errors defined with `errors.New` for expected caller-handled conditions
  *Ref: [errors package](https://pkg.go.dev/errors)*
- [ ] Custom domain error types implement `error` and have `IsXxxError(err) bool` helpers

## Domain Modeling

- [ ] No primitive obsession: domain IDs use typed value objects, not raw `string`/`int`/`uuid.UUID`
  *Ref: [Refactoring — Replace Primitive with Object, Martin Fowler](https://refactoring.com/catalog/replacePrimitiveWithObject.html)*
- [ ] Domain types not exported with ORM, HTTP, or infrastructure fields attached
- [ ] Aggregate state transitions happen through intentful methods, not field mutation

## Package and Interface Design

- [ ] Interfaces defined in the package that *uses* them, not the package that *implements* them
  *Ref: [Effective Go — Interfaces](https://go.dev/doc/effective_go#interfaces)*
- [ ] Interface size ≤ 3 methods; larger interfaces composed from smaller ones
  *Ref: [Go Proverbs — Rob Pike](https://go-proverbs.github.io/)*
- [ ] No circular package imports
  *Ref: [Go specification — Import declarations](https://go.dev/ref/spec#Import_declarations)*
- [ ] `domain/` package has zero imports from `infrastructure/`, `ports/`, or framework packages

## Code Style and Correctness

- [ ] No `init()` functions with I/O, network calls, or panic-prone logic
  *Ref: [Uber Go Style Guide — Avoid init()](https://github.com/uber-go/guide/blob/master/style.md#avoid-init)*
- [ ] `context.Context` passed as first parameter to every function that needs it
  *Ref: [Contexts and structs — Go Blog](https://go.dev/blog/context-and-structs)*
- [ ] No naked returns in functions longer than 5 lines
  *Ref: [Effective Go — Named result parameters](https://go.dev/doc/effective_go#named-results)*
- [ ] Table-driven tests used where cases vary only in input/output
  *Ref: [Go testing package](https://pkg.go.dev/testing)*
- [ ] `-race` flag used in CI test runs
  *Ref: [Go Data Race Detector](https://go.dev/doc/articles/race_detector)*