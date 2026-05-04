#!/usr/bin/env bash
# codex/switch.sh — vendor-switch behavior for Codex

vendor_codex_files_exist() {
  [[ -d "$VENDOR_FILES_DIR/codex" ]]
}

vendor_codex_preflight_conflicts() {
  local target_path="$TARGET/.agents/orchestration"
  if [[ -e "$target_path" && ! -L "$target_path" ]]; then
    echo "Error: Cannot activate codex agents because $target_path exists and is not a symlink." >&2
    return 1
  fi
}

vendor_codex_create_symlinks() {
  echo "    Codex reads AGENTS.md natively — no file symlink needed"
  if [[ -d "$TARGET/.agentic/skills" ]]; then
    mkdir -p "$TARGET/.agents"
    ln -sfn "../.agentic/skills" "$TARGET/.agents/skills"
    echo "    Linked: .agents/skills → ../.agentic/skills"
  fi
  mkdir -p "$TARGET/.agents"
  ln -sfn "../.agentic/agents/codex" "$TARGET/.agents/orchestration"
  echo "    Linked: .agents/orchestration → ../.agentic/agents/codex"
}
