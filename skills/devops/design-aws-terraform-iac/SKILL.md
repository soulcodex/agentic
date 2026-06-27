---
name: design-aws-terraform-iac
description: >
  Designs AWS-targeted Terraform infrastructure plans before implementation.
  Focuses on service selection, module boundaries, state/backends, environment
  separation, security/compliance guardrails, acceptance criteria, and explicit
  risk/validation assumptions.
version: 1.1.0
tags:
  - devops
  - terraform
  - aws
  - iac
  - architecture
resources:
  - aws-service-matrix.md
  - acceptance-checklist.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Design AWS Terraform IaC Skill

Design AWS Terraform infrastructure before writing module code.

Always pair this skill with `terraform-risk-playbook`. That skill is
authoritative for the response contract, failure-mode classification,
version/runtime guards, validation chain, and rollback notes.

### Step 1 - Confirm Scope and Constraints

Capture required outcomes:
- workloads and critical paths
- regions, environments, and compliance constraints
- cost boundaries and availability targets
- runtime and version assumptions
- backend and execution path assumptions (local, CI, Terraform Cloud, Atlantis)

Capture non-goals to prevent accidental over-design.

### Step 2 - Map Services and Responsibility Boundaries

Use `aws-service-matrix.md` to map each capability to:
- primary AWS service(s)
- related Terraform module boundary
- key operational risks and ownership notes

Design composable modules with explicit interfaces between network, security,
platform, and workload layers.

### Step 3 - Define State and Environment Strategy

Decide and document:
- remote backend (prefer `s3` with `use_lockfile = true`; use DynamoDB locking
  only as a temporary compatibility bridge for older Terraform workflows)
- state key strategy per environment and region
- promotion model (`dev` -> `staging` -> `prod`)
- drift and rollback expectations
- explicit handling for sensitive values in state and plans

### Step 4 - Define Security and Policy Baselines

Specify minimum required controls:
- IAM least privilege for CI and runtime roles
- encryption at rest and in transit
- tag standards for ownership, cost, and data classification
- log/audit coverage and retention
- secret source-of-truth and rotation boundary (for example, Secrets Manager
  references rather than plaintext values in variables)

### Step 5 - Produce a Design Brief and Acceptance Criteria

Output a compact design brief with:
- service choices and tradeoffs
- module map and dependency order
- state strategy and CI plan/apply gate strategy
- explicit risk categories and validation expectations
- rollback notes for destructive or state-mutating steps
- measurable acceptance checks from `acceptance-checklist.md`

This skill is planning-first. For module file layout and implementation details,
use `create-terraform-module`. For test strategy and `terraform test` patterns,
use `create-terraform-tests`.
