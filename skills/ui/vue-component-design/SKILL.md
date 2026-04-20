---
name: vue-component-design
description: >
  Designs or reviews Vue 3 component APIs. Handles prop drilling decisions,
  applies compound component patterns with provide/inject, defines minimal public
  API surfaces with typed props/emits/slots, and enforces Vue 3.4+ composition
  conventions. Invoked when creating new components, refactoring existing ones,
  or reviewing component contracts.
version: 1.0.0
tags:
  - ui
  - vue
  - typescript
  - composition
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Vue Component Design Skill

### Step 1 — Identify the Component's Responsibility

Determine the component type before designing the API:

- **Page component** — orchestrates data fetching, permissions, and layout. Coordinates child components. Tests: mock data fetching, verify correct children are rendered.
- **Feature component** — contains feature-specific business logic and local state. May call store actions. Tests: mock store, assert state changes.
- **UI component** — pure presentational, props + slots only, no async logic, no store access. Tests: assert correct markup for given props.

### Step 2 — Design the Public API Surface

- **Props**: minimal, typed with TypeScript interfaces, `withDefaults` for optional props with safe defaults.
- **Emits**: typed `defineEmits<{ eventName: [payload] }>()` — one event per user action.
- **Slots**: default for content, named for layout regions, scoped when parent needs child-provided state.
- **`expose()`**: only for imperative handles (focus, open, reset) — never expose internal state.
- Use `defineModel<T>()` (Vue 3.4+) for two-way binding instead of `modelValue` + `update:modelValue`.

### Step 3 — Evaluate Prop Drilling Depth

Count how many component levels the data crosses:

- **1–2 levels** → props are acceptable
- **3+ levels** through components that do not use the data → refactor to `provide`/`inject` with typed Symbol keys
- **Global / cross-feature / persisted** → Pinia store

```ts
// keys.ts
import type { InjectionKey } from 'vue'

export const AccordionKey: InjectionKey<{
  openId: Readonly<Ref<string | null>>
  toggle: (id: string) => void
}> = Symbol('accordion')
```

### Step 4 — Composition Review

- Does the component do too much? Apply single responsibility: extract orchestration logic into a composable, keep the template as a thin consumer.
- Are slots used where a child component should receive data and render itself? Prefer scoped slots over prop-drilling display logic.
- Is `<Teleport>` needed? Use for modals, toasts, and dropdowns that must escape their stacking context.

### Step 5 — Verify

- [ ] No props passed through more than 2 intermediate components that do not use them
- [ ] `defineModel()` used instead of manual `modelValue` + `update:modelValue` pattern
- [ ] Provide/inject keys are typed Symbols, not plain strings
- [ ] `expose()` only used for imperative handles (never internal state)
- [ ] UI components contain no async logic or store access
- [ ] `pnpm tsc --noEmit` passes with no errors
