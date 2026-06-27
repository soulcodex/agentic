---
name: use-aws-mini-stack-emulator
description: >
  Uses lightweight AWS stack emulation for faster local Terraform iteration.
  Defines what can be safely validated locally, compatibility caveats, and the
  handoff boundary to real-AWS verification and reviewed plan/apply flows.
version: 1.1.0
tags:
  - devops
  - terraform
  - aws
  - local-testing
resources:
  - emulator-compatibility-matrix.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Use AWS Mini Stack Emulator Skill

Use local AWS emulation to accelerate Terraform feedback loops where appropriate.

Always pair this skill with `terraform-risk-playbook`. That skill is
authoritative for the response contract, failure-mode classification,
version/runtime guards, validation chain, and rollback notes.

### Step 1 - Select Emulator Scope

Use `emulator-compatibility-matrix.md` to decide what is safe to validate locally.

Classify each planned check as:
- emulator-suitable
- partial confidence only
- requires real AWS

### Step 2 - Configure Provider and Endpoints for Local Runs

Keep local endpoint wiring isolated from production configuration. Use explicit
variables or per-environment override files for emulator endpoint settings.
Use local state or `terraform init -backend=false` for emulator-first CI checks
to avoid touching shared remote backends.

### Step 3 - Validate Fast Feedback Cases

Good emulator targets:
- syntax and interpolation mistakes
- module wiring and basic dependencies
- selected resource contract checks where behavior is reliably emulated

### Step 4 - Document Gaps and Escalate

Always document unsupported services/behaviors and escalate those tests to real
AWS validation before merge.

### Step 5 - Keep Scope Boundary Explicit

This skill is for local acceleration only. It does not replace real AWS plan/apply
verification for production-impacting infrastructure.

It cannot prove:
- production backend locking or state migration behavior
- IAM or service semantics that emulators do not model faithfully
- reviewed plan artifact and approval parity in CI
- final confidence for production-impacting provider/runtime upgrades

Avoid overlap with `docker-compose-local-setup`: this skill covers Terraform + AWS
emulation behavior, not generic multi-service compose orchestration design.
