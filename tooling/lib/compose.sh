#!/bin/bash
# compose.sh — Assembles AGENTS.md from profile + fragments
# Called by: just compose <profile> <target>
set -euo pipefail

# ── Argument parsing ──────────────────────────────────────────────────────────
LIBRARY=""
PROFILE=""
TARGET=""
DRY_RUN=false
FULL_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --library)  LIBRARY="$2";  shift 2 ;;
    --profile)  PROFILE="$2";  shift 2 ;;
    --target)   TARGET="$2";   shift 2 ;;
    --dry-run)  DRY_RUN=true;  shift   ;;
    --full)     FULL_MODE=true; shift  ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$LIBRARY" ]] && { echo "Error: --library required" >&2; exit 1; }
[[ -z "$PROFILE" ]] && { echo "Error: --profile required" >&2; exit 1; }
[[ -z "$TARGET"  ]] && { echo "Error: --target required" >&2; exit 1; }

# ── Profile resolution ────────────────────────────────────────────────────────
PROFILE_FILE="$LIBRARY/profiles/$PROFILE.yaml"
[[ ! -f "$PROFILE_FILE" ]] && {
  echo "Error: profile '$PROFILE' not found at $PROFILE_FILE" >&2
  echo "Run 'just list-profiles' to see available profiles." >&2
  exit 1
}

PROFILE_NAME=$(yq '.meta.name'        "$PROFILE_FILE")
PROFILE_VER=$(yq  '.meta.version'     "$PROFILE_FILE")
GENERATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PROJECT_NAME=$(basename "$TARGET")
PROJECT_HEADER=$(yq '.output.project_header // ""' "$PROFILE_FILE")
BUILD_CMD=$(yq     '.output.build_command  // ""'  "$PROFILE_FILE")
TEST_CMD=$(yq      '.output.test_command   // ""'  "$PROFILE_FILE")
LINT_CMD=$(yq      '.output.lint_command   // ""'  "$PROFILE_FILE")

# Profile-level mode default (overridden by --full flag)
PROFILE_MODE=$(yq '.output.mode // "lean"' "$PROFILE_FILE")
[[ "$FULL_MODE" == "false" && "$PROFILE_MODE" == "full" ]] && FULL_MODE=true

# Output structure: flat (default) or nested
STRUCTURE=$(yq '.output.structure // "flat"' "$PROFILE_FILE")

# ── Fragment loading — builds RESOLVED_FRAGMENTS array ───────────────────────
# RESOLVED_FRAGMENTS holds the absolute path of every fragment, in layer order.
RESOLVED_FRAGMENTS=()

resolve_fragments() {
  local group="$1"   # e.g. "base", "languages", "architecture"
  local subdir="$2"  # e.g. "agents/base", "agents/languages"

  local names=()
  while IFS= read -r _name; do
    names+=("$_name")
  done < <(yq ".fragments.${group}[]" "$PROFILE_FILE" 2>/dev/null || true)

  for name in "${names[@]+"${names[@]}"}"; do
    [[ -z "$name" || "$name" == "null" ]] && continue
    local frag_file="$LIBRARY/$subdir/$name.md"
    if [[ ! -f "$frag_file" ]]; then
      echo "Warning: fragment '$subdir/$name.md' not found — skipping" >&2
      continue
    fi
    RESOLVED_FRAGMENTS+=("$frag_file")
  done
}

resolve_fragments "base"         "agents/base"
resolve_fragments "languages"    "agents/languages"
resolve_fragments "frameworks"   "agents/frameworks"
resolve_fragments "architecture" "agents/architecture"
resolve_fragments "practices"    "agents/practices"
resolve_fragments "domains"      "agents/domains"

# ── Fragment inline output (used in --full mode) ──────────────────────────────
inline_fragments() {
  for frag in "${RESOLVED_FRAGMENTS[@]+"${RESOLVED_FRAGMENTS[@]}"}"; do
    local rel_path="${frag#$LIBRARY/}"
    printf '\n<!-- fragment: %s -->\n\n' "$rel_path"
    cat "$frag"
    printf '\n'
  done
}

# ── Fragment copy (used in lean mode) ─────────────────────────────────────────
copy_fragments_to_target() {
  local dest="$TARGET/.agentic/fragments"
  mkdir -p "$dest"
  for frag in "${RESOLVED_FRAGMENTS[@]+"${RESOLVED_FRAGMENTS[@]}"}"; do
    cp "$frag" "$dest/$(basename "$frag")"
  done
}

# ── Fragment reference table (lean mode) ──────────────────────────────────────
build_fragment_reference_table() {
  local section=""
  section+=$'\n## Conventions & Patterns\n\n'
  section+="> Load the relevant file for full guidelines on that area."$'\n\n'
  section+="| Area | File |"$'\n'
  section+="|------|------|"$'\n'

  for frag in "${RESOLVED_FRAGMENTS[@]+"${RESOLVED_FRAGMENTS[@]}"}"; do
    local heading fname
    heading=$(grep -m1 '^## ' "$frag" | sed 's/^## //')
    fname=$(basename "$frag")
    section+="| ${heading} | \`.agentic/fragments/${fname}\` |"$'\n'
  done

  printf '%s' "$section"
}

# ── Technical Stack section ───────────────────────────────────────────────────
build_tech_stack_section() {
  # Check if tech_stack key exists and is not null
  local has_tech
  has_tech=$(yq '.tech_stack // "null"' "$PROFILE_FILE")
  [[ "$has_tech" == "null" ]] && return

  local section=""
  section+=$'\n## Technical Stack\n\n'
  section+="| Layer | Technology |"$'\n'
  section+="|-------|-----------|"$'\n'

  # Ordered field definitions: "yq_key|display_label"
  local -a field_defs=(
    "language_runtime|Language"
    "package_manager|Package Manager"
    "backend_framework|Backend Framework"
    "frontend_framework|Frontend Framework"
    "ui_component_library|UI Components"
    "css_framework|CSS"
    "build_tool|Build Tool"
    "test_framework|Test Framework"
    "cli_framework|CLI Framework"
    "database|Database"
    "messaging|Messaging"
  )

  for field_def in "${field_defs[@]}"; do
    local key="${field_def%%|*}"
    local label="${field_def##*|}"
    local value
    value=$(yq ".tech_stack.${key} // \"null\"" "$PROFILE_FILE")
    [[ -z "$value" || "$value" == "null" ]] && continue
    section+="| ${label} | ${value} |"$'\n'
  done

  # Additional items (array)
  local additional_raw
  additional_raw=$(yq '.tech_stack.additional // []' "$PROFILE_FILE")
  if [[ "$additional_raw" != "[]" && "$additional_raw" != "null" ]]; then
    local additional_items=()
    while IFS= read -r item; do
      [[ -z "$item" || "$item" == "null" ]] && continue
      additional_items+=("$item")
    done < <(yq '.tech_stack.additional[]' "$PROFILE_FILE" 2>/dev/null || true)
    if [[ ${#additional_items[@]} -gt 0 ]]; then
      local joined
      joined=$(IFS=", "; echo "${additional_items[*]}")
      section+="| Additional | ${joined} |"$'\n'
    fi
  fi

  printf '%s' "$section"
}

# ── Skills section ────────────────────────────────────────────────────────────
build_skills_section() {
  local full_mode="$1"  # "true" or "false"

  local skills_list=()
  while IFS= read -r _skill; do
    skills_list+=("$_skill")
  done < <(yq '.skills[]' "$PROFILE_FILE" 2>/dev/null || true)

  # Nothing to do if no skills declared
  [[ ${#skills_list[@]} -eq 0 ]] && return

  local skills_index="$LIBRARY/index/skills.json"
  [[ ! -f "$skills_index" ]] && {
    echo "Warning: index/skills.json not found — skipping Skills section" >&2
    return
  }

  if [[ "$full_mode" == "true" ]]; then
    # Full mode: embed complete SKILL.md content
    local section=""
    section+=$'\n## Skills\n\n'
    for skill_name in "${skills_list[@]+"${skills_list[@]}"}"; do
      [[ -z "$skill_name" || "$skill_name" == "null" ]] && continue
      local skill_path
      skill_path=$(jq -r --arg n "$skill_name" '.skills[] | select(.name == $n) | .path' "$skills_index")
      if [[ -z "$skill_path" || "$skill_path" == "null" ]]; then
        echo "Warning: skill '$skill_name' not found in index — skipping" >&2
        continue
      fi
      local skill_file="$LIBRARY/$skill_path"
      if [[ ! -f "$skill_file" ]]; then
        echo "Warning: skill file '$skill_file' not found — skipping" >&2
        continue
      fi
      section+=$'\n<!-- skill: '"$skill_name"' -->\n\n'
      section+=$(cat "$skill_file")
      section+=$'\n'
    done
    printf '%s' "$section"
  else
    # Lean mode: listing table
    local section=""
    section+=$'\n## Skills\n\n'
    section+="Load the relevant skill file before starting the task."$'\n\n'
    section+="| Skill | Description | Path |"$'\n'
    section+="|-------|-------------|------|"$'\n'

    for skill_name in "${skills_list[@]+"${skills_list[@]}"}"; do
      [[ -z "$skill_name" || "$skill_name" == "null" ]] && continue
      local skill_path skill_desc
      skill_path=$(jq -r --arg n "$skill_name" '.skills[] | select(.name == $n) | .path' "$skills_index")
      skill_desc=$(jq -r --arg n "$skill_name" '.skills[] | select(.name == $n) | .description' "$skills_index")
      if [[ -z "$skill_path" || "$skill_path" == "null" ]]; then
        echo "Warning: skill '$skill_name' not found in index — skipping" >&2
        continue
      fi
      section+="| ${skill_name} | ${skill_desc} | \`${skill_path}\` |"$'\n'
    done
    printf '%s' "$section"
  fi
}

# ── Shared OUTPUT header (used by both compose_flat and compose_nested) ───────
OUTPUT=$(cat <<HEADER
# Agent Instructions — ${PROJECT_NAME}

<!-- AUTO-GENERATED by agentic library -->
<!-- Source profile: ${PROFILE_NAME} (v${PROFILE_VER}) -->
<!-- Generated: ${GENERATED_AT} -->
<!-- DO NOT EDIT the generated sections — run \`just compose ${PROFILE} <target>\` to regenerate -->

HEADER
)

# Project-specific header (from profile output.project_header)
if [[ -n "$PROJECT_HEADER" && "$PROJECT_HEADER" != "null" ]]; then
  OUTPUT+=$'\n'"## Project Context"$'\n\n'"${PROJECT_HEADER}"$'\n'
fi

# Commands section
if [[ -n "$BUILD_CMD" || -n "$TEST_CMD" || -n "$LINT_CMD" ]]; then
  OUTPUT+=$'\n'"## Commands"$'\n\n'
  [[ -n "$BUILD_CMD" && "$BUILD_CMD" != "null" ]] && OUTPUT+="- **Build**: \`${BUILD_CMD}\`"$'\n'
  [[ -n "$TEST_CMD"  && "$TEST_CMD"  != "null" ]] && OUTPUT+="- **Test**: \`${TEST_CMD}\`"$'\n'
  [[ -n "$LINT_CMD"  && "$LINT_CMD"  != "null" ]] && OUTPUT+="- **Lint**: \`${LINT_CMD}\`"$'\n'
fi

# Technical Stack section
OUTPUT+=$(build_tech_stack_section)

# ── Flat mode (single AGENTS.md) ─────────────────────────────────────────────
compose_flat() {
  if [[ "$FULL_MODE" == "true" ]]; then
    OUTPUT+=$(inline_fragments)
  else
    OUTPUT+=$(build_fragment_reference_table)
  fi

  OUTPUT+=$(build_skills_section "$FULL_MODE")

  # Local override (project-specific additions, if present)
  LOCAL_OVERRIDE="$TARGET/AGENTS.local.md"
  if [[ -f "$LOCAL_OVERRIDE" ]]; then
    OUTPUT+=$'\n<!-- local override: AGENTS.local.md -->\n\n'
    OUTPUT+=$(cat "$LOCAL_OVERRIDE")
    OUTPUT+=$'\n'
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    printf '%s\n' "$OUTPUT"
  else
    mkdir -p "$TARGET"
    echo "$OUTPUT" > "$TARGET/AGENTS.md"

    LOCK_DIR="$TARGET/.agentic"
    mkdir -p "$LOCK_DIR"

    if [[ "$FULL_MODE" == "false" ]]; then
      # Lean mode: copy fragments and write lock with mode: lean
      copy_fragments_to_target
      cat > "$LOCK_DIR/config.yaml" <<LOCK
# Managed by agentic library — do not edit manually
# Regenerate with: just compose ${PROFILE} ${TARGET}
library_commit: "$(cd "$LIBRARY" && git rev-parse HEAD 2>/dev/null || echo "unknown")"
profile: "${PROFILE}"
profile_version: "${PROFILE_VER}"
composed_at: "${GENERATED_AT}"
mode: lean
LOCK
    else
      # Full mode: write lock with mode: full (no fragments copied)
      cat > "$LOCK_DIR/config.yaml" <<LOCK
# Managed by agentic library — do not edit manually
# Regenerate with: just compose-full ${PROFILE} ${TARGET}
library_commit: "$(cd "$LIBRARY" && git rev-parse HEAD 2>/dev/null || echo "unknown")"
profile: "${PROFILE}"
profile_version: "${PROFILE_VER}"
composed_at: "${GENERATED_AT}"
mode: full
LOCK
    fi

    echo "Composed AGENTS.md → $TARGET/AGENTS.md"
  fi
}

# ── Nested mode (root + per-tier AGENTS.md files) ────────────────────────────
compose_nested() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' RETURN

  # ── Root fragments: base + practices + domains (cross-cutting) ─────────────
  local root_frags=()
  local _grp _subdir _names _n _fp

  for _grp in "base|agents/base" "practices|agents/practices" "domains|agents/domains"; do
    local _g="${_grp%%|*}"
    local _sd="${_grp##*|}"
    _names=()
    while IFS= read -r _n; do
      [[ -n "$_n" && "$_n" != "null" ]] && _names+=("$_n")
    done < <(yq ".fragments.${_g}[]" "$PROFILE_FILE" 2>/dev/null || true)
    for name in "${_names[@]+"${_names[@]}"}"; do
      _fp="$LIBRARY/$_sd/$name.md"
      if [[ -f "$_fp" ]]; then
        root_frags+=("$_fp")
      else
        echo "Warning: fragment '$_sd/$name.md' not found — skipping" >&2
      fi
    done
  done

  # ── Tier names ─────────────────────────────────────────────────────────────
  local tiers=()
  while IFS= read -r _t; do
    [[ -n "$_t" && "$_t" != "null" ]] && tiers+=("$_t")
  done < <(yq '.tiers | keys | .[]' "$PROFILE_FILE" 2>/dev/null || true)

  # ── Per-tier fragment resolution ────────────────────────────────────────────
  local all_tier_frags=()
  local tier grp subdir

  for tier in "${tiers[@]+"${tiers[@]}"}"; do
    local tf="$tmp_dir/tier_${tier}.list"
    for grp in languages frameworks architecture; do
      case "$grp" in
        languages)    subdir="agents/languages" ;;
        frameworks)   subdir="agents/frameworks" ;;
        architecture) subdir="agents/architecture" ;;
      esac
      _names=()
      while IFS= read -r _n; do
        [[ -n "$_n" && "$_n" != "null" ]] && _names+=("$_n")
      done < <(yq ".tiers.${tier}.${grp}[]" "$PROFILE_FILE" 2>/dev/null || true)
      for name in "${_names[@]+"${_names[@]}"}"; do
        _fp="$LIBRARY/$subdir/$name.md"
        if [[ -f "$_fp" ]]; then
          echo "$_fp" >> "$tf"
          all_tier_frags+=("$_fp")
        else
          echo "Warning: fragment '$subdir/$name.md' not found — skipping" >&2
        fi
      done
    done
  done

  # ── Copy ALL fragments to .agentic/fragments/ (always in nested mode) ───────
  local dest="$TARGET/.agentic/fragments"
  mkdir -p "$dest"
  for f in "${root_frags[@]+"${root_frags[@]}"}"; do
    cp "$f" "$dest/$(basename "$f")"
  done
  for f in "${all_tier_frags[@]+"${all_tier_frags[@]}"}"; do
    cp "$f" "$dest/$(basename "$f")"
  done

  # ── Root AGENTS.md ──────────────────────────────────────────────────────────
  local root_out="$OUTPUT"

  if [[ "$FULL_MODE" == "true" ]]; then
    for f in "${root_frags[@]+"${root_frags[@]}"}"; do
      local rel_path="${f#$LIBRARY/}"
      root_out+=$'\n<!-- fragment: '"$rel_path"' -->\n\n'
      root_out+=$(cat "$f")
      root_out+=$'\n'
    done
  else
    root_out+=$'\n## Conventions & Patterns\n\n'
    root_out+="> Cross-cutting conventions — applied across all tiers."$'\n\n'
    root_out+="| Area | File |"$'\n'
    root_out+="|------|------|"$'\n'
    for f in "${root_frags[@]+"${root_frags[@]}"}"; do
      local h fname
      h=$(grep -m1 '^## ' "$f" | sed 's/^## //')
      fname=$(basename "$f")
      root_out+="| ${h} | \`.agentic/fragments/${fname}\` |"$'\n'
    done
  fi

  # Tier listing (always a reference table regardless of --full)
  root_out+=$'\n## Tiers\n\n'
  root_out+="> Load the relevant tier file for tier-specific language, framework, and architecture guidelines."$'\n\n'
  root_out+="| Tier | File |"$'\n'
  root_out+="|------|------|"$'\n'
  for tier in "${tiers[@]+"${tiers[@]}"}"; do
    root_out+="| ${tier} | \`${tier}/AGENTS.md\` |"$'\n'
  done

  root_out+=$(build_skills_section "$FULL_MODE")

  mkdir -p "$TARGET"
  printf '%s\n' "$root_out" > "$TARGET/AGENTS.md"

  # ── Per-tier AGENTS.md ──────────────────────────────────────────────────────
  for tier in "${tiers[@]+"${tiers[@]}"}"; do
    local tf="$tmp_dir/tier_${tier}.list"
    local tier_frags=()
    if [[ -f "$tf" ]]; then
      while IFS= read -r fp; do
        [[ -n "$fp" ]] && tier_frags+=("$fp")
      done < "$tf"
    fi

    local tier_cap
    tier_cap=$(echo "$tier" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')

    local tier_out=""
    tier_out+="# Agent Instructions — ${PROJECT_NAME}/${tier}"$'\n\n'
    tier_out+="<!-- AUTO-GENERATED by agentic library -->"$'\n'
    tier_out+="<!-- Source profile: ${PROFILE_NAME} (v${PROFILE_VER}) — tier: ${tier} -->"$'\n'
    tier_out+="<!-- Generated: ${GENERATED_AT} -->"$'\n'
    tier_out+="<!-- DO NOT EDIT — run \`just compose ${PROFILE} <target>\` to regenerate -->"$'\n\n'

    if [[ ${#tier_frags[@]} -gt 0 ]]; then
      if [[ "$FULL_MODE" == "true" ]]; then
        for f in "${tier_frags[@]}"; do
          local rel_path="${f#$LIBRARY/}"
          tier_out+=$'\n<!-- fragment: '"$rel_path"' -->\n\n'
          tier_out+=$(cat "$f")
          tier_out+=$'\n'
        done
      else
        tier_out+="## ${tier_cap} Guidelines"$'\n\n'
        tier_out+="> ${tier_cap}-specific language, framework, and architecture conventions."$'\n\n'
        tier_out+="| Area | File |"$'\n'
        tier_out+="|------|------|"$'\n'
        for f in "${tier_frags[@]}"; do
          local h fname
          h=$(grep -m1 '^## ' "$f" | sed 's/^## //')
          fname=$(basename "$f")
          tier_out+="| ${h} | \`.agentic/fragments/${fname}\` |"$'\n'
        done
      fi
    fi

    tier_out+=$'\n## Cross-tier Conventions\n\n'
    tier_out+="> Base conventions and practices are in the root \`AGENTS.md\`."$'\n'

    mkdir -p "$TARGET/$tier"
    printf '%s\n' "$tier_out" > "$TARGET/$tier/AGENTS.md"
    echo "Composed ${tier}/AGENTS.md → $TARGET/${tier}/AGENTS.md"
  done

  # ── Lock file ───────────────────────────────────────────────────────────────
  mkdir -p "$TARGET/.agentic"
  local compose_mode="lean"
  [[ "$FULL_MODE" == "true" ]] && compose_mode="full"
  {
    echo "# Managed by agentic library — do not edit manually"
    echo "# Regenerate with: just compose ${PROFILE} ${TARGET}"
    echo "library_commit: \"$(cd "$LIBRARY" && git rev-parse HEAD 2>/dev/null || echo unknown)\""
    echo "profile: \"${PROFILE}\""
    echo "profile_version: \"${PROFILE_VER}\""
    echo "composed_at: \"${GENERATED_AT}\""
    echo "mode: ${compose_mode}"
    echo "structure: nested"
    echo "tiers:"
    for tier in "${tiers[@]+"${tiers[@]}"}"; do
      echo "  - ${tier}"
    done
  } > "$TARGET/.agentic/config.yaml"

  echo "Composed AGENTS.md → $TARGET/AGENTS.md"
}

# ── Dispatch ──────────────────────────────────────────────────────────────────
if [[ "$DRY_RUN" == "true" || "$STRUCTURE" == "flat" ]]; then
  compose_flat
else
  compose_nested
fi
