## Nuxt 3

### Auto-Imports

- Nuxt auto-imports components from `components/`, composables from `composables/` and `utils/`, and Nuxt/Vue primitives everywhere.
- Do **not** add manual `import` statements for auto-imported items — it creates duplicates and confuses tree-shaking.
- If a composable or component is ambiguous, use `#imports` to make the source explicit.

### File-Based Routing

- Pages live in `pages/`. Every `.vue` file maps to a route automatically.
- Dynamic segments: `pages/users/[id].vue` → `/users/:id`. Catch-all: `pages/[...slug].vue`.
- Nested routes: create a `pages/users.vue` parent and a `pages/users/` directory for children.
- Use `<NuxtLink>` (not `<a>`) for internal navigation to get prefetching.

### Data Fetching

- `useFetch(url)` — declarative, component-lifecycle-aware, SSR-safe, and automatically deduplicated. Preferred for most cases.
- `useAsyncData(key, () => fetchFn())` — use when you need a custom key, multiple parallel fetches, or a non-URL data source (e.g., a database call in a server composable).
- Never use `fetch` or `axios` directly inside `<script setup>` without wrapping in `useAsyncData` — it will run twice (server + client) and cause hydration mismatches.
- Use `lazy: true` option for non-critical data to unblock navigation; show a loading skeleton while pending.

### Server Routes

- Server-side logic lives under `server/api/` (auto-prefixed at `/api/`) and `server/routes/` (mapped directly).
- Handler files export `defineEventHandler(async (event) => { ... })`.
- Read body: `await readBody(event)`. Read query params: `getQuery(event)`. Set status: `setResponseStatus(event, 201)`.
- Never import Node.js-only modules (e.g., `fs`, `crypto`) in shared code — use them only inside `server/`.

### SEO

- Use `useSeoMeta({ title, description, ogImage, ... })` for all meta tag management — never manipulate `<head>` directly.
- For page-level SEO that depends on async data, call `useSeoMeta` after `await useFetch(...)` resolves.
- Use `defineOgImageComponent` or `og-image` Nuxt module for dynamic OG image generation when needed.

### SSR Safety

- Code inside `<script setup>` runs on both server and client. Guard browser-only APIs:
  ```ts
  if (import.meta.client) { window.analytics.track(...) }
  // or
  onMounted(() => { /* browser-only */ })
  ```
- Never access `localStorage`, `sessionStorage`, `document`, or `window` at the top level of a composable or setup script.
- Use Nuxt's `useState` instead of `ref` for state that must be consistent across SSR/hydration boundaries.

### Middleware

- Route middleware lives in `middleware/`. Named middleware: `defineNuxtRouteMiddleware((to, from) => { ... })`.
- Apply per-page: `definePageMeta({ middleware: ['auth'] })`.
- Global middleware: prefix the file with `global` (e.g., `middleware/00.logging.global.ts`).
- Use middleware for auth guards, redirect logic, and analytics page-views — not for data fetching.

### Route Rules & Rendering Modes

- Configure per-route rendering in `nuxt.config.ts` under `routeRules`:
  ```ts
  routeRules: {
    '/':        { prerender: true },   // SSG
    '/dashboard/**': { ssr: false },   // SPA
    '/blog/**': { isr: 3600 },         // ISR — regenerate after 1 hour
  }
  ```
- Default is SSR. Only opt out of SSR when the page is purely client-side (e.g., authenticated dashboard with real-time data).
