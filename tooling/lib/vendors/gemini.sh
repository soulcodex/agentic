#!/usr/bin/env bash
# gemini.sh — Vendor generation for Gemini
gen_gemini() {
  echo "  Generating Gemini adapter..."
  local vendor_dir="$VENDOR_FILES_DIR/gemini"
  mkdir -p "$vendor_dir"

  # ── GEMINI.md — primary context file (auto-discovered at project root) ──────
  local gemini_md_template="$LIBRARY/vendors/gemini/template.GEMINI.md"
  local gemini_md_out="$vendor_dir/GEMINI.md"

  # Use different sed delimiter to avoid issues with {{}} on macOS sed
  sed -e "s@{{PROJECT_NAME}}@${PROJECT_NAME}@g" \
      -e "s@{{PROFILE_NAME}}@${PROFILE}@g" \
      -e "s@{{PROFILE_VERSION}}@${PROFILE_VER}@g" \
      -e "s@{{GENERATED_AT}}@${GENERATED_AT}@g" \
      -e "s@{{TARGET_PATH}}@${TARGET}@g" \
      -e "s@{{ALL_SECTIONS}}@@g" \
      "$gemini_md_template" > "$gemini_md_out"

  if [[ "$COMPOSE_MODE" == "lean" && -d "$FRAGS_DIR" ]]; then
    echo "" >> "$gemini_md_out"
    for frag_file in "$FRAGS_DIR"/*.md; do
      [[ -f "$frag_file" ]] && cat "$frag_file" >> "$gemini_md_out" && echo "" >> "$gemini_md_out"
    done
  else
    local all_sections
    all_sections=$(awk '/^## /{found=1} found{print}' "$AGENTS_MD")
    { echo ""; echo "$all_sections"; } >> "$gemini_md_out"
  fi
  format_markdown "$gemini_md_out"
  echo "  Created: .agentic/vendor-files/gemini/GEMINI.md"

  # ── system.md — full system prompt override (requires GEMINI_SYSTEM_MD=1) ──
  local system_md_template="$LIBRARY/vendors/gemini/template.system.md"
  local system_md_out="$vendor_dir/system.md"

  sed -e "s@{{PROJECT_NAME}}@${PROJECT_NAME}@g" \
      -e "s@{{PROFILE_NAME}}@${PROFILE}@g" \
      -e "s@{{PROFILE_VERSION}}@${PROFILE_VER}@g" \
      -e "s@{{GENERATED_AT}}@${GENERATED_AT}@g" \
      -e "s@{{TARGET_PATH}}@${TARGET}@g" \
      -e "s@{{ALL_SECTIONS}}@@g" \
      "$system_md_template" > "$system_md_out"

  if [[ "$COMPOSE_MODE" == "lean" && -d "$FRAGS_DIR" ]]; then
    echo "" >> "$system_md_out"
    for frag_file in "$FRAGS_DIR"/*.md; do
      [[ -f "$frag_file" ]] && cat "$frag_file" >> "$system_md_out" && echo "" >> "$system_md_out"
    done
  else
    local all_sections_sys
    all_sections_sys=$(awk '/^## /{found=1} found{print}' "$AGENTS_MD")
    { echo ""; echo "$all_sections_sys"; } >> "$system_md_out"
  fi
  format_markdown "$system_md_out"
  echo "  Created: .agentic/vendor-files/gemini/system.md"
}