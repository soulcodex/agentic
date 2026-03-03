---
name: sql-query-optimization
description: >
  Diagnoses and optimises slow SQL queries using EXPLAIN ANALYZE. Covers
  identifying bottlenecks (sequential scans, bad estimates, heap fetches),
  index strategy, query rewrites, and verification. Invoked when the user asks
  to optimize a query, fix a slow database query, or improve database performance.
version: 1.0.0
tags:
  - backend
  - database
  - sql
  - performance
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## SQL Query Optimization Skill

### Step 1 — Reproduce the Slow Query

Establish a reproducible baseline before making any changes:
- Capture the exact query (including parameter values if possible).
- Note the current execution time (p95 from APM, or run it manually 3–5 times).
- Confirm the database engine (PostgreSQL, MySQL, SQLite, etc.) and version.

### Step 2 — Run EXPLAIN (ANALYZE, BUFFERS)

PostgreSQL:
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT ...;  -- paste the full query here
```

MySQL:
```sql
EXPLAIN FORMAT=JSON
SELECT ...;
```

Capture the full output before making any changes.

### Step 3 — Identify the Bottleneck

Read the plan top-down (outermost → innermost). Look for:

| Signal | What it means |
|--------|--------------|
| `Seq Scan` on a large table | No index — or the planner chose not to use one |
| Rows estimate far from actual | Stale statistics — run `ANALYZE <table>` |
| `Hash Join` with a huge hash table | May need a nested-loop + index for small inputs |
| High `Buffers: shared hit` | Heavily cached — latency is CPU-bound, not I/O |
| High `Buffers: shared read` | I/O bound — consider indexes or read replicas |
| `Bitmap Heap Scan` with many rows | Covering index may eliminate heap fetches |

### Step 4 — Fix

**Add an index** (most common fix):
```sql
-- B-tree for equality and range
CREATE INDEX CONCURRENTLY ON orders(user_id);

-- Partial index for common filter
CREATE INDEX CONCURRENTLY ON orders(created_at)
  WHERE status = 'pending';

-- Covering index to eliminate heap fetch
CREATE INDEX CONCURRENTLY ON orders(user_id)
  INCLUDE (status, total_amount);

-- Expression index for function-wrapped column
CREATE INDEX CONCURRENTLY ON users(lower(email));
```

Always use `CONCURRENTLY` in production to avoid table locks.

**Rewrite the query** (when the plan is structurally wrong):
- Replace correlated subqueries with `JOIN` or `EXISTS`.
- Replace `SELECT *` with specific columns needed.
- Replace `OFFSET` pagination with keyset pagination:
  ```sql
  -- Instead of: LIMIT 20 OFFSET 10000
  WHERE id > :last_seen_id ORDER BY id LIMIT 20
  ```
- Replace `IN (SELECT ...)` with `EXISTS (SELECT 1 FROM ...)` for large subqueries.

**Update statistics** (when estimates are wrong):
```sql
ANALYZE orders;           -- single table
ANALYZE;                  -- all tables (run as superuser)
```

### Step 5 — Verify Improvement

Run `EXPLAIN (ANALYZE, BUFFERS)` again after the fix:
- Confirm the plan uses the new index.
- Compare actual execution time to the baseline.
- Check that row estimates are now accurate.

Run the query 3–5 times to account for cache warm-up; report the steady-state time.

### Step 6 — Document

Add a comment above the index in a migration file explaining which query it supports:

```sql
-- Supports: orders list by user, filtered on status (POST /api/users/:id/orders)
CREATE INDEX CONCURRENTLY ON orders(user_id, status);
```

State the before/after execution time in the PR description.
