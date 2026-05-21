## AWS Service Matrix

Use this matrix to keep service choice and Terraform ownership explicit.

| Capability | Preferred AWS Service(s) | Typical Module Boundary | Notes |
|---|---|---|---|
| Network foundation | VPC, Subnets, NAT Gateway, Route Tables | `network` | Keep CIDR and AZ strategy centrally managed. |
| Identity and authz | IAM, IAM Identity Center, KMS | `security-identity` | Separate human/admin and workload role policies. |
| Edge and DNS | Route 53, CloudFront, ACM, WAF | `edge-dns` | ACM for CloudFront must be in `us-east-1`. |
| Compute (container) | ECS Fargate, ECR, ALB | `compute-ecs` | Isolate service/task from shared cluster/network resources. |
| Compute (serverless) | Lambda, API Gateway, EventBridge | `compute-serverless` | Keep event contracts and IAM perms explicit per function. |
| Data (relational) | RDS / Aurora, RDS Proxy | `data-rds` | Encrypt, back up, and parameterize maintenance windows. |
| Data (NoSQL) | DynamoDB, DAX (optional) | `data-dynamodb` | Model capacity/autoscaling per access pattern. |
| Object storage | S3, S3 Lifecycle, S3 Replication | `storage-s3` | Block public access by default and enforce encryption. |
| Secrets/config | Secrets Manager, SSM Parameter Store | `secrets-config` | Do not put secrets in tfvars or outputs; treat Terraform state/plan artifacts as sensitive. |
| Observability | CloudWatch Logs/Metrics/Alarms, X-Ray | `observability` | Define alarm routing and actionable thresholds. |
| Eventing/queues | SQS, SNS, EventBridge | `messaging` | Preserve DLQ and retry semantics by design. |
| Access controls at perimeter | WAF, Shield | `security-edge` | Tie rules to app risk model and rollout safely. |
