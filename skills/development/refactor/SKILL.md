---
name: refactor
description: >
  Refactors specified code to improve clarity, reduce duplication, or align with
  the project's architectural patterns — without changing external behavior.
  Invoked when the user asks to refactor, clean up, simplify, or restructure code.
version: 1.0.0
tags:
  - refactoring
  - quality
  - design
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Refactor Skill

Improve the code structure without changing external behavior.

### Step 1 — Understand the Goal

Ask or infer:
- What is wrong with the current code? (too long, duplicated, wrong layer, hard to test)
- What is the desired outcome? (extracted function, renamed variable, moved to correct layer)
- Are there tests in place? (if not, write characterization tests before refactoring)

### Step 2 — Establish a Safety Net

Before changing anything, verify tests exist that cover the code being refactored.
If tests are missing, write characterization tests first:
- A characterization test captures *current* behavior (even if the behavior is wrong).
- It prevents accidental behavior changes during refactoring.

### Step 3 — Apply Refactoring in Small Steps

Work in small, safe increments. After each step, verify tests still pass:

Common refactoring moves:
- **Extract function/method**: identify a coherent chunk of logic with a clear purpose.
- **Rename**: choose a name that accurately describes the thing at the current abstraction level.
- **Move to correct layer**: domain logic in a controller → move to use case or domain service.
- **Replace conditional with polymorphism**: complex switch/if chains on type → strategy pattern.
- **Introduce value object**: raw primitive used to represent a domain concept → wrap it.
- **Remove duplication**: extract shared logic to a shared function; do not abstract prematurely.

### Step 4 — Verify Behavior is Unchanged

After refactoring:
- All tests pass.
- The public API (exported signatures) is unchanged.
- No new dependencies introduced.

### Step 5 — Summarize

```
## Refactor Summary

**What changed**: [List of moves applied]
**Why**: [The design problem that was addressed]
**Tests**: [Pass / added N new characterization tests]
**Breaking changes**: None (internal only)
```
