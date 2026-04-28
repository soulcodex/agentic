## React 19 + TypeScript

### Component Architecture

- Use function components only. Class components are not allowed.
- Keep one component per file. Use PascalCase for component files and exported component names.
- Keep rendering logic in components and domain logic in hooks or services.
- Extract reusable stateful logic into custom hooks (`use*.ts`) instead of utility classes.

### TypeScript Discipline

- Prefer explicit interfaces/types for public component props.
- Avoid `any`. Use `unknown` at boundaries and narrow with type guards.
- Type event handlers precisely (`React.ChangeEvent<HTMLInputElement>`, `React.FormEvent<HTMLFormElement>`).
- Use discriminated unions for UI states (`idle | loading | success | error`) instead of multiple booleans.

### State and Data Flow

- Use local state (`useState`) for view-local concerns.
- Use reducers (`useReducer`) for state with multiple transitions or domain rules.
- Derive values during render or with `useMemo` when expensive. Do not mirror derived values into state.
- Lift state only to the nearest common owner. Avoid globalizing state prematurely.

### Effects and Side Effects

- `useEffect` is for synchronizing with external systems (network subscriptions, timers, DOM APIs), not for derived data.
- Keep effect dependencies complete and stable. If dependencies cause loops, fix identity issues with `useMemo`/`useCallback`.
- Always clean up subscriptions, intervals, and listeners in effect cleanup.
- Prefer event handlers and framework data APIs over effect-driven fetching when possible.

### Forms and Actions

- Prefer native `<form>` semantics and progressive enhancement over custom click-only flows.
- Use controlled components for complex validation and formatting.
- Use uncontrolled inputs with refs for very large forms when performance is critical.
- Model form submission state explicitly (`pending`, `fieldErrors`, `formError`, `result`).

### Rendering and Performance

- Default to simple components first; profile before optimizing.
- Use `React.memo` only for proven hot paths with stable props.
- Use stable keys from domain IDs for lists. Never use array index as key when order can change.
- Split large pages into route-level and section-level boundaries to reduce re-render scope.

### Accessibility

- Use semantic HTML first (`button`, `label`, `fieldset`, `nav`, `main`).
- Every form control has an accessible label.
- Keyboard interactions must mirror pointer interactions.
- Use ARIA only when native semantics cannot express intent.
