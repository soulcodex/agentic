---
name: internationalization-i18n
description: >
  Audits and implements internationalization (i18n) and localization (l10n)
  for a frontend application. Covers message format selection, locale file
  organisation, pluralization, RTL layout, and CI extraction workflows.
  Invoked when the user asks to add i18n support, set up translations,
  or make the UI multilingual.
version: 1.0.0
tags:
  - ui
  - i18n
  - l10n
  - frontend
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Internationalization (i18n) Skill

### Step 1 — Audit Existing Setup

- Identify any hardcoded strings in templates, components, and error messages.
- Check whether an i18n library is already configured (vue-i18n, react-i18next, etc.).
- Note the target locales and RTL requirements (Arabic, Hebrew, etc.).

### Step 2 — Choose Message Format

Use **ICU Message Format** for all translation strings. It handles pluralization,
gender, and select cases in a portable way supported by most i18n libraries.

```
# Simple
"greeting": "Hello, {name}!"

# Plural
"item_count": "{count, plural, one {# item} other {# items}}"

# Select
"status": "{status, select, active {Active} inactive {Inactive} other {Unknown}}"
```

### Step 3 — Organise Locale Files

```
locales/
  en.json          ← source of truth (all keys must exist here)
  es.json
  ar.json          ← RTL locale
  fr.json
```

Rules:
- One flat or namespaced JSON file per locale.
- Key names use `snake_case` or namespaced dot notation consistently.
- The source locale (`en.json`) is the authoritative key list.

### Step 4 — Locale Detection

Detect locale in this priority order:
1. User preference stored in a cookie or `localStorage`.
2. `Accept-Language` HTTP header (server-side rendering).
3. Browser `navigator.language`.
4. Fallback to the source locale.

### Step 5 — Pluralization and Formatters

Use the `Intl.*` browser APIs for locale-sensitive formatting — do not hardcode
format strings in translation messages:

```ts
// Numbers
new Intl.NumberFormat(locale, { style: 'currency', currency: 'USD' }).format(amount)

// Dates
new Intl.DateTimeFormat(locale, { dateStyle: 'medium' }).format(date)

// Relative time
new Intl.RelativeTimeFormat(locale, { numeric: 'auto' }).format(-1, 'day')
```

### Step 6 — RTL Layout

For RTL locales:
- Set `dir="rtl"` on `<html>` or the root layout element.
- Use **CSS logical properties** throughout: `margin-inline-start` not `margin-left`,
  `padding-inline-end` not `padding-right`, `text-align: start` not `text-align: left`.
- Test bidirectional text (mixed LTR/RTL strings) in UI components.
- Flip icons and directional UI elements (arrows, carets) using `[dir="rtl"]` CSS selectors.

### Step 7 — Extraction Workflow

- Install an extraction tool (e.g., `vue-i18n-extract`, `i18next-parser`).
- Configure it to scan source files and report missing or unused keys.
- Add a CI step that fails the build if any key in the source locale is missing
  from any target locale file.

```bash
# Example CI step
pnpm i18n:check   # runs extraction + diff against committed locale files
```

### Step 8 — Verify

- [ ] All hardcoded UI strings replaced with translation keys.
- [ ] Source locale file is complete (no missing keys).
- [ ] Pluralization tested for count = 0, 1, and > 1.
- [ ] Date, number, and currency values use `Intl.*` formatters.
- [ ] RTL layout verified visually for at least one RTL locale.
- [ ] CI extraction check passes with no missing keys.
