## Next App Router Guidance

- Prefer Server Components by default
- Use `'use client'` only where interaction/browser APIs are required
- Keep mutations in Route Handlers or Server Actions
- Revalidate cache explicitly after writes
- Keep secrets and privileged code server-only
