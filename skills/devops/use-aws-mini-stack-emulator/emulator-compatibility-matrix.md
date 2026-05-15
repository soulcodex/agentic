## Emulator Compatibility Matrix

Use this matrix as planning guidance for local Terraform validation confidence.

| Service/Capability | Local Confidence | Notes |
|---|---|---|
| S3 basic buckets/policies | Medium | Good for structure checks; policy nuance may differ. |
| DynamoDB table basics | Medium | Validate schema and throughput config intent only. |
| SQS/SNS/EventBridge basics | Low-Medium | API surface may be partial depending on emulator. |
| IAM policies/assume-role behavior | Low | Validate syntax locally, semantics in real AWS. |
| Lambda packaging + wiring | Low-Medium | Basic resource graph checks only. |
| API Gateway integration | Low | Route behavior and auth should be verified in AWS. |
| CloudFront/ACM/WAF | Low | Treat as real-AWS-only for release confidence. |
| RDS/Aurora lifecycle | Low | Use real AWS for stateful and engine-specific behavior. |
| CloudWatch alarms and metrics | Low | Local behavior is not representative for alerting correctness. |

Confidence legend:
- High: trustworthy for merge-blocking checks
- Medium: useful guardrail but still requires targeted AWS confirmation
- Low: local-only smoke signal; always verify in AWS
