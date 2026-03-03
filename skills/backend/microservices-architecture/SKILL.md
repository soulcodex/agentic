---
name: microservices-architecture
description: >
  Guides service boundary analysis, communication pattern selection, data
  consistency design, API contract strategy, and resilience checklist for
  microservices systems. Complements the microservices fragment. Invoked when
  the user asks to design a microservices system, split a monolith, or review
  service boundaries.
version: 1.0.0
tags:
  - backend
  - microservices
  - architecture
  - design
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Microservices Architecture Skill

> This skill complements (does not replace) the `microservices.md` fragment.
> Load the fragment for general principles; use this skill for design decisions.

### Step 1 — Service Boundary Analysis

Use **Domain-Driven Design bounded contexts** to identify service boundaries:

1. List the core business domains (e.g., Orders, Inventory, Payments, Notifications).
2. For each domain, identify:
   - The **aggregate root** (the entity other entities reference through).
   - The **invariants** that must hold within the domain.
   - The **external events** the domain publishes when its state changes.
3. A service boundary aligns with a bounded context. Services should **not share a database**.

Red flags for a bad boundary:
- Two services always change together → consider merging them.
- A service has no domain logic (only CRUD) → it may not need to be a separate service.
- A service synchronously calls another service on every request → tight coupling.

### Step 2 — Communication Pattern Decision

For each service-to-service interaction, choose:

| Scenario | Pattern | Trade-off |
|----------|---------|-----------|
| Read-your-own-writes, low latency | Synchronous REST/gRPC | Temporal coupling; caller waits |
| Background processing, at-least-once | Async messaging (SQS, RabbitMQ) | Eventual consistency; harder to debug |
| Event fan-out (multiple consumers) | Pub/sub (EventBridge, Kafka) | Loose coupling; no direct contract |
| Streaming / time-series data | Kafka / Kinesis | High throughput; complex ops |

Rule: prefer **async messaging** for writes across service boundaries. Use sync calls
only for reads where the caller genuinely needs the response before proceeding.

### Step 3 — Data Consistency Design

You cannot have distributed transactions without accepting trade-offs. Choose:

**Saga (choreography or orchestration)**:
- Each service publishes an event after its local transaction commits.
- On failure, compensating transactions undo previous steps.
- Use the **outbox pattern** to guarantee event publication.

**Outbox pattern**:
```sql
-- In the same DB transaction as the domain change:
INSERT INTO outbox_events (id, topic, payload) VALUES (:id, 'order.placed', :payload);
-- Background worker polls and publishes to the message broker.
```

**Read models / projections**:
- Services maintain their own read-optimised data (CQRS).
- Accept that read models are eventually consistent with the write side.

### Step 4 — API Contract Design

- **Contract-first**: define the API (OpenAPI or Protobuf) before writing implementation.
- **Consumer-driven contract tests**: use Pact or similar to verify producers meet
  consumer expectations automatically in CI.
- **Versioning**: version breaking changes with URL path (`/v2/`) or content negotiation.
  Additive changes (new optional fields) are non-breaking.
- **Avoid shared libraries for domain types**: sharing a domain model library creates
  coupling. Share only transport types (DTOs), not domain objects.

### Step 5 — Resilience Checklist

Apply the following to **every synchronous service-to-service call**:

| Pattern | Configuration | Purpose |
|---------|-------------|---------|
| Timeout | 1–5 s (context-appropriate) | Bound failure time |
| Retry | 2–3 retries, exponential backoff | Recover from transient faults |
| Circuit breaker | Open after 5 failures in 10 s; probe after 30 s | Stop calling a failing service |
| Bulkhead | Separate thread pool or semaphore per upstream | Isolate failures |
| Fallback | Return cached/default value | Degrade gracefully |

Use a resilience library: `resilience4j` (JVM), `failsafe` (Go), `cockatiel` (TypeScript).

### Step 6 — Service Mesh Consideration

Consider a service mesh (Istio, Linkerd) when:
- You have > 10 services and managing retry/timeout/mTLS per service is becoming complex.
- You need zero-trust networking between services.
- You need fine-grained traffic splitting for canary deployments.

Do **not** add a service mesh prematurely — it adds significant operational complexity.

### Output: ADR-Style Summary

Produce a decision record for each major architecture choice:

```markdown
## ADR-001: Order Service communicates with Inventory via async messaging

**Status**: Accepted

**Context**: Order placement must decrement inventory. Inventory updates can take
up to 200 ms; we cannot block the order API response on this.

**Decision**: Order service publishes `order.placed` event to SQS. Inventory
service consumes the queue and decrements stock asynchronously.

**Trade-offs**: Orders may briefly oversell (resolved by reservation before publish).
Inventory is eventually consistent with orders.

**Consequences**: Order service requires an outbox table. Inventory service must
handle duplicate events (idempotency key = order_id).
```
