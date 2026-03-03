---
name: serverless-architecture
description: >
  Designs and implements serverless functions: function boundary design, runtime
  selection, event sources, IAM least privilege, configuration, observability,
  and cost estimation. Invoked when the user asks to build a serverless function,
  design a Lambda-based system, or move workloads to serverless.
version: 1.0.0
tags:
  - backend
  - serverless
  - cloud
  - aws
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Serverless Architecture Skill

### Step 1 — Function Boundary Design

A Lambda function (or equivalent) should do exactly one thing. Design boundaries by:
- **Event source**: each distinct trigger gets its own function.
- **Single responsibility**: one function = one business operation.
- **Avoid chaining**: do not call one Lambda synchronously from another — use queues.

```
Bad:  process-order Lambda → calls fulfillment Lambda → calls notification Lambda
Good: process-order Lambda → SQS → fulfillment Lambda → SQS → notification Lambda
```

### Step 2 — Runtime and Cold-Start

| Runtime | Cold-start | Notes |
|---------|-----------|-------|
| Go / Rust | Very fast (~10 ms) | Best for latency-sensitive workloads |
| Node.js (ESM) | Fast (~100–200 ms) | Keep bundle small; avoid large deps |
| Python | Medium (~200–500 ms) | Use Lambda layers for heavy deps |
| JVM (Java/Kotlin) | Slow (1–5 s) | Use GraalVM native image or SnapStart |

Mitigate cold starts for latency-critical functions:
```yaml
# serverless.yml or SAM template
Properties:
  ProvisionedConcurrencyConfig:
    ProvisionedConcurrentExecutions: 2  # keeps N instances warm
```

Use provisioned concurrency only where latency SLAs justify the cost.

### Step 3 — Event Sources

| Trigger | Pattern | Notes |
|---------|---------|-------|
| API Gateway / ALB | Synchronous HTTP | Return response within 29 s |
| SQS | Async batch processing | Set visibility timeout > max duration |
| EventBridge | Event-driven, fan-out | Ideal for domain events |
| S3 | File processing | Trigger on `ObjectCreated`, filter by prefix |
| DynamoDB Streams | Change data capture | Process in order per partition key |
| Scheduled (EventBridge) | Cron jobs | Use for periodic maintenance tasks |

### Step 4 — IAM Least Privilege

Every function gets its own IAM execution role. Grant only what the function needs:

```json
{
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["dynamodb:GetItem", "dynamodb:PutItem"],
      "Resource": "arn:aws:dynamodb:us-east-1:123456789:table/orders"
    },
    {
      "Effect": "Allow",
      "Action": ["sqs:SendMessage"],
      "Resource": "arn:aws:sqs:us-east-1:123456789:fulfillment-queue"
    }
  ]
}
```

Never attach `AdministratorAccess` or broad `*` actions to a Lambda role.

### Step 5 — Configuration

Store configuration and secrets outside the function bundle:
- Non-sensitive config: Lambda environment variables.
- Sensitive values: AWS SSM Parameter Store (`SecureString`) or Secrets Manager.

```go
// Fetch at cold-start, cache for the lifetime of the execution environment
var dbURL string
func init() {
    result, _ := ssm.GetParameter(&ssm.GetParameterInput{
        Name:           aws.String("/myapp/prod/db-url"),
        WithDecryption: aws.Bool(true),
    })
    dbURL = *result.Parameter.Value
}
```

### Step 6 — Observability

| Signal | Tool | What to capture |
|--------|------|----------------|
| Structured logs | CloudWatch Logs | JSON with `request_id`, `duration_ms`, `error` |
| Distributed tracing | AWS X-Ray | Annotate with business context (`user_id`, `order_id`) |
| Metrics | CloudWatch Metrics / EMF | Invocations, errors, duration, throttles |
| Alarms | CloudWatch Alarms | Error rate > 1%, duration p99 > 3s, throttle count > 0 |

Use Embedded Metric Format (EMF) for custom metrics without a separate service:
```go
log.Printf(`{"_aws":{"Timestamp":%d,"CloudWatchMetrics":[{"Namespace":"MyApp","Dimensions":[["FunctionName"]],"Metrics":[{"Name":"OrdersProcessed","Unit":"Count"}]}]},"FunctionName":"%s","OrdersProcessed":1}`, time.Now().UnixMilli(), os.Getenv("AWS_LAMBDA_FUNCTION_NAME"))
```

### Step 7 — Cost Estimation

Lambda pricing: **$0.20 per 1M requests + $0.0000166667 per GB-second**.

```
Example: 1M requests/day, 128 MB, average 200 ms duration
Requests: 1M × $0.20 = $0.20/day
Duration: 1M × 0.128 GB × 0.2 s × $0.0000166667 = $0.43/day
Total: ~$0.63/day = ~$19/month
```

Include SQS, API Gateway, and data transfer costs in the total estimate.
Consider reserved concurrency limits to cap runaway costs.
