---
name: react-component-design
description: >
  Designs or reviews React component APIs. Handles prop drilling decisions,
  composition patterns, controlled/uncontrolled contracts, and minimal public
  API surfaces for React 18+ TypeScript components. Invoked when creating new
  components, refactoring existing ones, or reviewing component contracts.
version: 1.0.0
tags:
  - ui
  - react
  - typescript
  - composition
resources:
  - resources/component-api-checklist.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## React Component Design Skill

### Step 1 — Identify the Component Responsibility

Determine the component type before designing the API:

- Page component: orchestrates data fetching, permissions, and layout.
- Feature component: contains feature-specific state and business behavior.
- UI component: pure presentational; props and callbacks only.

### Step 2 — Design the Public API Surface

- Keep props minimal and strongly typed.
- Prefer explicit callback names (`onSave`, `onDismiss`) over generic handlers.
- Support controlled and uncontrolled modes only when both are needed.
- Forward refs only for imperative handles (focus, scroll, open).

```tsx
interface TextInputProps {
  value?: string
  defaultValue?: string
  onValueChange?: (next: string) => void
}

export const TextInput = forwardRef<HTMLInputElement, TextInputProps>(
  ({ value, defaultValue, onValueChange }, ref) => {
    return (
      <input
        ref={ref}
        value={value}
        defaultValue={defaultValue}
        onChange={(e) => onValueChange?.(e.target.value)}
      />
    )
  },
)
```

### Step 3 — Evaluate Prop Drilling Depth

- 1-2 levels: props are acceptable.
- 3+ levels through intermediates that do not use data: refactor to context or composition.
- Global cross-feature state: dedicated store.

### Step 4 — Composition and Extensibility

- Prefer composition over inheritance.
- Use compound components with context for tightly-related primitives.
- Use render props or slot-like `children` patterns when parent-controlled rendering is required.
- Do not expose internal implementation state through props.

### Step 5 — Accessibility and Semantics

- Base UI components must render semantic HTML first.
- Ensure keyboard navigation and focus management are first-class API concerns.
- Tie labels and descriptions to controls via `id`, `aria-*`, and role-appropriate markup.

### Step 6 — Verify

- [ ] Component responsibility is single-purpose
- [ ] Public props are minimal and typed
- [ ] No prop drilling through more than two uninterested layers
- [ ] `forwardRef` is only used for imperative handles
- [ ] Interactive components meet semantic and keyboard accessibility basics
- [ ] `pnpm tsc --noEmit` passes with no errors
