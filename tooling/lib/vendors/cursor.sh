#!/usr/bin/env bash
# cursor.sh — Vendor generation for Cursor

gen_cursor() {
  echo "  Generating Cursor adapter..."
  local vendor_dir="$VENDOR_FILES_DIR/cursor"
  local rules_dir="$vendor_dir/rules"
  local adapter="$LIBRARY/vendors/cursor/adapter.json"

  mkdir -p "$rules_dir"

  local core_file="$rules_dir/00-core.mdc"
  {
    echo "---"
    echo "description: Global engineering conventions"
    echo "alwaysApply: true"
    echo "---"
    echo ""
    autogen_header

    jq -r '.section_mappings[] | select(.activation_mode == "always-on") | .agents_md_heading' "$adapter" | \
    sed 's/^## //' | while read -r heading; do
      content=$(get_section_content "$heading")
      [[ -n "$content" ]] && printf '\n## %s\n\n%s\n' "$heading" "$content"
    done
  } > "$core_file"
  format_markdown "$core_file"
  echo "  Created: .agentic/vendor-files/cursor/rules/00-core.mdc"

  jq -r '.section_mappings[] | select(.activation_mode == "glob-scoped") | [.agents_md_heading, .output_file, (.frontmatter.globs // [] | join(","))] | @tsv' "$adapter" | \
  while IFS=$'\t' read -r heading out_file globs_csv; do
    heading_text="${heading#\## }"
    content=$(get_section_content "$heading_text")
    [[ -z "$content" ]] && continue

    local out_path="$rules_dir/$out_file"
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
    echo "  Created: .agentic/vendor-files/cursor/rules/$out_file"
  done
}
