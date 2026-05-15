---
name: design-aws-terraform-iac
description: >
  Designs AWS-targeted Terraform infrastructure plans before implementation.
  Focuses on service selection, module boundaries, state/backends, environment
  separation, security/compliance guardrails, and acceptance criteria.
version: 1.0.0
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

### Step 1 - Confirm Scope and Constraints

Capture required outcomes:
- workloads and critical paths
- regions, environments, and compliance constraints
- cost boundaries and availability targets

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
- remote backend (`s3` + `dynamodb` locking)
- state key strategy per environment and region
- promotion model (`dev` -> `staging` -> `prod`)
- drift and rollback expectations

### Step 4 - Define Security and Policy Baselines

Specify minimum required controls:
- IAM least privilege for CI and runtime roles
- encryption at rest and in transit
- tag standards for ownership, cost, and data classification
- log/audit coverage and retention

### Step 5 - Produce a Design Brief and Acceptance Criteria

Output a compact design brief with:
- service choices and tradeoffs
- module map and dependency order
- state strategy and CI plan/apply gate strategy
- measurable acceptance checks from `acceptance-checklist.md`

This skill is planning-first. For module file layout and implementation details,
use `create-terraform-module`. For test strategy and `terraform test` patterns,
use `create-terraform-tests`.
