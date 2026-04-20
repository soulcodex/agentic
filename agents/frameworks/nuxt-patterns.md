## Nuxt 3 Patterns

### `definePageMeta` Full Options

All options available on every page component:

- **`layout`** — choose a named layout from `layouts/`
- **`middleware`** — array of named middleware to run before the page renders
- **`keepalive`** — preserve component state between route changes (wrap pages in `<KeepAlive>`)
- **`transition`** — named Vue transition applied on route change
- **`validate`** — async function returning `true` to render or `false` to trigger 404
- **`ssr: false`** — opt out of SSR for purely client-side pages (authenticated dashboards)

```vue
<script setup lang="ts">
definePageMeta({
  layout: 'dashboard',
  middleware: ['auth', 'subscription'],
  keepalive: true,
  transition: 'fade',
  validate: async (route) => {
    return !isNaN(Number(route.params.id))
  },
})
</script>
```

### Error Handling

- **`createError({ statusCode, statusMessage })`** — throw in server handlers, composables, and pages. Creates an error that Nuxt will convert into the error page.
- **`showError(error)`** — display the error page programmatically from client code.
- **`clearError({ redirect: '/' })`** — dismiss the error and optionally redirect.
- **`error.vue`** in `app/` — custom error page component; receives `error` prop with `{ statusCode, statusMessage, message }`.

```ts
// server/api/users/[id].ts
export default defineEventHandler(async (event) => {
  const user = await db.user.findUnique({ where: { id: event.context.params.id } })
  if (!user) throw createError({ statusCode: 404, statusMessage: 'User not found' })
  return user
})
```

```vue
<!-- app/error.vue -->
<script setup lang="ts">
const props = defineProps<{ error: { statusCode: number; message: string } }>()
</script>
<template>
  <div>
    <h1>{{ props.error.statusCode }}</h1>
    <p>{{ props.error.message }}</p>
    <button @click="clearError({ redirect: '/' })">Go home</button>
  </div>
</template>
```

### Plugins (`plugins/` Directory)

Use plugins for: registering third-party libraries, providing app-level typed injections, one-time async setup. Export `provide` to make the plugin injectable via `useNuxtApp().$myPlugin`. Plugins run in sorted filename order — prefix with `01.`, `02.` when order matters. Keep plugins lightweight — no heavy synchronous startup work.

```ts
// plugins/01.logger.ts
export default defineNuxtPlugin((nuxtApp) => {
  nuxtApp.provide('logger', {
    info: (msg: string) => console.info(`[nuxt] ${msg}`),
    error: (msg: string) => console.error(`[nuxt] ${msg}`),
  })
})
```

### `useRuntimeConfig` vs `useAppConfig`

- **`useRuntimeConfig()`** — for secrets and environment-specific values. Server-only by default. Public keys under `runtimeConfig.public` are available client-side. Values come from environment variables and `nuxt.config.ts`.
- **`useAppConfig()`** — for static, typed, non-secret app configuration that can be overridden per layer. Always available on both client and server. Defined in `app.config.ts`.

Never put secrets in `appConfig` — it is serialised to the client bundle.

### Nitro Caching

Use `defineCachedEventHandler` or `cachedFunction` to cache expensive server computations. Set `maxAge` in seconds. Use `staleWhileRevalidate` for background refresh without blocking requests.

```ts
// server/api/expensive.ts
export default defineCachedEventHandler(
  async (event) => {
    const data = await fetchFromExternalService()
    return data
  },
  {
    maxAge: 60 * 5,           // 5 minutes
    staleWhileRevalidate: 60, // serve stale for 1 min while revalidating
  },
)
```

### Nuxt Layers

A layer is a composable Nuxt app that another Nuxt app extends — use for shared UI kits, theme configuration, and composables across multiple Nuxt apps in a monorepo. Do NOT use a layer for code that non-Nuxt packages consume — use a regular npm package instead. Extend in `nuxt.config.ts` via `extends: ['../layers/ui']`.
