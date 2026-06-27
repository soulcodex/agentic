---
name: terraform-risk-playbook
description: >
  Diagnoses Terraform/OpenTofu risk before generating changes. Defines the
  response contract, failure-mode routing, version/runtime guards, validation
  commands, and rollback expectations for modules, tests, CI, and state work.
version: 1.0.0
tags:
  - devops
  - terraform
  - opentofu
  - safety
  - iac
resources:
  - risk-routing.md
  - version-runtime-matrix.md
  - llm-mistake-checklist.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Terraform Risk Playbook Skill

Use this skill first for any Terraform or OpenTofu task that plans changes,
reviews risk, debugs drift/state/CI issues, or proposes destructive or
state-mutating operations.

### Step 1 - Emit the Response Contract

Every response must include:
- assumptions and version floor:
  runtime (`terraform` or `tofu`), exact or assumed version, providers,
  backend, execution path (local, CI, Cloud, Atlantis), environment criticality
- risk category addressed
- chosen remediation and tradeoffs
- validation plan with exact commands tailored to the risk tier
- rollback notes for destructive or state-mutating changes

Mandatory rules:
- never recommend direct production apply without a reviewed plan artifact and
  explicit approval
- never recommend `destroy` before `plan -destroy` has been reviewed
- never use `-auto-approve` for destroy guidance

### Step 2 - Diagnose Before You Generate

Use `risk-routing.md` to classify the failure mode before suggesting code,
module changes, test strategy, CI updates, or state operations.

If the task spans multiple failure modes, cover each one explicitly instead of
collapsing them into a single generic fix.

### Step 3 - Apply Version and Runtime Guards

Use `version-runtime-matrix.md` before recommending:
- `moved`, `import`, `removed`, `check`, mock providers, `write_only`
- S3 `use_lockfile`
- native `terraform test` / `tofu test`

If the runtime/version is unknown, state the assumption before suggesting
version-sensitive patterns.

### Step 4 - Run the LLM Mistake Checklist

Use `llm-mistake-checklist.md` before finalizing guidance that touches:
- resource identity or address changes
- secrets handling
- provider/runtime upgrades
- plan/apply workflow
- set-type assertions or computed values in tests

### Step 5 - Handoff to the Right Terraform Skill

This skill is the shared safety layer. It does not own implementation details.

Use:
- `design-aws-terraform-iac` for architecture, service boundaries, backend
  strategy, and acceptance criteria
- `create-terraform-module` for module layout, variables/outputs, examples, and
  implementation scaffolding
- `create-terraform-tests` for `terraform test`, fixtures, and risk-focused test
  coverage
- `terraform-infrastructure` for repo/stack structure, CI composition, and
  multi-region patterns
- `use-aws-mini-stack-emulator` for local AWS emulation limits and handoff to
  real-cloud validation
