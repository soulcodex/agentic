---
name: add-tests
description: >
  Generates tests for existing code. Analyzes the target function, method, or class
  to identify the happy path, error cases, and edge cases, then writes test cases
  following the project's testing framework and naming conventions.
  Invoked when the user asks to add tests, write tests, cover code, or increase coverage.
version: 1.0.0
tags:
  - testing
  - quality
  - tdd
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Add Tests Skill

Generate comprehensive tests for the specified code.

### Step 1 — Read the Target Code

Read the file(s) the user specifies. If no file is specified, ask which code to test.

Identify:
- The public API (exported functions, public methods)
- Dependencies (what should be mocked vs real)
- Return types and error types
- Preconditions and postconditions

### Step 2 — Identify Test Cases

For each public function/method, identify:

**Happy path**
- Standard input → expected output

**Error cases**
- Invalid input → expected error
- Dependency failure → expected error propagation

**Edge cases**
- Empty collections, zero values, null/undefined
- Boundary values (min, max)
- Concurrent access (if applicable)

### Step 3 — Write the Tests

Follow the project's existing test file conventions:
- Use the same test framework already in use (detect from package.json / go.mod / pyproject.toml)
- Mirror the source file structure: `user-service.ts` → `user-service.test.ts`
- Use AAA structure (Arrange / Act / Assert)
- Name tests as behavior descriptions: `it("returns null when user is not found")`

Each test must:
- Cover exactly one behavior
- Be deterministic (freeze time, mock randomness)
- Clean up any side effects

### Step 4 — Output

Write the test file. If it already exists, add the new test cases without breaking existing ones.

After writing, list the test cases added and any coverage gaps that remain.
