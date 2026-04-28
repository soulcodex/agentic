## React 19 Component Design

### Composition Over Configuration

- Prefer composing smaller components over large prop-heavy components.
- Keep public APIs narrow: only expose props that express real variation.
- Prefer explicit child components and slots-by-composition (`children`, render props) over many boolean flags.
- If a component has many mutually exclusive modes, split it into focused components.

### State Ownership Rules

- **1-2 levels deep**: pass props directly.
- **3+ levels deep within one feature tree**: use React Context with a typed provider hook.
- **Cross-feature or persisted state**: use a dedicated app state layer.
- Do not pass props through intermediates that do not use the value.

### Context Design

- Create one context per domain concern, not a global catch-all context.
- Export a typed `useXContext()` hook that throws when provider is missing.
- Keep context values stable using memoized value objects.
- Put mutation functions in context only when consumers genuinely need them.

```ts
import { createContext, useContext } from 'react'

type TabsContextValue = {
  activeId: string
  setActiveId: (id: string) => void
}

const TabsContext = createContext<TabsContextValue | null>(null)

export function useTabsContext(): TabsContextValue {
  const ctx = useContext(TabsContext)
  if (!ctx) throw new Error('useTabsContext must be used within <TabsProvider>')
  return ctx
}
```

### Compound Components

- Use compound components for coordinated UI families (`Tabs`, `Accordion`, `Menu`).
- Share state through local context created by the parent component.
- Keep child components usable only inside the parent boundary when they depend on that context.
- Expose controlled and uncontrolled variants when a component is a reusable primitive.

### Controlled vs Uncontrolled

- Offer controlled APIs when parent orchestration is needed (`value`, `onChange`).
- Offer uncontrolled APIs for ergonomics (`defaultValue`) in leaf UI usage.
- Never mix controlled and uncontrolled modes in the same render path.
- Document precedence when both `value` and `defaultValue` are provided.

### Public API Surface

- Prefer typed props and standard event handlers.
- Use `forwardRef` only when consumers need imperative DOM access (focus, measure, scroll).
- Keep imperative handles minimal with `useImperativeHandle`.
- Avoid leaking internal state shape through callback arguments.

### Client-Only Boundaries

- Encapsulate browser-only APIs (selection, resize observers, drag/drop) in dedicated client components/hooks.
- Keep server-renderable wrappers free from browser assumptions.
- Expose serializable props across boundaries.
