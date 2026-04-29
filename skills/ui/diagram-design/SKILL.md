---
name: diagram-design
description: >
  Designs implementation-grounded architecture, sequence, and flow diagrams from
  existing code and documentation. Ensures notation is chosen intentionally,
  avoids invented components or flows, and explicitly flags mismatches across
  ADRs, RFCs, and code.
version: 1.0.0
tags:
  - ui
  - architecture
  - diagram
  - design
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Diagram Design Skill

### Step 1 — Inspect Source of Truth

Inspect implementation artifacts before drawing:
- Code structure and runtime boundaries (modules, routes, services, adapters).
- Existing docs (`README`, ADRs, RFCs, architecture docs, API contracts).
- Current terminology used by the codebase and product language.

Capture what is explicitly evidenced. If evidence is missing, mark it as unknown.

### Step 2 — Define Diagram Objective

State the single primary question the diagram must answer, such as:
- "How data moves from UI action to persistence."
- "Which components own state vs orchestration."
- "Where sync vs async boundaries are enforced."

Limit scope to one context per diagram to keep it reviewable.

### Step 3 — Choose Notation Intentionally

Select notation based on the objective:
- C4/container or component view for structural ownership and dependencies.
- Sequence diagram for request/response timing and actor interactions.
- Flow/state diagram for decision branches, retries, and error handling.

Document why this notation was chosen and why alternatives were not.

### Step 4 — Map Only Verified Components and Flows

Build the diagram strictly from verified artifacts:
- Use real component/service/module names from code/docs.
- Include only flows that can be traced to handlers, functions, contracts, or tests.
- Mark uncertain links as `Unknown` or `TBD (needs evidence)` instead of inventing paths.

Do not add speculative systems, side effects, queues, or external actors without evidence.

### Step 5 — Cross-Check ADR/RFC/Code Consistency

Validate consistency across design intent and implementation:
- ADR says X, code does Y.
- RFC flow omits a runtime guard present in code.
- Code introduces dependency or sync call not reflected in docs.

List mismatches explicitly with:
- Source reference (ADR/RFC filename or code path).
- Observed conflict.
- Impact (correctness, performance, operability, ownership).

### Step 6 — Deliver Diagram + Review Notes

Provide:
- The diagram artifact (Mermaid/PlantUML/ASCII/Figma structure as requested).
- A short legend for symbols and boundaries.
- Assumptions and unknowns.
- Mismatch log with recommended follow-up actions (doc update, ADR amendment, refactor).
