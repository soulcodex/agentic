#!/usr/bin/env bash
# gemini/switch.sh — vendor-switch behavior for Gemini

vendor_gemini_files_exist() {
  [[ -f "$VENDOR_FILES_DIR/gemini/GEMINI.md" ]]
}

vendor_gemini_create_symlinks() {
  if [[ -f "$VENDOR_FILES_DIR/gemini/GEMINI.md" ]]; then
    ln -sf ".agentic/vendor-files/gemini/GEMINI.md" "$TARGET/GEMINI.md"
    echo "    Linked: GEMINI.md → .agentic/vendor-files/gemini/GEMINI.md"
  fi
  if [[ -f "$VENDOR_FILES_DIR/gemini/system.md" ]]; then
    mkdir -p "$TARGET/.gemini"
    ln -sf "../.agentic/vendor-files/gemini/system.md" "$TARGET/.gemini/system.md"
    echo "    Linked: .gemini/system.md → ../.agentic/vendor-files/gemini/system.md"
  fi
  if [[ -d "$TARGET/.agentic/skills" ]]; then
    mkdir -p "$TARGET/.gemini"
    ln -sf "../.agentic/skills" "$TARGET/.gemini/skills"
    echo "    Linked: .gemini/skills → ../.agentic/skills"
  fi
}
