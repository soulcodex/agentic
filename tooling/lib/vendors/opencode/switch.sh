#!/usr/bin/env bash
# opencode/switch.sh — vendor-switch behavior for OpenCode

vendor_opencode_files_exist() {
  [[ -d "$VENDOR_FILES_DIR/opencode" ]]
}

vendor_opencode_create_symlinks() {
  if [[ -d "$TARGET/.agentic/skills" ]]; then
    mkdir -p "$TARGET/.opencode"
    ln -sf "../.agentic/skills" "$TARGET/.opencode/skills"
    echo "    Linked: .opencode/skills → ../.agentic/skills"
  fi
}
