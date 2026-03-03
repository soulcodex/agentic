---
name: nosql-database-design
description: >
  Designs a NoSQL data model by leading with access pattern analysis. Covers
  DynamoDB single-table design (PK/SK/GSI) and MongoDB embedding vs referencing,
  consistency models, and capacity planning. Invoked when the user asks to design
  a DynamoDB schema, MongoDB data model, or NoSQL data model.
version: 1.0.0
tags:
  - backend
  - nosql
  - database
  - dynamodb
  - mongodb
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## NoSQL Database Design Skill

### Step 1 — Access Pattern Analysis

**List every query the application must answer before touching the schema.**
NoSQL schemas are derived from access patterns, not from entity relationships.

```
Access patterns for an e-commerce system:
1. Get order by order_id
2. List all orders for a user (paginated, newest first)
3. List all orders with status=PENDING (for fulfillment worker)
4. Get all line items for an order
5. Get product by product_id
6. List products by category
```

Identify for each pattern:
- Query type: GetItem (by exact key) or Query (by key + filter)
- Cardinality: how many results (1, tens, millions?)
- Sort order: unsorted, by date, by score?
- Filter: additional attributes to filter on after key lookup?

### Step 2 — Choose the Model

| Factor | DynamoDB | MongoDB |
|--------|---------|---------|
| Access patterns | Known and stable | Flexible / evolving |
| Scale | 10 B+ items, unlimited throughput | Moderate to high scale |
| Joins | Not supported — model for single-table | `$lookup` supported (avoid in hot paths) |
| Transactions | Supported (2-phase, up to 100 items) | Multi-document transactions supported |
| Consistency | Eventually consistent reads by default (strongly consistent optional) | Tunable read/write concern |

### Step 3 — DynamoDB: Single-Table Design

Use a single table with a generic `PK` and `SK`:

```
Table: ecommerce
PK (partition key)     SK (sort key)            Attributes
─────────────────────  ─────────────────────────  ──────────────────────────
USER#u-123             PROFILE                    name, email, created_at
USER#u-123             ORDER#o-456               status, total, placed_at
USER#u-123             ORDER#o-789               status, total, placed_at
ORDER#o-456            ITEM#p-001                quantity, unit_price
ORDER#o-456            ITEM#p-002                quantity, unit_price
PRODUCT#p-001          METADATA                  name, price, category
```

**GSI (Global Secondary Index)** for access patterns that don't fit the base key:

```
GSI1:
  GSI1PK = STATUS#PENDING   → query all pending orders
  GSI1SK = placed_at        → sort by placement time
```

Rules:
- Use string prefixes (`USER#`, `ORDER#`) to avoid key collisions.
- Design GSIs for access patterns that require a different partition key.
- Avoid hot partitions: ensure high-cardinality partition keys.

### Step 4 — MongoDB: Embedding vs Referencing

**Embed** when the nested data:
- Is always read together with the parent.
- Has bounded cardinality (a few dozen items at most).
- Is not queried independently.

```js
// Embed: order with line items (always read together, bounded count)
{
  _id: "o-456",
  user_id: "u-123",
  status: "PLACED",
  line_items: [
    { product_id: "p-001", quantity: 2, unit_price: 19.99 },
    { product_id: "p-002", quantity: 1, unit_price: 49.99 }
  ]
}
```

**Reference** when the nested data:
- Grows without bound (e.g., comments on a post).
- Is queried independently.
- Is shared across multiple parent documents.

```js
// Reference: reviews stored separately, queried independently
{ _id: "r-001", product_id: "p-001", rating: 5, body: "..." }
{ _id: "r-002", product_id: "p-001", rating: 4, body: "..." }
```

**Array discipline**: never put unbounded arrays in a document — the 16 MB document
size limit will be hit and updates become O(n).

**Indexes** (add for every access pattern that requires a sort or filter):
```js
db.orders.createIndex({ user_id: 1, placed_at: -1 })  // list orders by user
db.orders.createIndex({ status: 1 })                   // filter by status
db.reviews.createIndex({ product_id: 1, rating: -1 }) // reviews by product
```

### Step 5 — Consistency Model

- **DynamoDB**: use strongly consistent reads (`ConsistentRead: true`) only where
  stale data is unacceptable — it costs 2× read capacity units.
- **MongoDB**: use `{ readConcern: "majority", writeConcern: { w: "majority" } }` for
  operations that must survive a primary failover.

Document the chosen consistency level and its trade-offs.

### Step 6 — Capacity Planning

**DynamoDB**:
- Calculate RCU/WCU requirements per access pattern.
- Use on-demand mode for unpredictable traffic; provisioned + auto-scaling for steady workloads.
- Monitor `ConsumedReadCapacityUnits` and `ThrottledRequests` alarms.

**MongoDB**:
- Size working set (frequently accessed data) to fit in RAM.
- Monitor `cache bytes dirty` — if consistently > 20% of cache, increase instance size.
- Plan for index memory: each index adds to RAM footprint.
