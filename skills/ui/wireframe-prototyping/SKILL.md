---
name: wireframe-prototyping
description: >
  Creates low-fidelity wireframes and interaction annotations for a feature or
  screen. Covers user flow identification, ASCII wireframe sketching, interaction
  annotation, and acceptance criteria. Invoked when the user asks to wireframe a
  screen, prototype a UI, or sketch a user flow.
version: 1.0.0
tags:
  - ui
  - design
  - wireframe
  - prototype
resources: []
vendor_support:
  claude: native
  opencode: native
  copilot: prompt-inject
  codex: prompt-inject
  gemini: prompt-inject
---

## Wireframe Prototyping Skill

### Step 1 — Clarify Scope

Before sketching, confirm:
- Which screen or flow is being wireframed?
- What device target: desktop, mobile, or both?
- What is the primary user goal this screen must satisfy?
- Are there existing designs or brand constraints to follow?

### Step 2 — Identify User Flows

List the key flows the wireframe must cover:
- Happy path (primary action the user takes)
- Empty states (no data yet)
- Error states (validation failure, network error)
- Edge cases (long strings, many items in a list)

### Step 3 — ASCII Wireframe

Sketch the layout using ASCII art. Use these conventions:

```
+------------------------+   ← container border
| Page Title             |   ← text
+------------------------+
| [ Search...          ] |   ← text input
| [ Button ]  [ Cancel ] |   ← buttons
+--------+---------------+
| Nav    | Main Content   |
| - Item |                |
| - Item | +------------+ |
|        | | Card Title | |   ← card
|        | | Subtitle   | |
|        | [ Action     ] |
|        | +------------+ |
+--------+---------------+
| Footer                  |
+------------------------+

Legend:
  [ text ]         ← button
  [ text...      ] ← text input
  < Option ▼ >    ← dropdown / select
  (•) Option       ← radio button
  [x] Label        ← checkbox
  ~~~              ← image / media placeholder
```

Produce a separate wireframe per breakpoint if mobile and desktop differ significantly.

### Step 4 — Interaction Annotations

After each wireframe, add a numbered annotation list:

```
Interactions:
1. Clicking [ Search ] submits the search form → loads results in Main Content.
2. Empty state shows "No results found" with a [ Clear filters ] button.
3. Clicking a Card opens a detail drawer (slides in from the right).
4. < Option ▼ > dropdown filters results in real-time (no submit needed).
5. Error state shows an inline banner: "Something went wrong. [ Retry ]"
```

### Step 5 — Figma / Excalidraw Handoff Notes

If handing off to a designer, note:
- Spacing guidelines (e.g., 8-pt grid, 16 px section padding).
- Component names to reuse from the design system (if known).
- Any animation or transition intent (e.g., "drawer slides in 200 ms ease-out").
- Responsive behaviour: how the layout reflows on smaller screens.

### Step 6 — Acceptance Criteria

Write testable acceptance criteria for each screen:

```
Given the user is on the search screen
When they enter a query and press Enter
Then results appear within 300 ms
And each result shows: title, description (truncated at 120 chars), and a [ View ] button

Given there are no results
When the search completes
Then the empty state message "No results for '…'" is displayed
And a [ Clear search ] button resets the input
```
