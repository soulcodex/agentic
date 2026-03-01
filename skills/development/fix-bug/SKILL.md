---
name: fix-bug
description: >
  Investigates and fixes a reported bug. Reads relevant code, identifies the root cause,
  proposes a fix, and adds or updates tests to prevent regression.
  Invoked when the user describes unexpected behavior, an error, a crash, or a failing test.
version: 1.0.0
tags:
  - debugging
  - fix
  - quality
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Fix Bug Skill

Investigate and fix the reported bug systematically.

### Step 1 — Understand the Bug

Gather:
- What is the expected behavior?
- What is the actual behavior?
- How is it reproduced? (steps, input, environment)
- Is there an error message, stack trace, or failing test?

If this information is missing, ask the user before proceeding.

### Step 2 — Locate the Root Cause

Read the relevant code:
1. Start at the reported error location or the code path described in reproduction steps.
2. Trace upward through callers to understand context.
3. Trace downward through callees to understand what data flows in.
4. Look for: off-by-one, null dereference, wrong conditional, missing error handling,
   incorrect assumption about external behavior, race condition.

State the root cause explicitly before writing any fix:
> "Root cause: The `findUser` function assumes the result is never null, but the database
> returns null when no row matches. The null propagates to `user.email` access, causing
> the crash."

### Step 3 — Write a Failing Test First (if no test exists)

Before fixing, write a test that reproduces the bug and currently fails.
This proves you understand the bug and prevents regression.

### Step 4 — Fix

Apply the minimal fix that addresses the root cause. Do not refactor surrounding code
unless it is directly related to the bug.

### Step 5 — Verify

Run the test written in Step 3 — it must now pass.
Run the full test suite — no regressions introduced.

### Step 6 — Summarize

Output:
```
## Bug Fix Summary

**Root cause**: [One sentence]
**Fix**: [What was changed and why]
**Test added**: [File and test name]
**Regression risk**: [None / Low / Medium — explain if not None]
```
