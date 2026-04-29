---
name: next-application-structure
description: >
  Establishes or reviews directory layout, server/client boundaries, routing,
  data-fetching strategy, and testing structure for Next.js 14+ App Router
  TypeScript applications. Invoked when the user asks to structure a Next app,
  set App Router conventions, or review architecture for React parity.
version: 1.0.0
tags:
  - ui
  - nextjs
  - react
  - typescript
resources:
  - resources/app-router-guidance.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Next Application Structure Skill

### Step 1 — App Router Directory Layout

Organise by route segment and feature ownership:

```
src/
  app/
    (marketing)/
      page.tsx
    (app)/
      dashboard/
        page.tsx
        loading.tsx
        error.tsx
    api/
      auth/
        route.ts
    layout.tsx
  features/
    auth/
      components/
      server/
      client/
      auth.types.ts
  components/
    ui/
  lib/
    db/
    auth/
    validation/
```

### Step 2 — Server and Client Boundaries

- Default to Server Components; add `'use client'` only when interactivity or browser APIs are needed.
- Keep data fetching and secrets in server modules/route handlers.
- Pass serialized data to client components via props.
- Avoid importing server-only modules into client components.
- Use alias imports for cross-directory modules and ESM `import`/`export` syntax only.

### Step 3 — Data Fetching and Mutations

- Read data in Server Components when possible.
- Use Route Handlers or Server Actions for mutations.
- Revalidate with `revalidatePath`/`revalidateTag` after mutations.
- Centralize schema validation (for example Zod) at request boundaries.

### Step 4 — State and Caching Strategy

- URL and route params: App Router primitives.
- Shared client interaction state: React context or local store in client layer.
- Remote data cache: Next fetch cache + query library only when client-side refetching is needed.

### Step 5 — Testing Parity with React Stack

- Unit and component tests: Vitest + React Testing Library.
- E2E flows: Playwright.
- For Server Components and route handlers, test logic in extracted server utilities where possible.

### Step 6 — Verify

- [ ] App Router segments contain `page.tsx`/`layout.tsx` and special files only where needed
- [ ] Server-first component model is respected, with minimal `'use client'`
- [ ] Secrets and privileged logic stay server-side
- [ ] Mutation flows trigger explicit revalidation
- [ ] `pnpm tsc --noEmit` and `pnpm test` pass
