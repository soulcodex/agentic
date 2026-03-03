---
name: vue-application-structure
description: >
  Establishes or reviews the directory layout, component conventions, composable
  design, Pinia store structure, and Vue Router configuration for a Vue 3
  TypeScript application. Invoked when the user asks to structure a Vue app,
  set up the project layout, or review Vue architecture.
version: 1.0.0
tags:
  - ui
  - vue
  - typescript
  - pinia
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Vue Application Structure Skill

### Step 1 — Directory Layout (Feature-Based)

Organise by feature, not by file type. Co-locate everything a feature needs:

```
src/
  features/
    auth/
      AuthLoginForm.vue
      useAuth.ts          ← composable
      auth.store.ts       ← Pinia store
      auth.types.ts
      auth.api.ts         ← HTTP calls
  components/             ← shared/generic UI components
    BaseButton.vue
    TheNavbar.vue
  composables/            ← shared composables used across features
    useBreakpoint.ts
  router/
    index.ts
    guards.ts
  stores/                 ← global stores (not feature-specific)
    ui.store.ts
  lib/                    ← utilities, formatters, constants
  assets/
  App.vue
  main.ts
```

### Step 2 — Composition API Conventions

- Use `<script setup lang="ts">` exclusively — no Options API, no `defineComponent`.
- Declare `defineProps` and `defineEmits` with TypeScript interfaces, not runtime validators.
- Keep template logic minimal — extract complex expressions into `computed` refs or composables.

```vue
<script setup lang="ts">
interface Props {
  userId: string
  readonly?: boolean
}
const props = withDefaults(defineProps<Props>(), { readonly: false })
const emit = defineEmits<{ saved: [userId: string] }>()
</script>
```

### Step 3 — Composable Design

- Name composables with the `use` prefix: `useAuth`, `useCart`, `useDebounce`.
- Each composable has a **single responsibility**.
- Return reactive state and actions from a composable; do not mutate props.
- Composables that wrap a Pinia store should not duplicate store state — return
  store refs directly.

```ts
// composables/useDebounce.ts
export function useDebounce<T>(value: Ref<T>, delay: number): Readonly<Ref<T>> {
  const debounced = ref<T>(value.value) as Ref<T>
  watchEffect(() => {
    const timer = setTimeout(() => { debounced.value = value.value }, delay)
    return () => clearTimeout(timer)
  })
  return readonly(debounced)
}
```

### Step 4 — Pinia Store Design

- **One store per domain** (auth, cart, notifications). Do not create a single
  monolithic store.
- Use the **setup store** syntax (returns reactive state + actions, full TypeScript support).
- Keep side effects (API calls) inside actions, not in the template or composables.

```ts
// features/auth/auth.store.ts
export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const isAuthenticated = computed(() => user.value !== null)

  async function login(credentials: Credentials) {
    user.value = await authApi.login(credentials)
  }

  return { user, isAuthenticated, login }
})
```

### Step 5 — Vue Router

- Use **typed routes** (`vue-router` 4.x + `unplugin-vue-router` or manual `RouteNamedMap`).
- Use `defineRoute` or name constants for route names — never inline string names in code.
- Lazy-load page-level components: `component: () => import('./views/HomePage.vue')`.
- Put navigation guards in `router/guards.ts`, not inline in route definitions.

```ts
// router/index.ts
{ path: '/dashboard', component: () => import('@/features/dashboard/DashboardPage.vue'),
  meta: { requiresAuth: true } }
```

### Step 6 — Component Conventions

| Rule | Example |
|------|---------|
| PascalCase filenames | `UserProfileCard.vue` |
| `Base` prefix for generic UI | `BaseButton.vue`, `BaseModal.vue` |
| `The` prefix for singletons | `TheNavbar.vue`, `TheFooter.vue` |
| Feature prefix for feature components | `AuthLoginForm.vue` |
| No abbreviations in names | `UserProfileCard` not `UsrProfCard` |

### Step 7 — Verify

Run the TypeScript compiler — no type errors allowed:

```bash
pnpm tsc --noEmit
```

- [ ] All components use `<script setup lang="ts">`.
- [ ] No Options API usage.
- [ ] Pinia stores use setup-store syntax.
- [ ] Router uses lazy-loaded page components.
- [ ] `pnpm tsc --noEmit` passes with zero errors.
