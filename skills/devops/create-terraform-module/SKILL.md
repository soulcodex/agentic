---
name: create-terraform-module
description: >
  Creates or updates AWS-oriented Terraform module structure and implementation
  scaffolding. Focuses on file layout, variable/output contracts, provider and
  version constraints, tagging standards, safe composition patterns, and
  address-stability guardrails.
version: 1.1.0
tags:
  - devops
  - terraform
  - aws
  - modules
resources:
  - module-skeleton.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Create Terraform Module Skill

Create or revise Terraform module implementation details for AWS workloads.

Always pair this skill with `terraform-risk-playbook`. That skill is
authoritative for the response contract, risk category, version/runtime floor,
validation expectations, and rollback notes.

Authoritative precedence: when this skill and `terraform-infrastructure` are both
active, this skill is authoritative for module layout, file set, and module
interface details.

### Step 1 - Define Module Contract

Define module inputs/outputs first:
- required vs optional variables
- typed structures (`object`, `list(object)`) where appropriate
- sensitive inputs marked with `sensitive = true`
- outputs scoped to consumer needs only
- do not treat `sensitive = true` as state protection; avoid module interfaces
  that require raw secret values when a reference/ARN can be passed instead

### Step 2 - Create Module Structure

Use `module-skeleton.md` as the required baseline layout.

Rules:
- include `README.md`, `versions.tf`, `providers.tf`, `main.tf`, `variables.tf`, `outputs.tf`
- keep environment-specific values outside reusable modules
- avoid hidden dependencies on caller-side locals/naming
- child modules must not configure provider credentials/regions directly; define
  `required_providers` and let the root module pass provider instances/aliases

### Step 3 - Implement AWS Resources Safely

Apply consistent tagging and naming conventions.

Implementation guardrails:
- explicit `required_providers` and Terraform version constraints
- `lifecycle` usage only when justified and documented
- stable resource addressing to reduce churn in plans
- prefer `for_each` over `count` when item identity must survive reordering or
  selective removal
- when refactoring addresses, emit `moved` blocks or explicit migration notes
  instead of rename-only changes
- verify runtime floor before suggesting `import`, `moved`, `optional()`, mock
  providers, or `write_only` patterns
- no plaintext secrets in code or defaults

### Step 4 - Add Example Consumer and Validation Steps

Include a minimal example usage block and required validate/fmt checks.

### Step 5 - Handoff

Provide:
- module purpose and public interface summary
- migration notes if refactoring existing resources
- known limits and follow-up test requirements

For test-case authoring and `terraform test` implementation, hand off to
`create-terraform-tests`.
