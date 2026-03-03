---
name: webhook-development
description: >
  Implements reliable webhook receiving and sending with HMAC signature
  verification, idempotent processing, retry-with-backoff, and dead-letter
  handling. Invoked when the user asks to add webhooks, implement a webhook
  endpoint, or send webhook events to external systems.
version: 1.0.0
tags:
  - backend
  - webhook
  - reliability
  - integration
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Webhook Development Skill

### Step 1 — Receiving Webhooks

**Verify the signature first — before any processing:**

```go
// HMAC-SHA256 verification (Go)
func verifySignature(body []byte, signatureHeader, secret string) bool {
    mac := hmac.New(sha256.New, []byte(secret))
    mac.Write(body)
    expected := "sha256=" + hex.EncodeToString(mac.Sum(nil))
    return hmac.Equal([]byte(expected), []byte(signatureHeader))
}
```

```ts
// HMAC-SHA256 verification (TypeScript)
async function verifySignature(body: string, signature: string, secret: string): Promise<boolean> {
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'])
  const mac = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(body))
  const expected = 'sha256=' + Array.from(new Uint8Array(mac)).map(b => b.toString(16).padStart(2, '0')).join('')
  return expected === signature
}
```

**Respond immediately — enqueue for async processing:**

```
POST /webhooks/stripe
  1. Read raw body (before any parsing)
  2. Verify HMAC-SHA256 signature → 401 if invalid
  3. Return HTTP 200 immediately
  4. Enqueue event → message queue (SQS, RabbitMQ, etc.)
```

Never do database writes or downstream API calls inside the HTTP handler — the
sender's retry logic will time out.

### Step 2 — Processing Webhooks (Idempotent Consumer)

```
Worker loop:
  1. Dequeue event
  2. Check idempotency key (event_id) in processed_events table
     → if found: ack and skip
  3. Begin transaction
     4. Process business logic
     5. Insert event_id into processed_events
  6. Commit
  7. Ack message
```

Idempotency key: use the sender's event ID (e.g., Stripe's `evt_xxx`, GitHub's
`X-GitHub-Delivery` header). If the sender does not provide one, derive it from
a hash of the payload.

**Retry with exponential backoff:**

```
Attempt 1: immediate
Attempt 2: +1 second
Attempt 3: +5 seconds
Attempt 4: +30 seconds
Attempt 5: → dead-letter queue
```

### Step 3 — Dead-Letter Handling

After max retries, move the event to a dead-letter queue (DLQ):
- Alert the on-call engineer (PagerDuty, Slack, CloudWatch alarm).
- Store the raw payload and failure reason for manual inspection.
- Provide an operations endpoint to replay a DLQ event manually:
  `POST /admin/webhooks/replay/:event-id`

### Step 4 — Sending Webhooks (Outbox Pattern)

Never send webhooks synchronously inside a business transaction:

```
1. In the same DB transaction as the domain event:
   INSERT INTO outbox_events (id, topic, payload, status='pending')

2. Background worker polls outbox (or listens via CDC):
   SELECT * FROM outbox_events WHERE status='pending' ORDER BY created_at LIMIT 100

3. For each event:
   a. POST to subscriber URL with:
      X-Webhook-ID: <outbox_event.id>
      X-Webhook-Timestamp: <unix epoch>
      X-Webhook-Signature: sha256=<hmac>
   b. On 2xx: UPDATE outbox_events SET status='sent'
   c. On failure: retry with backoff; after max retries → status='failed'
```

### Step 5 — Monitor

Add these observability signals:
- **Counter**: `webhooks_received_total{vendor, status}` — track 2xx vs. 4xx/5xx rates.
- **Counter**: `webhooks_processed_total{topic, outcome}` — track success vs. failure.
- **Gauge**: `webhook_dlq_depth` — alert when > 0 for more than 5 minutes.
- **Histogram**: `webhook_processing_duration_seconds` — track consumer latency.
