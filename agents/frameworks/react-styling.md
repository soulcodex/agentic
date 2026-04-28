## React 19 Styling Discipline

### Approach Selection

- Utility-first classes are the default for layout, spacing, typography, and color.
- CSS Modules are preferred for component-scoped structural styles and complex selectors.
- CSS-in-JS is acceptable only when dynamic runtime styling is required by the product.
- Keep one styling strategy dominant in a codebase to reduce cognitive load.

### Design Tokens

- All colors, spacing, radius, typography, and motion values come from design tokens.
- Reference tokens via CSS variables and shared theme files.
- Never hardcode brand values directly in component files.
- Use semantic token names (`--color-surface`, `--color-text-muted`) over raw intent-less names.

### Class Composition

- Use a `cn()` helper for conditional class composition.
- Keep class lists readable by grouping layout, spacing, typography, and state classes.
- Extract repeated class patterns into reusable components or style utilities.

```ts
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

### Theming and Variants

- Build variants through explicit prop maps (`size`, `tone`, `intent`) instead of ad hoc string concatenation.
- Keep default, hover, active, disabled, and focus-visible states defined for every interactive component.
- Ensure contrast and state differentiation meet accessibility requirements.
- Prefer `data-*` attributes for state-driven styling over deep selector chains.

### Motion and Layout Safety

- Respect reduced motion preferences.
- Keep animations purposeful and short; avoid perpetual decorative motion.
- Prevent layout shift with reserved space for async content, media, and skeletons.
- Use logical CSS properties for RTL-safe spacing and positioning.

### Escape Hatches

- Avoid global overrides except for resets, typography primitives, and legacy integration boundaries.
- Do not style third-party internals unless no public API exists.
- If deep overrides are required, isolate them behind a wrapper component.
