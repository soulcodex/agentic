#!/usr/bin/env bash
# claude.sh — Vendor generation for Claude
gen_claude() {
  echo "  Generating Claude adapter..."
  local vendor_dir="$VENDOR_FILES_DIR/claude"
  mkdir -p "$vendor_dir"
  local template="$LIBRARY/vendors/claude/template.CLAUDE.md"
  local out_file="$vendor_dir/CLAUDE.md"

  sed \
    -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
    -e "s|{{PROFILE_NAME}}|${PROFILE}|g" \
    -e "s|{{PROFILE_VERSION}}|${PROFILE_VER}|g" \
    -e "s|{{GENERATED_AT}}|${GENERATED_AT}|g" \
    -e "s|{{TARGET_PATH}}|${TARGET}|g" \
    "$template" > "$out_file"

  format_markdown "$out_file"
  echo "  Created: .agentic/vendor-files/claude/CLAUDE.md"
}