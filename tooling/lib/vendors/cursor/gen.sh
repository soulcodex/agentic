#!/usr/bin/env bash
# cursor.sh — Vendor generation for Cursor

gen_cursor() {
  echo "  Generating Cursor adapter..."
  local vendor_dir="$VENDOR_FILES_DIR/cursor"
  local rules_dir="$vendor_dir/rules"
  local lock_file="$TARGET/.agentic/config.yaml"
  local manifest_file="$vendor_dir/switch-manifest.json"
  local structure="flat"
  local manifest_entries='[{"target":".cursor/rules","source":".agentic/vendor-files/cursor/rules"}]'

  mkdir -p "$rules_dir"
  if [[ -f "$lock_file" ]]; then
    structure=$(yq '.structure // "flat"' "$lock_file" 2>/dev/null || echo "flat")
    [[ "$structure" == "null" ]] && structure="flat"
  fi

  generate_cursor_ruleset "$rules_dir" "root"
  echo "  Created: .agentic/vendor-files/cursor/rules/00-core.mdc"

  if [[ "$structure" == "nested" ]]; then
    local tiers=()
    while IFS= read -r _tier; do
      [[ -n "$_tier" && "$_tier" != "null" ]] && tiers+=("$_tier")
    done < <(yq '.tiers[]' "$lock_file" 2>/dev/null || true)

    local tier
    for tier in "${tiers[@]}"; do
      local tier_agents="$TARGET/$tier/AGENTS.md"
      [[ -f "$tier_agents" ]] || continue
      local tier_rules_dir="$rules_dir/$tier"
      mkdir -p "$tier_rules_dir"
      generate_cursor_ruleset "$tier_rules_dir" "$tier_agents"
      manifest_entries=$(printf '%s' "$manifest_entries" | jq --arg t "$tier" '. + [{"target":($t + "/.cursor/rules"),"source":(".agentic/vendor-files/cursor/rules/" + $t)}]')
      echo "  Created: .agentic/vendor-files/cursor/rules/$tier/00-core.mdc"
    done
  fi

  jq -n --argjson managed "$manifest_entries" '{version: 1, managed_paths: $managed}' > "$manifest_file"
  echo "  Created: .agentic/vendor-files/cursor/switch-manifest.json"
}

generate_cursor_ruleset() {
  local out_dir="$1"
  local source="$2" # "root" or path to AGENTS.md
  local adapter="$LIBRARY/vendors/cursor/adapter.json"
  local core_file="$out_dir/00-core.mdc"
  {
    echo "---"
    echo "description: Global engineering conventions"
    echo "alwaysApply: true"
    echo "---"
    echo ""
    autogen_header

    jq -r '.section_mappings[] | select(.activation_mode == "always-on") | .agents_md_heading' "$adapter" | \
    sed 's/^## //' | while read -r heading; do
      content=$(get_cursor_section_content "$heading" "$source")
      [[ -n "$content" ]] && printf '\n## %s\n\n%s\n' "$heading" "$content"
    done || true
  } > "$core_file"
  format_markdown "$core_file"

  jq -r '.section_mappings[] | select(.activation_mode == "glob-scoped") | [.agents_md_heading, .output_file, (.frontmatter.globs // [] | join(","))] | @tsv' "$adapter" | \
  while IFS=$'\t' read -r heading out_file globs_csv; do
    heading_text="${heading#\## }"
    content=$(get_cursor_section_content "$heading_text" "$source")
    [[ -z "$content" ]] && continue

    local out_path="$out_dir/$out_file"
    IFS=',' read -ra glob_list <<< "$globs_csv"

    {
      echo "---"
      echo "description: ${heading_text} language rules"
      echo "globs:"
      for glob in "${glob_list[@]}"; do
        [[ -n "$glob" ]] && printf '  - "%s"\n' "$glob"
      done
      echo "---"
      echo ""
      autogen_header
      printf '## %s\n\n%s\n' "$heading_text" "$content"
    } > "$out_path"

    format_markdown "$out_path"
    if [[ "$source" == "root" ]]; then
      echo "  Created: .agentic/vendor-files/cursor/rules/$out_file"
    else
      echo "  Created: .agentic/vendor-files/cursor/rules/$(basename "$out_dir")/$out_file"
    fi
  done || true
}

get_cursor_section_content() {
  local heading="$1"
  local source="$2"

  if [[ "$source" == "root" ]]; then
    get_section_content "$heading"
  else
    extract_section "$heading" "$source"
  fi
}
