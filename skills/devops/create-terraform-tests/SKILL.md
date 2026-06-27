---
name: create-terraform-tests
description: >
  Designs and implements Terraform module tests for AWS-targeted modules.
  Covers terraform-native tests, validation gates, fixture composition, and
  risk-focused assertions for regressions, address migration, and unsafe
  changes.
version: 1.1.0
tags:
  - devops
  - terraform
  - testing
  - aws
resources:
  - tftest-patterns.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Create Terraform Tests Skill

Author Terraform test coverage for AWS modules.

Always pair this skill with `terraform-risk-playbook`. That skill is
authoritative for the response contract, risk classification, version/runtime
guards, validation chain, and rollback notes.

Authoritative precedence: when this skill and `terraform-infrastructure` are both
active, this skill is authoritative for module testing strategy, test layout,
and assertion patterns.

### Step 1 - Identify Risk-Critical Behaviors

Prioritize tests for:
- security controls (encryption, public exposure prevention)
- destructive change prevention for stateful resources
- required inputs and invalid configuration rejection
- output contract stability
- identity and address migration safety (`count`/`for_each`, `moved` flows)
- provider/runtime upgrade compatibility when version constraints change

### Step 2 - Implement Terraform-Native Test Layout

Use `tftest-patterns.md` for baseline structure and pattern selection.

Minimum coverage:
- happy path apply/plan expectations
- invalid input validation checks
- policy/security checks for sensitive resources
- choose `command = apply` when assertions depend on computed values or set-type
  nested blocks

### Step 3 - Add CI-Friendly Validation Chain

Ensure deterministic checks in CI:
1. `terraform fmt -check -recursive`
2. `terraform init -backend=false`
3. `terraform validate`
4. `terraform test`

CI safety guardrails:
- do not point tests at production/shared backends
- use ephemeral credentials/accounts for apply-capable tests
- skip or scope tests when required cloud credentials are not present
- if the risk category includes compliance or secret exposure, include the
  repo's existing policy/security checks where applicable

### Step 4 - Keep Tests Bounded

Use minimal fixtures and avoid long-running integration behavior unless explicitly
requested. Document emulator vs real-AWS assumptions clearly.

### Step 5 - Report Coverage Gaps

Summarize what is covered, known blind spots, and next highest-value tests.
Call out whether each scenario is plan-only confidence, emulator confidence, or
real-cloud confidence.
