# Architecture Code Review Checklist

Applies when hexagonal, DDD, CQRS, or microservices patterns are detected.
Extends the generic checklist. Apply every item to architectural concerns.

## Hexagonal / Clean Architecture

- [ ] `domain/` package has zero imports from `infrastructure/`, `ports/`, or any framework package
  *Ref: [Hexagonal Architecture — Alistair Cockburn, 2005](https://alistair.cockburn.us/hexagonal-architecture/)*
- [ ] No framework annotations (`@ORM`, `@Column`, `@ApiProperty`, `json:"..."` struct tags with DB semantics) inside domain types
- [ ] Concrete adapters (DB repos, HTTP clients) constructed only at the composition root — not instantiated mid-layer
  *Ref: [Dependency Inversion Principle — Robert C. Martin](https://web.archive.org/web/20110714224327/http://www.objectmentor.com/resources/articles/dip.pdf)*
- [ ] Ports (interfaces) return domain types, not infrastructure types (no Doctrine entities, no `*sql.Row`, no HTTP response objects through a port)
- [ ] No circular package/module dependencies
- [ ] Application-layer errors are infrastructure-agnostic (`ErrNotFound`, `ErrPermissionDenied` — not DB-driver errors)
- [ ] Driving adapters (HTTP controllers, CLI commands) call application layer through a port interface — never directly instantiate domain objects

## Domain-Driven Design

- [ ] No anemic domain model: entities have behavior methods, not only getters/setters
  *Ref: [AnemicDomainModel — Martin Fowler](https://martinfowler.com/bliki/AnemicDomainModel.html)*
- [ ] No God Aggregate: aggregate root does not reference many other aggregates by value or span multiple bounded contexts
  *Ref: [DDD Reference — Eric Evans, 2014](https://www.domainlanguage.com/ddd/reference/); [DDD Aggregate — Martin Fowler](https://martinfowler.com/bliki/DDD_Aggregate.html)*
- [ ] Repositories defined only for aggregate roots, not for child entities
  *Ref: [DDD Reference — Eric Evans, 2014](https://www.domainlanguage.com/ddd/reference/)*
- [ ] No primitive obsession: domain IDs are typed value objects (`UserId`, `OrderId`), not raw primitives
  *Ref: [Refactoring — Replace Primitive with Object, Martin Fowler](https://refactoring.com/catalog/replacePrimitiveWithObject.html)*
- [ ] Domain events named in past tense (`OrderPlaced`, `UserEmailVerified`, `PaymentFailed`)
  *Ref: [Domain Events — Martin Fowler](https://martinfowler.com/eaaDev/DomainEvent.html)*
- [ ] No cross-context direct import: bounded contexts communicate via domain events or ACL, not shared domain models
  *Ref: [DDD — Bounded Context, Eric Evans, 2003, ch. 14](https://www.domainlanguage.com/ddd/reference/)*
- [ ] Authorization is handled in the application layer (command/query handlers, middleware, policy services) — not inside aggregate methods or domain services, unless: (a) authorization *is* the core business domain (e.g. an IAM or permission-management service), or (b) the team has made an explicit, documented architectural trade-off to encode access rules inside the domain
  *Ref: [Domain-Driven Design — Eric Evans, 2003, ch. 4 — Isolating the Domain](https://www.domainlanguage.com/ddd/reference/); [Hexagonal Architecture — Alistair Cockburn, 2005](https://alistair.cockburn.us/hexagonal-architecture/)*
- [ ] Domain objects not leaked to transport or persistence adapters — `ToPrimitives`/`FromPrimitives` mappers used

## CQRS

- [ ] Command handlers return void or a minimal result (created ID) — never a read-model DTO
  *Ref: [CQRS — Martin Fowler](https://martinfowler.com/bliki/CQRS.html)*
- [ ] Query handlers do not mutate state
- [ ] Commands from external systems (HTTP, queue) have idempotency key handling
  *Ref: [Making retries safe with idempotent APIs — AWS Builders Library](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/)*
- [ ] Schema for commands/queries updated in the same commit as the handler change (no schema drift)
  *Ref: [CQRS — Martin Fowler](https://martinfowler.com/bliki/CQRS.html)*
- [ ] One command/query type maps to exactly one handler registration

## Microservices

- [ ] No two services share a database schema or table
  *Ref: [Building Microservices, Sam Newman, 2nd Ed., ch. 4](https://samnewman.io/books/building_microservices_2nd_edition/)*
- [ ] Every external service call has an explicit timeout set
  *Ref: [Timeout pattern — Microsoft Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/patterns/)*
- [ ] Circuit breaker implemented for calls to downstream services
  *Ref: [Circuit Breaker — Martin Fowler](https://martinfowler.com/bliki/CircuitBreaker.html)*
- [ ] Async message consumers are idempotent (processing the same message twice has no incorrect side effect)
  *Ref: [Transactional Outbox pattern — microservices.io](https://microservices.io/patterns/data/transactional-outbox.html)*
- [ ] Outbox pattern or equivalent used when reliable event publishing alongside DB writes is needed
  *Ref: [Transactional Outbox — microservices.io](https://microservices.io/patterns/data/transactional-outbox.html)*
- [ ] Services independently deployable without coordinating deploys with other services