# Markdown Formatting Rules

Use these baseline rules unless repository-specific config overrides them:

1. Headings:
- Use one top-level H1 per document.
- Keep heading levels sequential (no skipped levels).

2. Spacing:
- Keep exactly one blank line around headings, lists, and fenced code blocks.
- Remove trailing whitespace.

3. Lists:
- Use a consistent marker style per list (`-` for bullets).
- Keep indentation consistent for wrapped lines.

4. Code fences:
- Preserve existing fence language identifiers when present.
- Do not edit code content unless explicitly requested.

5. Tables:
- Keep column separators aligned if formatter supports it.
- Do not alter header semantics or cell values.

6. Links:
- Preserve link destinations and reference labels.
- Keep relative links relative; do not rewrite to absolute paths.

7. Frontmatter:
- Preserve frontmatter keys/order unless repository conventions require normalization.
- Keep valid YAML syntax.
