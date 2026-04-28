## Next.js App Router

### Routing Model

- Use App Router (`app/`) as the default architecture.
- Route segments map to folders; `page.tsx` defines route UI and `layout.tsx` defines shared shells.
- Keep layouts persistent and push data dependencies down to the segment that needs them.
- Use route groups (`(group)`) for organization without URL changes.

### Server and Client Boundaries

- Components are Server Components by default.
- Add `'use client'` only where browser APIs, stateful interactivity, or client hooks are required.
- Keep client islands as small as possible; compose them inside server-rendered shells.
- Props passed from Server Components to Client Components must be serializable.

### Data Fetching

- Fetch on the server whenever possible.
- Use `fetch` in Server Components, route handlers, or server actions.
- Explicitly choose cache mode (`force-cache`, `no-store`) and revalidation strategy.
- Avoid client-side duplicate fetches for data already available on the server.

### Route Files and Fallback UX

- Provide segment-level `loading.tsx` for streaming and perceived performance.
- Provide segment-level `error.tsx` to recover from runtime failures.
- Provide `not-found.tsx` for missing resources and unmatched segment states.
- Throw `notFound()` when resource lookup fails and 404 is the expected UX.

### Route Handlers and Server Actions

- Use route handlers (`app/**/route.ts`) for HTTP APIs and webhook endpoints.
- Validate input at the boundary and return explicit status codes.
- Use server actions (`'use server'`) for form mutations and authenticated write flows.
- Keep server actions close to the owning route segment or feature module.

### Metadata

- Use static `metadata` exports for stable page metadata.
- Use `generateMetadata` for metadata derived from async data or route params.
- Canonical URL, title, description, and social tags are required for indexable pages.
- Keep metadata generation fast and deterministic.

### Caching and Revalidation

- Document caching intent near each fetch path.
- Use time-based revalidation for mostly-static content.
- Use tag/path invalidation after mutations to refresh stale reads.
- Default to dynamic rendering only when data freshness or per-request personalization requires it.

### Runtime and Environment

- Choose Node.js runtime for ecosystem-heavy server code.
- Choose Edge runtime only for latency-sensitive, compatible handlers.
- Read secrets only on the server and avoid exposing non-public env vars to clients.
- Keep shared modules runtime-safe (no accidental Node-only imports in client trees).
