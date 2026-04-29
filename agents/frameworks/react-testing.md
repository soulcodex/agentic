## React 19 Testing Strategy

### Three-Tier Test Taxonomy

| Tier | Tool | What belongs here |
|------|------|------------------|
| Unit | Vitest/Jest (no DOM) | Pure functions, reducers, mappers, validators, custom hook logic with mocked adapters |
| Component | Testing Library + Vitest/Jest | DOM behavior, accessibility roles, user interactions, form states, conditional rendering |
| E2E / Acceptance | Playwright | Full user flows, routing transitions, auth gates, integration with backend or API mocks |

### Testing Philosophy

- Test observable behavior, not implementation details.
- Prefer user-centric queries (`getByRole`, `getByLabelText`, `findByText`) over brittle selectors.
- Use one assertion block per behavior and keep tests intention-revealing.
- Mock network boundaries, not internal component methods.

### Component Tests

- Render real components; avoid shallow rendering.
- Drive interactions with `@testing-library/user-event`.
- Assert loading, success, empty, and error states for data-driven components.
- Verify keyboard behavior for interactive components.

```ts
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect } from 'vitest'
import { SearchForm } from '<alias>/components/SearchForm'

it('submits query from form', async () => {
  const user = userEvent.setup()
  const onSubmit = vi.fn()

  render(<SearchForm onSubmit={onSubmit} />)

  await user.type(screen.getByLabelText('Search'), 'react')
  await user.click(screen.getByRole('button', { name: 'Submit' }))

  expect(onSubmit).toHaveBeenCalledWith('react')
})
```

### Hook and Reducer Tests

- Test reducers as pure functions with explicit action/state tables.
- Test hooks through a small harness component or `renderHook` utility.
- Reset shared state between tests.
- Assert cleanup behavior for hooks with subscriptions or timers.

### What Not to Test

- Internal state variable names.
- CSS class implementation details unless class changes are the behavior.
- Large snapshots of full markup trees.
- Third-party library internals.

### Coverage Priorities

- Prioritize critical flows: auth, checkout/submission, permission-gated actions, data mutation paths.
- Include at least one test per component state branch.
- Add regression tests for every production bug fix.
