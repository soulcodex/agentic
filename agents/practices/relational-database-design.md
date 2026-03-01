## Relational Database Design

Conventions for designing, querying, and maintaining relational databases. These rules
apply regardless of engine (PostgreSQL, MySQL, SQLite). Prefer correctness and clarity
over premature optimization.

### Schema Design

**Normalization:**
- Start at 3NF: every non-key attribute depends on the whole primary key and nothing but
  the primary key.
- Denormalize only when a measured query bottleneck justifies it — document the trade-off
  in a comment or ADR.
- Do not store derived values (totals, counts) in base tables unless recomputing them is
  demonstrably too expensive.

**Column types:**
- Use the smallest type that fits the domain: `SMALLINT` for status codes, `TEXT` for
  unbounded strings (not `VARCHAR(255)` as a habit).
- Store monetary values as `NUMERIC(19,4)` or a scaled integer — never `FLOAT`/`DOUBLE`.
- Store timestamps in UTC using `TIMESTAMPTZ` (PostgreSQL) or `DATETIME` with a UTC
  convention documented in the schema.
- Use `UUID` or `BIGSERIAL` for primary keys; prefer `UUID` in distributed or replicated
  environments.

**Naming:**
- Table names: `snake_case`, plural nouns (`orders`, `line_items`).
- Column names: `snake_case`, singular (`created_at`, `user_id`, not `userID`).
- Foreign key columns: `{referenced_table_singular}_id` (e.g., `order_id` in `line_items`).
- Boolean columns: affirmative predicates (`is_active`, `has_been_verified`).

### Indexes

**When to add an index:**
- Columns used in `WHERE`, `JOIN ON`, `ORDER BY`, or `GROUP BY` with high selectivity.
- Foreign key columns (most engines do not create these automatically).
- Columns used in range queries or sort-heavy pagination.

**Index types:**
- B-tree: default — range queries, equality, `ORDER BY`.
- Covering index: include all columns touched by a query to avoid a heap fetch
  (`CREATE INDEX … INCLUDE (col1, col2)`).
- Partial index: index only the rows that satisfy a condition (`WHERE is_active = true`)
  to keep the index small and fast.
- Expression index: index a function result (`lower(email)`) for case-insensitive lookups.

**When NOT to index:**
- Columns with very low cardinality (boolean flags) unless combined with a partial predicate.
- Tables that are small enough for a sequential scan to be faster (< ~1 000 rows).
- Every column "just in case" — indexes consume write I/O and storage.

**Maintenance:**
- Run `ANALYZE` (or equivalent) after bulk loads.
- Monitor index bloat; rebuild or `VACUUM` periodically.
- Drop unused indexes — query the `pg_stat_user_indexes` view to identify them.

### Constraints

Enforce data integrity at the database level, not only in application code. Application
constraints can be bypassed (migrations, scripts, other services).

- **Primary key**: every table has one; prefer a surrogate key (`id UUID DEFAULT gen_random_uuid()`).
- **Foreign keys**: always declare them; let the engine enforce referential integrity.
  Define `ON DELETE` behavior explicitly (`CASCADE`, `RESTRICT`, `SET NULL`).
- **Unique**: declare `UNIQUE` constraints for natural keys (e.g., `email`, `slug`)
  in addition to the surrogate PK.
- **Not null**: columns that must never be null — declare `NOT NULL`; don't rely on
  application-layer validation alone.
- **Check**: encode domain invariants (`CHECK (amount > 0)`, `CHECK (status IN (…))`).
  Prefer `CHECK` over application-only validation for immutable business rules.

### Query Design

- Avoid `SELECT *` — list columns explicitly so schema changes surface as compile/test errors
  rather than silent runtime bugs.
- Use parameterised queries for all user-supplied input; never interpolate values into SQL
  strings.
- Prefer `INNER JOIN` when the relationship is mandatory; use `LEFT JOIN` deliberately and
  document why a nullable join is expected.

**Pagination:**
- Use keyset (cursor) pagination for large result sets:
  `WHERE (created_at, id) < ($last_created_at, $last_id) ORDER BY created_at DESC, id DESC LIMIT $n`
- Avoid `OFFSET` on large tables — it forces the engine to scan and discard rows; performance
  degrades linearly with offset size.
- Always pair `LIMIT` with an `ORDER BY` to produce deterministic results.

**Bounding queries:**
- Every query that could return an unbounded number of rows must have a `LIMIT`.
- Aggregate queries on large tables should be run against a replica or a pre-materialized
  summary table, not the primary write replica during peak traffic.

### Connection Management

- Use a connection pool (PgBouncer, HikariCP, database/sql pool). Never open a new
  connection per request.
- Pool size formula starting point: `connections = (core_count * 2) + effective_spindle_count`.
  Tune empirically; a pool that is too large is worse than one that is too small.
- Set a `statement_timeout` and `lock_timeout` for all application connections to prevent
  runaway queries from starving the pool.
- Avoid long-lived transactions: acquire a connection, do the work, commit/rollback, release.
  Do not hold transactions open while waiting for external I/O (HTTP calls, user input).

### Migrations

- Migrations must be additive first: add a nullable column, back-fill it, add the `NOT NULL`
  constraint in a later migration once no nulls remain.
- Never rename or drop a column or table in the same migration as any application code that
  removes the old reference — deploy the application change first, then drop after all
  instances are updated.
- Every migration must have a rollback script or a documented manual rollback path.
- Migrations run in CI against a real database engine; never test migrations only against
  in-memory or mock stores.
- Use a migration tool that records applied migrations in a `schema_migrations` table
  (Flyway, Liquibase, golang-migrate, Alembic, Prisma Migrate) — do not apply raw SQL
  files by hand.

### Partitioning and Archiving

**Partitioning:**
- Partition large, time-series tables by range on a timestamp column when the table exceeds
  tens of millions of rows or query patterns are strongly time-bounded.
- Partition by list (tenant ID, region) when multi-tenant isolation or regulatory data
  residency requires it.
- Evaluate partitioning as a response to a measured problem, not as a default.

**Archiving cold data:**
- Define a data retention policy before the table grows large.
- Move rows older than the retention window to an archive table or cold storage in a
  background job — never in the hot path.
- Archive jobs must be idempotent and run in small batches to avoid long lock contention.
