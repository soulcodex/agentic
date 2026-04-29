---
name: react-component-testing
description: >
  Applies the three-tier test taxonomy for React applications: unit tests for
  hooks and pure logic, component tests for behavior and interactions, and end-to-end
  tests for user flows. Uses Vitest, React Testing Library, and Playwright while
  focusing on observable behavior over implementation details.
version: 1.0.0
tags:
  - ui
  - react
  - testing
  - vitest
resources:
  - resources/testing-matrix.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## React Component Testing Skill

### Step 1 — Classify What Needs to Be Tested

Assign each file to a test tier before writing tests:

- Hook / reducer / pure function -> unit test.
- Component behavior / interaction -> component test.
- Multi-page user flow -> end-to-end test.

### Step 2 — Write Unit Tests

- Test hooks with `renderHook` and explicit inputs.
- Test reducers and utilities as pure functions.
- Mock network boundaries; do not mount full UI.

```ts
import { describe, expect, it } from 'vitest'
import { authReducer } from './auth.reducer'

it('sets user on login success', () => {
  const state = authReducer({ user: null }, { type: 'login/success', payload: { id: '1' } })
  expect(state.user?.id).toBe('1')
})
```

### Step 3 — Write Component Tests

- Use React Testing Library queries by role/label/text.
- Use `userEvent` for interactions, not low-level DOM event simulation unless necessary.
- Wrap with providers used in production (router, query client, store) via a shared test render utility.
- Assert user-visible output and callback side effects.
- In TypeScript projects, keep TS/JS imports ESM-only and use aliases for cross-directory imports.

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { SaveButton } from './SaveButton'

it('calls onSave when clicked', async () => {
  const onSave = vi.fn()
  render(<SaveButton onSave={onSave} />)
  await userEvent.click(screen.getByRole('button', { name: 'Save' }))
  expect(onSave).toHaveBeenCalledTimes(1)
})
```

### Step 4 — Write End-to-End Tests

- Use Playwright for full browser flows across routes.
- Cover one happy path and key failure path for each critical user journey.
- Keep E2E focused on integration risks, not exhaustive branch coverage.

### Step 5 — Verify

- [ ] Each custom hook has unit tests for success and edge behavior
- [ ] Interactive components test primary user interactions
- [ ] No tests assert private state or implementation-only details
- [ ] Critical journeys have Playwright coverage (happy path + failure path)
- [ ] `pnpm test` passes with zero failures
