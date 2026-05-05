# Aggregate Modeling Checklist

## Context and Language

- [ ] Bounded context owner is explicit.
- [ ] Names reflect ubiquitous language (no generic placeholders).

## Aggregate Boundaries

- [ ] Exactly one aggregate root is the external entry point.
- [ ] Cross-aggregate references use root IDs only.
- [ ] Aggregate size is justified by consistency needs.

## Entity and Value Object Modeling

- [ ] Child entities are used only when identity matters.
- [ ] Value objects are immutable and validated at creation.
- [ ] String/number/range/enum constraints are encoded in value objects.

## Invariants and Behavior

- [ ] Invariants are enforced in factories/constructors and mutators.
- [ ] Root fields are private and changed via intentful behavior methods.
- [ ] Temporal ordering rules are deterministic for stale/replayed updates.
- [ ] Domain behavior is authorization-agnostic.

## Snapshots and Mappings

- [ ] Domain-to-adapter mapping uses explicit primitives/snapshots.
- [ ] Domain does not depend on HTTP/ORM/transport DTOs.
- [ ] Mapping code keeps context semantics clear.

## Repository and Query Design

- [ ] Repository interfaces are in domain/application.
- [ ] Repository returns domain aggregates/collections.
- [ ] Criteria/specification objects express query intent.
- [ ] Criteria translation happens only in infrastructure adapters.
- [ ] Projection-only queries without domain logic may keep criteria/specification in application
      layer.
- [ ] Port placement is explicit: domain ports for domain policy dependencies, application ports
      for use-case decoupling.

## Verification

- [ ] Unit tests cover invariant failures and successful transitions.
- [ ] Tests include snapshot round-trip behavior.
- [ ] Error model distinguishes invalid input vs not found vs conflicts.
