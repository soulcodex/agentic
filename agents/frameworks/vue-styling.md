## Vue 3 Styling Discipline

### When to Use Each Approach

- **`<style scoped>`** — for component-specific structural styles that cannot be expressed with utilities (complex selectors, pseudo-elements, animations, keyframes).
- **Tailwind utility classes** — preferred for layout, spacing, colour, typography. Default choice.
- **CSS Modules** — use when you need generated class names for deeply nested or dynamic class logic.
- **Rule**: if a component needs more than 6 distinct utility class groups across states, extract a small component or use `@layer components`.

### Tailwind v4 CSS-First Config

Define design tokens in `@theme {}` block in a CSS file — this replaces `tailwind.config.js` for most customisation. Use CSS custom properties via `@theme` — they become available as Tailwind utilities automatically. Use `@utility` to create reusable utility classes and `@variant` for custom variants.

```css
@import "tailwindcss";

@theme {
  --color-brand-50: #eff6ff;
  --color-brand-500: #3b82f6;
  --color-brand-600: #2563eb;
}

@layer components {
  .btn {
    @apply px-4 py-2 rounded-lg font-medium transition-colors;
    background-color: var(--color-brand-500);
    color: white;
  }
  .btn:hover {
    background-color: var(--color-brand-600);
  }
}
```

### Template Readability with Utility Classes

Use a `cn()` helper (`clsx` + `tailwind-merge` based) for conditional class composition. Break long class lists across multiple lines in template bindings. Extract repeated class patterns into a small component rather than copy-pasting class strings.

```ts
// lib/cn.ts
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

```vue
<script setup lang="ts">
const cn = useCn()
</script>

<template>
  <button
    :class="cn(
      'flex items-center gap-2 rounded-lg font-medium transition-colors',
      'px-4 py-2',
      isActive && 'bg-brand-500 text-white',
      size === 'sm' && 'text-sm px-3 py-1',
      size === 'lg' && 'text-lg px-6 py-3',
    )"
  >
    <slot />
  </button>
</template>
```

### shadcn/vue Philosophy

Consume via "copy-and-adapt" — components live in your repo, not installed as a black box. Override via CSS custom properties and props/slots — never reach into internals. Theme tokens via CSS variables; map to Tailwind `@theme` tokens.

### `:deep()` Rules

- **Legitimate**: styling third-party library components you cannot modify (e.g. date pickers, third-party rich text editors).
- **Smell**: using `:deep()` to override a component you own — add a prop or slot instead.
- **Never use `:deep()`** to bypass intentional encapsulation of a UI library you could instead theme or configure.

### CSS Logical Properties (RTL Support)

Use logical properties for directionality so layouts work correctly in RTL languages:

- `inline-size` / `block-size` instead of `width` / `height`
- `margin-inline-start` / `padding-inline-end` instead of `margin-left` / `padding-right`
- `inset-inline-start` instead of `left`
- `border-start-start-radius` instead of `border-top-left-radius`

Tailwind v4 includes logical property utilities. Prefer them for any directional spacing.
