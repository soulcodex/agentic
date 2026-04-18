#!/usr/bin/env bash
# copilot.sh — Vendor generation for Copilot
gen_copilot() {
  echo "  Generating Copilot adapter..."
  local vendor_dir="$VENDOR_FILES_DIR/copilot"
  local instructions_dir="$vendor_dir/instructions"
  local adapter="$LIBRARY/vendors/copilot/adapter.json"
  local global_file="$vendor_dir/copilot-instructions.md"

  mkdir -p "$vendor_dir" "$instructions_dir"

  # Global instructions file (all always-on sections concatenated)
  {
    autogen_header
    echo "# GitHub Copilot Instructions — ${PROJECT_NAME}"
    echo ""
    # Extract always-on sections by reading adapter mappings
    jq -r '.section_mappings[] | select(.activation_mode == "always-on") | .agents_md_heading' "$adapter" | \
    sed 's/^## //' | while read -r heading; do
      content=$(get_section_content "$heading")
      [[ -n "$content" ]] && printf '\n## %s\n\n%s\n' "$heading" "$content"
    done
  } > "$global_file"
  format_markdown "$global_file"
  echo "  Created: .agentic/vendor-files/copilot/copilot-instructions.md"

  # Per-language scoped instruction files
  jq -r '.section_mappings[] | select(.activation_mode == "glob-scoped") | [.agents_md_heading, .output_file, (.frontmatter.applyTo // "")] | @tsv' "$adapter" | \
  while IFS=$'\t' read -r heading out_file glob; do
    heading_text="${heading#\## }"
    content=$(get_section_content "$heading_text")
    [[ -z "$content" ]] && continue

    # Extract just the filename from output_file (e.g. instructions/typescript.instructions.md -> typescript.instructions.md)
    local out_filename
    out_filename=$(basename "$out_file")
    local out_path="$instructions_dir/$out_filename"
    {
      echo "---"
      echo "applyTo: \"${glob}\""
      echo "---"
      echo ""
      autogen_header
      printf '## %s\n\n%s\n' "$heading_text" "$content"
    } > "$out_path"
    format_markdown "$out_path"
    echo "  Created: .agentic/vendor-files/copilot/instructions/$out_filename"
  done
}