---
name: terraform-infrastructure
description: >
  Structures, writes, and reviews Terraform infrastructure code. Covers module
  layout, remote state, workspace strategy, variable and secrets handling, CI
  plan/apply pipeline, and naming conventions. Invoked when the user asks to
  write Terraform, set up infrastructure as code, or review IaC.
version: 1.0.0
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

Use `{project}-{environment}-{resource}` for all cloud resources:

```
acme-staging-vpc
acme-staging-rds-primary
acme-staging-ecs-api
acme-production-s3-uploads
```

Apply tags to every resource:
```hcl
tags = {
  Project     = var.project
  Environment = var.environment
  ManagedBy   = "terraform"
}
```

### Verify

- [ ] `terraform validate` passes with no errors.
- [ ] `terraform plan` shows only intended changes.
- [ ] No secrets in `.tfvars` or state file (check `terraform show`).
- [ ] State is stored in remote backend — not local `terraform.tfstate`.
- [ ] All resources tagged with `Project`, `Environment`, `ManagedBy`.
