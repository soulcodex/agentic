#!/usr/bin/env bash
# compose.sh — Assembles AGENTS.md from profile + fragments
# Called by: just compose <profile> <target>
set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tooling/lib/common.sh
source "$SCRIPT_DIR/common.sh"

# ── Argument parsing ──────────────────────────────────────────────────────────
LIBRARY=""
PROFILE=""
PROFILE_FILE=""
TARGET=""
DRY_RUN=false
FULL_MODE=false
LINK_MODE=false
IMPORT_MODE="adopt"  # default: adopt when user-authored AGENTS.md detected
IMPORT_MODE_SET=false  # tracks if --import was explicitly passed
YES_FLAG=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --library)      require_arg "--library" "$2"; LIBRARY="$2";      shift 2 ;;
    --profile)     require_arg "--profile" "$2"; PROFILE="$2";      shift 2 ;;
    --profile-file) require_arg "--profile-file" "$2"; PROFILE_FILE="$2"; shift 2 ;;
    --target)      require_arg "--target" "$2";  TARGET="$2";       shift 2 ;;
    --dry-run)     DRY_RUN=true;      shift   ;;
    --full)        FULL_MODE=true;     shift   ;;
    --link)        LINK_MODE=true;     shift   ;;
    --import)
      require_arg "--import" "$2"
      IMPORT_MODE_SET=true
      case "$2" in
        adopt|skip|overwrite) IMPORT_MODE="$2" ;;
        *) echo "Error: --import must be one of: adopt, skip, overwrite" >&2; exit 1 ;;
      esac
      shift 2 ;;
    -y|--yes)      YES_FLAG=true;     shift   ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$LIBRARY" ]] && { echo "Error: --library required" >&2; exit 1; }
[[ -z "$PROFILE" && -z "$PROFILE_FILE" ]] && { echo "Error: --profile or --profile-file required" >&2; exit 1; }
[[ -z "$TARGET"  ]] && { echo "Error: --target required" >&2; exit 1; }

# ── Profile resolution ────────────────────────────────────────────────────────
# If --profile-file is provided, use it directly; otherwise lookup by name
if [[ -n "$PROFILE_FILE" ]]; then
  [[ ! -f "$PROFILE_FILE" ]] && {
    echo "Error: profile file not found at $PROFILE_FILE" >&2
    exit 1
  }
  # Derive profile name from file for lock metadata
  PROFILE=$(yq '.meta.name // "local"' "$PROFILE_FILE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
else
  PROFILE_FILE="$LIBRARY/profiles/$PROFILE.yaml"
  [[ ! -f "$PROFILE_FILE" ]] && {
    echo "Error: profile '$PROFILE' not found at $PROFILE_FILE" >&2
    echo "Run 'just list-profiles' to see available profiles." >&2
    exit 1
  }
fi

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

# Custom rules configuration (for AGENTS.local.md injection)
CUSTOM_RULES_PLACEMENT=$(yq '.output.custom_rules.placement // "append"' "$PROFILE_FILE")
CUSTOM_RULES_AFTER_SECTION=$(yq '.output.custom_rules.after_section // ""' "$PROFILE_FILE")

# Apply profile import strategy if --import flag was not explicitly provided
if [[ "$IMPORT_MODE_SET" == "false" ]]; then
  IMPORT_MODE=$(yq '.output.custom_rules.import_strategy // "adopt"' "$PROFILE_FILE")
fi

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
    local rel_path="${frag#"$LIBRARY"/}"
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

# ── Fragment symlink (used in --link mode) ────────────────────────────────────
link_fragments_to_library() {
  local dest="$TARGET/.agentic/fragments"
  # Remove any existing copy or symlink using safe_rm_rf
  safe_rm_rf "$dest"
  ln -sf "$LIBRARY/agents" "$dest"
}

# ── Fragment reference table (lean mode) ──────────────────────────────────────
build_fragment_reference_table() {
  local section=""
  section+=$'\n## Conventions & Patterns\n\n'
  section+="> Load the relevant file for full guidelines on that area."$'\n\n'
  section+="| Area | File |"$'\n'
  section+="|------|------|"$'\n'

  for frag in "${RESOLVED_FRAGMENTS[@]+"${RESOLVED_FRAGMENTS[@]}"}"; do
    local heading fname rel_path group
    heading=$(grep -m1 '^## ' "$frag" | head -1)
    heading="${heading#'## '}"
    fname=$(basename "$frag")
    # In link mode, preserve the subdirectory structure since .agentic/fragments is a symlink
    # to $LIBRARY/agents where files live in subdirectories (e.g., base/git-conventions.md)
    if [[ "$LINK_MODE" == "true" ]]; then
      rel_path="${frag#"$LIBRARY"/agents/}"
      group=$(dirname "$rel_path")
      if [[ "$group" == "." ]]; then
        # Fragment is directly in agents/ (no subdirectory)
        section+="| ${heading} | \`.agentic/fragments/${fname}\` |"$'\n'
      else
        # Fragment is in a subdirectory (e.g., base/git-conventions.md)
        section+="| ${heading} | \`.agentic/fragments/${group}/${fname}\` |"$'\n'
      fi
    else
      # Copy mode: fragments are flattened into .agentic/fragments/
      section+="| ${heading} | \`.agentic/fragments/${fname}\` |"$'\n'
    fi
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
      local joined=""
      local item
      for item in "${additional_items[@]}"; do
        [[ -n "$joined" ]] && joined+=", "
        joined+="$item"
      done
      section+="| Additional | ${joined} |"$'\n'
    fi
  fi

  printf '%s' "$section"
}

# ── Commands section builder ───────────────────────────────────────────────────
build_commands_block() {
  local build_cmd="$1" test_cmd="$2" lint_cmd="$3"
  local section=""
  [[ -z "$build_cmd" && -z "$test_cmd" && -z "$lint_cmd" ]] && return
  [[ "$build_cmd" == "null" && "$test_cmd" == "null" && "$lint_cmd" == "null" ]] && return

  section+=$'\n## Commands\n\n'
  [[ -n "$build_cmd" && "$build_cmd" != "null" ]] && section+="- **Build**: \`${build_cmd}\`"$'\n'
  [[ -n "$test_cmd"  && "$test_cmd"  != "null" ]] && section+="- **Test**: \`${test_cmd}\`"$'\n'
  [[ -n "$lint_cmd"  && "$lint_cmd"  != "null" ]] && section+="- **Lint**: \`${lint_cmd}\`"$'\n'
  printf '%s' "$section"
}

# ── Proprietary Libraries section builder ─────────────────────────────────────
build_proprietary_libraries_section() {
  local profile_file="$1"
  local yq_path="$2"

  local count
  count=$(yq "${yq_path} | length" "$profile_file" 2>/dev/null || echo "0")
  [[ "$count" == "0" || "$count" == "null" ]] && return

  local section=""
  section+=$'\n## Proprietary Libraries\n\n'
  section+="> Internal packages not available on public registries. Load the relevant docs before making changes."$'\n\n'
  section+="| Package | Description | Docs |"$'\n'
  section+="|---------|-------------|------|"$'\n'

  local i=0
  while [[ $i -lt $count ]]; do
    local name desc url_doc
    name=$(yq    "${yq_path}[$i].name"            "$profile_file")
    desc=$(yq    "${yq_path}[$i].description"     "$profile_file")
    url_doc=$(yq "${yq_path}[$i].url_doc // \"\"" "$profile_file")
    local docs_cell="—"
    [[ -n "$url_doc" && "$url_doc" != "null" ]] && docs_cell="[docs](${url_doc})"
    section+="| \`${name}\` | ${desc} | ${docs_cell} |"$'\n'
    i=$(( i + 1 ))
  done

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

# ── User-authored AGENTS.md detection and migration ──────────────────────────

# Check if existing AGENTS.md is user-authored (no AUTO-GENERATED marker)
is_user_authored_agents() {
  local target_dir="$1"
  local agents_file="$target_dir/AGENTS.md"
  [[ ! -f "$agents_file" ]] && return 1  # No existing file
  if grep -q "AUTO-GENERATED by agentic library" "$agents_file"; then
    return 1  # Has marker, so it's already generated
  fi
  return 0  # User-authored
}

# Handle user-authored AGENTS.md based on import mode
handle_user_authored_agents() {
  local target_dir="$1"
  local import_mode="$2"  # adopt, skip, or overwrite
  local yes_flag="$3"     # true or false

  local agents_file="$target_dir/AGENTS.md"
  local local_file="$target_dir/AGENTS.local.md"

  case "$import_mode" in
    adopt)
      if [[ -f "$local_file" ]]; then
        echo "Warning: AGENTS.local.md already exists — skipping migration of existing AGENTS.md" >&2
        echo "Adopted existing AGENTS.md → AGENTS.local.md (review and clean up manually)" >&2
        return 1
      else
        # Copy existing AGENTS.md to AGENTS.local.md
        cp "$agents_file" "$local_file"
        echo "Adopted existing AGENTS.md → AGENTS.local.md (review and clean up manually)"
        return 0
      fi
      ;;
    skip)
      echo "Error: Existing AGENTS.md found without AUTO-GENERATED marker (user-authored)." >&2
      echo "Use --import adopt to migrate to AGENTS.local.md, or --import overwrite to replace." >&2
      return 1
      ;;
    overwrite)
      # Confirm if not -y and stdin is a TTY
      if [[ "$yes_flag" != "true" ]] && [[ -t 0 ]]; then
        echo "Existing user-authored AGENTS.md will be overwritten. Continue? [Y/n]: "
        read -r answer
        case "${answer^^}" in
          N) return 1 ;;
        esac
      fi
      return 0  # Proceed to overwrite
      ;;
  esac
}

# ── Local override injection helper ───────────────────────────────────────────

# Injects AGENTS.local.md content into specified output variable at configured placement
# Usage: inject_local_override <target_dir> <output_var_name> [override_name]
# The output is modified in place via nameref
# override_name is optional and defaults to "AGENTS.local.md", used in the comment
inject_local_override() {
  local target_dir="$1"
  local -n output_ref="$2"  # nameref to the caller's variable
  local override_name="${3:-AGENTS.local.md}"
  local local_file="$target_dir/AGENTS.local.md"

  # Skip if file doesn't exist or is empty
  [[ ! -f "$local_file" ]] && return
  [[ ! -s "$local_file" ]] && return

  local local_content
  local_content=$(cat "$local_file")

  local placement="${CUSTOM_RULES_PLACEMENT:-append}"

  case "$placement" in
    append)
      output_ref+=$'\n\n<!-- local override: '"$override_name"' -->\n\n'
      output_ref+="$local_content"
      output_ref+=$'\n'
      ;;
    prepend)
      # Insert after the DO NOT EDIT comment block (always present in generated header)
      # Find the position after "<!-- DO NOT EDIT"
      local header_end
      header_end=$(echo "$output_ref" | grep -n "<!-- DO NOT EDIT" | head -1 | cut -d: -f1 || true)
      if [[ -n "$header_end" && "$header_end" -gt 0 ]]; then
        # Insert after the DO NOT EDIT line
        local before after
        before=$(echo "$output_ref" | head -n "$header_end")
        after=$(echo "$output_ref" | tail -n +$((header_end + 1)))
        output_ref="$before"$'\n\n'"<!-- local override: ${override_name} -->\n\n$local_content"$'\n\n'"$after"
      else
        # Defensive fallback: prepend at very top
        echo "Warning: Could not find header anchor — prepending at top" >&2
        output_ref="<!-- local override: ${override_name} -->"$'\n\n'"$local_content"$'\n\n'"$output_ref"
      fi
      ;;
    after_section)
      local after_section="${CUSTOM_RULES_AFTER_SECTION:-}"
      if [[ -z "$after_section" ]]; then
        echo "Warning: custom_rules.placement is 'after_section' but after_section is not set — using append" >&2
        output_ref+=$'\n\n<!-- local override: '"$override_name"' -->\n\n'
        output_ref+="$local_content"
        output_ref+=$'\n'
        return
      fi
      # Find the H2 section using fixed-string matching (not regex)
      local section_marker="## ${after_section}"
      local section_pos
      section_pos=$(echo "$output_ref" | grep -nF "$section_marker" | head -1 | cut -d: -f1 || true)
      if [[ -n "$section_pos" ]]; then
        # Find the next H2 or end of file
        local next_section_pos
        next_section_pos=$(echo "$output_ref" | tail -n +$((section_pos + 1)) | grep -n "^## " | head -1 | cut -d: -f1 || true)
        local before after
        if [[ -n "$next_section_pos" ]]; then
          next_section_pos=$((section_pos + next_section_pos - 1))
          before=$(echo "$output_ref" | head -n "$next_section_pos")
          after=$(echo "$output_ref" | tail -n +$((next_section_pos + 1)))
        else
          before="$output_ref"
          after=""
        fi
        output_ref="$before"$'\n\n'"<!-- local override: ${override_name} -->\n\n$local_content"$'\n\n'"$after"
      else
        # Section not found — append with warning
        echo "Warning: Section '## ${after_section}' not found — appending local override" >&2
        output_ref+=$'\n\n<!-- local override: '"$override_name"' -->\n\n'
        output_ref+="$local_content"
        output_ref+=$'\n'
      fi
      ;;
  esac
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
  OUTPUT+=$'\n\n---\n\n'"## Project Context"$'\n\n'"${PROJECT_HEADER}"$'\n'
fi

# Technical Stack section
OUTPUT+=$(build_tech_stack_section)
OUTPUT+=$(build_proprietary_libraries_section "$PROFILE_FILE" ".tech_stack.proprietary_libraries")

# ── Flat mode (single AGENTS.md) ─────────────────────────────────────────────
compose_flat() {
  # Check for user-authored AGENTS.md and handle based on import mode
  if is_user_authored_agents "$TARGET"; then
    handle_user_authored_agents "$TARGET" "$IMPORT_MODE" "$YES_FLAG" || {
      # Non-zero return means we should abort (either skip, or adopt found existing AGENTS.local.md)
      local local_file="$TARGET/AGENTS.local.md"
      if [[ "$IMPORT_MODE" == "adopt" && -f "$local_file" ]]; then
        # adopt mode but AGENTS.local.md already exists - just skip the migration but continue
        :
      else
        exit 1
      fi
    }
  fi

  OUTPUT+=$(build_commands_block "$BUILD_CMD" "$TEST_CMD" "$LINT_CMD")

  if [[ "$FULL_MODE" == "true" ]]; then
    OUTPUT+=$(inline_fragments)
  else
    OUTPUT+=$(build_fragment_reference_table)
  fi

  OUTPUT+=$(build_skills_section "$FULL_MODE")

  # Inject local override (AGENTS.local.md) at configured placement
  inject_local_override "$TARGET" OUTPUT "AGENTS.local.md"

  if [[ "$DRY_RUN" == "true" ]]; then
    printf '%s\n' "$OUTPUT"
  else
    mkdir -p "$TARGET"
    # Atomic write: write to temp file first, then move into place
    local tmp_agents
    trap '[[ -n "${tmp_agents:-}" ]] && rm -f "$tmp_agents"' RETURN
    tmp_agents=$(mktemp "$TARGET/.agents-tmp-XXXXXX")
    printf '%s\n' "$OUTPUT" > "$tmp_agents"
    mv "$tmp_agents" "$TARGET/AGENTS.md"
    tmp_agents=""  # clear so RETURN trap is a no-op
    format_markdown "$TARGET/AGENTS.md"

    LOCK_DIR="$TARGET/.agentic"
    mkdir -p "$LOCK_DIR"

    if [[ "$FULL_MODE" == "false" ]]; then
      # Lean mode: link or copy fragments and write lock with mode: lean
      if [[ "$LINK_MODE" == "true" ]]; then
        link_fragments_to_library
      else
        copy_fragments_to_target
      fi
      local deploy_mode_str="copy"
      [[ "$LINK_MODE" == "true" ]] && deploy_mode_str="link"
      cat > "$LOCK_DIR/config.yaml" <<LOCK
# Managed by agentic library — do not edit manually
# Regenerate with: just compose ${PROFILE} ${TARGET}
library_commit: "$(cd "$LIBRARY" && git rev-parse HEAD 2>/dev/null || echo "unknown")"
profile: "${PROFILE}"
profile_version: "${PROFILE_VER}"
composed_at: "${GENERATED_AT}"
mode: lean
agentic_root: "${LIBRARY}"
deploy_mode: ${deploy_mode_str}
active_vendors: []
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
agentic_root: "${LIBRARY}"
active_vendors: []
LOCK
    fi

    # Copy profile to .agentic/profile.yaml for local customization
    # (skip if already using the local profile as source)
    local profile_dst="$LOCK_DIR/profile.yaml"
    local profile_src_real profile_dst_real
    profile_src_real="$(cd "$(dirname "$PROFILE_FILE")" && pwd)/$(basename "$PROFILE_FILE")"
    if [[ -f "$profile_dst" ]]; then
      profile_dst_real="$(cd "$(dirname "$profile_dst")" && pwd)/$(basename "$profile_dst")"
    else
      profile_dst_real="$profile_dst"
    fi
    if [[ "$profile_src_real" != "$profile_dst_real" ]]; then
      cp "$PROFILE_FILE" "$profile_dst"
    fi

    # Seed MCP servers from profile (no-op if mcp key absent)
    local has_mcp
    has_mcp=$(yq '.mcp.servers // "null"' "$PROFILE_FILE")
    if [[ "$has_mcp" != "null" && "$has_mcp" != "{}" ]]; then
      local mcp_strategy
      mcp_strategy=$(yq '.mcp.strategy // "merge"' "$PROFILE_FILE")
      bash "$LIBRARY/tooling/lib/mcp.sh" \
        --action seed \
        --target "$TARGET" \
        --profile-file "$PROFILE_FILE" \
        --strategy "$mcp_strategy"
    fi

    update_gitignore
    echo "Composed AGENTS.md → $TARGET/AGENTS.md"
  fi
}

# ── Nested mode (root + per-tier AGENTS.md files) ────────────────────────────
compose_nested() {
  local tmp_dir
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' RETURN

  # Check for user-authored AGENTS.md and handle based on import mode
  if is_user_authored_agents "$TARGET"; then
    handle_user_authored_agents "$TARGET" "$IMPORT_MODE" "$YES_FLAG" || {
      local local_file="$TARGET/AGENTS.local.md"
      if [[ "$IMPORT_MODE" == "adopt" && -f "$local_file" ]]; then
        :
      else
        exit 1
      fi
    }
  fi

  # ── Root fragments: base + practices + domains (cross-cutting) ─────────────
  local root_frags=()
  local _grp _names _n _fp

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
      local rel_path="${f#"$LIBRARY"/}"
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
      local h fname rel_path group
      h=$(grep -m1 '^## ' "$f" | head -1)
      h="${h#'## '}"
      fname=$(basename "$f")
      # In link mode, preserve the subdirectory structure
      if [[ "$LINK_MODE" == "true" ]]; then
        rel_path="${f#"$LIBRARY"/agents/}"
        group=$(dirname "$rel_path")
        if [[ "$group" == "." ]]; then
          root_out+="| ${h} | \`.agentic/fragments/${fname}\` |"$'\n'
        else
          root_out+="| ${h} | \`.agentic/fragments/${group}/${fname}\` |"$'\n'
        fi
      else
        root_out+="| ${h} | \`.agentic/fragments/${fname}\` |"$'\n'
      fi
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

  # Inject local override for root AGENTS.md
  inject_local_override "$TARGET" root_out "AGENTS.local.md"

  mkdir -p "$TARGET"
  # Atomic write: write to temp file first, then move into place
  local tmp_agents
  trap '[[ -n "${tmp_agents:-}" ]] && rm -f "$tmp_agents"' RETURN
  tmp_agents=$(mktemp "$TARGET/.agents-tmp-XXXXXX")
  printf '%s\n' "$root_out" > "$tmp_agents"
  mv "$tmp_agents" "$TARGET/AGENTS.md"
  tmp_agents=""  # clear so RETURN trap is a no-op
  format_markdown "$TARGET/AGENTS.md"

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

    local tier_build tier_test tier_lint
    tier_build=$(yq ".tiers.${tier}.commands.build_command // \"\"" "$PROFILE_FILE")
    tier_test=$(yq  ".tiers.${tier}.commands.test_command  // \"\""  "$PROFILE_FILE")
    tier_lint=$(yq  ".tiers.${tier}.commands.lint_command  // \"\""  "$PROFILE_FILE")
    tier_out+=$(build_commands_block "$tier_build" "$tier_test" "$tier_lint")

    if [[ ${#tier_frags[@]} -gt 0 ]]; then
      if [[ "$FULL_MODE" == "true" ]]; then
        for f in "${tier_frags[@]}"; do
          local rel_path="${f#"$LIBRARY"/}"
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
          h=$(grep -m1 '^## ' "$f" | head -1)
          h="${h#'## '}"
          fname=$(basename "$f")
          tier_out+="| ${h} | \`.agentic/fragments/${fname}\` |"$'\n'
        done
      fi
    fi

    tier_out+=$(build_proprietary_libraries_section "$PROFILE_FILE" ".tiers.${tier}.proprietary_libraries")

    tier_out+=$'\n## Cross-tier Conventions\n\n'
    tier_out+="> Base conventions and practices are in the root \`AGENTS.md\`."$'\n'

    # Inject tier-level local override using the shared helper
    inject_local_override "$TARGET/$tier" tier_out "AGENTS.local.md"

    mkdir -p "$TARGET/$tier"
    # Atomic write: write to temp file first, then move into place
    local tmp_tier_agents
    trap '[[ -n "${tmp_tier_agents:-}" ]] && rm -f "$tmp_tier_agents"' RETURN
    tmp_tier_agents=$(mktemp "$TARGET/$tier/.agents-tmp-XXXXXX")
    printf '%s\n' "$tier_out" > "$tmp_tier_agents"
    mv "$tmp_tier_agents" "$TARGET/$tier/AGENTS.md"
    tmp_tier_agents=""  # clear so RETURN trap is a no-op
    format_markdown "$TARGET/$tier/AGENTS.md"
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
    echo "agentic_root: \"${LIBRARY}\""
    echo "active_vendors: []"
    echo "structure: nested"
    echo "tiers:"
    for tier in "${tiers[@]+"${tiers[@]}"}"; do
      echo "  - ${tier}"
    done
  } > "$TARGET/.agentic/config.yaml"

  # Copy profile to .agentic/profile.yaml for local customization
  # (skip if already using the local profile as source)
  local profile_dst="$TARGET/.agentic/profile.yaml"
  local profile_src_real profile_dst_real
  profile_src_real="$(cd "$(dirname "$PROFILE_FILE")" && pwd)/$(basename "$PROFILE_FILE")"
  if [[ -f "$profile_dst" ]]; then
    profile_dst_real="$(cd "$(dirname "$profile_dst")" && pwd)/$(basename "$profile_dst")"
  else
    profile_dst_real="$profile_dst"
  fi
  if [[ "$profile_src_real" != "$profile_dst_real" ]]; then
    cp "$PROFILE_FILE" "$profile_dst"
  fi

  # Seed MCP servers from profile (no-op if mcp key absent)
  local has_mcp
  has_mcp=$(yq '.mcp.servers // "null"' "$PROFILE_FILE")
  if [[ "$has_mcp" != "null" && "$has_mcp" != "{}" ]]; then
    local mcp_strategy
    mcp_strategy=$(yq '.mcp.strategy // "merge"' "$PROFILE_FILE")
    bash "$LIBRARY/tooling/lib/mcp.sh" \
      --action seed \
      --target "$TARGET" \
      --profile-file "$PROFILE_FILE" \
      --strategy "$mcp_strategy"
  fi

  update_gitignore
  echo "Composed AGENTS.md → $TARGET/AGENTS.md"
}

# ── Gitignore managed block injection ─────────────────────────────────────────────
update_gitignore() {
  local gitignore="$TARGET/.gitignore"

  # Full marker strings for precise detection
  local MARKER_START="# agentic:start — managed block (do not edit manually, regenerated by agentic)"
  local MARKER_END="# agentic:end"

  # Build canonical block content based on mode
  # Copy mode (default): vendor entry-point files only
  # Link mode: vendor entry-point files + runtime directories

  local AGENTIC_BLOCK_BASE
  local AGENTIC_BLOCK_LINK

  # Copy mode block — vendor entry-points only (real files in copy mode)
  AGENTIC_BLOCK_BASE=$(cat <<BLOCK
$MARKER_START

# Vendor entry-point files — recreated by \`agentic switch\` / \`agentic sync\`
CLAUDE.md
GEMINI.md
opencode.json
.github/copilot-instructions.md
.github/instructions/
.gemini/system.md
.gemini/skills/
.claude/skills
.opencode/skills
.agents/skills

$MARKER_END
BLOCK
)

  # Link mode block — adds runtime directories (symlinks to library)
  AGENTIC_BLOCK_LINK=$(cat <<BLOCK
$MARKER_START

# Vendor entry-point files — recreated by \`agentic switch\` / \`agentic sync\`
CLAUDE.md
GEMINI.md
opencode.json
.github/copilot-instructions.md
.github/instructions/
.gemini/system.md
.gemini/skills/
.claude/skills
.opencode/skills
.agents/skills

# Agentic runtime directories — symlinks to library, recreated by \`agentic sync\`
.agentic/skills/
.agentic/fragments/
.agentic/vendor-files/

$MARKER_END
BLOCK
)

  # Select the correct block based on mode
  local AGENTIC_BLOCK
  if [[ "$LINK_MODE" == "true" ]]; then
    AGENTIC_BLOCK="$AGENTIC_BLOCK_LINK"
  else
    AGENTIC_BLOCK="$AGENTIC_BLOCK_BASE"
  fi

  # Check for marker presence using full-line matching
  local has_start=false
  local has_end=false

  if [[ -f "$gitignore" ]]; then
    grep -qxF "$MARKER_START" "$gitignore" 2>/dev/null && has_start=true || has_start=false
    grep -qxF "$MARKER_END" "$gitignore" 2>/dev/null && has_end=true || has_end=false
  fi

  # Handle based on marker state
  if [[ -f "$gitignore" && "$has_start" == "true" && "$has_end" == "true" ]]; then
    # Guard against multiple blocks — count occurrences of each marker
    local start_count end_count
    start_count=$(grep -cxF "$MARKER_START" "$gitignore" 2>/dev/null || true)
    end_count=$(grep -cxF "$MARKER_END" "$gitignore" 2>/dev/null || true)

    # If multiple blocks exist, treat as malformed — warn and append fresh block instead
    if [[ "$start_count" -gt 1 || "$end_count" -gt 1 ]]; then
      echo "Warning: agentic: multiple managed blocks found in $gitignore — appending fresh block instead of replacing" >&2
      printf '\n%s\n' "$AGENTIC_BLOCK" >> "$gitignore"
      return
    fi

    # Normal case: replace existing managed block in-place using pure bash parameter expansion
    local full before after
    full=$(< "$gitignore")
    before="${full%%"$MARKER_START"*}"
    after="${full##*"$MARKER_END"}"
    # Ensure trailing newline is preserved
    printf '%s%s%s\n' "$before" "$AGENTIC_BLOCK" "$after" > "$gitignore"

  elif [[ -f "$gitignore" && "$has_start" == "true" && "$has_end" == "false" ]]; then
    # Malformed: start marker present but end marker missing — warn and append fresh block
    echo "Warning: agentic: found '# agentic:start' without '# agentic:end' in $gitignore — appending fresh block" >&2
    printf '\n%s\n' "$AGENTIC_BLOCK" >> "$gitignore"

  elif [[ -f "$gitignore" ]]; then
    # No managed block exists — append to existing file
    printf '\n%s\n' "$AGENTIC_BLOCK" >> "$gitignore"

  else
    # Create new file with managed block
    printf '%s\n' "$AGENTIC_BLOCK" > "$gitignore"
  fi
}

# ── Dispatch ──────────────────────────────────────────────────────────────────
if [[ "$DRY_RUN" == "true" || "$STRUCTURE" == "flat" ]]; then
  compose_flat
else
  compose_nested
fi
