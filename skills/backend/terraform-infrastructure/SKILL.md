---
name: terraform-infrastructure
description: >
  Structures, writes, and reviews Terraform infrastructure code. Covers module
  layout, remote state, workspace strategy, variable and secrets handling, CI
  plan/apply pipeline, naming conventions, and multi-region deployment patterns
  (provider aliases, per-region state, failover strategies). Invoked when the
  user asks to write Terraform, set up infrastructure as code, or review IaC.
version: 1.1.0
tags:
  - devops
  - terraform
  - iac
  - cloud
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Terraform Infrastructure Skill

### Step 1 — Module Structure

Organise Terraform code into reusable modules:

```
infra/
  modules/
    vpc/
      main.tf
      variables.tf
      outputs.tf
    rds/
      main.tf
      variables.tf
      outputs.tf
    ecs-service/
      main.tf
      variables.tf
      outputs.tf
  environments/
    staging/
      main.tf          ← calls modules, sets env-specific vars
      terraform.tfvars ← non-secret values only
      backend.tf       ← remote state config
    production/
      main.tf
      terraform.tfvars
      backend.tf
```

Rules:
- Every module has exactly three files: `main.tf`, `variables.tf`, `outputs.tf`.
- Modules accept inputs via `variables.tf` and expose results via `outputs.tf`.
- Never put environment-specific config inside a module.

### Step 2 — Remote State

Use S3 + DynamoDB for state locking (AWS):

```hcl
# environments/staging/backend.tf
terraform {
  backend "s3" {
    bucket         = "acme-terraform-state"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "acme-terraform-locks"
    encrypt        = true
  }
}
```

State bucket requirements:
- Versioning enabled.
- Server-side encryption enabled (SSE-S3 or SSE-KMS).
- Block all public access.
- Access restricted to CI role and infrastructure team.

### Step 3 — Workspace Strategy

Use one Terraform workspace per environment (not per feature branch):

| Workspace | Environment | State key |
|-----------|------------|-----------|
| `default` | Not used — rename to `staging` | — |
| `staging` | Staging | `staging/terraform.tfstate` |
| `production` | Production | `production/terraform.tfstate` |

Do **not** use workspaces for feature branches — use separate directories instead.

### Step 4 — Variable Handling

```hcl
# variables.tf — declare type and description for every variable
variable "db_instance_class" {
  type        = string
  description = "RDS instance class (e.g., db.t3.medium)"
  default     = "db.t3.micro"
}

variable "db_password" {
  type        = string
  description = "Database master password — inject from CI secrets, never store in tfvars"
  sensitive   = true   # masks value in plan output and logs
}
```

Rules:
- Mark secrets (`sensitive = true`) — they are never stored in `.tfvars` files.
- Inject secrets via CI environment variables: `TF_VAR_db_password=${{ secrets.DB_PASSWORD }}`.
- Commit `.tfvars` files only for non-sensitive configuration values.
- Never commit `*.tfvars` files that contain secrets to version control.

### Step 5 — CI Plan / Apply Pipeline

```yaml
# .github/workflows/terraform.yml
jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with: { terraform_version: "1.8.x" }
      - name: Init
        run: terraform -chdir=infra/environments/staging init
      - name: Plan
        run: terraform -chdir=infra/environments/staging plan -out=tfplan
        env:
          TF_VAR_db_password: ${{ secrets.STAGING_DB_PASSWORD }}
      - name: Upload plan
        uses: actions/upload-artifact@v4
        with: { name: tfplan, path: infra/environments/staging/tfplan }

  apply:
    needs: plan
    environment: staging     # manual approval gate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with: { terraform_version: "1.8.x" }
      - name: Download plan
        uses: actions/download-artifact@v4
        with: { name: tfplan, path: infra/environments/staging }
      - name: Apply
        run: terraform -chdir=infra/environments/staging apply tfplan
```

### Step 6 — Naming Conventions

For single-region projects, use `{project}-{environment}-{resource}`:

```
acme-staging-vpc
acme-staging-rds-primary
acme-production-s3-uploads
```

For multi-region projects, include a short region code: `{project}-{environment}-{region_code}-{resource}`:

```
acme-staging-use1-vpc
acme-staging-use1-rds-primary
acme-production-euw1-ecs-api
```

Recommended region short codes:

| AWS Region | Code |
|-----------|------|
| us-east-1 | use1 |
| us-west-2 | usw2 |
| eu-west-1 | euw1 |
| ap-southeast-1 | apse1 |

Apply tags to every resource:
```hcl
tags = {
  Project     = var.project
  Environment = var.environment
  Region      = var.region      # include for multi-region projects
  ManagedBy   = "terraform"
}
```

---

### Step 7 — Multi-Region Directory Layout

Separate *global* resources (IAM, Route53, ACM for CloudFront) from *regional* stacks.
Apply `global/` first — regional stacks depend on its outputs.

```
infra/
  global/                    ← IAM roles, Route53 zones, ACM certs for CloudFront (us-east-1 only)
    main.tf
    variables.tf
    outputs.tf
    backend.tf
  regions/
    us-east-1/               ← primary region
      main.tf
      variables.tf
      terraform.tfvars
      backend.tf
    eu-west-1/               ← secondary region
      main.tf
      variables.tf
      terraform.tfvars
      backend.tf
  modules/
    vpc/
    rds/
    ecs-service/
```

Rules:
- `global/` has no dependency on any regional stack.
- Each regional directory has its own state file — never share state between regions.
- Regional stacks reference global outputs via `terraform_remote_state`.

### Step 8 — Provider Aliases and `configuration_aliases`

Declare provider aliases at the calling stack and pass them to modules.
Child modules **must** declare `configuration_aliases` — passing an alias without declaring it causes a provider configuration error.

```hcl
# regions/us-east-1/main.tf
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "secondary"
  region = "eu-west-1"
}

module "replication" {
  source = "../../modules/s3-replication"
  providers = {
    aws.primary   = aws.primary
    aws.secondary = aws.secondary
  }
}
```

```hcl
# modules/s3-replication/main.tf
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.primary, aws.secondary]
    }
  }
}

resource "aws_s3_bucket" "source" {
  provider = aws.primary
  bucket   = "${var.project}-${var.env}-${var.primary_region_code}-uploads"
}

resource "aws_s3_bucket" "replica" {
  provider = aws.secondary
  bucket   = "${var.project}-${var.env}-${var.secondary_region_code}-uploads"
}
```

### Step 9 — Per-Region State and Cross-Region References

Store each region's state in a bucket **in that same region** — a single state bucket is a single point of failure.

```hcl
# regions/eu-west-1/backend.tf
terraform {
  backend "s3" {
    bucket         = "acme-terraform-state-eu-west-1"  # regional bucket
    key            = "production/eu-west-1/terraform.tfstate"
    region         = "eu-west-1"                       # always explicit
    dynamodb_table = "acme-terraform-locks"
    encrypt        = true
  }
}
```

Reference another region's outputs with `terraform_remote_state`. Always set `region` explicitly — the provider's default region is unreliable across CI runners.

```hcl
data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = "acme-terraform-state-us-east-1"
    key    = "global/terraform.tfstate"
    region = "us-east-1"                      # explicit — do not rely on provider default
  }
}

resource "aws_route53_record" "api" {
  zone_id = data.terraform_remote_state.global.outputs.hosted_zone_id
  # ...
}
```

### Step 10 — Failover Patterns

Choose a strategy based on RPO/RTO requirements:

| Pattern | RPO / RTO | Key AWS services |
|---------|----------|-----------------|
| Active-passive | minutes / minutes | Route53 health checks + failover routing |
| Active-active | seconds / zero | DynamoDB Global Tables, Aurora Global Database |

**Active-passive — Route53 health-check failover:**

```hcl
resource "aws_route53_health_check" "primary" {
  fqdn              = "api.us-east-1.acme.com"
  port              = 443
  type              = "HTTPS"
  failure_threshold = 3
  request_interval  = 10
}

resource "aws_route53_record" "api_primary" {
  zone_id        = var.hosted_zone_id
  name           = "api.acme.com"
  type           = "A"
  set_identifier = "primary"
  failover_routing_policy { type = "PRIMARY" }
  health_check_id = aws_route53_health_check.primary.id
  alias { name = aws_lb.primary.dns_name; zone_id = aws_lb.primary.zone_id; evaluate_target_health = false }
}

resource "aws_route53_record" "api_secondary" {
  zone_id        = var.hosted_zone_id
  name           = "api.acme.com"
  type           = "A"
  set_identifier = "secondary"
  failover_routing_policy { type = "SECONDARY" }
  alias { name = aws_lb.secondary.dns_name; zone_id = aws_lb.secondary.zone_id; evaluate_target_health = false }
}
```

**Active-active — DynamoDB Global Tables with replication lag alarm:**

```hcl
resource "aws_dynamodb_table" "sessions" {
  provider         = aws.primary
  name             = "acme-production-sessions"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "pk"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  replica { region_name = "eu-west-1" }
}

resource "aws_cloudwatch_metric_alarm" "replication_lag" {
  provider            = aws.secondary
  alarm_name          = "dynamodb-replication-lag"
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/DynamoDB"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 5000    # milliseconds
  comparison_operator = "GreaterThanThreshold"
}
```

### Step 11 — Multi-Region CI Pipeline

Apply global resources first, then the primary region, then secondary regions in parallel:

```yaml
jobs:
  global:
    name: Apply global
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with: { terraform_version: "1.8.x" }
      - run: terraform -chdir=infra/global init
      - run: terraform -chdir=infra/global apply -auto-approve

  primary-region:
    name: Apply us-east-1
    needs: global
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with: { terraform_version: "1.8.x" }
      - run: terraform -chdir=infra/regions/us-east-1 init
      - run: terraform -chdir=infra/regions/us-east-1 apply -auto-approve

  secondary-regions:
    name: Apply ${{ matrix.region }}
    needs: primary-region
    runs-on: ubuntu-latest
    environment: production
    strategy:
      matrix:
        region: [eu-west-1, ap-southeast-1]
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with: { terraform_version: "1.8.x" }
      - run: terraform -chdir=infra/regions/${{ matrix.region }} init
      - run: terraform -chdir=infra/regions/${{ matrix.region }} apply -auto-approve
```

**Multi-region pitfalls:**
- ACM certificates for CloudFront **must** be in `us-east-1` — even if your origin is elsewhere. Create them in `global/`.
- Route53 and IAM are global services — create them once in `global/`, never replicate across regional stacks.
- `configuration_aliases` must be declared inside `terraform { required_providers { ... } }` in the child module.
- Always set `region` explicitly in `terraform_remote_state` config blocks.
- Do not store all state in one region — use per-region S3 buckets to avoid a regional outage blocking applies elsewhere.

### Verify

- [ ] `terraform validate` passes with no errors.
- [ ] `terraform plan` shows only intended changes.
- [ ] No secrets in `.tfvars` or state file (check `terraform show`).
- [ ] State is stored in remote backend — not local `terraform.tfstate`.
- [ ] All resources tagged with `Project`, `Environment`, `ManagedBy`.
- [ ] (Multi-region) `global/` applies cleanly before any regional stack.
- [ ] (Multi-region) Each region has its own state bucket in the same region.
- [ ] (Multi-region) `configuration_aliases` declared in all modules receiving provider aliases.
- [ ] (Multi-region) Replication lag alarm configured for active-active data stores.
