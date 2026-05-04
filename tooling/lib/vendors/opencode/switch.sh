#!/usr/bin/env bash
# opencode/switch.sh — vendor-switch behavior for OpenCode

vendor_opencode_files_exist() {
  [[ -d "$VENDOR_FILES_DIR/opencode" ]]
}

vendor_opencode_preflight_conflicts() {
  local target_path="$TARGET/.opencode/agents"
  if [[ -e "$target_path" && ! -L "$target_path" ]]; then
    echo "Error: Cannot activate opencode agents because $target_path exists and is not a symlink." >&2
    return 1
  fi
}

vendor_opencode_create_symlinks() {
  if [[ -d "$TARGET/.agentic/skills" ]]; then
    mkdir -p "$TARGET/.opencode"
    ln -sfn "../.agentic/skills" "$TARGET/.opencode/skills"
    echo "    Linked: .opencode/skills → ../.agentic/skills"
  fi
  mkdir -p "$TARGET/.opencode"
  ln -sfn "../.agentic/agents/opencode" "$TARGET/.opencode/agents"
  echo "    Linked: .opencode/agents → ../.agentic/agents/opencode"
}
