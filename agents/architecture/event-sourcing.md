## Event Sourcing

In event sourcing, the state of an aggregate is derived by **replaying its history of
domain events**, rather than storing a snapshot of current state. The event log is the
source of truth.

### Core Concepts

**Event**: An immutable, past-tense record of something that happened.
- `OrderPlaced`, `ItemAddedToCart`, `PaymentSucceeded`, `OrderCancelled`
- Events carry all data needed to reconstruct state.
- Events are never deleted or modified.

**Event Store**: An append-only log of events, indexed by aggregate ID and sequence number.
- `EventStore.append(aggregateId, events, expectedVersion)` — optimistic concurrency via version.
- `EventStore.load(aggregateId)` — returns all events for an aggregate in order.

**Aggregate Reconstruction**:
```typescript
const events = await eventStore.load(orderId)
const order = Order.reconstitute(events)  // replay all events to rebuild state
```

**Snapshot**: A performance optimization — a point-in-time snapshot of state stored alongside
events. Load the latest snapshot + only events after the snapshot version.

### Aggregate Design

```typescript
class Order {
  private id: OrderId
  private items: OrderItem[] = []
  private status: OrderStatus

  // Private: events applied during reconstitution (no side effects)
  private apply(event: DomainEvent): void {
    switch (event.type) {
      case 'OrderPlaced':   this.applyOrderPlaced(event); break
      case 'ItemAdded':     this.applyItemAdded(event);   break
      case 'OrderCancelled': this.status = OrderStatus.Cancelled; break
    }
  }

  // Public: domain command methods (raise events, then apply)
  place(customerId: CustomerId, items: OrderItemDto[]): void {
    this.raise(new OrderPlaced({ customerId, items, placedAt: new Date() }))
  }

  private raise(event: DomainEvent): void {
    this.apply(event)
    this.uncommittedEvents.push(event)
  }

  static reconstitute(events: DomainEvent[]): Order {
    const order = new Order()
    events.forEach(e => order.apply(e))
    return order
  }
}
```

### Projections

Projections (read models) are built by subscribing to the event stream and updating a
denormalized view:
- `OrderProjection` listens for `OrderPlaced`, `ItemAdded`, `OrderCancelled` and updates a
  SQL table optimized for listing.
- Projections are rebuild-able by replaying all events from the beginning.
- A broken projection does not lose data — replay to fix it.

### Idempotency

Event handlers and projection updates must be idempotent:
- Track processed event IDs to prevent double-processing.
- Use database transactions to atomically update the projection and mark the event as processed.

### Concurrency Safety

Optimistic concurrency in the event store (version checks) is necessary but not sufficient:

- **Test under race conditions**: append and projection-update paths must be exercised with
  a race-condition detector (e.g., Go's `-race` flag, ThreadSanitizer, or equivalent). A
  passing test suite without race detection does not qualify as validation for event-sourced
  aggregates.
- Use atomic database transactions to update a projection and mark its checkpoint in a single
  operation — never two separate writes. A crash between them causes double-processing or
  silent data loss.
- Competing consumers reading the same stream partition must use optimistic locking or
  upsert semantics; assume concurrent execution is the default, not the exception.

### Event Schema as a Public Contract

Events that cross service boundaries (published to a broker or event store consumed by
external systems) are public contracts — treat them with the same discipline as API schemas:

- **Define a versioned schema** (JSON Schema, Protobuf, Avro) for every published event type.
  The schema is the source of truth; generated serialization code is derived from it.
- **Breaking changes require a migration plan**: add a `v2` event type, run both versions in
  parallel until all consumers have migrated, then retire `v1`. Never silently change the
  shape of an existing event type.
- **Internal events** (never leaving the service boundary) are lower risk, but still benefit
  from schema definitions — they become external the moment a second consumer appears.

### When to Use Event Sourcing

Good fit:
- Audit trail is a hard requirement (financial, medical, legal domains).
- Temporal queries ("what was the state of X on date Y?") are needed.
- Complex aggregate history is business-critical.

Poor fit:
- Simple CRUD with no meaningful history.
- Reporting-heavy workloads (projections add complexity for simple reporting).
- Team unfamiliar with the pattern (high learning curve — start with CQRS without ES first).
