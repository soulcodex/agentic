#!/usr/bin/env bash
# codex/switch.sh — vendor-switch behavior for Codex

vendor_codex_files_exist() {
  [[ -d "$VENDOR_FILES_DIR/codex" ]]
}

vendor_codex_create_symlinks() {
  echo "    Codex reads AGENTS.md natively — no file symlink needed"
  if [[ -d "$TARGET/.agentic/skills" ]]; then
    mkdir -p "$TARGET/.agents"
    ln -sf "../.agentic/skills" "$TARGET/.agents/skills"
    echo "    Linked: .agents/skills → ../.agentic/skills"
  fi
}
