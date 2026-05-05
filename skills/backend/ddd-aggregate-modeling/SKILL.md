---
name: ddd-aggregate-modeling
description: >
  Guides aggregate modeling decisions for DDD services: aggregate root boundaries,
  child entity vs value object decisions, invariants, snapshot/primitives mapping,
  specification/criteria usage, and repository contract design. Invoked when the
  user asks to model or refactor domain entities and aggregate behavior.
version: 1.0.0
tags:
  - backend
  - ddd
  - aggregates
  - domain-modeling
resources:
  - aggregate-modeling-checklist.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## DDD Aggregate Modeling Skill

### Step 1 - Define Context and Ubiquitous Language

1. Identify the bounded context owning the behavior.
2. Name entities, value objects, and commands using domain language.
3. Reject generic names (`Manager`, `Helper`, `Data`) unless they are domain terms.

### Step 2 - Choose the Aggregate Root

1. Pick one root that owns consistency for the invariant set.
2. Ensure external callers reference only root IDs, not child internals.
3. Keep the aggregate small; if many transactions touch disjoint invariants, split aggregates.

### Step 3 - Classify Members Correctly

Use this decision table:

| Case | Model as |
|---|---|
| Needs identity inside aggregate lifecycle | Child Entity |
| Structural equality only, immutable meaning | Value Object |
| External persistence detail | Adapter DTO / Row Model (not domain) |

Value object categories to model explicitly:
- constrained strings (`Email`, `Name`, `VatId`)
- bounded numbers/ranges (`Lanes`, `Port`, `Quantity`)
- enumerations (`Language`, `Role`, `SystemType`)

### Step 4 - Encode Invariants in Domain Behavior

1. Validate on constructor/factory and on every mutating method.
2. Keep aggregate state private; expose intent methods (`Create`, `Update`, `Delete`, `Verify`).
3. Guard temporal ordering when needed (ignore/reject stale updates deterministically).
4. Keep authorization outside entities; enforce in application handlers.

### Step 5 - Model Snapshot/Primitives Boundaries

1. Add explicit primitives/snapshot structures for adapter boundaries.
2. Use `ToPrimitives`/`Snapshot` and `FromPrimitives`/`RestoreFromSnapshot`.
3. Do not pass transport or ORM models directly into domain behavior.
4. Keep mapping explicit; avoid reflection-based generic mappers.

### Step 6 - Define Repository and Collection Contracts

1. Define repository interfaces in domain/application, implementations in infrastructure.
2. Split reader/writer contracts when beneficial.
3. Return aggregates or domain collections, not adapter structs.
4. Add domain collections when query semantics have domain meaning.

### Step 7 - Add Criteria/Specification for Queries

1. Represent query intent via criteria/specification objects.
2. Keep filtering/sorting/pagination rules reusable and testable.
3. Translate criteria to SQL/ORM query builders only in adapters.

### Step 8 - Validate with the Checklist

Run the checklist from `aggregate-modeling-checklist.md` before finalizing model changes.

