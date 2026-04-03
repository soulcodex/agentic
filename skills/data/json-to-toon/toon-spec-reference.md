# TOON Spec Reference

Token-Oriented Object Notation (TOON) v0.9-beta1 — compact encoding rules for LLM-optimised data.

---

## Primitives

| Type | Rule | JSON → TOON |
|---|---|---|
| Safe string | Alphanumeric + underscore: unquoted | `"Alice"` → `Alice` |
| Empty string | Always quoted | `""` → `""` |
| Ambiguous string | Looks like bool/null/number: quoted | `"true"` → `"true"`, `"42"` → `"42"` |
| Special chars string | Contains `,` `:` `[` `{` `-`(leading) space: quoted | `"a,b"` → `"a,b"` |
| Control chars | Escape inside quotes | `"a\nb"` → `"a\\nb"` |
| Integer / float | Unquoted | `42` → `42`, `3.14` → `3.14` |
| Boolean | Lowercase, unquoted | `true` → `true`, `false` → `false` |
| Null / undefined | Unquoted keyword | `null` → `null` |
| Date / time | ISO 8601, quoted | `"2025-01-01T00:00:00.000Z"` |
| Non-serialisable | Functions, symbols, Infinity, NaN | → `null` |

---

## Objects

```
key: value          ← simple pair
nested:             ← object value on next line, indented 2 spaces
  inner: value
empty_obj:          ← empty object (colon, no value)
```

Key quoting rules: quote keys that contain `,` `:` `[` `{` spaces, leading `-`,
numeric-only keys, or empty key.

---

## Arrays — Three Formats

### 1. Inline (primitive elements)

```
tags[3]: reading,gaming,coding
nums[4]: 1,2,3,4
empty[0]:
```

Syntax: `key[N]: v1,v2,...`  
Quote elements containing `,` or other special chars.

### 2. Tabular (uniform objects — all same keys, all flat values)

```
products[3]{id,name,price}:
  1,Widget,9.99
  2,Gadget,14.50
  3,Tool,7.25
```

Syntax: `key[N]{field1,field2,...}:\n  row1\n  row2`  
Field order comes from the **first object**. Quote cells containing `,`.

### 3. List (non-uniform objects, nested values, or mixed types)

```
items[2]:
  - id: 1
    name: First
  - id: 2
    name: Second
    extra: true
    tags[2]: a,b
```

Syntax: `key[N]:` then each item starts with `- ` at indent+2; subsequent
fields align with first field (indent+4 for 2-space indent).

---

## Decision Tree

```
All elements are primitives?
  YES → Inline

All elements are objects AND identical top-level keys AND all values are flat?
  YES → Tabular

Otherwise (mixed, nested, heterogeneous)?
  → List
```

---

## Nesting

Objects in objects → 2-space indent per level, no closing braces:

```
user:
  id: 123
  address:
    city: London
    zip: W1A1AA
```

Arrays inside list items → apply same rules recursively:

```
orders[1]:
  - id: 42
    lines[2]{sku,qty}:
      A1,3
      B2,1
    tags[2]: urgent,new
```

---

## Root-Level Arrays

```
[3]: a,b,c                          ← root primitive array
[2]{id,name}:                       ← root tabular array
  1,Alice
  2,Bob
[2]:                                ← root list array
  - id: 1
  - id: 2
    name: Ada
[0]:                                ← root empty array
```

---

## Invariants — Never Violate

- No trailing whitespace on any line.
- No trailing newline at end of output.
- Consistent 2-space indentation (or chosen level, but must be uniform).
- Array `[N]` length must equal actual element count.
- Tabular column order must match header throughout all rows.

---

## Token Savings Reference (cl100k_base)

| Data pattern | Typical reduction vs JSON |
|---|---|
| Tabular arrays (10+ rows) | 50–70% |
| Nested objects | 30–50% |
| Primitive arrays | 20–40% |
| Small flat objects (< 5 fields) | 5–15% |

---

## Caveats

- **Lossy edge cases**: `key:` is ambiguous between empty string and empty
  object. Decoder infers from context — do not rely on lossless round-trips.
- **Type coercion**: `"true"` (quoted) → string; `true` (unquoted) → boolean.
- **Purpose**: TOON is a forward-transformation format for LLM consumption, not
  a lossless interchange format. Keep original JSON for strict APIs.
