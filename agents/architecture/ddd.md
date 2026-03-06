## Domain-Driven Design (DDD)

### Core Building Blocks

**Entity**: An object defined by its identity, not its attributes. Two entities with the same
attributes but different IDs are different entities.
- Always accessed and modified through the aggregate root.
- IDs are typed value objects, not raw primitives: `UserId`, not `string`.

**Value Object**: An object defined by its attributes, with no identity. Immutable.
- Equality is structural (all attributes equal = same value).
- Contains behavior related to what it represents: `Money.add()`, `Email.domain()`.
- Common examples: `Money`, `Email`, `Address`, `DateRange`, `Quantity`.

**Aggregate**: A cluster of entities and value objects treated as a single unit for data changes.
- Has one **aggregate root** — the only entry point for external code.
- Enforces all invariants within its boundary.
- Only root IDs may be referenced from outside the aggregate.
- Keep aggregates small. If an aggregate spans multiple database tables with many relations,
  it is likely too large.

**Domain Event**: Records something that happened in the domain. Immutable facts.
- Named in past tense: `OrderPlaced`, `UserEmailVerified`, `PaymentFailed`.
- Published by the aggregate root after a state change.
- Used to integrate between aggregates and bounded contexts.

**Repository**: Provides collection-like access to aggregates.
- Interface defined in `domain/`. Implementation in `infrastructure/`.
- Methods return domain objects, not ORM entities or raw rows.
- Never returns partial aggregates.

**Domain Service**: Encapsulates domain logic that does not belong to a single aggregate.
- Stateless.
- Operates on domain objects.
- Example: `TransferService` that coordinates two `Account` aggregates.

### Bounded Contexts

A bounded context defines the boundary within which a domain model applies.
- Each bounded context has its own ubiquitous language. The same word may mean different things
  in different contexts (`Account` in `Billing` vs `Account` in `IAM`).
- Bounded contexts communicate via published events or explicit anti-corruption layers (ACL),
  never by sharing a database or domain model.

### Ubiquitous Language

- Code (class names, method names, variable names) must use the exact words from the domain
  language agreed with domain experts.
- If a domain expert would not recognize a term in your code, rename it.
- Maintain a glossary in `docs/ubiquitous-language.md`.

### Invariants and Validation

- Invariants belong in the aggregate, enforced in the constructor and command methods.
- An aggregate must never be in an invalid state.
- Throw domain exceptions (`OrderAlreadyShippedException`) when invariants are violated — never
  return error codes from domain methods.
- Input validation (format, required fields) happens at the boundary (controller/handler),
  not in the domain.

### Pre-Modeling Checklist

Answer these questions **before** writing any model, aggregate, or handler. Capture the
answers in the PR description or a short design note so the reasoning stays discoverable.

1. **Context ownership** — which bounded context owns this change? Where do the invariants
   naturally live?
2. **Business capabilities** — which capabilities are affected? Sketch a one-paragraph
   use-case narrative referencing existing application services.
3. **Aggregate boundaries** — what are the aggregates, their invariants, and their consistency
   boundaries? Does the change require a new aggregate root or extend an existing one?
4. **Cross-context interactions** — are there cross-context collaborations? If so, can they be
   expressed via domain events or read models instead of synchronous imports? Prefer async
   event hand-offs over direct cross-context calls.
5. **Policy placement** — which policies belong to the domain layer (pure business rules) vs.
   the application layer (orchestration, authorization, validation)? Document the decision.

### Authorization Boundary

Authorization is a cross-cutting concern — keep it entirely out of the domain:

- Domain models must stay **ignorant of permissions and roles** so business invariants remain
  pure and independently testable.
- Define authorization interfaces and errors in an **infrastructure-agnostic shared package**
  (e.g., `pkg/authorization`) — never inside domain packages.
- Module-specific permissions and authorizers belong in the **application layer**; the domain
  layer never calls them.
- Concrete authorization adapters (e.g., OpenFGA, OPA, Casbin) live in infrastructure and
  implement the interfaces — never imported directly by application services.
- Permission-to-relation mappings are registered once at the **composition root** (wiring), not
  scattered across handlers.

### Shared Module Discipline

A shared/common module must stay lean:

- Limit it to truly cross-cutting primitives: base value objects, shared DTOs, error types, and
  cross-context interface definitions.
- If accepting a dependency would force the shared module to know about a specific bounded
  context, push the abstraction down to that context instead.
- Never place bounded-context business logic in a shared module to avoid duplication — duplication
  is preferable to the wrong coupling.

### Anti-Patterns to Avoid

- **Anemic Domain Model**: entities with only getters/setters and no behavior. Behavior belongs
  in the domain, not in service classes that manipulate data bags.
- **God Aggregate**: aggregates that reference many other aggregates by value (not ID) and span
  the whole domain. Breaks transactional boundaries.
- **Repository for every entity**: only aggregate roots have repositories. Child entities are
  accessed through the root.
- **Authorization in domain**: checking permissions inside aggregate methods or domain services
  couples business rules to infrastructure concerns and breaks testability.
- **Cross-context direct imports**: importing another bounded context's domain or infrastructure
  package directly. Use well-defined ports, shared DTOs, or domain events instead.
