---
name: technical-roadmap-planning
description: >
  Gathers inputs, defines initiatives, prioritises with an impact/effort matrix,
  sequences dependencies, and produces a roadmap table. Invoked when the user
  asks to plan a technical roadmap, prioritise engineering initiatives, or create
  a quarter/half-year engineering plan.
version: 1.0.0
tags:
  - planning
  - roadmap
  - strategy
  - backend
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Technical Roadmap Planning Skill

### Step 1 — Gather Inputs

Before defining initiatives, collect:
- **Business objectives** for the period (OKRs, product strategy, growth targets).
- **Tech debt inventory** — known architectural problems, reliability gaps, security risks.
- **Reliability data** — incident history, SLA breaches, on-call burden.
- **Team capacity** — headcount, planned leave, hiring timeline.
- **Dependencies** — migrations, third-party deprecations, compliance deadlines.

Ask the user to provide or confirm these inputs before proceeding.

### Step 2 — Define Initiatives

For each initiative, capture:

```
Initiative: <name>
Problem:    <what is broken or missing — one sentence>
Metric:     <how success is measured — must be quantifiable>
Effort:     <S | M | L | XL>  (S=days, M=weeks, L=1-2 months, XL=quarter+)
Impact:     <Low | Medium | High | Critical>
Dependencies: <other initiatives or teams this blocks or is blocked by>
```

Example:
```
Initiative: Database connection pooling
Problem:    Under peak load, the API exhausts the DB connection limit, causing 503s.
Metric:     Zero connection-limit errors in staging load test at 2× current peak traffic.
Effort:     S
Impact:     High
Dependencies: None
```

### Step 3 — Prioritise (Impact / Effort Matrix)

Plot each initiative on a 2×2 grid and apply the priority rules:

```
Impact
  High │ Quick Wins ★ │ Strategic Bets ◆
       │ (do now)     │ (plan carefully)
       ├──────────────┼──────────────────
  Low  │ Fill-ins     │ Avoid / defer
       │ (if capacity)│
       └──────────────┴────────────────
          Low Effort      High Effort
```

| Priority | Quadrant | Action |
|----------|---------|--------|
| 1 | High Impact + Low Effort | Schedule immediately |
| 2 | High Impact + High Effort | Plan with milestones |
| 3 | Low Impact + Low Effort | Fill between larger items |
| 4 | Low Impact + High Effort | Defer or remove |

Mark compliance/security items as **non-negotiable** regardless of quadrant.

### Step 4 — Sequence

Apply dependency ordering:
- Initiatives with no dependencies come first.
- Identify the **critical path**: the longest chain of dependent initiatives.
- Avoid starting more than 2 large initiatives in parallel (context switching cost).

### Step 5 — Milestone Definition

Break each Large or XL initiative into milestones with binary (done/not-done)
completion criteria:

```
Initiative: Event-driven order processing
Milestone 1: Outbox pattern implemented and tested in staging        — Week 2
Milestone 2: Consumer deployed; order events flowing in staging       — Week 4
Milestone 3: Production rollout complete; legacy sync path removed    — Week 6
```

### Step 6 — Output: Roadmap Table

Produce the roadmap in this format:

```markdown
## Technical Roadmap — Q2 2025

| # | Initiative | Impact | Effort | Owner | Target | Status |
|---|-----------|--------|--------|-------|--------|--------|
| 1 | DB connection pooling | High | S | Platform | Week 1 | Planned |
| 2 | Event-driven orders | High | L | Backend | Week 6 | Planned |
| 3 | Remove legacy auth | Medium | M | Backend | Week 4 | Planned |
| 4 | Upgrade Go 1.23 | Low | S | Platform | Week 2 | Planned |

### Dependencies
- Item 3 (Remove legacy auth) is blocked by item X (New auth rollout, owned by product).

### Risks
- Item 2 requires DB schema changes; coordinate with DBA team.

### Out of Scope This Quarter
- GraphQL federation migration (deferred to Q3 — too high effort)
```
