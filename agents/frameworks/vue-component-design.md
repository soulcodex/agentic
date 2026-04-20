## Vue 3 Component Design

### Prop Drilling Prevention — Depth Rules

- **1–2 levels deep** — passing props is fine. Direct parent-to-child or parent-to-grandchild is acceptable.
- **3+ levels deep** — use `provide`/`inject` with typed Symbol keys. Never pass props through intermediate components that do not use the data.
- **Cross-feature, app-wide, or persisted state** — use a Pinia store.
- Prop drilling is a code smell when the intermediate components have no reason to know about the data. If the component doesn't use it, it shouldn't receive it.

### `defineModel()` (Vue 3.4+)

`defineModel<T>()` replaces the `modelValue` + `update:modelValue` pattern entirely. It returns a writable ref that you can bind with `v-model` in the parent.

Use it for custom inputs and form field wrappers.

```vue
<!-- Child: SearchInput.vue -->
<script setup lang="ts">
const modelValue = defineModel<string>({ default: '' })
</script>

<template>
  <input v-model="modelValue" placeholder="Search…" />
</template>
```

```vue
<!-- Parent -->
<SearchInput v-model="query" />
```

### Compound Components with `provide`/`inject`

Export injection keys as typed Symbols from a dedicated `keys.ts` file. This prevents typos and gives TypeScript accurate type inference.

```ts
// keys.ts
import type { InjectionKey } from 'vue'

export const TabsKey: InjectionKey<{
  activeTab: Readonly<Ref<string>>
  registerTab: (id: string) => void
  unregisterTab: (id: string) => void
}> = Symbol('tabs')
```

```vue
<!-- Tabs.vue — provides -->
<script setup lang="ts">
import { TabsKey } from './keys.ts'

const activeTab = ref('')
const tabs = ref<string[]>([])

function registerTab(id: string) { tabs.value.push(id) }
function unregisterTab(id: string) {
  tabs.value = tabs.value.filter(t => t !== id)
}

provide(TabsKey, { activeTab: readonly(activeTab), registerTab, unregisterTab })
</script>
```

```vue
<!-- Tab.vue — injects -->
<script setup lang="ts">
import { TabsKey } from './keys.ts'

const ctx = inject(TabsKey)!
// Call registerTab in onMounted, unregisterTab in onUnmounted
</script>
```

Never expose injection keys as plain strings — use typed Symbols.

### Component Public API Surface

Keep the surface minimal. Each element earns its place.

- **Props** — primary data and configuration. Use TypeScript interfaces, `withDefaults` for optionals.
- **Emits** — one typed event per user action: `defineEmits<{ saved: [id: string] }>()`
- **Slots** — prefer default + named slots over render-prop composables for visual composition. Use scoped slots when the parent needs child-provided state.
- **`expose()`** — only when consumers need imperative control (focus, open/close, reset). Never expose internal state.

```vue
<script setup lang="ts">
defineExpose({ focus, open, close })
</script>
```

```vue
<!-- Consumer -->
<Modal ref="modal" />
<!-- later: modal.open() -->
```

### `<Teleport>` for Overlay Elements

Use `<Teleport to="body">` for modals, toasts, and dropdowns that must escape their stacking context. Always wrap in `v-if` so the element is not rendered until needed.

```vue
<Teleport to="body">
  <div v-if="isOpen" class="modal-backdrop" @click.self="close">
    <div class="modal-content">
      <slot />
    </div>
  </div>
</Teleport>
```

Pitfall: avoid teleporting large, stateful trees. Preserve focus management for accessibility.

### Event Bus Is Banned

Do not use mitt or any event bus for domain logic. The correct replacements are:

- **Pinia actions** — for domain events and shared state
- **Direct prop/emit** — for parent-child communication
- **`provide`/`inject`** — for component families

mitt is acceptable only for decoupling ephemeral UI events between unrelated UI components that cannot share a store.

### Performance — Reactive Data Discipline

- **`shallowRef`** — for large datasets (maps, arrays of hundreds of items) that do not need deep reactivity tracking.
- **`markRaw`** — for third-party library instances (chart libraries, WebSocket clients, canvas objects) that must not be proxied.
- **`v-memo="[dep1, dep2]"`** — on expensive list items to skip re-renders when the listed dependencies have not changed.
- Never use `reactive()` for large immutable datasets.
