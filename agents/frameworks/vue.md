## Vue 3

### Syntax & Component Style

- `<script setup>` is the only accepted syntax — never use the Options API or the classic `export default {}` form.
- All components are single-file components (`.vue`). One component per file; file name matches the exported component name in PascalCase.
- Extract reusable stateful logic into composables (`use*.ts`), not mixins. Mixins are banned.

### Props & Emits

- Declare props with `defineProps<Props>()` for full TypeScript type inference — no runtime-only definitions.
- Declare emits with `defineEmits<{ (e: 'change', value: string): void }>()` (typed form).
- Props are read-only inside the child. Never mutate a prop; emit an event instead.

### State Management

- **Local state**: `ref()` for primitives, `reactive()` for objects (prefer `ref` — it is more explicit).
- **Computed values**: `computed()`. Never derive state in a method that runs on every render.
- **Shared/global state**: Pinia. One store per domain concept (`useCartStore`, `useAuthStore`).
  - Stores are defined with `defineStore`. Use the Setup Store form (function syntax) — not the Options Store form.
  - Actions are plain functions inside the store; they may be async.
  - Never access store internals from outside — always call actions and read state through the store ref.

### Reactivity Pitfalls

- Do **not** destructure reactive objects — reactivity is lost: `const { count } = reactive(state)` breaks.
- Use `toRefs(state)` when you need to destructure and keep reactivity.
- Avoid mutating arrays by index (`arr[0] = x`) inside reactive state; use `.splice()` or replace the ref value.
- `watch` vs `watchEffect`: prefer `watchEffect` for side effects that depend on reactive data; use `watch` when you need the previous value or explicit source control.

### Templates

- Keep templates declarative and free of business logic. Move non-trivial expressions into `computed` properties.
- Use `v-bind="$attrs"` intentionally on root element when building wrapper components (and set `inheritAttrs: false`).
- Avoid `v-html` — XSS risk. Only use it with sanitized, trusted content.
- Always provide a `key` attribute on `v-for` items (use a stable ID, not the array index).

### Testing

- Unit test composables and stores independently using Vitest.
- Test components with `@vue/test-utils`. Prefer `mount` over `shallowMount` unless child component rendering is irrelevant to the test.
- Use `flushPromises()` from `@vue/test-utils` after async operations before asserting DOM state.
- Do not test implementation details (internal refs, private methods). Test observable behavior.
