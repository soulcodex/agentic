---
name: vue-component-testing
description: >
  Applies the three-tier test taxonomy for Vue 3 applications: writes unit tests for
  composables and Pinia stores with Vitest, component tests for behaviour and user
  interactions with @testing-library/vue, and acceptance tests for full user flows
  with Playwright. Ensures tests focus on observable behaviour, not implementation
  details. Invoked when adding or reviewing tests for a Vue project.
version: 1.0.0
tags:
  - ui
  - vue
  - testing
  - vitest
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Vue Component Testing Skill

### Step 1 — Classify What Needs to Be Tested

For each piece of code, assign a test tier:

- **Composable / store action / pure function** → Unit test (Vitest, no DOM)
- **Component behaviour / user interaction / emitted events** → Component test (@testing-library/vue + Vitest)
- **User flow across pages / real navigation** → E2E (Playwright)

List all files in scope and assign each a tier before writing any tests.

### Step 2 — Write Unit Tests (Composables and Stores)

- **Composable**: import and call directly, assert returned refs/computed values. Use `setActivePinia(createPinia())` in `beforeEach` if the composable accesses a store.
- **Store**: `setActivePinia(createPinia())` in `beforeEach`, call actions directly, assert state. Test getters by patching state.
- No DOM, no component mounting — pure JS/TS only.

```ts
import { setActivePinia, createPinia } from 'pinia'
import { beforeEach, describe, expect, it } from 'vitest'
import { useAuthStore } from './auth.store'

let store: ReturnType<typeof useAuthStore>
beforeEach(() => { setActivePinia(createPinia()); store = useAuthStore() })

it('login sets user', async () => {
  await store.login({ email: 'a@b.com', password: 'secret' })
  expect(store.user).not.toBeNull()
})
```

### Step 3 — Write Component Tests

- Use `@testing-library/vue` for user-centric assertions: `getByRole`, `findByText`, `userEvent`.
- Use `@vue/test-utils` when asserting emitted events, inspecting component output, or working with slots.
- Use `createTestingPinia()` from `@pinia/testing` to stub store actions.
- Mount the real component (not shallow) unless the child is a heavy external library.
- Assert: what the user sees (text, roles, visibility), which events are emitted, which store actions are called.
- Do NOT assert: internal refs, CSS classes, snapshot blobs.

```ts
import { render, screen, fireEvent } from '@testing-library/vue'
import { createTestingPinia } from '@pinia/testing'
import { describe, expect, it, vi } from 'vitest'
import BaseButton from './BaseButton.vue'

const mockTrack = vi.fn()
vi.mock('./analytics', () => ({ trackEvent: mockTrack }))

it('tracks click event on button press', async () => {
  render(BaseButton, {
    props: { label: 'Save' },
    global: { plugins: [createTestingPinia()] },
  })
  await fireEvent.click(screen.getByRole('button', { name: 'Save' }))
  expect(mockTrack).toHaveBeenCalledWith('button_click', expect.any(Object))
})
```

### Step 4 — Write Acceptance Tests (Component Level)

- Use Playwright component testing (`@playwright/experimental-ct-vue`) for cross-browser component acceptance tests.
- Write in Given/When/Then language: "Given a user is on the login page, when they submit invalid credentials, then an error message is displayed."
- Test the full component contract from a user perspective: inputs → visible output.
- Place in `tests/acceptance/*.acceptance.spec.ts` — separate from unit and component tests.

```ts
// tests/acceptance/LoginForm.acceptance.spec.ts
import { test, expect } from '@playwright/test'

test('shows error on invalid credentials', async ({ mount }) => {
  const component = await mount(LoginForm, { props: { onSuccess: () => {} } })

  await component.getByPlaceholder('Email').fill('bad@example.com')
  await component.getByPlaceholder('Password').fill('wrong')
  await component.getByRole('button', { name: 'Sign in' }).click()

  await expect(component.locator('.error-message')).toContainText('Invalid credentials')
})
```

### Step 5 — Verify

- [ ] Each composable has at least one unit test
- [ ] Each Pinia store has unit tests for actions and getters
- [ ] Each interactive component has component tests for its primary interactions
- [ ] No test asserts internal implementation details (refs, private state, CSS classes)
- [ ] `pnpm test` passes with zero failures
