# Plan: Full Gemini CLI Integration + Vendor Script Isolation

**GitHub Issue:** [#54](https://github.com/soulcodex/agentic/issues/54)
**Status:** In Progress
**Last Updated:** 2026-04-18

---

## Background

Research against the official `google-gemini/gemini-cli` repo (v0.38.x, April 2026)
revealed two correctness bugs and several missing features in the current Gemini adapter.
Separately, `vendor-gen.sh` is a monolithic script that mixes all vendor logic together —
touching one vendor risks side-effects on the others. Both issues are addressed here.

---

## Part 1 — Vendor Script Isolation

### Goal

Split each vendor's generation logic into its own dedicated script sourced by a thin
dispatcher, so future vendor work is contained to a single file.

### New Directory Layout

```
tooling/lib/
├── vendor-gen.sh                ← thin dispatcher (resolves vendors, sources scripts)
└── vendors/
    ├── claude.sh                ← extracted from current gen_claude()
    ├── copilot.sh               ← extracted from current gen_copilot()
    ├── codex.sh                 ← extracted from current gen_codex()
    ├── gemini.sh                ← new; full Gemini logic (see Part 2)
    └── opencode.sh              ← extracted from current gen_opencode()
```

### Contract for each `vendors/<vendor>.sh`

Every script:

- Is sourced (not executed) by `vendor-gen.sh`
- Exports exactly one public function: `gen_<vendor>()`
- May use any variable already exported by `vendor-gen.sh` at source time:
  `LIBRARY`, `TARGET`, `VENDOR_FILES_DIR`, `FRAGS_DIR`, `PROJECT_NAME`,
  `PROFILE`, `PROFILE_VER`, `GENERATED_AT`, `COMPOSE_MODE`, `AGENTS_MD`
- May call any helper from `common.sh` (`format_markdown`, `autogen_header`, etc.)
- Does **not** call `source common.sh` again (already sourced by dispatcher)
- Must be `shellcheck`-clean at `--severity=style --external-sources`

### Changes to `vendor-gen.sh`

1. Move `gen_claude`, `gen_copilot`, `gen_codex`, `gen_opencode` bodies into their
   respective `vendors/<vendor>.sh` files.
2. Replace `gen_gemini` body with the new implementation (Part 2).
3. Add a `load_vendor_script()` helper that sources
   `$SCRIPT_DIR/vendors/<vendor>.sh` before dispatching.
4. Add `shellcheck source=tooling/lib/vendors/claude.sh` etc. directives.
5. The dispatch `case` block remains in `vendor-gen.sh`; it just calls the functions
   after loading the scripts.

### ShellCheck directive pattern (required)

```bash
# shellcheck source=tooling/lib/vendors/claude.sh
source "$SCRIPT_DIR/vendors/claude.sh"
```

---

## Part 2 — Full Gemini CLI Integration

### 2a. Fix output filename and add primary GEMINI.md output

**Current behaviour:** generates `.agentic/vendor-files/gemini/systemPrompt.md`
which is symlinked to `.gemini/systemPrompt.md`. Gemini CLI does **not** auto-load
this file.

**Target behaviour:** generate **two** output files:

| File                                     | Purpose                     | How Gemini CLI loads it                      |
| ---------------------------------------- | --------------------------- | -------------------------------------------- |
| `.agentic/vendor-files/gemini/GEMINI.md` | Primary context file        | Auto-discovered at project root, zero config |
| `.agentic/vendor-files/gemini/system.md` | Full system prompt override | Loaded when `GEMINI_SYSTEM_MD=1` in env      |

**Symlinks created by `vendor-switch.sh`:**

- `GEMINI.md` (project root) → `.agentic/vendor-files/gemini/GEMINI.md`
- `.gemini/system.md` → `../.agentic/vendor-files/gemini/system.md`

### 2b. Update `vendors/gemini/adapter.json`

```json
{
  "vendor": "gemini",
  "version": "2.0.0",
  "output_paths": {
    "base": ".",
    "skills": ".gemini/skills"
  },
  "section_mappings": [
    {
      "agents_md_heading": "## Git Conventions",
      "output_file": "GEMINI.md",
      "activation_mode": "always-on",
      "frontmatter": {}
    },
    {
      "agents_md_heading": "## Security",
      "output_file": "GEMINI.md",
      "activation_mode": "always-on",
      "frontmatter": {}
    },
    {
      "agents_md_heading": "## Code Review",
      "output_file": "GEMINI.md",
      "activation_mode": "always-on",
      "frontmatter": {}
    },
    {
      "agents_md_heading": "## Testing Philosophy",
      "output_file": "GEMINI.md",
      "activation_mode": "always-on",
      "frontmatter": {}
    },
    {
      "agents_md_heading": "## Documentation",
      "output_file": "GEMINI.md",
      "activation_mode": "always-on",
      "frontmatter": {}
    },
    {
      "agents_md_heading": "## TypeScript",
      "output_file": "GEMINI.md",
      "activation_mode": "always-on",
      "frontmatter": {}
    },
    { "agents_md_heading": "## Go", "output_file": "GEMINI.md", "activation_mode": "always-on", "frontmatter": {} },
    { "agents_md_heading": "## Python", "output_file": "GEMINI.md", "activation_mode": "always-on", "frontmatter": {} },
    { "agents_md_heading": "## PHP", "output_file": "GEMINI.md", "activation_mode": "always-on", "frontmatter": {} }
  ],
  "unsupported_sections": [],
  "character_limit_per_file": null,
  "total_character_limit": null,
  "notes": "Gemini CLI auto-discovers GEMINI.md at the project root (zero config). .gemini/system.md is used as a full system-prompt override when GEMINI_SYSTEM_MD=1 is set. Skills are deployed natively to .gemini/skills/ and activated lazily via the activate_skill tool."
}
```

### 2c. New and renamed templates

**`vendors/gemini/template.GEMINI.md`** (replaces `template.systemPrompt.md`):

```markdown
<!-- AUTO-GENERATED by agentic library -->
<!-- Source profile: {{PROFILE_NAME}} (v{{PROFILE_VERSION}}) -->
<!-- Generated: {{GENERATED_AT}} -->
<!-- DO NOT EDIT — regenerate with: just vendor-gen {{TARGET_PATH}} -->

# {{PROJECT_NAME}} — Agent Instructions

{{ALL_SECTIONS}}
```

**`vendors/gemini/template.system.md`** (new, for system prompt override):

```markdown
<!-- AUTO-GENERATED by agentic library -->
<!-- Source profile: {{PROFILE_NAME}} (v{{PROFILE_VERSION}}) -->
<!-- Generated: {{GENERATED_AT}} -->
<!-- DO NOT EDIT — regenerate with: just vendor-gen {{TARGET_PATH}} -->
<!-- Usage: set GEMINI_SYSTEM_MD=1 to activate this as the full system prompt -->

# {{PROJECT_NAME}} — System Prompt

{{ALL_SECTIONS}}
```

**Remove:** `vendors/gemini/template.systemPrompt.md`

### 2d. `tooling/lib/vendors/gemini.sh` — new isolated script

```
gen_gemini() logic:
  1. Create $VENDOR_FILES_DIR/gemini/
  2. Generate GEMINI.md (primary)  using template.GEMINI.md
     - Substitute {{PROJECT_NAME}}, {{PROFILE_NAME}}, {{PROFILE_VERSION}},
       {{GENERATED_AT}}, {{TARGET_PATH}}
     - Append all sections (lean: fragments loop / full: AGENTS.md extract)
  3. Generate system.md (override) using template.system.md
     - Same substitution and section append as GEMINI.md
  4. If skills exist in .agentic/skills/:
     - Create .agentic/vendor-files/gemini/skills/ directory
     - For each skill, copy SKILL.md + assets into it
       (skills.sh already handles canonical deployment;
        this step only creates a Gemini-structured copy)
  5. format_markdown on both output files
  6. Echo created paths
```

### 2e. `tooling/lib/vendor-switch.sh` — update Gemini block

```bash
gemini)
  # Primary context file (auto-discovered, zero config)
  if [[ -f "$VENDOR_FILES_DIR/gemini/GEMINI.md" ]]; then
    ln -sf ".agentic/vendor-files/gemini/GEMINI.md" "$TARGET/GEMINI.md"
    echo "    Linked: GEMINI.md → .agentic/vendor-files/gemini/GEMINI.md"
  fi
  # System prompt override (requires GEMINI_SYSTEM_MD=1)
  if [[ -f "$VENDOR_FILES_DIR/gemini/system.md" ]]; then
    mkdir -p "$TARGET/.gemini"
    ln -sf "../.agentic/vendor-files/gemini/system.md" "$TARGET/.gemini/system.md"
    echo "    Linked: .gemini/system.md → ../.agentic/vendor-files/gemini/system.md"
  fi
  # Native skills directory
  if [[ -d "$TARGET/.agentic/skills" ]]; then
    mkdir -p "$TARGET/.gemini"
    ln -sf "../.agentic/skills" "$TARGET/.gemini/skills"
    echo "    Linked: .gemini/skills → ../.agentic/skills"
  fi
  ;;
```

Update `remove_all_vendor_symlinks()` and `vendor_files_exist()` to track the new paths.

### 2f. `tooling/lib/deploy-skills.sh` — add Gemini native support

Update `create_skill_symlinks()`:

```bash
gemini)
  mkdir -p "$TARGET/.gemini"
  rm -f "$TARGET/.gemini/skills"
  ln -s "../.agentic/skills" "$TARGET/.gemini/skills"
  echo "  Linked: .gemini/skills → ../.agentic/skills"
  ;;
```

Update `generate_skills_readme()` to show Gemini's native path:

```markdown
| Gemini | `.gemini/skills/` (symlinked here) | Native (lazy via activate_skill) |
```

Update `common.sh` `get_vendor_skill_dir()`:

```bash
gemini)  echo ".gemini/skills" ;;
```

### 2g. `vendors/gemini/README.md` — corrections and additions

1. **Remove** incorrect statement: _"Gemini does not support glob-scoped rules"_
2. **Replace** with: _"Gemini does not apply glob-scoped rules at the instruction level;
   all context from GEMINI.md is always-on. Tool-level conditional rules are available
   via the policy engine (`.gemini/policies/*.toml`)."_
3. **Add** section documenting `GEMINI_SYSTEM_MD=1` and `.gemini/system.md`
4. **Add** section documenting native skills (`.gemini/skills/`, lazy `activate_skill`)
5. **Add** section documenting `@import` / multi-file context (`@./path/to/file.md`)
6. **Update** output files table to include `GEMINI.md` and `.gemini/system.md`
7. **Update** gitignore note: `GEMINI.md` at root must be explicitly un-ignored too

---

## Part 3 — Test Suite Updates

### Tests to update (file path / assertion changes)

| Test | Current assertion                            | New assertion                                          |
| ---- | -------------------------------------------- | ------------------------------------------------------ |
| T10  | `vendor-files/gemini/systemPrompt.md` exists | `vendor-files/gemini/GEMINI.md` exists                 |
| T10  | _(new)_                                      | `vendor-files/gemini/system.md` exists                 |
| T28  | `.gemini/systemPrompt.md` symlink            | `.gemini/system.md` symlink + `GEMINI.md` root symlink |
| T43  | `.gemini/systemPrompt.md`                    | `GEMINI.md` + `.gemini/system.md`                      |

### New tests to add

| ID  | Area                  | What it asserts                                                                   |
| --- | --------------------- | --------------------------------------------------------------------------------- |
| T90 | vendor-gen: gemini    | `GEMINI.md` generated at `vendor-files/gemini/GEMINI.md` with project name header |
| T91 | vendor-gen: gemini    | `system.md` generated at `vendor-files/gemini/system.md`                          |
| T92 | vendor-gen: gemini    | Both files contain fragment content in lean mode                                  |
| T93 | vendor-switch: gemini | `GEMINI.md` root symlink created after switch                                     |
| T94 | vendor-switch: gemini | `.gemini/system.md` symlink created after switch                                  |
| T95 | vendor-switch: gemini | `.gemini/skills` symlink created when skills exist                                |
| T96 | deploy-skills: gemini | `.gemini/skills` symlink created with `--vendor gemini`                           |
| T97 | vendor isolation      | Sourcing `vendors/claude.sh` in isolation defines `gen_claude()`                  |
| T98 | vendor isolation      | Sourcing `vendors/gemini.sh` in isolation defines `gen_gemini()`                  |

---

## Part 4 — Housekeeping

### `index/` rebuild

Run `just index` after all changes and commit updated `index/skills.json` and
`index/fragments.json` together with the source change.

### `just lint`

Run `just lint` after modifying adapter.json, README.md, and any fragment/skill.
All findings must be zero.

### ShellCheck

Run `shellcheck --severity=style --external-sources` on every modified script.
Zero findings required. No suppressions.

---

## Execution Checklist (for worker)

- [ ] Create `tooling/lib/vendors/` directory
- [ ] Extract `gen_claude()` → `tooling/lib/vendors/claude.sh`
- [ ] Extract `gen_copilot()` → `tooling/lib/vendors/copilot.sh`
- [ ] Extract `gen_codex()` → `tooling/lib/vendors/codex.sh`
- [ ] Extract `gen_opencode()` → `tooling/lib/vendors/opencode.sh`
- [ ] Refactor `vendor-gen.sh` to thin dispatcher with `shellcheck source=` directives
- [ ] Write `tooling/lib/vendors/gemini.sh` (new, full Gemini logic)
- [ ] Update `vendors/gemini/adapter.json` (v2.0.0, dual output, skills path)
- [ ] Add `vendors/gemini/template.GEMINI.md`
- [ ] Add `vendors/gemini/template.system.md`
- [ ] Remove `vendors/gemini/template.systemPrompt.md`
- [ ] Update `tooling/lib/vendor-switch.sh` (new symlinks, remove old `.gemini/systemPrompt.md`)
- [ ] Update `tooling/lib/deploy-skills.sh` (`.gemini/skills` symlink support)
- [ ] Update `tooling/lib/common.sh` (`get_vendor_skill_dir` for gemini)
- [ ] Update `vendors/gemini/README.md` (correct docs)
- [ ] Update T10, T28, T43 in `tooling/lib/test.sh`
- [ ] Add T90–T98 to `tooling/lib/test.sh`
- [ ] Run `just test` — all assertions must pass
- [ ] Run `just lint` — zero findings
- [ ] Run `shellcheck --severity=style --external-sources` on all changed scripts
- [ ] Run `just index` and commit updated index files
- [ ] Commit: `feat(gemini): full Gemini CLI integration with native files, skills, and vendor isolation`
- [ ] Remove `PLAN.md`

---

## Commit Strategy

Single atomic commit covering all changes, with the message:

```
feat(gemini): full Gemini CLI integration with native files, skills, and vendor isolation

- Fix output filename: generate GEMINI.md (auto-discovered) + .gemini/system.md
  (override) instead of the unrecognised systemPrompt.md
- Add native .gemini/skills/ support (lazy activate_skill flow)
- Isolate each vendor into tooling/lib/vendors/<vendor>.sh to prevent
  cross-vendor side-effects
- Update adapter.json to v2.0.0 with dual outputs and skills path
- Correct README: glob-scoping via policy engine, @import support
- Add T90-T98 regression tests

Closes #54
```
