---
name: react-application-structure
description: >
  Establishes or reviews the directory layout, feature boundaries, state design,
  routing approach, and data-fetching conventions for a React 18+ TypeScript
  application. Invoked when the user asks to structure a React app, set up a
  scalable architecture, or review React project organization.
version: 1.0.0
tags:
  - ui
  - react
  - typescript
  - architecture
resources:
  - resources/stack-guidance.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## React Application Structure Skill

### Step 1 — Directory Layout (Feature-Based)

Organise by feature, not by file type. Co-locate everything a feature needs:

```
src/
  app/
    providers/
      QueryProvider.tsx
      RouterProvider.tsx
  features/
    auth/
      components/
        AuthLoginForm.tsx
      hooks/
        useAuth.ts
      state/
        auth.store.ts
      api/
        auth.api.ts
      types/
        auth.types.ts
  components/
    ui/
      Button.tsx
      Modal.tsx
  routes/
    index.tsx
  lib/
    http.ts
    env.ts
  styles/
  main.tsx
```

### Step 2 — Component and Hook Conventions

- Use function components with TypeScript; no class components.
- Keep components thin; move reusable logic to custom hooks.
- Name hooks with the `use` prefix and keep single responsibility.
- Keep side effects in hooks/components where they are consumed; avoid hidden global effects.
- Use alias imports for cross-directory modules and ESM `import`/`export` syntax only.

```tsx
interface Props {
  userId: string
  readonly?: boolean
}

export function UserCard({ userId, readonly = false }: Props) {
  const { user } = useAuthUser(userId)
  return <section>{readonly ? user.name : <strong>{user.name}</strong>}</section>
}
```

### Step 3 — State Management Boundaries

- Local transient UI state: `useState` / `useReducer`.
- Shared server state: TanStack Query (queries + mutations).
- Shared client state across features: Zustand or Redux Toolkit slice per domain.
- Do not duplicate server state into client stores unless offline/derived behaviour requires it.

### Step 4 — Routing and Entry Points

- Use a typed router setup (`react-router-dom` data routers or framework router).
- Keep route definitions in `routes/` and route-level loaders/actions with route modules.
- Lazy-load route components where possible.
- Route guards should be centralized helper wrappers, not repeated inline logic.

### Step 5 — Data and API Layer

- Keep API clients in `features/*/api` or shared `lib/http.ts`.
- Normalize error handling in one place (interceptor or query/mutation wrapper).
- Validate API payloads at boundaries (for example Zod schemas) before wider app use.

### Step 6 — Verify

- [ ] Feature-first directory layout is used
- [ ] Hooks handle reusable logic; components stay presentation-focused
- [ ] Server state is handled by query layer, not duplicated into global client state
- [ ] Route modules are lazy-loaded where appropriate
- [ ] `pnpm tsc --noEmit` passes with zero errors
