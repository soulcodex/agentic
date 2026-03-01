---
name: relational-database-design
description: >
  Designs or reviews a relational database schema for a given domain. Covers
  table structure, normalization, indexes, constraints, and migration strategy.
  Invoked when the user asks to design a schema, review a database structure,
  or optimize a data model.
version: 1.0.0
tags:
  - data
  - database
  - schema
  - sql
  - design
resources: []
vendor_support:
  claude: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Relational Database Design Skill

### Step 1 — Gather Requirements

Ask (or infer from context) before designing anything:
- What are the core **domain entities** and their relationships?
- What are the primary **access patterns** (queries the application must answer)?
- What are the expected **data volumes** (rows per table, growth rate)?
- What are the **SLA and consistency requirements** (read latency, write throughput, ACID)?
- Are there regulatory or retention requirements (GDPR deletion, audit trails)?
- Which **database engine** will be used (PostgreSQL, MySQL, SQLite, …)?

### Step 2 — Draft Entity List and Relationships

Enumerate entities and classify relationships:
- **One-to-many**: a parent row owns many child rows (`orders` → `line_items`).
- **Many-to-many**: resolve via a join table (`users` ↔ `roles` via `user_roles`).
- **One-to-one**: split tables only when the subset is queried independently or has
  different access control requirements.

Sketch an ERD in text or ASCII before writing DDL:
```
users (id, email, created_at)
  └── orders (id, user_id FK, status, placed_at)
        └── line_items (id, order_id FK, product_id FK, quantity, unit_price)
products (id, sku, name, price)
```

### Step 3 — Apply Normalization

Normalize to **3NF** as the default:
1. **1NF**: atomic values per column, no repeating groups.
2. **2NF**: every non-key column depends on the entire primary key (relevant for composite PKs).
3. **3NF**: no transitive dependencies — non-key columns depend only on the primary key.

Document any **intentional denormalization** with a comment explaining the trade-off:
```sql
-- Denormalized: product_name copied at order time so historical orders
-- remain readable even if the product is later renamed or deleted.
line_items.product_name TEXT NOT NULL
```

### Step 4 — Define Indexes

Map each identified access pattern to an index strategy:

| Access pattern | Index type | Example |
|---|---|---|
| Equality lookup by FK | B-tree | `CREATE INDEX ON orders(user_id)` |
| Range query on timestamp | B-tree | `CREATE INDEX ON orders(placed_at)` |
| Partial: active records only | Partial B-tree | `CREATE INDEX ON orders(user_id) WHERE status = 'active'` |
| Case-insensitive lookup | Expression | `CREATE INDEX ON users(lower(email))` |
| Avoid heap fetch on hot query | Covering | `CREATE INDEX ON orders(user_id) INCLUDE (status, placed_at)` |

State the rationale for each index — indexes have a write-time cost.

### Step 5 — Define Constraints

Specify all constraints in DDL, not only application code:
```sql
-- Primary keys
id UUID PRIMARY KEY DEFAULT gen_random_uuid()

-- Foreign keys with explicit ON DELETE semantics
order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE

-- Unique constraints (natural keys)
email TEXT NOT NULL UNIQUE

-- Check constraints (domain invariants)
quantity INTEGER NOT NULL CHECK (quantity > 0),
unit_price NUMERIC(19,4) NOT NULL CHECK (unit_price >= 0)

-- Not null for mandatory fields
placed_at TIMESTAMPTZ NOT NULL DEFAULT now()
```

### Step 6 — Review for Common Query Pitfalls

Audit the schema against these anti-patterns:
- **N+1 queries**: ensure relationships that will be loaded together are indexable in one
  query (use `JOIN` + covering index, not per-row lookups).
- **Unbounded queries**: every table read in application code must have a `LIMIT`; flag
  any path that could return the entire table.
- **Missing pagination**: collection endpoints must use keyset pagination — do not use
  `OFFSET` on tables expected to grow large.
- **Implicit type coercions**: mismatched column and parameter types (e.g., comparing a
  `TEXT` FK to a `UUID` parameter) disable index use; check types match exactly.

### Step 7 — Output: Schema DDL + Migration Notes + Index Rationale

Deliver:
1. **Schema DDL** — complete `CREATE TABLE` statements with all columns, types, constraints,
   and default values. Order: PK → FKs → data columns → metadata columns (`created_at`, `updated_at`).
2. **Migration notes** — if this modifies an existing schema, list the steps and whether any
   require back-fill or downtime. Call out non-additive changes explicitly.
3. **Index rationale** — one line per index explaining which access pattern it serves and why
   that type of index was chosen.
4. **Open questions** — list anything that requires a product or operational decision before
   the schema can be finalized (retention policy, expected peak write rate, etc.).
