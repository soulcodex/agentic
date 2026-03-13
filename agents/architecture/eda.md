## Event-Driven Architecture

EDA decouples services through asynchronous event exchange. Producers publish events to a
broker; consumers subscribe independently. This fragment covers inter-service communication
via events — for event sourcing as a persistence strategy, see `event-sourcing.md`.

### Event Design

- Name events in the **past tense**: `OrderPlaced`, `PaymentFailed`, `UserDeactivated`.
  An event is a fact — something that already happened.
- Keep payloads **minimal**: carry only the data that consumers need. Avoid embedding full
  aggregates; prefer IDs and key attributes. Consumers who need more can query the producing
  service.
- Every event must carry an **envelope** of metadata:
  ```json
  {
    "id": "uuid-v7",
    "type": "order.placed",
    "source": "order-service",
    "timestamp": "2024-01-15T10:30:00Z",
    "correlation_id": "trace-id-propagated-from-request",
    "payload": { "order_id": "…", "amount": 99.00 }
  }
  ```
- Event schemas are a **public contract** — evolve them carefully (see Schema Evolution).

### Message Broker Selection

| Broker | Best for | Trade-offs |
|---|---|---|
| **Kafka** | High throughput, ordered streams, event replay, audit log | Operationally heavier; consumer offset management |
| **RabbitMQ** | Complex routing (topic/fanout/headers), low-latency RPC-style messaging | No native replay; messages deleted on ack |
| **SQS** (AWS) | AWS-native simplicity, at-least-once delivery, auto-scaling consumers | No ordering guarantee (except FIFO queues); no replay |

Choose based on throughput requirements, replay needs, routing complexity, and team
familiarity — not trend. A monolith that deploys to AWS rarely needs Kafka.

### Consumer Patterns

**Idempotency:**
- Brokers guarantee *at-least-once* delivery; consumers must handle duplicate events.
- Track processed event IDs in a `processed_events` table (or Redis SET) and skip
  re-processing events already seen.
- Use database transactions to atomically mark an event as processed and apply its effect.

**At-least-once delivery:**
- Acknowledge (ack) an event only after the side effect has been durably committed.
- Do not ack before writing to the database — a crash between ack and write loses the event.
- Distinguish transient errors (retry) from poison pills (dead-letter queue).

**Competing consumers:**
- Multiple instances of the same consumer share a consumer group; the broker distributes
  partitions/messages across them for horizontal scaling.
- Ensure shared state updates (database writes, cache invalidation) are safe under concurrent
  consumption — use optimistic locking or upsert semantics.

### Choreography vs Orchestration

**Choreography:** each service reacts to events and emits its own; no central controller.
- Pros: low coupling, services evolve independently, no single point of failure.
- Cons: flow is implicit and hard to trace; debugging a multi-step process requires
  correlating logs across services.
- Use when: simple, branching, or truly independent side effects.

**Orchestration:** a dedicated orchestrator (workflow engine or saga coordinator) explicitly
calls services and tracks the overall flow state.
- Pros: flow is explicit and auditable in one place; error handling is centralized.
- Cons: the orchestrator becomes a coupling point; must be designed for durability.
- Use when: multi-step workflows with complex compensation logic, strict ordering guarantees,
  or audit requirements.

Avoid **distributed god-orchestrators** that call every service — this recreates a monolith's
coupling without its transactional safety. Decompose long workflows into smaller, cohesive sagas.

### Saga Pattern

A saga coordinates a multi-step workflow across services using a sequence of local
transactions and compensating transactions on failure.

- Each step emits an event on success; the next step listens for it.
- On failure, compensating events trigger rollback actions in reverse order
  (e.g., `ReservationCancelled` → `InventoryReleased` → `PaymentRefunded`).
- Compensating transactions must themselves be idempotent.
- Use a saga state machine (or a workflow engine like Temporal) to persist saga state
  durably — do not keep saga state only in memory.

### Dead Letter Queues

- Route events that fail processing after N retries to a DLQ rather than discarding them.
- A DLQ entry is a bug signal — alert on non-zero DLQ depth.
- Provide a replay mechanism: once the bug is fixed, messages can be moved from the DLQ
  back to the main queue for re-processing.
- Log the original event, the error, and the retry count when moving to a DLQ.
- Do not route DLQ events to a generic alerting channel — each consumer should have its
  own DLQ monitored by the owning team.

### Schema Evolution

Event schemas are public contracts; breaking changes break consumers without warning.

**Backwards-compatible changes (allowed):**
- Add a new optional field.
- Widen a type (e.g., `int32` → `int64`).

**Breaking changes (forbidden without a migration plan):**
- Remove or rename a field.
- Change a field's type incompatibly.
- Change the semantics of an existing field.

- Use a **schema registry** (Confluent Schema Registry, AWS Glue, Apicurio) to validate
  producer and consumer schema compatibility at publish time.
- Version event types when a breaking change is unavoidable: `order.placed.v2`. Run both
  versions in parallel until all consumers have migrated, then retire v1.

### Observability

- Propagate the **correlation ID** from the originating request through every event envelope
  and into every downstream log and span. This is the single most important observability
  practice in EDA.
- Use **distributed tracing** (OpenTelemetry) to link producer and consumer spans across
  service boundaries via the event envelope.
- Monitor **consumer lag** (Kafka: consumer group lag; SQS: `ApproximateNumberOfMessagesNotVisible`).
  Lag growth signals a processing bottleneck or consumer failure.
- Emit a metric for **processing duration** per event type and **error rate** per consumer.
- Log the event `id`, `type`, and `correlation_id` at the start and end of every consumer
  handler — never lose the ability to trace an event through the system.

### Dependency & Local Parity

- Only adopt a message broker or external event store if it **publishes a Docker image**
  (official or community). This ensures integration tests can spin up the dependency
  deterministically without mocks and without relying on shared/remote environments.
- For SaaS brokers that lack a Docker image, build a lightweight stub/mock container and
  treat it as the canonical local and CI target.
- Document broker startup, teardown, and any required seeding in the project's compose file
  and README so any contributor can reproduce a full local environment with a single command.

### Intentional Planning Before Implementation

Before writing any producer or consumer, capture and communicate:

1. **Which events are produced and consumed** — name them explicitly in past tense.
2. **Which bounded contexts or services are affected** — map ownership of each event type.
3. **Correlation and tracing strategy** — how will `correlation_id` flow from the originating
   request through every downstream handler?
4. **Failure and retry contract** — what is the retry policy, DLQ owner, and replay mechanism?

Skipping this step leads to undocumented event flows that are expensive to debug and nearly
impossible to hand off to other agents or team members.

### Document Flows When They Change

When event flows, choreography boundaries, consumer ownership, or schema contracts change:

- Update the relevant architecture diagrams or flow documentation in the same PR.
- Update the schema registry or contract files alongside the code change.
- Stale EDA documentation is the most dangerous kind of drift: a consumer reading an outdated
  flow diagram may silently process events incorrectly.
