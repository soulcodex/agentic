## Vue 3 Testing Strategy

### Three-Tier Test Taxonomy

| Tier | Tool | What belongs here |
|------|------|------------------|
| Unit | Vitest (no DOM) | Pure functions, composables, Pinia store actions/getters, formatters, validators |
| Component | Vitest + @testing-library/vue | Single component DOM/behaviour, user interactions, emitted events, slot rendering |
| E2E / Acceptance | Playwright | Full user flows, page navigation, real or mocked backend, a11y |

### Composable Unit Testing

Import the composable and call it directly — no component wrapper needed for pure composables. If the composable uses a Pinia store, initialise a test Pinia first.

```ts
import { setActivePinia, createPinia } from 'pinia'
import { describe, it, expect, beforeEach } from 'vitest'
import { useCounter } from './useCounter'

beforeEach(() => { setActivePinia(createPinia()) })

it('returns initial count of 0', () => {
  const { count } = useCounter()
  expect(count.value).toBe(0)
})

it('increments count', () => {
  const { count, increment } = useCounter()
  increment()
  expect(count.value).toBe(1)
})
```

### Pinia Store Testing

Use `setActivePinia(createPinia())` in `beforeEach` — always reset between tests. Test actions by calling them directly and asserting state changes. Test getters by setting state and asserting getter output.

```ts
import { setActivePinia, createPinia } from 'pinestest'
import { describe, it, expect, beforeEach } from 'vitest'
import { useCartStore } from './cart.store'

let store: ReturnType<typeof useCartStore>

beforeEach(() => {
  setActivePinia(createPinia())
  store = useCartStore()
})

it('addItem increases item count', async () => {
  await store.addItem({ id: '1', name: 'Widget', price: 9.99 })
  expect(store.items.length).toBe(1)
})

it('total getter sums prices', () => {
  store.$patch({ items: [{ id: '1', name: 'W', price: 10 }, { id: '2', name: 'X', price: 5 }] })
  expect(store.total).toBe(15)
})
```

### Component Testing with @testing-library/vue

Prefer `@testing-library/vue` over raw `@vue/test-utils` for user-centric assertions (`getByRole`, `findByText`). Use `@vue/test-utils` when you need to assert emitted events, inspect specific component output, or work with slots.

Mount the real component (not shallow) unless the child is a heavy external library. Use `createTestingPinia()` from `@pinia/testing` to stub store actions.

```ts
import { render, screen, fireEvent } from '@testing-library/vue'
import { createTestingPinia } from '@pinia/testing'
import { describe, it, expect, vi } from 'vitest'
import BaseButton from './BaseButton.vue'

const mockTrack = vi.fn()
vi.mock('./analytics', () => ({ track: mockTrack }))

it('emits click and tracks analytics', async () => {
  render(BaseButton, {
    props: { label: 'Submit' },
    global: { plugins: [createTestingPinia()] },
  })
  await fireEvent.click(screen.getByRole('button', { name: 'Submit' }))
  expect(mockTrack).toHaveBeenCalledWith('button_click', expect.any(Object))
})
```

### What NOT to Test

- Internal `ref` values and private composable state
- CSS classes (assert behaviour, not styling)
- Snapshot blobs of entire component HTML — use targeted assertions
- Implementation details that can change without breaking behaviour

### Acceptance Testing — Component Level

Use Playwright component testing (`@playwright/experimental-ct-vue`) for cross-browser component acceptance tests. Write acceptance tests in Given/When/Then language.

Place in `tests/acceptance/*.acceptance.spec.ts` or mark with `.acceptance.spec.ts` suffix — separate from unit tests.

```ts
// tests/acceptance/Modal.acceptance.spec.ts
import { test, expect } from '@playwright/test'

test('modal opens and displays content', async ({ mount }) => {
  const onClose = async () => {}
  const component = await mount(Modal, { props: { onClose, isOpen: true } })

  await expect(component.getByRole('dialog')).toBeVisible()
  await expect(component.locator('.modal-body')).toContainText('Confirm action')
})
```
