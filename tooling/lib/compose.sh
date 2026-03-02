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

# ── Fragment loading ──────────────────────────────────────────────────────────
load_fragments() {
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
    printf '\n<!-- fragment: %s/%s -->\n\n' "$subdir" "$name"
    cat "$frag_file"
    printf '\n'
  done
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
    # Slim mode: listing table
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

# ── Assemble ──────────────────────────────────────────────────────────────────
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

# Fragments in layer order
OUTPUT+=$(load_fragments "base"         "agents/base")
OUTPUT+=$(load_fragments "languages"    "agents/languages")
OUTPUT+=$(load_fragments "frameworks"   "agents/frameworks")
OUTPUT+=$(load_fragments "architecture" "agents/architecture")
OUTPUT+=$(load_fragments "practices"    "agents/practices")
OUTPUT+=$(load_fragments "domains"      "agents/domains")

# Skills section (slim listing or full embedded, depending on --full flag)
OUTPUT+=$(build_skills_section "$FULL_MODE")

# Local override (project-specific additions, if present)
LOCAL_OVERRIDE="$TARGET/AGENTS.local.md"
if [[ -f "$LOCAL_OVERRIDE" ]]; then
  OUTPUT+=$'\n<!-- local override: AGENTS.local.md -->\n\n'
  OUTPUT+=$(cat "$LOCAL_OVERRIDE")
  OUTPUT+=$'\n'
fi

# ── Output ────────────────────────────────────────────────────────────────────
# Determine output filename
OUTPUT_FILENAME="AGENTS.md"
[[ "$FULL_MODE" == "true" ]] && OUTPUT_FILENAME="AGENTS.full.md"

if [[ "$DRY_RUN" == "true" ]]; then
  printf '%s\n' "$OUTPUT"
else
  mkdir -p "$TARGET"
  echo "$OUTPUT" > "$TARGET/$OUTPUT_FILENAME"

  # Write lock file (only for primary AGENTS.md, not full mode)
  if [[ "$FULL_MODE" == "false" ]]; then
    LOCK_DIR="$TARGET/.agentic"
    mkdir -p "$LOCK_DIR"
    cat > "$LOCK_DIR/config.yaml" <<LOCK
# Managed by agentic library — do not edit manually
# Regenerate with: just compose ${PROFILE} ${TARGET}
library_commit: "$(cd "$LIBRARY" && git rev-parse HEAD 2>/dev/null || echo "unknown")"
profile: "${PROFILE}"
profile_version: "${PROFILE_VER}"
composed_at: "${GENERATED_AT}"
LOCK
  fi

  echo "Composed ${OUTPUT_FILENAME} → $TARGET/$OUTPUT_FILENAME"
fi
