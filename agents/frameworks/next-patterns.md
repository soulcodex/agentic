## Next.js App Router Patterns

### Server-First Composition

- Build pages as Server Components that assemble data and pass minimal props to client islands.
- Keep interactivity boundaries explicit with small `'use client'` leaves.
- Push expensive logic and secret-bearing operations to server-only modules.
- Use `server-only` for modules that must never enter client bundles.

### Loading, Error, and Not Found Files

- `loading.tsx` should render skeletons sized to final content to avoid layout shifts.
- `error.tsx` must include a clear recovery action and call `reset()` when retry is meaningful.
- `not-found.tsx` should provide navigation back to a useful parent route.
- Prefer local segment fallbacks over one global catch-all fallback.

### Route Handlers

- Co-locate handlers in `app/<segment>/route.ts` and support only required verbs.
- Validate params, query, and body with a schema at the handler boundary.
- Return typed JSON payloads and explicit cache headers when needed.
- Keep handlers thin: orchestration only; domain logic belongs in shared server modules.

### Server Actions

- Use server actions for authenticated mutations triggered by forms or user events.
- Validate `FormData`/input on the server before mutating.
- Return structured action results (`ok`, `fieldErrors`, `message`) for predictable UI handling.
- After mutation, call `revalidatePath('/target')` or `revalidateTag('resource')` to refresh reads.

### Metadata Patterns

- Use `generateMetadata` for param-based pages and fetched entities.
- Keep metadata fetching aligned with page data fetching to avoid duplicate remote calls.
- Include title templates and canonical URLs for nested routes.
- Use robots directives intentionally for private or duplicate-content routes.

### Cache and Revalidation Matrix

- **Static, slow-changing content**: `fetch(..., { cache: 'force-cache', next: { revalidate: 3600 } })`.
- **User-specific or highly dynamic content**: `fetch(..., { cache: 'no-store' })`.
- **Shared data invalidated by writes**: tag fetches and call `revalidateTag` in mutation paths.
- **Route-level refresh after mutation**: call `revalidatePath` for affected segments.

### Boundary Contracts

- Keep server-to-client props serializable (`string`, `number`, `boolean`, plain objects/arrays).
- Pass IDs and display-ready values, not ORM entities or class instances.
- Normalize dates to ISO strings at the server boundary.
- Keep client state UI-focused; source-of-truth data remains server-owned.

### Common Failure Modes to Avoid

- Marking entire routes with `'use client'` when only a leaf needs interactivity.
- Mixing multiple caching strategies without documenting intent.
- Failing to revalidate after server action mutations.
- Throwing generic errors where `notFound()` or typed action errors are expected.
