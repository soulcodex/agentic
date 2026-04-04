---
name: json-to-toon
description: >
  Transforms JSON input into Token-Oriented Object Notation (TOON) to reduce
  token consumption in LLM prompts and context windows. Applies the full TOON
  spec: inline primitive arrays, tabular format for uniform object arrays, and
  list format for heterogeneous or nested structures. Invoked when the user asks
  to compress, optimize, or convert JSON for LLM use, or to reduce token count
  on structured input data.
version: 1.0.0
tags:
  - data
  - token-optimization
  - toon
  - json
  - llm
resources:
  - toon-spec-reference.md
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## JSON to TOON Transformation Skill

Convert JSON input into TOON (Token-Oriented Object Notation) to achieve 30–70%
token reduction, making it ideal for use in LLM prompts, RAG pipelines, and any
context-window-sensitive application.

---

### Step 1 — Load the Specification

Read `toon-spec-reference.md` (in this skill's directory). It contains the
complete encoding rules you must apply throughout this skill.

---

### Step 2 — Assess the Input

Inspect the JSON the user has provided:

1. **Identify the root type**: is it an object, array of uniform objects, array
   of mixed objects, or a primitive array?
2. **Scan for high-repetition patterns**: arrays of objects with identical keys
   are prime candidates for tabular format (biggest token savings).
3. **Flag any values that require quoting**: strings containing `,`, `:`, `[`,
   `{`, `-` at start, leading/trailing spaces, or values that look like
   booleans/numbers/null.
4. **Note depth**: deeply nested structures may benefit most from TOON's
   indentation-based nesting (no closing braces).

Output a brief one-line assessment: e.g.
`"Root object with 3 tabular arrays and 2 nested objects — expect ~55% token reduction."`

---

### Step 3 — Choose Array Format for Each Array

For every array in the input, apply this decision tree:

```
Is every element a primitive (string, number, boolean, null)?
  YES → Inline format:  key[N]: v1,v2,v3

Are ALL elements objects AND do they share identical top-level keys AND
are all their values primitives (no nested objects or arrays)?
  YES → Tabular format: key[N]{f1,f2,f3}:
                          v1,v2,v3
                          v4,v5,v6

Otherwise (different keys, nested values, mixed types)
       → List format:   key[N]:
                          - field: value
                            field2: value2
```

Use the **field order of the first object** for all tabular rows. Never
re-order fields.

---

### Step 4 — Encode the Full Structure

Walk the JSON top-down and apply the rules from `toon-spec-reference.md`:

- **Objects**: `key: value` pairs, one per line. Nested objects indent 2 spaces.
- **Primitive values**: unquoted alphanumeric strings/numbers/booleans. Quote
  only when required (see spec quoting rules).
- **Empty structures**: `key:` for empty objects, `key[0]:` for empty arrays,
  `""` for empty strings.
- **Nulls**: `null` (unquoted).
- **Booleans**: `true` / `false` (lowercase, unquoted).
- **Dates/times**: ISO 8601 quoted string (`"2025-01-01T00:00:00.000Z"`).
- **Non-serialisable values** (functions, symbols, Infinity, NaN): `null`.

Formatting invariants — never violate these:
- No trailing whitespace on any line.
- No trailing newline at end of output.
- Consistent 2-space indentation throughout.
- Array length markers must match actual element counts.

---

### Step 5 — Wrap Output and Report Savings

Output the TOON-encoded data inside a fenced code block:

~~~
```toon
<encoded output here>
```
~~~

Then append a short savings summary:

```
Token estimate: JSON ~{N} tokens → TOON ~{M} tokens ({P}% reduction)
Format choices: {brief justification — e.g. "3 tabular arrays, 1 list array, inline primitives"}
```

Use the `cl100k_base` tokenizer heuristic (≈ 1 token per 4 characters of JSON,
≈ 1 token per 5 characters of TOON) for the estimate if an exact count is not
available. Always clarify it is an estimate.

---

### Step 6 — Offer Round-Trip Guidance (Optional)

If the user will need to reconstruct the original JSON from TOON, proactively
mention the known lossy edge cases:

- **Empty string vs. empty object**: both encode as `key:` — decoder must infer
  from schema context.
- **Quoted vs. unquoted type coercion**: `"true"` stays a string; `true` becomes
  a boolean.
- **Key order**: TOON preserves insertion order but round-trip tools may vary.
- **Recommendation**: for APIs requiring exact lossless JSON, keep the original
  JSON. Use TOON for LLM prompt payloads and discard after the LLM call.

Only include this section if the user asks about round-tripping or if the
payload contains edge-case values (empty strings, ambiguous-looking strings,
datetime objects).

---

### Quick Reference — Format Decision Table

| Input pattern | Format | Example |
|---|---|---|
| Primitive array | Inline | `tags[3]: a,b,c` |
| Uniform objects, flat values | Tabular | `rows[2]{id,name}: 1,Alice\n 2,Bob` |
| Non-uniform objects | List | `items[2]:\n  - id: 1\n  - id: 2\n    extra: true` |
| Nested objects | Indented key-value | `user:\n  id: 1\n  name: Alice` |
| Mixed array | List | `data[3]:\n  - 1\n  - a: 1\n  - text` |
