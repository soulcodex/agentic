## API Design

### REST Conventions

**URLs are nouns, methods are verbs**:
```
GET    /users              — list users
POST   /users              — create a user
GET    /users/{id}         — get a user
PUT    /users/{id}         — replace a user (full update)
PATCH  /users/{id}         — update a user (partial update)
DELETE /users/{id}         — delete a user
```

- Use plural resource names: `/orders`, not `/order`.
- Use kebab-case for multi-word resources: `/order-items`.
- Nest resources only when the relationship is strict ownership and max 2 levels deep:
  `/orders/{id}/items`. Beyond that, use query parameters.
- Never expose database IDs directly. Use UUIDs or opaque string IDs.

### Versioning

- Version from day one: `/v1/users`, `/v2/users`.
- Version in the URL path (not headers) — easier to test, log, and route.
- Never make breaking changes to a published version. Add a new version instead.
- A breaking change is: removing a field, renaming a field, changing a field type, removing an
  endpoint, changing status code semantics.
- Additive changes (new optional fields, new endpoints) are backward-compatible.

### Request and Response Shapes

**Response envelope**:
```json
{
  "data": { "id": "...", "name": "..." },
  "meta": { "requestId": "abc-123" }
}
```

**List response**:
```json
{
  "data": [ { "id": "...", "name": "..." } ],
  "meta": {
    "page": 1,
    "pageSize": 20,
    "totalCount": 143,
    "requestId": "abc-123"
  }
}
```

**Error response**:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [
      { "field": "email", "message": "Must be a valid email address" }
    ]
  },
  "meta": { "requestId": "abc-123" }
}
```

### HTTP Status Codes

| Scenario | Status Code |
|---|---|
| Success (with body) | 200 OK |
| Created | 201 Created |
| Success (no body) | 204 No Content |
| Bad request / validation | 400 Bad Request |
| Unauthenticated | 401 Unauthorized |
| Forbidden | 403 Forbidden |
| Not found | 404 Not Found |
| Conflict | 409 Conflict |
| Rate limited | 429 Too Many Requests |
| Server error | 500 Internal Server Error |
| Downstream error | 502 Bad Gateway |
| Service unavailable | 503 Service Unavailable |

Use codes precisely. `401` means "not authenticated". `403` means "authenticated but not allowed".

### Validation

- Validate request bodies against a schema (OpenAPI, Zod, JSON Schema) at the entry point.
- Return all validation errors at once (not just the first one) with field-level detail.
- Reject unknown fields in strict mode to surface client bugs early.

### Schema-Driven Contracts

- Every externally consumed request/response must have a machine-readable schema.
- Keep schema versions explicit (for example: `create-company.v1.schema.json`).
- Update handlers and schemas in the same change; stale schemas are contract bugs.
- Prefer JSON Schema/OpenAPI at HTTP boundaries and typed internal DTOs behind them.

### Webhook Safety and Reliability

- Verify webhook signatures before parsing payloads.
- Enforce event timestamp tolerance and reject stale requests to reduce replay windows.
- Store provider event IDs (or equivalent nonce) to enforce idempotency.
- Return 2xx only after processing state is safely persisted or queued durably.
- Retries must be safe: duplicate delivery cannot create duplicate side effects.

### Pagination

Use cursor-based pagination for large, frequently-changing datasets:
```json
{
  "data": [ ... ],
  "meta": {
    "nextCursor": "eyJpZCI6IjEyMyJ9",
    "hasMore": true
  }
}
```

Use offset/page pagination for stable, small datasets.

### API Documentation

- Generate OpenAPI spec from code (not hand-written) using decorators or schema definitions.
- Publish an interactive Swagger UI at `/docs` in non-production environments.
- Every endpoint must have a summary, description, request schema, and all possible response schemas.
